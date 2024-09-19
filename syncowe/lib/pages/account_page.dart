import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/services/auth/auth_service.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';
import 'package:syncowe/services/notifications/notification_service.dart';

class AccountPage extends StatefulWidget
{
  const AccountPage({super.key});

  @override
  State<AccountPage> createState() => _AccountPage();
}

class _AccountPage extends State<AccountPage>
{
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  bool notificationEnabled = false;

  void onPressed()
  {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
  }

  Future<void> confirmDelete() async
  {
    bool? confirmed = await showDialog<bool>
    (
      context: context,
      builder: (context) => AlertDialog
      (
        title: const Text ("Delete account?"),
        content: const Text("Are you sure you want to delete your account?"),
        actions: 
        [
          TextButton
          (
            onPressed: () => Navigator.of(context).pop(false), 
            child: const Text("Cancel")
          ),
          TextButton
          (
            onPressed: () => Navigator.of(context).pop(true), 
            child: const Text("Yes")
          ),
        ],
      )
    );

    if(confirmed == true)
    {
      await _userFirestoreService.deleteAccount();
    }
  }

  void updateName(User user)
  {
    final displayNameController = TextEditingController(text: user.displayName);
    showDialog
    (
      context: context, 
      builder: (context) =>
        AlertDialog(
          content: TextField(
            controller: displayNameController,
            decoration: const InputDecoration(hintText: 'Full Name'),
          ),
          actions: [
            ElevatedButton
            (
              onPressed: () 
              {
                user.displayName = displayNameController.text;
                _userFirestoreService.addOrUpdateUser(user);
                Navigator.pop(context);
              }, 
              child: const Text("Save")
            )
          ],
        )
    );
  }


  @override
  Widget build(BuildContext context) {
    
    final currentUser = Provider.of<User?>(context);
    final notificationService = Provider.of<NotificationService>(context);
    final notificationToken = notificationService.notificationToken;
    notificationEnabled = notificationToken?.enabled ?? false;

    return Scaffold(
      body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: 
              SingleChildScrollView(
                primary: false,
                child: Column(
                  children: [

                    const SizedBox(height: 25,),
                    const Icon(
                      Icons.account_circle,
                      size: 80,
                    ),

                    const SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Invisible button for consistent spacing
                        const IconButton
                        (
                          onPressed: null, 
                          icon: Icon(Icons.edit),
                          disabledColor: Colors.transparent,
                          enableFeedback: false,
                        ),
                        Text(currentUser?.displayName ?? currentUser?.email ?? "Unknown"),
                        IconButton
                        (
                          onPressed: () => updateName(currentUser!), 
                          icon: const Icon(Icons.edit)
                        )
                      ],
                    ),

                    const SizedBox(height: 25,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Notifications: "),
                        SegmentedButton(
                          segments: const [
                            ButtonSegment<bool>(value: false, label: Text("Off")),
                            ButtonSegment<bool>(value: true, label: Text("On"))
                          ], 
                          selected: <bool>{notificationEnabled},
                          onSelectionChanged: (Set<bool> newSelection) 
                          {
                            if(!newSelection.first)
                            {
                              notificationEnabled = newSelection.first;
                              notificationToken!.enabled = newSelection.first;
                              _userFirestoreService.addOrUpdateNotificationToken(notificationToken);
                            }
                            else
                            {
                              notificationService.getNotificationToken();
                            }
                            setState(() {});
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 25,),
                    FilledButton(
                      onPressed: onPressed, 
                      child: const Text("Log Out")
                    ),
                    const SizedBox(height: 25,),
                    FilledButton.icon(onPressed: _userFirestoreService.deleteAccount, 
                      label: const Text("Delete Account"),
                      icon: const Icon(Icons.delete_forever),)
                  ],
                )
              )
            )
          )
        )
    );
  }
}