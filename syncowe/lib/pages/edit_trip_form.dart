import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/components/user_manager.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class EditTripForm extends ConsumerStatefulWidget {
  const EditTripForm({super.key});

  @override
  ConsumerState<EditTripForm> createState() => _EditTripForm();
}

class _EditTripForm extends ConsumerState<EditTripForm> {
  List<String> _users = <String>[];

  final TextEditingController _nameController = TextEditingController();

  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  void updateTrip() {
    String? tripId = ref.watch(currentTripIdProvider);

    if (_nameController.text.isNotEmpty) {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      if (!_users.contains(currentUserId)) {
        _users.add(currentUserId);
      }

      Trip trip = Trip(
          owner: currentUserId, name: _nameController.text, sharedWith: _users);

      _tripFirestoreService.addOrUpdateTrip(trip, tripId);

      Navigator.pop(context);
    }
  }

  Future<void> archiveTrip() async {
    String? tripId = ref.read(currentTripIdProvider);
    Trip? trip = ref.read(currentTripProvider);

    bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Archive trip?"),
              content: Text(
                  "Are you sure you want to archive ${trip?.name}?\nYou will not be able to submit any new transactions or reimbursements once this is done."),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Yes")),
              ],
            ));

    if (trip != null && confirmed == true) {
      trip.isArchived = true;
      _tripFirestoreService.addOrUpdateTrip(trip, tripId);
    }
  }

  @override
  void initState() {
    super.initState();
    Trip? currentTrip = ref.read(currentTripProvider);
    _nameController.text = currentTrip?.name ?? "";
    _users = ref.read(tripUsersProvider).entries.map((x) => x.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    Trip? currentTrip = ref.watch(currentTripProvider);

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${currentTrip == null ? "Create" : "Edit"} Trip"),
          centerTitle: true,
          actions: [
            if (currentTrip != null)
              IconButton(
                icon: const Icon(Icons.archive),
                onPressed: archiveTrip,
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: "Trip Name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ],
                ),
              ),
            ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: UserManager(
                    onChange: (users) => setState(() {
                          _users = users.map((x) => x.id).toList();
                        }),
                    users: _users),
              ),
            ),
            const SizedBox(
              height: 75,
            )
          ],
        ),
        floatingActionButton: FilledButton.icon(
          onPressed: updateTrip,
          icon: const Icon(Icons.check),
          label: Text("${currentTrip == null ? "Create" : "Update"} Trip"),
        ),
      ),
    );
  }
}
