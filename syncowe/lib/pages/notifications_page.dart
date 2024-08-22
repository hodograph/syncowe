import 'package:flutter/material.dart';

class NotificationsPage extends StatefulWidget
{
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPage();
}

class _NotificationsPage extends State<NotificationsPage>
{
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center
      (
        child: Text("No Notifications"),
      ),
    );
  }
}