import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/components/user_manager.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/pages/edit_transaction_form.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class EditTripForm extends ConsumerStatefulWidget {
  /// Determines trip type when creating. Ignored when editing an existing trip.
  final bool isOneOff;

  const EditTripForm({super.key, this.isOneOff = false});

  @override
  ConsumerState<EditTripForm> createState() => _EditTripForm();
}

class _EditTripForm extends ConsumerState<EditTripForm> {
  List<String> _users = <String>[];
  Map<String, String> _namedUsers = <String, String>{};
  late bool _isOneOff;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _namedUserController = TextEditingController();

  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  Future<void> updateTrip() async {
    final String? tripId = ref.read(currentTripIdProvider);
    final bool isCreating = tripId == null;

    if (_nameController.text.isNotEmpty) {
      final String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      if (!_users.contains(currentUserId)) {
        _users.add(currentUserId);
      }

      final Trip trip = Trip(
        owner: currentUserId,
        name: _nameController.text,
        sharedWith: _users,
        isOneOff: _isOneOff,
        namedUsers: _isOneOff ? _namedUsers : const {},
      );

      final String savedTripId =
          await _tripFirestoreService.addOrUpdateTrip(trip, tripId);

      if (!mounted) return;

      if (_isOneOff && isCreating) {
        // New one-off: set trip context and go straight to adding the transaction.
        ref.read(currentTripIdProvider.notifier).setTrip(savedTripId);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
              builder: (context) => const EditTransactionForm()),
        );
      } else {
        Navigator.pop(context);
      }
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

  Future<void> _addNamedUser() async {
    _namedUserController.clear();
    final String? name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Participant"),
        content: TextField(
          controller: _namedUserController,
          autofocus: true,
          decoration: InputDecoration(
            labelText: "Name",
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          textCapitalization: TextCapitalization.words,
          onSubmitted: (_) =>
              Navigator.of(context).pop(_namedUserController.text.trim()),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: const Text("Cancel")),
          TextButton(
              onPressed: () =>
                  Navigator.of(context).pop(_namedUserController.text.trim()),
              child: const Text("Add")),
        ],
      ),
    );

    if (name != null && name.isNotEmpty) {
      final id = 'named_${DateTime.now().millisecondsSinceEpoch}';
      setState(() {
        _namedUsers = Map.from(_namedUsers)..[id] = name;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    Trip? currentTrip = ref.read(currentTripProvider);
    _nameController.text = currentTrip?.name ?? "";
    // isOneOff is fixed: from the existing trip when editing, or from widget param when creating.
    _isOneOff = currentTrip?.isOneOff ?? widget.isOneOff;
    _namedUsers = Map.from(currentTrip?.namedUsers ?? {});
    _users = ref.read(tripUsersProvider).entries.map((x) => x.key).toList();
  }

  @override
  Widget build(BuildContext context) {
    Trip? currentTrip = ref.watch(currentTripProvider);
    final bool isCreating = currentTrip == null;

    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: Text("${isCreating ? "Create" : "Edit"} "
              "${_isOneOff ? "One-Off" : "Trip"}"),
          centerTitle: true,
          actions: [
            if (!isCreating)
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
                child: TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: _isOneOff ? "Transaction Name" : "Trip Name",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textCapitalization: TextCapitalization.sentences,
                ),
              ),
            ),
            if (_isOneOff)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Participants",
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          OutlinedButton.icon(
                            onPressed: _addNamedUser,
                            icon: const Icon(Icons.person_add_alt_1),
                            label: const Text("Add"),
                          ),
                        ],
                      ),
                      if (_namedUsers.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12.0),
                          child: Text(
                            "No participants yet. Add people to split with.",
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _namedUsers.length,
                          itemBuilder: (context, index) {
                            final entry =
                                _namedUsers.entries.toList()[index];
                            return ListTile(
                              leading: const Icon(Icons.person_outline),
                              title: Text(entry.value),
                              trailing: IconButton(
                                icon: const Icon(Icons.person_remove_alt_1),
                                onPressed: () => setState(() {
                                  _namedUsers = Map.from(_namedUsers)
                                    ..remove(entry.key);
                                }),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
              )
            else
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
            const SizedBox(height: 75),
          ],
        ),
        floatingActionButton: FilledButton.icon(
          onPressed: updateTrip,
          icon: const Icon(Icons.check),
          label: Text("${isCreating ? "Create" : "Update"} "
              "${_isOneOff ? "One-Off" : "Trip"}"),
        ),
      ),
    );
  }
}
