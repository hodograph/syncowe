import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide Notification;
import 'package:syncowe/models/notification_token.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/pages/trip_page.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';
import 'package:syncowe/models/notification.dart';

class NotificationService extends ChangeNotifier
{
  final _userFirestoreService = UserFirestoreService();

  String? _currentToken;

  NotificationToken? notificationToken;

  Future<NotificationToken?> getNotificationToken() async
  {
    final notificationSettings = await FirebaseMessaging.instance.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true
    );
    
    String? token;

    if(kIsWeb)
    {
      token = "BGvQqHgjEwJXV0oz0HXnMmiylDUpim5QH1ZJjJZoskaYN97CFh-2uoJxlK7Mp5voFoDJyRlSugwyiWNWj3yTmL4";
    }
    else if(Platform.isIOS)
    {
      final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
      if (apnsToken == null)
      {
        return null;
      }
    }

    final fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: token);

    if(fcmToken != null)
    {
      _currentToken = fcmToken;

      notificationToken = NotificationToken(
        token: _currentToken!, 
        enabled: notificationSettings.authorizationStatus == AuthorizationStatus.authorized
      );

      _userFirestoreService.addOrUpdateNotificationToken(notificationToken!);

      notifyListeners();
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken)
    {
      if(_currentToken != fcmToken)
      {
        _currentToken = fcmToken;

        notificationToken = NotificationToken(
          token: _currentToken!, 
          enabled: notificationSettings.authorizationStatus == AuthorizationStatus.authorized
        );

        _userFirestoreService.addOrUpdateNotificationToken(notificationToken!);
        notifyListeners();
      }
    });

    return notificationToken;
  }

  Future<void> initNotificationListening(BuildContext context) async
  {
    // Handle if the app was opened via notification from a terminated state.
    RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();

    if(initialMessage != null && context.mounted)
    {
      _handleNotification(initialMessage, context);
    }

    // Handle if the app was opened via notification from the background.
    FirebaseMessaging.onMessageOpenedApp.listen((message) => _handleNotification(message, context));
  }

  void _handleNotification(RemoteMessage message, BuildContext context) async
  {
    String notificationId = message.data["notificationId"];

    Notification notification = await _userFirestoreService.getNotification(notificationId);

    if(context.mounted)
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
    }
  }
}