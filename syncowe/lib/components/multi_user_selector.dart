import 'package:flutter/material.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class MultiUserSelector extends StatefulWidget
{
  final List<String> users;
  final ValueChanged<List<String>> usersChanged;

  const MultiUserSelector({ super.key, required this.users, required this.usersChanged });

  @override
  State<StatefulWidget> createState() => _MultiUserSelector();
}

class _MultiUserSelector extends State<MultiUserSelector>
{
  final Map<String, bool> _selectedUsers = <String, bool>{};
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  @override
  void initState() {

    for (String user in widget.users)
    {
      _selectedUsers[user] = true;
    }
    
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _userFirestoreService.listenToUsers(widget.users), 
      builder: (context, snapshot)
      {
        if (snapshot.hasError) 
        {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }
        else if (!snapshot.hasData) 
        {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }
        else
        {
          Map<String, User> users = { for (var doc in snapshot.data!.docs) doc.id : doc.data() as User };
          
          return ListView.builder
          (
            itemCount: widget.users.length,
            itemBuilder: (context, index)
            {
              String userId = widget.users[index];
              User user = users[userId]!;
              return CheckboxListTile(
                value: _selectedUsers[userId],
                title: Text(user.getDisplayString()),
                onChanged: (value) 
                {
                  setState(() {
                    _selectedUsers[userId] = value!;
                  });

                  widget.usersChanged(_selectedUsers.entries.where((x) => x.value).map((x) => x.key).toList());
                }
              );
            }
          );
        }
      }
    );
  }
}