import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/current_trip.dart';

class MultiUserSelector extends ConsumerStatefulWidget {
  final ValueChanged<List<String>> usersChanged;

  const MultiUserSelector({super.key, required this.usersChanged});

  @override
  ConsumerState<MultiUserSelector> createState() => _MultiUserSelector();
}

class _MultiUserSelector extends ConsumerState<MultiUserSelector> {
  final Map<String, bool> _selectedUsers = <String, bool>{};

  @override
  void initState() {
    super.initState();

    for (String user
        in ref.read(tripAllUsersProvider).entries.map((x) => x.key)) {
      _selectedUsers[user] = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final users = ref.watch(tripAllUsersProvider);

    return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final String userId = users.entries.toList()[index].key;
          final User user = users[userId]!;
          return CheckboxListTile(
              value: _selectedUsers[userId] ?? false,
              title: Text(user.getDisplayString()),
              onChanged: (value) {
                setState(() {
                  _selectedUsers[userId] = value!;
                });

                widget.usersChanged(_selectedUsers.entries
                    .where((x) => x.value)
                    .map((x) => x.key)
                    .toList());
              });
        });
  }
}
