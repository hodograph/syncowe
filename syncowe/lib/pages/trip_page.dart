import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/pages/edit_transaction_form.dart';
import 'package:syncowe/pages/edit_trip_form.dart';
import 'package:syncowe/pages/transactions_page.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class TripPage extends StatefulWidget
{
  final String tripId;
  const TripPage({super.key, required this.tripId});

  @override
  State<StatefulWidget> createState() => _TripPage();
}

class _TripPage extends State<TripPage>
{
  
  final isDialOpen = ValueNotifier(false);

  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  Trip? _initialTripData;

  late final String _tripId;

  @override
  void initState() {
    loadInitialTripData();
    super.initState();
  }

  Future<void> loadInitialTripData() async
  {
    _tripId = widget.tripId;
    var tripData = await _tripFirestoreService.getTrip(_tripId);

    setState(() {
      _initialTripData = tripData;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        StreamProvider.value(value: _tripFirestoreService.listenToTrip(_tripId), initialData: _initialTripData)
      ],
      builder: (context, widget) => SafeArea(
        child: DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(Provider.of<Trip?>(context)?.name ?? "Trip"),
              centerTitle: true,
              bottom: const TabBar(
                tabs: [
                  Tab(
                    icon: Icon(Icons.data_thresholding),
                    text: "Overview",
                  ),
                  Tab(
                    icon: Icon(Icons.attach_money_rounded),
                    text: "Transactions",
                  ),
                  Tab(
                    icon: Icon(Icons.money_off_csred_rounded),
                    text: "Reimbursements",
                  )
                ],
              ),
              actions: 
              [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => EditTripForm(tripId: _tripId))), 
                  icon: const Icon(Icons.edit)
                )
              ],
            ),
            body: TabBarView(
              children: [
                const Center(child: Text("Overview TBD"),),
                TransactionsPage(tripId: _tripId),
                const Center(child: Text("There are no reimbursements"),)
              ],
            ),
            floatingActionButton: SpeedDial(
              icon: Icons.add,
              activeIcon: Icons.close,
              openCloseDial: isDialOpen,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.attach_money_rounded),
                  label: "Transaction",
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => EditTransactionForm(tripId: _tripId))),
                ),
                SpeedDialChild(
                  child: const Icon(Icons.money_off_csred_rounded),
                  label: "Reimbursement"
                )
              ],
            ),
          )
        )
      )
    );
  }
}