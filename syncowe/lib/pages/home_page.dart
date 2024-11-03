import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/pages/account_page.dart';
import 'package:syncowe/pages/notifications_page.dart';
import 'package:syncowe/pages/trips_page.dart';
import 'package:syncowe/services/auth/current_user.dart';
import 'package:syncowe/services/firestore/current_transaction.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/notifications/notification_service.dart';

class HomePage extends ConsumerStatefulWidget{
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage>
{
  int currentPageIndex = 1;

  @override
  void initState()
  {
    initUserData();
    super.initState();
  }

  Future<void> initUserData() async
  {
    NotificationService notificationService = ref.read(notificationServiceProvider.notifier);
    notificationService.initNotificationListening(context);
    await notificationService.getNotificationToken();
  }

  @override
  Widget build(BuildContext context) {
    // Watch all default state providers so they are initialized here.
    ref.watch(currentTripIdProvider);
    ref.watch(currentTransactionIdProvider);
    ref.watch(loadedTransactionsProvider);
    ref.watch(currentTransactionProvider);
    ref.watch(currentTransactionAsyncProvider);
    ref.watch(currentUserProvider);

    return Scaffold(
      bottomNavigationBar: NavigationBar(onDestinationSelected: (int index) {
        setState(() {
          currentPageIndex = index;
        });
      },
      selectedIndex: currentPageIndex,
      destinations: const <Widget>[
        NavigationDestination(icon: Icon(Icons.notifications), label: 'Notifications'),
        NavigationDestination(icon: Icon(Icons.airplane_ticket), label: 'Trips'),
        NavigationDestination(icon: Icon(Icons.account_circle), label: 'Me')
      ]),
      body: <Widget>[
        const NotificationsPage(),
        const TripsPage(),
        const AccountPage()
      ][currentPageIndex]
    );
  }
}