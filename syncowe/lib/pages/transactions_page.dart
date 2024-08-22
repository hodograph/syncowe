import 'package:flutter/material.dart';
import 'package:syncowe/models/transaction.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _tripFirestoreService.listenToTransactions(widget.tripId), 
      builder: (context, snapshot)
      {
        if (snapshot.hasError) 
        {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        else if (!snapshot.hasData) 
        {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        else
        {
          final transactions = snapshot.data!.docs.where((doc) => doc.data() is Transaction).toList();

          if (transactions.isEmpty)
          {
            return const Center(
              child: Text("There are no transactions in this trip."),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) 
            {
              final transaction = transactions[index].data() as Transaction;
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
                leading: Text("\$${transaction.total}",
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => TransactionSummaryPage(
                      tripId: widget.tripId, 
                      transactionId: transactions[index].id)
                    )
                  );
                },
              );
            }
          );
        }
      },
    );
  }
}