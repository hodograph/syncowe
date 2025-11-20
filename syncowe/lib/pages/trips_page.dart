import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/pages/edit_trip_form.dart';
import 'package:syncowe/pages/trip_page.dart';
import 'package:syncowe/services/firestore/current_trip.dart';

class TripsPage extends ConsumerStatefulWidget {
  final bool archivedTrips;
  const TripsPage({super.key, this.archivedTrips = false});

  @override
  ConsumerState<TripsPage> createState() => _TripsPage();
}

class _TripsPage extends ConsumerState<TripsPage> {
  final isDialOpen = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    final Map<String, Trip> trips = widget.archivedTrips
        ? ref.watch(archivedTripsProvider)
        : ref.watch(tripsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.archivedTrips ? "Archived Trips" : "My Trips"),
        centerTitle: true,
      ),
      body: trips.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.card_travel,
                    size: 80,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No trips yet!',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Create a trip to get started.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: trips.length,
              itemBuilder: (context, index) {
                final String tripId = trips.entries.toList()[index].key;
                final trip = trips[tripId]!;
                return Card(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: ListTile(
                    leading: const Icon(Icons.card_travel_outlined),
                    title: Text(
                      trip.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    trailing: const Icon(Icons.arrow_forward_ios_rounded),
                    onTap: () {
                      ref.read(currentTripIdProvider.notifier).setTrip(tripId);
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => const TripPage()))
                          .then((context) => ref
                              .read(currentTripIdProvider.notifier)
                              .setTrip(null));
                    },
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        label: const Text("Create trip"),
        icon: const Icon(Icons.add),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const EditTripForm()),
        ),
      ),
    );
  }
}
