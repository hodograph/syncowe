import 'package:flutter/material.dart' hide Notification;
import 'package:syncowe/models/notification.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/pages/trip_page.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class NotificationsPage extends StatefulWidget
{
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPage();
}

class _NotificationsPage extends State<NotificationsPage>
{
  final _userFirestoreService = UserFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center
      (
        child: StreamBuilder(
          stream: _userFirestoreService.listenToNotifications(),
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
              final notifications = snapshot.data!.docs.where((doc) => doc.data() is Notification).toList();

              if (notifications.isEmpty)
              {
                return const Center(
                  child: Text("You have no notifications."),
                );
              }

              notifications.sort((b, a) => 
                ((a.data() as Notification).createdDate as DateTime).compareTo((b.data() as Notification).createdDate as DateTime));

              return ListView.builder(
                itemCount: notifications.length,
                itemBuilder: (context, index)
                {
                  Notification notification = notifications[index].data() as Notification;
                  return ListTile(
                    title: Text(notification.title),
                    subtitle: Text(notification.message),
                    onTap: () 
                    {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (context) => TripPage(tripId: notification.tripId))
                      );

                      if (notification.transactionId != null)
                      {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (context) => 
                            TransactionSummaryPage(tripId: notification.tripId, transactionId: notification.transactionId!,
                          ))
                        );
                      }
                    },
                  );
                }
              );
            }
          }
        )
      ),
    );
  }
}