import 'package:firebase_ui_auth/firebase_ui_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/trips_page.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';
import 'package:syncowe/services/notifications/notification_service.dart';

class AccountPage extends ConsumerStatefulWidget {
  const AccountPage({super.key});

  @override
  ConsumerState<AccountPage> createState() => _AccountPage();
}

class _AccountPage extends ConsumerState<AccountPage> {
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  bool notificationEnabled = false;

  Future<void> confirmDelete() async {
    bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
              title: const Text("Delete account?"),
              content:
                  const Text("Are you sure you want to delete your account?"),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text("Cancel")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text("Yes")),
              ],
            ));

    if (confirmed == true) {
      await _userFirestoreService.deleteAccount();
    }
  }

  void updateName(User user) {
    final displayNameController = TextEditingController(text: user.displayName);
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              content: TextField(
                controller: displayNameController,
                decoration: const InputDecoration(hintText: 'Full Name'),
                textCapitalization: TextCapitalization.sentences,
              ),
              actions: [
                ElevatedButton(
                    onPressed: () {
                      user.displayName = displayNameController.text;
                      _userFirestoreService.addOrUpdateUser(user);
                      Navigator.pop(context);
                    },
                    child: const Text("Save"))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {

    final notificationService = ref.read(notificationServiceProvider.notifier);
    final notificationToken = ref.watch(notificationServiceProvider);
    notificationEnabled = notificationToken?.enabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ProfileScreen(
        actions: [
          SignedOutAction((context) {
            // AuthGate will handle navigation after sign-out.
            // Pop all routes until the first one.
            Navigator.of(context).popUntil((route) => route.isFirst);
          }),
          AccountDeletedAction((context, user) async {
            // This callback is after Firebase Auth user is deleted.
            // Now, delete the corresponding Firestore document.
            if (!user.isAnonymous) {
              try {
                await confirmDelete();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Account data removed from our records.'),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Error removing account data: ${e.toString()}',
                      ),
                    ),
                  );
                }
              }
            }
            // AuthGate will handle navigation.
            if (mounted) {
              Navigator.of(context).popUntil((route) => route.isFirst);
            }
          }),
        ],
        children: [
          SizedBox(height: 15,),
          Text("Personal",style: Theme.of(context).textTheme.titleMedium),
          ListTile(
            leading: const Icon(Icons.notifications),
            title: const Text("Notifications"),
            trailing: Switch(
              value: notificationEnabled,
              onChanged: (bool value) {
                if (!value) {
                  notificationEnabled = value;
                  notificationToken!.enabled = value;
                  _userFirestoreService
                      .addOrUpdateNotificationToken(notificationToken);
                } else {
                  notificationService.getNotificationToken();
                }
                setState(() {});
              },
            ),
          ),
          const Divider(height: 0),
          ListTile(
            leading: const Icon(Icons.archive),
            title: const Text("Archived Trips"),
            trailing: const Icon(Icons.arrow_forward_ios_rounded),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (context) => const TripsPage(
                      archivedTrips: true,
                    ))),
          ),
        ],
      )
    );
  }
}
