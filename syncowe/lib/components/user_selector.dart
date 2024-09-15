import 'package:flutter/material.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class UserSelector extends StatefulWidget
{
  final List<String> availableUserIds;
  final ValueChanged<User?> onSelectedUserChanged;
  final String? initialUser;
  final String label;

  const UserSelector({super.key, 
    required this.availableUserIds, 
    required this.onSelectedUserChanged, 
    required this.label, 
    this.initialUser});

  @override
  State<StatefulWidget> createState() => _UserSelector();
}

class _UserSelector extends State<UserSelector>
{
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  User? selectedUser;
  final User _noneUser = User(displayName: "None", id: "", email: "None", picture: null);
  List<User> availableUsers = <User>[];

  bool _usersInitialized = false;
  bool _userInitialized = false;

  Future<void> initUserData() async
  {
    bool updated = false;
    if (widget.availableUserIds.any((id) => !availableUsers.any((user) => user.id == id)))
    {
      availableUsers.clear();
      availableUsers.add(_noneUser);
      for(String id in widget.availableUserIds)
      {
        User? user = await _userFirestoreService.getUser(id);
        if (user != null && !availableUsers.any((x) => x.id == user.id))
        {
          availableUsers.add(user);
        }
      }
      _usersInitialized = true;
      updated = true;
    }

    if (widget.initialUser?.isNotEmpty ?? false)
    {
      // Only update user if id is new or user was not previously set.
      if (selectedUser != null && selectedUser!.id != widget.initialUser || selectedUser == null)
      {
        var futureSelectedUser = await _userFirestoreService.getUser(widget.initialUser!);

        selectedUser = futureSelectedUser;
        _userInitialized  = true;
        updated = true;
      }
    }
    else if(selectedUser != _noneUser)
    {
      selectedUser = _noneUser;
      _userInitialized = true;
      updated = true;
    }

    if(updated && _usersInitialized && _userInitialized)
    {
      setState(() {
        
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    initUserData();
    
    return DropdownButtonFormField<User>(
      value: selectedUser,
      items: availableUsers.map((user) => DropdownMenuItem<User>(
          value: user,
          child: Text(user.getDisplayString()),
          )
        ).toList(),
      onChanged: (option) => setState(() {
        selectedUser = option;
        widget.onSelectedUserChanged(option);
      }),
      decoration: InputDecoration(label: Text(widget.label)),
    );
  }
}