import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/pages/edit_transaction_form.dart';
import 'package:syncowe/pages/edit_trip_form.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/pages/trip_page.dart';
import 'package:syncowe/services/firestore/current_transaction.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class TripsPage extends ConsumerStatefulWidget {
  final bool archivedTrips;
  const TripsPage({super.key, this.archivedTrips = false});

  @override
  ConsumerState<TripsPage> createState() => _TripsPage();
}

class _TripsPage extends ConsumerState<TripsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _openTrip(String tripId, bool isOneOff) async {
    ref.read(currentTripIdProvider.notifier).setTrip(tripId);

    if (isOneOff) {
      final tripFirestoreService = TripFirestoreService();
      final snapshot =
          await tripFirestoreService.transactions(tripId).get();

      if (!mounted) return;

      if (snapshot.docs.isNotEmpty) {
        ref
            .read(currentTransactionIdProvider.notifier)
            .setTransactionId(snapshot.docs.first.id);
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => const TransactionSummaryPage()),
        );
        ref
            .read(currentTransactionIdProvider.notifier)
            .setTransactionId(null);
      } else {
        await Navigator.of(context).push(
          MaterialPageRoute(
              builder: (context) => const EditTransactionForm()),
        );
      }
    } else {
      await Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const TripPage()));
    }

    ref.read(currentTripIdProvider.notifier).setTrip(null);
  }

  Widget _buildTripList(Map<String, Trip> trips, bool isOneOff) {
    if (trips.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOneOff ? Icons.receipt_long_outlined : Icons.card_travel,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 20),
            Text(
              isOneOff ? 'No one-off transactions yet!' : 'No trips yet!',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            Text(
              isOneOff
                  ? 'Create a one-off transaction to get started.'
                  : 'Create a trip to get started.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8.0),
      itemCount: trips.length,
      itemBuilder: (context, index) {
        final String tripId = trips.entries.toList()[index].key;
        final trip = trips[tripId]!;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: ListTile(
            leading: Icon(isOneOff
                ? Icons.receipt_long_outlined
                : Icons.card_travel_outlined),
            title: Text(
              trip.name,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => _openTrip(tripId, isOneOff),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.archivedTrips) {
      final Map<String, Trip> trips = ref.watch(archivedTripsProvider);
      return Scaffold(
        appBar: AppBar(
          title: const Text("Archived Trips"),
          centerTitle: true,
        ),
        body: _buildTripList(trips, false),
      );
    }

    final Map<String, Trip> regularTripsList = ref.watch(regularTripsProvider);
    final Map<String, Trip> oneOffTripsList = ref.watch(oneOffTripsProvider);
    final bool isOnOneOffTab = _tabController.index == 1;

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Trips"),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.card_travel), text: "Trips"),
            Tab(icon: Icon(Icons.receipt_long_outlined), text: "One-Off"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripList(regularTripsList, false),
          _buildTripList(oneOffTripsList, true),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        label: Text(isOnOneOffTab ? "Create one-off" : "Create trip"),
        icon: const Icon(Icons.add),
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) =>
                EditTripForm(isOneOff: isOnOneOffTab),
          ),
        ),
      ),
    );
  }
}
