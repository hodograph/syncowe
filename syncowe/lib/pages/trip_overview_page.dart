import 'package:flutter/material.dart';
import 'package:syncowe/models/transaction.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class TripOverviewPage extends StatefulWidget
{
  final String tripId;
  const TripOverviewPage({super.key, required this.tripId});

  @override
  State<StatefulWidget> createState() => _TripOverviewPage();
}

class _TripOverviewPage extends State<TripOverviewPage>
{
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

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
          return Center(child: Text("TBD"));
        }
      }
    );
  }
}