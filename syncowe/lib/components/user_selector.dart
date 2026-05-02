import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class UserSelector extends ConsumerStatefulWidget {
  final ValueChanged<User?> onSelectedUserChanged;
  final String? initialUser;
  final String label;

  const UserSelector(
      {super.key,
      required this.onSelectedUserChanged,
      required this.label,
      this.initialUser});

  @override
  ConsumerState<UserSelector> createState() => _UserSelector();
}

class _UserSelector extends ConsumerState<UserSelector> {
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  User? selectedUser;
  final User _noneUser =
      User(displayName: "None", id: "", email: "None", picture: null);

  bool _userInitialized = false;

  Future<void> initUserData() async {
    bool updated = false;

    if (widget.initialUser?.isNotEmpty ?? false) {
      if (selectedUser == null) {
        // Check named/trip users first before hitting Firestore.
        final allUsers = ref.read(tripAllUsersProvider);
        final found = allUsers[widget.initialUser!];

        if (found != null) {
          selectedUser = found;
          _userInitialized = true;
          updated = true;
        } else {
          final fetched =
              await _userFirestoreService.getUser(widget.initialUser!);
          selectedUser = fetched;
          _userInitialized = true;
          updated = true;
        }
      }
    } else if (selectedUser != _noneUser) {
      selectedUser = _noneUser;
      _userInitialized = true;
      updated = true;
    }

    if (updated && _userInitialized && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    List<User> availableUsers = [_noneUser];
    availableUsers
        .addAll(ref.watch(tripAllUsersProvider).entries.map((x) => x.value));

    initUserData();

    return DropdownButtonFormField<User>(
      initialValue: selectedUser,
      isExpanded: true,
      items: availableUsers
          .map((user) => DropdownMenuItem<User>(
                value: user,
                child: Text(
                  user.getDisplayString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ))
          .toList(),
      onChanged: (option) => setState(() {
        selectedUser = option;
        widget.onSelectedUserChanged(option);
      }),
      decoration: InputDecoration(
        label: Text(widget.label),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
