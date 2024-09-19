import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncowe/models/notification_token.dart';
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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  void onPressed()
  {
    final authService = Provider.of<AuthService>(context, listen: false);
    authService.signOut();
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
                  )
                ],
              )
            )
          )
        )
    );
  }
}