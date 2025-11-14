import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:syncowe/models/notification_token.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/pages/trip_page.dart';
import 'package:syncowe/services/firestore/current_transaction.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';
import 'package:syncowe/models/notification.dart';

part 'notification_service.g.dart';

@riverpod
class NotificationService extends _$NotificationService {
  final _userFirestoreService = UserFirestoreService();

  @override
  NotificationToken? build() {
    return null;
  }

  Future<void> getNotificationToken() async {
    String? currentToken = state?.token;

    final notificationSettings = await FirebaseMessaging.instance
        .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            carPlay: false,
            criticalAlert: false,
            provisional: false,
            sound: true);

    String? token;

    if (kIsWeb) {
      token =
          "BGvQqHgjEwJXV0oz0HXnMmiylDUpim5QH1ZJjJZoskaYN97CFh-2uoJxlK7Mp5voFoDJyRlSugwyiWNWj3yTmL4";
    } else if (Platform.isIOS) {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null) {
        return;
      }
    }

    final fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: token);

    if (fcmToken != null) {
      currentToken = fcmToken;

      state = NotificationToken(
          token: currentToken,
          enabled: notificationSettings.authorizationStatus ==
              AuthorizationStatus.authorized);

      _userFirestoreService.addOrUpdateNotificationToken(state!);
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken) {
      if (currentToken != fcmToken) {
        currentToken = fcmToken;

        state = NotificationToken(
            token: currentToken!,
            enabled: notificationSettings.authorizationStatus ==
                AuthorizationStatus.authorized);

        _userFirestoreService.addOrUpdateNotificationToken(state!);
      }
    });
  }

  Future<void> initNotificationListening(BuildContext context) async {
    // Handle if the app was opened via notification from a terminated state.
    RemoteMessage? initialMessage =
        await FirebaseMessaging.instance.getInitialMessage();

    if (initialMessage != null && context.mounted) {
      _handleNotification(initialMessage, context);
    }

    if (context.mounted) {
      // Handle if the app was opened via notification from the background.
      FirebaseMessaging.onMessageOpenedApp
          .listen((message) => _handleNotification(message, context));
    }
  }

  void _handleNotification(RemoteMessage message, BuildContext context) async {
    String notificationId = message.data["notificationId"];

    Notification notification =
        await _userFirestoreService.getNotification(notificationId);

    if (context.mounted) {
      ref.read(currentTripIdProvider.notifier).setTrip(notification.tripId);
      Navigator.of(context)
          .push(MaterialPageRoute(builder: (context) => const TripPage()));

      ref
          .read(currentTransactionIdProvider.notifier)
          .setTransactionId(notification.transactionId);
      if (notification.transactionId != null) {
        Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => const TransactionSummaryPage(),
        ));
      }
    }
  }
}
