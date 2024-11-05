import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/current_trip.dart';

class MultiUserSelector extends ConsumerStatefulWidget
{
  final ValueChanged<List<String>> usersChanged;

  const MultiUserSelector({ super.key, required this.usersChanged });

  @override
  ConsumerState<MultiUserSelector> createState() => _MultiUserSelector();
}

class _MultiUserSelector extends ConsumerState<MultiUserSelector>
{
  final Map<String, bool> _selectedUsers = <String, bool>{};

  @override
  void initState() {    
    super.initState();
    
    for (String user in ref.read(tripUsersProvider).entries.map((x) => x.key))
    {
      _selectedUsers[user] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    var users = ref.watch(tripUsersProvider);
          
    return ListView.builder
    (
      itemCount: users.length,
      itemBuilder: (context, index)
      {
        String userId = users.entries.toList()[index].key;
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