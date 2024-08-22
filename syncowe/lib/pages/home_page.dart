import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/account_page.dart';
import 'package:syncowe/pages/notifications_page.dart';
import 'package:syncowe/pages/trips_page.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class HomePage extends StatefulWidget{
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
{
  final _userFirestoreService = UserFirestoreService();
  int currentPageIndex = 1;
  User? _initialUserData;

  @override
  void initState()
  {
    initUserData();
    super.initState();
  }

  Future<void> initUserData() async
  {
    _initialUserData = await _userFirestoreService.getUser(null);
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider.value(value: _userFirestoreService.listenToUser(null), initialData: _initialUserData,),
      ],
      child: Scaffold(
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
      )
    );
  }
}