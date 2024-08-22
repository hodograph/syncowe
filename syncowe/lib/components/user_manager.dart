import 'package:firebase_auth/firebase_auth.dart' as fireauth;
import 'package:flutter/material.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class UserManager extends StatefulWidget
{
  final List<String> users;
  final ValueChanged<Iterable<User>> onChange;
  const UserManager({super.key, required this.onChange, this.users = const <String>[]});

  @override
  State<StatefulWidget> createState() => _UserManager();
}

class _UserManager extends State<UserManager>
{
  final _userFirestoreService = UserFirestoreService();

  final List<User> _users = <User>[];

  Future<void> initSelectedUsers() async
  {
    for(String userId in widget.users)
    {
      if (userId != fireauth.FirebaseAuth.instance.currentUser!.uid){
        User? user = await _userFirestoreService.getUser(userId);
        if (user != null && !_users.any((x) => x.id == userId))
        {
          setState(() {
            _users.add(user);
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    initSelectedUsers();

    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: () async
          {
            User? user = await _userDialogBuilder(context, _users);
            if (user != null){
              setState(() {
                _users.add(user);
                widget.onChange(_users);
              });
            }
          },
          icon: const Icon(Icons.add),
          label: const Text("Add User")
        ),
        ListView.builder
          (
            scrollDirection: Axis.vertical,
            shrinkWrap: true,
            itemCount: _users.length,
            itemBuilder: (context, index)
            {
              final user = _users[index];
              return ListTile(
                title: Text(user.displayName ?? user.email),
                trailing: IconButton
                (
                  icon: const Icon(Icons.person_remove_alt_1),
                  onPressed: () => setState(() {
                    _users.removeAt(index);
                    widget.onChange(_users);
                  }),
                ),
              );
            },
          )
      ]
    );
  }

  Future<User?> _userDialogBuilder(BuildContext context, List<User> selectedUsers)
  {
    User? selectedUser;

    return showDialog<User?>(
      context: context, 
      builder: (context)
      {
        return AlertDialog(
          title: const Text("Add User"),
          content: Autocomplete<User>(
            optionsBuilder: (textEditingValue) async
            {
              Iterable<User> users = await _userFirestoreService.getUsers(selectedUsers);
              
              if (textEditingValue.text == '')
              {
                return users;
              }
              else
              {
                return users.where((user) => user.matches(textEditingValue.text));
              }
            },
            displayStringForOption: (user) => user.displayName ?? user.email,
            onSelected: (option) => setState(() {
              selectedUser = option;
            }),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')
              ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, selectedUser),
              child: const Text('Add')
              ),
          ],
        );
      }
    );
  }
}