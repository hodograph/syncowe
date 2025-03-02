import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/pages/create_reimbursement_form.dart';
import 'package:syncowe/pages/edit_transaction_form.dart';
import 'package:syncowe/pages/edit_trip_form.dart';
import 'package:syncowe/pages/reimbursements_page.dart';
import 'package:syncowe/pages/transactions_page.dart';
import 'package:syncowe/pages/trip_overview_page.dart';
import 'package:syncowe/services/firestore/current_transaction.dart';
import 'package:syncowe/services/firestore/current_trip.dart';

class TripPage extends ConsumerStatefulWidget {
  const TripPage({super.key});

  @override
  ConsumerState<TripPage> createState() => _TripPage();
}

class _TripPage extends ConsumerState<TripPage> {
  final isDialOpen = ValueNotifier(false);

  @override
  Widget build(BuildContext context) {
    Trip? currentTrip = ref.watch(currentTripProvider);

    return SafeArea(
        child: DefaultTabController(
            length: 3,
            child: Scaffold(
                appBar: AppBar(
                  title: Text(currentTrip?.name ?? "Trip"),
                  centerTitle: true,
                  bottom: const TabBar(
                    labelPadding: EdgeInsets.all(0),
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
                  actions: [
                    Visibility(
                        visible: !currentTrip!.isArchived,
                        child: IconButton(
                            onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                    builder: (context) =>
                                        const EditTripForm())),
                            icon: const Icon(Icons.edit)))
                  ],
                ),
                body: const TabBarView(
                  children: [
                    TripOverviewPage(),
                    TransactionsPage(),
                    ReimbursementsPage()
                  ],
                ),
                floatingActionButton: Visibility(
                  visible: !currentTrip.isArchived,
                  child: SpeedDial(
                    icon: Icons.add,
                    activeIcon: Icons.close,
                    openCloseDial: isDialOpen,
                    children: [
                      SpeedDialChild(
                          child: const Icon(Icons.attach_money_rounded),
                          label: "Transaction",
                          onTap: () {
                            ref
                                .read(currentTransactionIdProvider.notifier)
                                .setTransactionId(null);
                            Navigator.of(context).push(MaterialPageRoute(
                                builder: (context) =>
                                    const EditTransactionForm()));
                          }),
                      SpeedDialChild(
                        child: const Icon(Icons.money_off_csred_rounded),
                        label: "Reimbursement",
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    const CreateReimbursementForm())),
                      )
                    ],
                  ),
                ))));
  }
}
