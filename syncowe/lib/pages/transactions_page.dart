import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncowe/models/calculated_debt.dart';
import 'package:syncowe/models/transaction.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';
import 'package:collection/collection.dart';

class TransactionsPage extends StatefulWidget
{
  final String tripId;
  const TransactionsPage({super.key, required this.tripId});

  @override
  State<StatefulWidget> createState() => _TransactionPage();
}

class _TransactionPage extends State<TransactionsPage>
{
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  double getPersonalChange(Transaction transaction, String user)
  {
    if(transaction.payer == user)
    {
      CalculatedDebt payerDebt = transaction.calculatedDebts.firstWhere((x) => x.debtor == user);
      return transaction.total - payerDebt.amount;
    }
    else
    {
      CalculatedDebt? personalDebt = transaction.calculatedDebts.firstWhereOrNull((x) => x.debtor == user);
      if (personalDebt != null)
      {
        return personalDebt.amount;
      }
      else{
        return 0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return FirestorePagination(
      isLive: true,
      padding: const EdgeInsets.only(bottom: 75),
      viewType: ViewType.list,
      query: _tripFirestoreService.transactions(widget.tripId).orderBy(NameofTransaction.fieldCreatedDate, descending: true), 
      itemBuilder: (context, snapshot, index)
      {
        Transaction transaction = snapshot[index].data() as Transaction;

        double personalChange = getPersonalChange(transaction, _userFirestoreService.currentUserId());
        Color changeColor = personalChange == 0 ? 
          Theme.of(context).colorScheme.onPrimary : 
          transaction.payer == _userFirestoreService.currentUserId() ? 
            Colors.green : 
            Colors.red;

        return ListTile(
          title: Text(transaction.transactionName),
          subtitle: FutureBuilder(
            future: _userFirestoreService.getUser(transaction.payer),
            builder: (context, snapshot)
            {
              if(snapshot.hasError)
              {
                return Text('Error: ${snapshot.error}');
              }
              else if(!snapshot.hasData)
              {
                return const CircularProgressIndicator();
              }
              else
              {
                User? user = snapshot.data;
                if(user != null)
                {
                  return Text(user.displayName ?? user.email);
                }
                else
                {
                  return const CircularProgressIndicator();
                }
              }
            },
          ),
          leading: Text(
            NumberFormat.currency(
              locale: "en_US", 
              symbol: "\$")
            .format(transaction.total),
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          trailing: Text( personalChange != 0 ?
            NumberFormat.currency(
              locale: "en_US", 
              symbol: "\$")
            .format(personalChange) :
            "-",
            style: Theme.of(context).textTheme.headlineSmall!.copyWith(
              color: changeColor
            ),
          ),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => TransactionSummaryPage(
                tripId: widget.tripId, 
                transactionId: snapshot[index].id)
              )
            );
          },
        );
      }
    );
    
    // return StreamBuilder(
    //   stream: _tripFirestoreService.listenToTransactions(widget.tripId), 
    //   builder: (context, snapshot)
    //   {
    //     if (snapshot.hasError) 
    //     {
    //       return Center(
    //         child: Text('Error: ${snapshot.error}'),
    //       );
    //     }
    //     else if (!snapshot.hasData) 
    //     {
    //       return const Center(
    //         child: CircularProgressIndicator(),
    //       );
    //     }
    //     else
    //     {
    //       final transactions = snapshot.data!.docs.where((doc) => doc.data() is Transaction).toList();

    //       if (transactions.isEmpty)
    //       {
    //         return const Center(
    //           child: Text("There are no transactions in this trip."),
    //         );
    //       }

    //       transactions.sort((b, a) => 
    //         ((a.data() as Transaction).createdDate as DateTime).compareTo((b.data() as Transaction).createdDate as DateTime));

    //       return ListView.builder(
    //         itemCount: transactions.length,
    //         itemBuilder: (context, index) 
    //         {
    //           final transaction = transactions[index].data() as Transaction;

    //           double personalChange = getPersonalChange(transaction, _userFirestoreService.currentUserId());
    //           Color changeColor = personalChange == 0 ? 
    //             Theme.of(context).colorScheme.onPrimary : 
    //             transaction.payer == _userFirestoreService.currentUserId() ? 
    //               Colors.green : 
    //               Colors.red;

    //           return ListTile(
    //             title: Text(transaction.transactionName),
    //             subtitle: FutureBuilder(
    //               future: _userFirestoreService.getUser(transaction.payer),
    //               builder: (context, snapshot)
    //               {
    //                 if(snapshot.hasError)
    //                 {
    //                   return Text('Error: ${snapshot.error}');
    //                 }
    //                 else if(!snapshot.hasData)
    //                 {
    //                   return const CircularProgressIndicator();
    //                 }
    //                 else
    //                 {
    //                   User? user = snapshot.data;
    //                   if(user != null)
    //                   {
    //                     return Text(user.displayName ?? user.email);
    //                   }
    //                   else
    //                   {
    //                     return const CircularProgressIndicator();
    //                   }
    //                 }
    //               },
    //             ),
    //             leading: Text(
    //               NumberFormat.currency(
    //                 locale: "en_US", 
    //                 symbol: "\$")
    //               .format(transaction.total),
    //               style: Theme.of(context).textTheme.headlineMedium,
    //             ),
    //             trailing: Text( personalChange != 0 ?
    //               NumberFormat.currency(
    //                 locale: "en_US", 
    //                 symbol: "\$")
    //               .format(personalChange) :
    //               "-",
    //               style: Theme.of(context).textTheme.headlineSmall!.copyWith(
    //                 color: changeColor
    //               ),
    //             ),
    //             onTap: () {
    //               Navigator.of(context).push(
    //                 MaterialPageRoute(builder: (context) => TransactionSummaryPage(
    //                   tripId: widget.tripId, 
    //                   transactionId: transactions[index].id)
    //                 )
    //               );
    //             },
    //           );
    //         }
    //       );
    //     }
    //   },
    // );
  }
}