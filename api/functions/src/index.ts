import {onDocumentCreated, onDocumentCreatedWithAuthContext, onDocumentUpdatedWithAuthContext}
  from "firebase-functions/v2/firestore";
import * as admin from "firebase-admin";
import {DocumentReference, FieldValue, initializeFirestore, Timestamp}
  from "firebase-admin/firestore";
//import {defineSecret} from "firebase-functions/params";
import {onCall} from "firebase-functions/v2/https";
import DocumentIntelligence,
{AnalyzeResultOperationOutput,
  getLongRunningPoller,
  isUnexpected} from "@azure-rest/ai-document-intelligence";

//All available logging functions
import {log}
  from "firebase-functions/logger";

const app = admin.initializeApp();
const firestore = initializeFirestore(app, {preferRest: true});

const tripsCollectionName = "Trips";
const transactionsCollectionName = "Transactions";
const reimbursementsCollectionName = "Reimbursements";
const overallDebtsCollectionName = "OverallDebts";
const overallDebtSummaryCollectionName = "OverallDebtSummary";

const usersCollectionName = "Users";
const notificationsCollectionName = "Notifications";
const notificationTokensCollectionName = "NotificationTokens";

exports.readReceipt = onCall({secrets: ["AZURE_DOC_INTEL_API_KEY", "AZURE_DOC_INTEL_ENDPOINT"]}, async (request) => {
  if (request.auth?.token != undefined) {
    const client = DocumentIntelligence(process.env.AZURE_DOC_INTEL_ENDPOINT ?? "", {
      key: process.env.AZURE_DOC_INTEL_API_KEY ?? "",
    });

    const initialResponse =
      await client.path("/documentModels/{modelId}:analyze",
        "prebuilt-receipt")
        .post({
          contentType: "application/json",
          body: {
            base64Source: request.data
          },
        });

    if (isUnexpected(initialResponse)) {
      throw initialResponse.body.error;
    }

    const poller = await getLongRunningPoller(client, initialResponse);

    const analyzeResult = ((await (poller).pollUntilDone())
      .body as AnalyzeResultOperationOutput).analyzeResult;

    const documents = analyzeResult?.documents;

    const document = documents && documents[0];

    if (document) {
      if (document.fields != undefined) {
        let total: number = 0;
        const transactionName = document.fields["MerchantName"].valueString;
        const totalField = document.fields["Total"];

        // If total failed to be extracted, attempt to create it from subtotal, tip, and tax.
        if (totalField == undefined || totalField.valueCurrency == undefined)
        {
          const subtotal = document.fields["Subtotal"].valueCurrency;
          if (subtotal != undefined)
          {
            total += subtotal.amount;
          }

          const tip = document.fields["Tip"].valueCurrency;
          if (tip != undefined)
          {
            total += tip.amount;
          }

          const totalTax = document.fields["TotalTax"].valueCurrency;
          if (totalTax != undefined)
          {
            total += totalTax.amount;
          }
        }
        else
        {
          total = totalField.valueCurrency.amount;
        }

        const debts: Debt[] = [];

        document.fields["Items"].valueArray?.forEach((item) => {
          if (item.valueObject != undefined) {
            const itemQuantity = item.valueObject["Quantity"];

            if (itemQuantity.valueNumber != undefined) {
              const amount = itemQuantity.valueNumber;
              for (let i = 0; i < amount; i++) {
                const memo = item.valueObject["Description"].valueString;
                const itemPrice = (item.valueObject["TotalPrice"].valueCurrency?.amount ?? 0) / amount;

                if (itemPrice != undefined) {
                  debts.push(new Debt(itemPrice, "", memo ?? ""));
                }
                
              }
            }
          }
        });

        const transaction = new Transaction(transactionName ?? "",
          "",
          SplitType.proportionalSplit,
          total ?? 0,
          debts,
          [],
          undefined
        );

        return serializeFS(transaction);
      }
    }
  }

  return undefined;
});

exports.notificationCreated = onDocumentCreated(`/${usersCollectionName}` +
  `/{userId}/${notificationsCollectionName}/{notificationId}`,
async (event) => 
{
  const tokensRef = firestore.collection(usersCollectionName).doc(event.params.userId)
    .collection(notificationTokensCollectionName).where(nameof<NotificationToken>("enabled"),
    "==",
    true);
    
  const tokens = await tokensRef.get();

  const notification = event.data?.data() as Notification;

  tokens.forEach((token) => 
  {
    const notificationToken = token.data() as NotificationToken;

    const payload = {
      data: {
        notificationId: event.params.notificationId
      },
      notification: {
        title: notification.title,
        body: notification.message
      },
      token: notificationToken.token
    }
    
    admin.messaging().send(payload)
  });
});

exports.transactionCreated = onDocumentCreatedWithAuthContext(`/${tripsCollectionName}` +
  `/{tripId}/${transactionsCollectionName}/{transactionId}`,
async (event) => {
  const newTransaction = event.data?.data() as Transaction;

  await updateOverallSummariesFromTransaction(newTransaction,
    event.params.tripId,
    event.params.transactionId,
    event.authId);
});

exports.reimbursementCreated = onDocumentCreatedWithAuthContext(`/${tripsCollectionName}` +
  `/{tripId}/${reimbursementsCollectionName}/{reimbursementId}`,
async (event) => {
  await updateOverallSummariesFromReimbursement(
    event.data?.data() as Reimbursement,
    event.params.tripId,
    event.params.reimbursementId,
    event.authId);
});

exports.transactionUpdated = onDocumentUpdatedWithAuthContext(`/${tripsCollectionName}` +
  `/{tripId}/${transactionsCollectionName}/{transactionId}`,
async (event) => {
  await deleteOverallSummaries(event.params.tripId,
    event.params.transactionId);

  const newTransaction = event.data?.after.data() as Transaction;

  await updateOverallSummariesFromTransaction(newTransaction,
    event.params.tripId,
    event.params.transactionId,
    event.authId);
});

exports.reimbursementUpdated = onDocumentUpdatedWithAuthContext(`/${tripsCollectionName}` +
  `/{tripId}/${reimbursementsCollectionName}/{reimbursementId}`,
async (event) => {
  await deleteOverallSummaries(event.params.tripId,
    event.params.reimbursementId);

  const newReimbursement = event.data?.after.data() as Reimbursement;

  await updateOverallSummariesFromReimbursement(newReimbursement,
    event.params.tripId,
    event.params.reimbursementId,
    event.authId);
});

/**
 * adds summaries based on transaction.
 * @param {Transaction} newTransaction The transaction to use.
 * @param {string} tripId ID of parent trip.
 * @param {string} transactionId ID of transaction.
 * @param {string} submittingUser The user that submitted the update. Notifications will not be sent to them.
 */
async function updateOverallSummariesFromTransaction(
  newTransaction : Transaction,
  tripId: string,
  transactionId: string,
  submittingUser: string | undefined) {
  const tripDoc = firestore
    .collection(tripsCollectionName).doc(tripId);

  newTransaction.calculatedDebts.forEach(async (calculatedDebt) => {
    if (calculatedDebt.debtor == calculatedDebt.owedTo) {
      if(calculatedDebt.owedTo != submittingUser)
      {
        firestore
          .collection(usersCollectionName)
          .doc(calculatedDebt.owedTo)
          .collection(notificationsCollectionName)
          .add(serializeFS(new Notification(
            "Transaction Updated",
            `You are owed \$${(newTransaction.total - calculatedDebt.amount).toFixed(2)} for ${newTransaction.transactionName}`,
            tripId,
            transactionId,
            undefined
          )));
      }
      
      return;
    }

    let debtPair: DebtPair;
    let debtPairRef: DocumentReference;

    // get debt pair where payer and debtor are tracked.
    let debtsRef = await tripDoc.collection(overallDebtsCollectionName).where(
      nameof<DebtPair>("user1"),
      "==",
      calculatedDebt.owedTo).where(
      nameof<DebtPair>("user2"),
      "==",
      calculatedDebt.debtor).get();

    // if debt pair doesn't exist, check the reverse.
    if (debtsRef.docs.length == 0) {
      debtsRef = await tripDoc.collection(overallDebtsCollectionName).where(
        nameof<DebtPair>("user1"),
        "==",
        calculatedDebt.debtor).where(
        nameof<DebtPair>("user2"),
        "==",
        calculatedDebt.owedTo).get();

      // if debt pair still doesn't exist, create a debt pair.
      if (debtsRef.docs.length == 0) {
        debtPair = new DebtPair(calculatedDebt.owedTo, calculatedDebt.debtor);
        debtPairRef = await tripDoc.collection(overallDebtsCollectionName)
          .add(serializeFS(debtPair));
      } else {
        debtPair = debtsRef.docs[0].data() as DebtPair;
        debtPairRef = debtsRef.docs[0].ref;
      }
    } else {
      debtPair = debtsRef.docs[0].data() as DebtPair;
      debtPairRef = debtsRef.docs[0].ref;
    }

    debtPairRef.collection(overallDebtSummaryCollectionName).add(
      serializeFS(new OverallDebtSummary(
        calculatedDebt.debtor,
        calculatedDebt.owedTo,
        calculatedDebt.amount,
        newTransaction.transactionName,
        transactionId,
        false,
        false,
        newTransaction.createdDate!,
        false)));

    firestore
      .collection(usersCollectionName)
      .doc(calculatedDebt.debtor)
      .collection(notificationsCollectionName)
      .add(serializeFS(new Notification(
        "Transaction Updated",
        `You owe \$${calculatedDebt.amount.toFixed(2)} for ${newTransaction.transactionName}`,
        tripId,
        transactionId,
        undefined
      )));
  });
}

/**
 * deletes all linked summaries.
 * @param {string} tripId parent trip ID.
 * @param {string} transactionId linked transaction ID.
 */
async function deleteOverallSummaries(tripId: string, transactionId: string) {
  const tripDoc = firestore
    .collection(tripsCollectionName).doc(tripId);

  // Clear existing data related to this transaction.
  const allOverallDebts =
    await tripDoc.collection(overallDebtsCollectionName).get();
  allOverallDebts.docs.forEach( async (overallDebtDoc) => {
    const debtSummaries = await overallDebtDoc.ref
      .collection(overallDebtSummaryCollectionName).where(
        nameof<OverallDebtSummary>("transactionId"),
        "==",
        transactionId).get();

    debtSummaries.docs.forEach(async (debtSummary) => {
      await debtSummary.ref.delete();
    });
  });
}

/**
 * adds summaries based on reimbursement.
 * @param {Transaction} newReimbursement The reimbursement to use.
 * @param {string} tripId ID of parent trip.
 * @param {string} reimbursementId ID of reimbursement.
 * @param {string} submittingUser The user that submitted the reimbursement. Will not be sent notification.
 */
async function updateOverallSummariesFromReimbursement(
  newReimbursement: Reimbursement,
  tripId: string,
  reimbursementId: string,
  submittingUser: string | undefined) {
  const tripDoc = firestore
    .collection(tripsCollectionName).doc(tripId);

  let debtPair: DebtPair;
  let debtPairRef: DocumentReference;

  // get debt pair where payer and debtor are tracked.
  let debtsRef = await tripDoc.collection(overallDebtsCollectionName).where(
    nameof<DebtPair>("user1"),
    "==",
    newReimbursement.payer).where(
    nameof<DebtPair>("user2"),
    "==",
    newReimbursement.recipient).get();

  // if debt pair doesn't exist, check the reverse.
  if (debtsRef.docs.length == 0) 
  {
    debtsRef = await tripDoc.collection(overallDebtsCollectionName).where(
      nameof<DebtPair>("user1"),
      "==",
      newReimbursement.recipient).where(
      nameof<DebtPair>("user2"),
      "==",
      newReimbursement.payer).get();

    // if debt pair still doesn't exist, create a debt pair.
    if (debtsRef.docs.length == 0) 
    {
      debtPair = new DebtPair(newReimbursement.payer,
        newReimbursement.recipient);
      debtPairRef = await tripDoc.collection(overallDebtsCollectionName)
        .add(serializeFS(debtPair));
    } 
    else 
    {
      debtPair = debtsRef.docs[0].data() as DebtPair;
      debtPairRef = debtsRef.docs[0].ref;
    }
  } 
  else 
  {
    debtPair = debtsRef.docs[0].data() as DebtPair;
    debtPairRef = debtsRef.docs[0].ref;
  }
  let archive: boolean = false;

  // Only check and archive debts if reimbursement is confirmed.
  if(newReimbursement.confirmed)
  {
    const debtSummariesRef = await debtPairRef.collection(overallDebtSummaryCollectionName)
      .where(nameof<OverallDebtSummary>("archived"), "==", false).get();

    let totalOwed: number = 0;

    debtSummariesRef.forEach((debtSummaryRef) =>
    {
      const debtSummary = debtSummaryRef.data() as OverallDebtSummary;

      if(debtSummary.debtor == newReimbursement.payer)
      {
        if(debtSummary.isReimbursement)
        {
          totalOwed -= debtSummary.amount;
        }
        else
        {
          totalOwed += debtSummary.amount;
        }
      }
      else
      {
        if(debtSummary.isReimbursement)
        {
          totalOwed += debtSummary.amount;
        }
        else 
        {
          totalOwed -= debtSummary.amount;
        }
      }
    });
    log(totalOwed);

    totalOwed = parseFloat(totalOwed.toFixed(2));
    log(totalOwed);
    log(newReimbursement.amount);


    archive = totalOwed == newReimbursement.amount;

    if (archive)
    {
      const archiveParamUpdate: {[key:string]: any} = {};
      archiveParamUpdate[nameof<OverallDebtSummary>("archived")] = true;
      debtSummariesRef.forEach((debtSummaryRef) =>
      {
        debtSummaryRef.ref.update(archiveParamUpdate)
      });
    }

    firestore
        .collection(usersCollectionName)
        .doc(newReimbursement.payer)
        .collection(notificationsCollectionName)
        .add(serializeFS(new Notification(
          "Reimbursement Confirmed",
          `Reimbursement confirmed for \$${newReimbursement.amount}`,
          tripId,
          undefined,
          reimbursementId
        )));
  }

  debtPairRef.collection(overallDebtSummaryCollectionName)
      .add(serializeFS(new OverallDebtSummary(
        newReimbursement.payer,
        newReimbursement.recipient,
        newReimbursement.amount,
        "Reimbursement",
        reimbursementId,
        true,
        !newReimbursement.confirmed,
        newReimbursement.createdDate,
        archive
      )));

  if(!newReimbursement.confirmed)
  {
    if(newReimbursement.payer != submittingUser)
    {
      firestore
        .collection(usersCollectionName)
        .doc(newReimbursement.payer)
        .collection(notificationsCollectionName)
        .add(serializeFS(new Notification(
          "Reimbursement Updated",
          `You paid ${newReimbursement.amount}`,
          tripId,
          undefined,
          reimbursementId
        )));
    }

    if(newReimbursement.recipient != submittingUser)
    {
      firestore
        .collection(usersCollectionName)
        .doc(newReimbursement.recipient)
        .collection(notificationsCollectionName)
        .add(serializeFS(new Notification(
          "Reimbursement Updated",
          `You were paid ${newReimbursement.amount}`,
          tripId,
          undefined,
          reimbursementId
        )));
    }
  }
}

const nameof = <T>(name: Extract<keyof T, string>): string => name;

/**
 * serializes for firestore.
 * @param {any} value object to serialize.
 * @return {any} serialized object.
 */
function serializeFS(value: any) : any {
  const isDate = (value: any) => {
    if (value instanceof Date || value instanceof Timestamp) {
      return true;
    }
    try {
      if (value.toDate() instanceof Date) {
        return true;
      }
    } catch (e) {
      // intentionally left blank.
    }

    return false;
  };

  if (value == null) {
    return null;
  }
  if (typeof value == "boolean" ||
      typeof value == "bigint" ||
      typeof value == "string" ||
      typeof value == "symbol" ||
      typeof value == "number" ||
      isDate(value) ||
      value instanceof FieldValue) {
    return value;
  }

  if (Array.isArray(value)) {
    return (value as Array<any>).map((v) => serializeFS(v));
  }

  const res : any = {};
  for (const key of Object.keys(value)) {
    res[key] = serializeFS(value[key]);
  }
  return res;
}

/**
 * DebtPair model.
 */
class DebtPair {
  user1: string;
  user2: string;

  /**
   * @param {string} user1 first user id of the pair.
   * @param {string} user2 second user id of the pair.
   */
  public constructor(user1: string, user2: string) {
    this.user1 = user1;
    this.user2 = user2;
  }
}

class Notification {
  title: string;
  message: string;
  transactionId: string | undefined;
  reimbursementId: string | undefined;
  tripId: string;
  timestamp: FieldValue;

  public constructor(
    title: string,
    message: string,
    tripId: string,
    transactionId: string | undefined,
    reimbursementId: string | undefined
  )
  {
    this.title = title;
    this.message = message;
    this.tripId = tripId;
    this.transactionId = transactionId;
    this.reimbursementId = reimbursementId;
    this.timestamp = FieldValue.serverTimestamp();
  }
}

class NotificationToken {
  token: string;
  enabled: boolean;

  public constructor(token: string, enabled: boolean)
  {
    this.token = token;
    this.enabled = enabled;
  }
}

/**
 * OverallDebtSummary model.
 */
class OverallDebtSummary {
  debtor: string;
  payer: string;
  amount: number;
  memo: string;
  transactionId: string;
  isReimbursement: boolean;
  isPending: boolean;
  createdDate: Timestamp;
  archived: boolean;

  /**
   * @param {string} debtor who owed money.
   * @param {string} payer who is owed money.
   * @param {number} amount the amount owed.
   * @param {string} memo title of why money is owed.
   * @param {string} transactionId ID of the memo that caused this.
   * @param {boolean} isReimbursement if this is a reimbursement or not.
   * @param {boolean} isPending if this reimbursement has been confirmed.
   * @param {Timestamp} createdDate time this was created.
   */
  public constructor(
    debtor: string,
    payer: string,
    amount: number,
    memo: string,
    transactionId: string,
    isReimbursement: boolean,
    isPending: boolean,
    createdDate: Timestamp,
    archived: boolean | undefined
  ) {
    this.debtor = debtor;
    this.payer = payer;
    this.amount = amount;
    this.memo = memo;
    this.transactionId = transactionId;
    this.isReimbursement = isReimbursement;
    this.isPending = isPending;
    this.createdDate = createdDate;
    this.archived = archived ?? false;
  }
}

/**
 * Transaction model.
 */
class Transaction {
  transactionName: string;
  payer: string;
  splitType: SplitType;
  total: number;
  debts: Debt[];
  calculatedDebts: CalculatedDebt[];
  createdDate: Timestamp | undefined;

  /**
   *
   * @param {string} transactionName the name of the transaction
   * @param {string} payer who paid for this transaction
   * @param {SplitType} splitType the method of splitting the remainder
   * @param {number} total the total amount spent for this transaction.
   * @param {Debt[]} debts the debts for this transaction.
   * @param {CalculatedDebt[]} calculatedDebts the calculated debts.
   * @param {Timestamp | undefined} createdDate time this was created.
   */
  public constructor(transactionName: string,
    payer: string,
    splitType: SplitType,
    total: number,
    debts: Debt[],
    calculatedDebts: CalculatedDebt[],
    createdDate: Timestamp | undefined ) {
    this.transactionName = transactionName;
    this.payer = payer;
    this.splitType = splitType;
    this.total = total;
    this.debts = debts;
    this.calculatedDebts = calculatedDebts;
    this.createdDate = createdDate;
  }
}

/**
 * Reimbursement model.
 */
class Reimbursement {
  payer: string;
  recipient: string;
  amount: number;
  confirmed: boolean;
  createdDate: Timestamp;

  /**
   *
   * @param {string} payer who payed this reimbursement.
   * @param {string} recipient who received this reimbursement.
   * @param {number} amount how much was sent.
   * @param {boolean} confirmed if the recipient has confirmed they received.
   * @param {Timestamp} createdDate date this reimbursements was
   * submitted.
   */
  public constructor(payer: string,
    recipient: string,
    amount: number,
    confirmed: boolean,
    createdDate: Timestamp) {
    this.payer = payer;
    this.recipient = recipient;
    this.amount = amount;
    this.confirmed = confirmed;
    this.createdDate = createdDate;
  }
}

/**
 * Type of split method to apply to remainder.
 */
enum SplitType {
  evenSplit = "evenSplit",
  proportionalSplit = "proportionalSplit",
  payerPays = "payerPays"
}

/**
 * Debt model.
 */
class Debt {
  amount: number;
  debtor: string;
  memo: string;

  /**
   * @param {number} amount the amount owed for this item.
   * @param {string} debtor the person who owes the payer for this item.
   * @param {string} memo A note about what this was for.
   */
  public constructor(amount: number, debtor: string, memo: string) {
    this.amount = amount;
    this.debtor = debtor;
    this.memo = memo;
  }
}

/**
 * Calculated Debt model.
 */
class CalculatedDebt {
  debtor: string;
  amount: number;
  owedTo: string;
  summary: CalculatedDebtSummaryEntry[];
  createdDate: Timestamp | undefined;

  /**
   * @param {string} debtor Who owes the money.
   * @param {number} amount The overall amount the user owes.
   * @param {string} owedTo Who the money is owed to.
   * @param {CalculatedDebtSummaryEntry[]} summary list of summary items.
   * @param {Timestamp | undefined} createdDate time this was created.
   */
  public constructor(debtor: string,
    amount: number,
    owedTo: string,
    summary: CalculatedDebtSummaryEntry[],
    createdDate: Timestamp | undefined) {
    this.debtor = debtor;
    this.amount = amount;
    this.owedTo = owedTo;
    this.summary = summary;
    this.createdDate = createdDate;
  }
}

/**
 * Calculated Debt Summary Entry model.
 */
class CalculatedDebtSummaryEntry {
  memo: string;
  amount: number;
  createdDate: Timestamp | undefined;

  /**
   * @param {string} memo note about what this value is for.
   * @param {number} amount the amount this memo changed the overall number.
   * @param {Timestamp | undefined} createdDate time this was created.
   */
  public constructor(memo: string,
    amount: number,
    createdDate: Timestamp | undefined) {
    this.memo = memo;
    this.amount = amount;
    this.createdDate = createdDate;
  }
}
