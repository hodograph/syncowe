import 'package:flutter/material.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/pages/edit_trip_form.dart';
import 'package:syncowe/pages/trip_page.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class TripsPage extends StatefulWidget
{
  const TripsPage({super.key});

  @override
  State<TripsPage> createState() => _TripsPage();
}

class _TripsPage extends State<TripsPage>
{
  final isDialOpen = ValueNotifier(false);

  final _tripsFirestoreService = TripFirestoreService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2, 
      child: Scaffold(
        appBar: AppBar(
          title: const Text("SyncOwe"),
          centerTitle: true,
        ),
        body: StreamBuilder(
          stream: _tripsFirestoreService.listenToTrips(), 
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
              final trips = snapshot.data!.docs.where((doc) => doc.data() is Trip).toList();

              if (trips.isEmpty)
              {
                return const Center(
                  child: Text("You are not part of any active Trips."),
                );
              }

              return ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) 
                {
                  final trip = trips[index].data() as Trip;
                  return ListTile(
                    title: Center(child: Text(trip.name)),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => TripPage(tripId: trips[index].id))
                      );
                    },
                  );
                }
              );
            }
          }
        ),
        floatingActionButton: FilledButton.icon(
          label: const Text("Create trip"),
          icon: const Icon(Icons.add),
          onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const EditTripForm(tripId: null))),
        )
      )
    );
  }
}