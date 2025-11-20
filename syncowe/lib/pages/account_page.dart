import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/trips_page.dart';
import 'package:syncowe/services/auth/auth_service.dart';
import 'package:syncowe/services/auth/current_user.dart';
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

  void onPressed() {
    final authService = ref.read(authServiceProvider.notifier);
    authService.signOut();
  }

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
    User? currentUser = ref.watch(currentUserProvider);

    final notificationService = ref.read(notificationServiceProvider.notifier);
    final notificationToken = ref.watch(notificationServiceProvider);
    notificationEnabled = notificationToken?.enabled ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(
                    Icons.account_circle,
                    size: 80,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currentUser?.getDisplayString() ?? "Unknown",
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  Text(
                    currentUser?.email ?? "",
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: () => updateName(currentUser!),
                    icon: const Icon(Icons.edit),
                    label: const Text("Edit Name"),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
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
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.logout,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    "Log Out",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: onPressed,
                ),
                const Divider(height: 0),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    "Delete Account",
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error),
                  ),
                  onTap: confirmDelete,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
