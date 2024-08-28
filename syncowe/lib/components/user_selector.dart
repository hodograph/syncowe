import 'package:flutter/material.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class UserSelector extends StatefulWidget
{
  final List<String> availableUserIds;
  final ValueChanged<User> onSelectedUserChanged;
  final String? initialUser;
  final String label;
  final OptionsViewOpenDirection openDirection;

  const UserSelector({super.key, 
    required this.availableUserIds, 
    required this.onSelectedUserChanged, 
    required this.label, 
    this.initialUser,
    this.openDirection = OptionsViewOpenDirection.down});

  @override
  State<StatefulWidget> createState() => _UserSelector();
}

class _UserSelector extends State<UserSelector>
{
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  User? selectedUser;
  List<User> availableUsers = <User>[];

  Future<void> initUserData() async
  {
    if (widget.initialUser?.isNotEmpty ?? false)
    {
      // Only update user if id is new or user was not previously set.
      if (selectedUser != null && selectedUser!.id != widget.initialUser || selectedUser == null)
      {
        var futureSelectedUser = await _userFirestoreService.getUser(widget.initialUser!);

        setState(() {
          selectedUser = futureSelectedUser;
        });
      }
    }
    
    for(String id in widget.availableUserIds)
    {
      User? user = await _userFirestoreService.getUser(id);
      if (user != null && !availableUsers.any((x) => x.id == user.id))
      {
        availableUsers.add(user);
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    initUserData();
    
    return Autocomplete<User>(
      optionsViewOpenDirection: widget.openDirection,
      optionsBuilder: (textEditingValue)
      {
        if (textEditingValue.text == '')
        {
          return availableUsers;
        }
        else
        {
          return availableUsers.where((user) => user.matches(textEditingValue.text));
        }
      },
      displayStringForOption: (user) => user.displayName ?? user.email,
      onSelected: (option) => setState(() {
        selectedUser = option;
        widget.onSelectedUserChanged(option);
      }),
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted)
      {
        return TextFormField(
          controller: textEditingController..text = selectedUser?.displayName ?? selectedUser?.email ?? "",
          focusNode: focusNode,
          onFieldSubmitted: (str) => onFieldSubmitted,
          decoration: InputDecoration(
            labelText: widget.label
          ),
        );
      }
    );
  }
}