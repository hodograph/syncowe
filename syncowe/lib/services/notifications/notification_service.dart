import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

class NotificationService
{
  Future<void> getNotificationToken() async
  {
    final notificationSettings = await FirebaseMessaging.instance.requestPermission(provisional: true);
    
    String? token;

    if(kIsWeb)
    {
      token = "BGvQqHgjEwJXV0oz0HXnMmiylDUpim5QH1ZJjJZoskaYN97CFh-2uoJxlK7Mp5voFoDJyRlSugwyiWNWj3yTmL4";
    }

    final fcmToken = await FirebaseMessaging.instance.getToken(vapidKey: token);

    FirebaseMessaging.instance.onTokenRefresh.listen((fcmToken)
    {
      
    });
  }
}