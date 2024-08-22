import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:syncowe/components/user_manager.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class EditTripForm extends StatefulWidget
{
  final String? tripId;
  const EditTripForm({super.key, required this.tripId});

  @override
  State<StatefulWidget> createState() => _EditTripForm();
}

class _EditTripForm extends State<EditTripForm>
{
  List<String> _users = <String>[];

  final TextEditingController _nameController = TextEditingController();

  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  Trip? tripToEdit;

  @override
  void initState() {
    initTripData();

    super.initState();
  }

  Future<void> initTripData() async
  {
    if (widget.tripId != null){
      tripToEdit = await _tripFirestoreService.getTrip(widget.tripId!);
      setState(() {
        if(tripToEdit != null)
        {
          for (String userId in tripToEdit!.sharedWith)
          {
            _users.add(userId);
          }
        }

        _nameController.text = tripToEdit?.name ?? "";
      });
    }
  }

  void updateTrip()
  {
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

      _tripFirestoreService.addOrUpdateTrip(trip, widget.tripId);

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {    
    return SafeArea
    (
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.tripId == null ? "Create" : "Edit"} Trip"),
          centerTitle: true,
        ),
        body: 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
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
                  child: Text("${widget.tripId == null ? "Create" : "Update"} Trip")
                )
              )
            ],
          )
        ),
      ),
    );
  }
}