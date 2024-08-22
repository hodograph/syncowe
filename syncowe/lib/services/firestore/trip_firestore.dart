import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:syncowe/models/debt.dart';
import 'package:syncowe/models/reimbursement.dart';
import 'package:syncowe/models/split_type.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/models/transaction.dart' as syncowe_transaction;

class TripFirestoreService
{
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  final CollectionReference _trips = FirebaseFirestore.instance.collection("Trips").withConverter<Trip>(
    fromFirestore: Trip.fromFirestore,
    toFirestore: (trip, options) => (trip).toJson());

  Stream<QuerySnapshot> listenToTrips()
  {
    return _trips.where(NameofTrip.fieldSharedWith, arrayContains: _firebaseAuth.currentUser!.uid).snapshots();
  }

  Stream<Trip?> listenToTrip(String id)
  {
    return _trips.doc(id).snapshots().map((snapshot) => snapshot.data() as Trip);
  }

  Future<Trip?> getTrip(String id) async
  {
    Trip? trip;
    final docRef = getTripDoc(id);
    final doc = await docRef.get();
    
    if(doc.exists)
    {
      trip = doc.data() as Trip;
    }

    return trip;
  }

  DocumentReference getTripDoc(String id)
  {
    return _trips.doc(id);
  }

  Future<void> addOrUpdateTrip(Trip trip, String? id) async
  {
    if(id == null)
    {
      await _trips.add(trip);
    }
    else
    {
      await _trips.doc(id).set(trip);
    }
  }

  CollectionReference _transactions(String tripId)
  {
    return getTripDoc(tripId).collection("Transactions").withConverter<syncowe_transaction.Transaction>(
      fromFirestore: syncowe_transaction.Transaction.fromFirestore, 
      toFirestore: (transaction, options) => transaction.toJson());
  }

  Stream<syncowe_transaction.Transaction?> listenToTransaction(String tripId, String id)
  {
    return _transactions(tripId).doc(id).snapshots().map((snapshot) => snapshot.data() as syncowe_transaction.Transaction);
  }

  Future<syncowe_transaction.Transaction?> getTransaction(String tripId, String id) async
  {
    syncowe_transaction.Transaction? transaction;
    final docRef = getTransactionDoc(tripId, id);
    final doc = await docRef.get();

    if(doc.exists)
    {
      transaction = doc.data() as syncowe_transaction.Transaction;
    }

    return transaction;
  }

  DocumentReference getTransactionDoc(String tripId, String transactionId)
  {
    return _transactions(tripId).doc(transactionId);
  }

  Stream<QuerySnapshot> listenToTransactions(String tripId)
  {
    return _transactions(tripId).snapshots();
  }

  Future<String> addOrUpdateTransaction(syncowe_transaction.Transaction transaction, String tripId, String? id) async
  {
    if (id == null)
    {
      var doc = await _transactions(tripId).add(transaction);
      return doc.id;
    }
    else
    {
      await _transactions(tripId).doc(id).set(transaction);
      return id;
    }
  }

  Future<Map<String, double>> calculateDebtsForTransaction(String tripId, String transactionId) async
  {
    Map<String, double> calculatedDebts = <String, double>{};
    
    var transaction = await getTransaction(tripId, transactionId);
    List<Debt> debts = await getDebts(tripId, transactionId);

    if (transaction != null)
    {
      for (Debt debt in debts)
      {
        calculatedDebts[debt.debtor] = (calculatedDebts[debt.debtor] ?? 0) + debt.amount;
      }

      if (!calculatedDebts.containsKey(transaction.payer))
      {
        calculatedDebts[transaction.payer] = 0;
      }

      double totalDebts = calculatedDebts.values.reduce((a, b) => a + b);
      double remainder = transaction.total - totalDebts;

      if (transaction.splitType == SplitType.evenSplit)
      {
        for (String debtor in calculatedDebts.keys)
        {
          calculatedDebts[debtor] = calculatedDebts[debtor]! + (remainder/calculatedDebts.length);
        }
      }
      else if (transaction.splitType == SplitType.proportionalSplit)
      {
        for (String debtor in calculatedDebts.keys)
        {
          double proportionalPercent = calculatedDebts[debtor]! / totalDebts;
          calculatedDebts[debtor] = calculatedDebts[debtor]! + (remainder * proportionalPercent);
        }
      }
      else if(transaction.splitType == SplitType.payerPays)
      {
        calculatedDebts[transaction.payer] = calculatedDebts[transaction.payer]! + remainder;
      }
    }

    return calculatedDebts;
  }

  CollectionReference _debts(String tripId, String transactionId)
  {
    return getTransactionDoc(tripId, transactionId).collection("Debts").withConverter<Debt>(
      fromFirestore: Debt.fromFirestore, 
      toFirestore: (debt, options) => debt.toJson());
  }

  Future<List<Debt>> getDebts(String tripId, String transactionId) async
  {
    var debtSnapshots = await _debts(tripId, transactionId).get();
    return debtSnapshots.docs.map((snapshot) => snapshot.data() as Debt).toList();
  }

  Stream<Debt?> listenToDebt(String tripId, String transactionId, String id)
  {
    return _debts(tripId, transactionId).doc(id).snapshots().map((snapshot) => snapshot.data() as Debt);
  }

  Future<Debt?> getDebt(String tripId, String transactionId, String id) async
  {
    Debt? debt;
    final docRef = getDebtDoc(tripId, transactionId, id);
    final doc = await docRef.get();

    if(doc.exists)
    {
      debt = doc.data() as Debt;
    }

    return debt;
  }

  DocumentReference getDebtDoc(String tripId, String transactionId, String debtId)
  {
    return _debts(tripId, transactionId).doc(debtId);
  }

  Stream<QuerySnapshot> listenToDebts(String tripId, String transactionId)
  {
    return _debts(tripId, transactionId).snapshots();
  }

  Future<void> addOrUpdateDebt(Debt debt, String tripId, String transactionId, String? id) async
  {
    if (id == null)
    {
      await _debts(tripId, transactionId).add(debt);
    }
    else
    {
      await _debts(tripId, transactionId).doc(id).set(debt);
    }
  }

  Future<void> writeAllDebts(List<Debt> debts, String tripId, String transactionId) async
  {
    CollectionReference debtsCollection = _debts(tripId, transactionId);
    var debtDocs = await debtsCollection.get();
    for(QueryDocumentSnapshot snapshot in debtDocs.docs)
    {
      snapshot.reference.delete();
    }

    for(Debt debt in debts)
    {
      debtsCollection.add(debt);
    }
  }

  CollectionReference _reimbursements(String tripId)
  {
    return getTripDoc(tripId).collection("Reimbursements");
  }
}