import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncowe/models/debt_pair.dart';
import 'package:syncowe/models/overall_debt_summary.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/create_reimbursement_form.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class TripOverviewPage extends StatefulWidget
{
  final String tripId;
  const TripOverviewPage({super.key, required this.tripId});

  @override
  State<StatefulWidget> createState() => _TripOverviewPage();
}

class _TripOverviewPage extends State<TripOverviewPage>
{
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _tripFirestoreService.listenToTrip(widget.tripId), 
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
          final trip = snapshot.data as Trip;

          return StreamBuilder
          (
            stream: _userFirestoreService.listToUsers(trip.sharedWith),
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
                Map<String, User> users = { for (var doc in snapshot.data!.docs) doc.id : doc.data() as User };

                return StreamBuilder
                (
                  stream: _tripFirestoreService.listenToOverallDebts(widget.tripId),
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
                      final debtPairs = snapshot.data!.docs.where((doc) => doc.data() is DebtPair).toList();

                      return ListView.builder(
                        itemCount: debtPairs.length,
                        itemBuilder: (context, index)
                        {
                          QueryDocumentSnapshot<Object?> debtPairDoc = debtPairs[index];
                          DebtPair debtPair = debtPairDoc.data() as DebtPair;

                          return StreamBuilder
                          (
                            stream: _tripFirestoreService.listenToOverallDebtSummary(widget.tripId, debtPairDoc.id), 
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
                                final summaryList = snapshot.data!.docs.map((doc) => doc.data() as OverallDebtSummary).toList();

                                summaryList.sort((a,b) => (a.createdDate as DateTime).compareTo(b.createdDate as DateTime));

                                double user1Total = 0;
                                double user2Total = 0;

                                for (OverallDebtSummary summary in summaryList)
                                {
                                  double amount = summary.amount;
                                  if (summary.isReimbursement)
                                  { 
                                    amount *= -1;
                                  }

                                  if (summary.debtor == debtPair.user1)
                                  {
                                    user1Total += amount;
                                  }
                                  else
                                  {
                                    user2Total += amount;
                                  }
                                }

                                User debtor = users[user1Total > user2Total ? debtPair.user1 : debtPair.user2]!;
                                User owedTo = users[user1Total > user2Total ? debtPair.user2 : debtPair.user1]!;
                                double totalOwed = user1Total > user2Total ? user1Total - user2Total : user2Total - user1Total;

                                if (num.parse(totalOwed.toStringAsFixed(2)) == 0)
                                {
                                  return const SizedBox();
                                }

                                List<Widget> summaryWidgets = [];
                                for (OverallDebtSummary summary in summaryList)
                                {
                                  double amount = summary.amount;
                                  if (user1Total > user2Total && summary.debtor == debtPair.user2 ||
                                    user2Total > user1Total && summary.debtor == debtPair.user1)
                                  {
                                    amount *= -1;
                                  }

                                  summaryWidgets.add(ListTile
                                  (
                                    title: Text(summary.memo),
                                    leading: Text( 
                                      NumberFormat.currency(
                                        locale: "en_US", 
                                        symbol: "\$")
                                      .format(summary.amount),
                                      style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                                        color: amount < 0 ? Colors.green : Colors.red
                                      ),
                                    ),
                                  ));
                                }

                                return ExpansionTile
                                (
                                  title: Text(debtor.getDisplayString()),
                                  subtitle: Text("Owed to: ${owedTo.getDisplayString()}"),
                                  leading: Text( 
                                    NumberFormat.currency(
                                      locale: "en_US", 
                                      symbol: "\$")
                                    .format(totalOwed),
                                    style: Theme.of(context).textTheme.headlineMedium
                                  ),
                                  trailing: debtor.id == _userFirestoreService.currentUserId() ? 
                                    FilledButton.icon(
                                      onPressed: () => Navigator.of(context).push(
                                        MaterialPageRoute(builder: (context) => CreateReimbursementForm
                                        (
                                          tripId: widget.tripId,
                                          amount: totalOwed,
                                          payTo: owedTo.id,
                                        )
                                      )), 
                                      icon: const Icon(Icons.attach_money_rounded),
                                      label: const Icon(Icons.send),
                                    ) :
                                    const Text(""),
                                  children: summaryWidgets,
                                );
                              }
                            }
                          );
                        }
                      );
                    }
                  }
                );
              }
            }
          );
        }
      }
    );
  }
}