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
        ? ref.watch(tripsProvider)
        : ref.watch(archivedTripsProvider);

    return DefaultTabController(
        length: 2,
        child: Scaffold(
            appBar: AppBar(
              title: const Text("SyncOwe"),
              centerTitle: true,
            ),
            body: ListView.builder(
                itemCount: trips.length,
                itemBuilder: (context, index) {
                  final String tripId = trips.entries.toList()[index].key;
                  final trip = trips[tripId]!;
                  return ListTile(
                    title: Center(child: Text(trip.name)),
                    onTap: () {
                      ref.read(currentTripIdProvider.notifier).setTrip(tripId);
                      Navigator.of(context)
                          .push(MaterialPageRoute(
                              builder: (context) => const TripPage()))
                          .then((context) => ref
                              .read(currentTripIdProvider.notifier)
                              .setTrip(null));
                    },
                  );
                }),
            floatingActionButton: FilledButton.icon(
              label: const Text("Create trip"),
              icon: const Icon(Icons.add),
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => const EditTripForm())),
            )));
  }
}
