import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/components/user_manager.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class EditTripForm extends ConsumerStatefulWidget
{
  const EditTripForm({super.key});

  @override
  ConsumerState<EditTripForm> createState() => _EditTripForm();
}

class _EditTripForm extends ConsumerState<EditTripForm>
{
  List<String> _users = <String>[];

  final TextEditingController _nameController = TextEditingController();

  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  void updateTrip()
  {
    String? tripId = ref.watch(currentTripIdProvider);
    
    if(_nameController.text.isNotEmpty)
    {
      String currentUserId = FirebaseAuth.instance.currentUser!.uid;

      if (!_users.contains(currentUserId)){
        _users.add(currentUserId);
      }

      Trip trip = Trip(
        owner: currentUserId, 
        name: _nameController.text,
        sharedWith: _users);

      _tripFirestoreService.addOrUpdateTrip(trip, tripId);

      Navigator.pop(context);
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

    return SafeArea
    (
      child: Scaffold(
        appBar: AppBar(
          title: Text("${currentTrip == null ? "Create" : "Edit"} Trip"),
          centerTitle: true,
        ),
        body: 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: 
          SingleChildScrollView
          (
            primary: false,
            child: Column
            (
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 15,),
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(label: Text("Trip Name")),
                ),
                const SizedBox(height: 15,),
                UserManager(
                  onChange: (users) => setState(() {
                    _users = users.map((x) => x.id).toList();
                  }), 
                  users: _users),
                const SizedBox(height: 15,),
                Center( 
                  child: TextButton(
                    onPressed: () => updateTrip(), 
                    child: Text("${currentTrip == null ? "Create" : "Update"} Trip")
                  )
                )
              ],
            )
          )
        ),
      ),
    );
  }
}