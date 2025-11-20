import 'package:firebase_pagination/firebase_pagination.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_time_ago/get_time_ago.dart';
import 'package:syncowe/models/notification.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/pages/trip_page.dart';
import 'package:syncowe/services/firestore/current_transaction.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class NotificationsPage extends ConsumerStatefulWidget
{
  const NotificationsPage({super.key});

  @override
  ConsumerState<NotificationsPage> createState() => _NotificationsPage();
}

class _NotificationsPage extends ConsumerState<NotificationsPage> {
  final _userFirestoreService = UserFirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: FirestorePagination(
        limit: 15,
        isLive: true,
        viewType: ViewType.list,
        query: _userFirestoreService
            .notifications(null)
            .orderBy(NameofNotification.fieldTimestamp, descending: true),
        itemBuilder: (context, snapshots, index) {
          final notification = snapshots[index].data() as Notification;

          String trailing = "";
          if (notification.timestamp is DateTime) {
            trailing = GetTimeAgo.parse(notification.timestamp as DateTime);
          }

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: ListTile(
              leading: const Icon(Icons.notifications_active),
              title: Text(notification.title),
              subtitle: Text(notification.message),
              trailing: Text(trailing),
              onTap: () {
                ref
                    .read(currentTripIdProvider.notifier)
                    .setTrip(notification.tripId);
                Navigator.of(context)
                    .push(MaterialPageRoute(builder: (context) => const TripPage()));

                if (notification.transactionId != null) {
                  ref
                      .read(currentTransactionIdProvider.notifier)
                      .setTransactionId(notification.transactionId);
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => const TransactionSummaryPage(),
                  ));
                }
              },
            ),
          );
        },
      ),
    );
  }
}