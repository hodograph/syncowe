import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncowe/models/debt_pair.dart';
import 'package:syncowe/models/overall_debt_summary.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/create_reimbursement_form.dart';
import 'package:syncowe/services/auth/current_user.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class TripOverviewPage extends ConsumerStatefulWidget {
  const TripOverviewPage({super.key});

  @override
  ConsumerState<TripOverviewPage> createState() => _TripOverviewPage();
}

class _TripOverviewPage extends ConsumerState<TripOverviewPage> {
  @override
  Widget build(BuildContext context) {
    final tripId = ref.watch(currentTripIdProvider);
    final users = ref.watch(tripUsersProvider);
    final currentUser = ref.watch(currentUserProvider);

    final debtPairs = ref.watch(tripDebtPairsProvider);
    final tripFirestoreService =
        ref.read(tripFirestoreServiceProvider.notifier);

    if (tripId == null || currentUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return ListView.builder(
      itemCount: debtPairs.length,
      itemBuilder: (context, index) {
        MapEntry debtPairEntry = debtPairs.entries.toList()[index];
        DebtPair debtPair = debtPairEntry.value;

        return StreamBuilder(
          stream: tripFirestoreService.listenToOverallDebtSummary(
              tripId!, debtPairEntry.key),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text('Error: ${snapshot.error}'),
              );
            } else if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            } else {
              final summaryList = snapshot.data!.docs
                  .map((doc) => doc.data() as OverallDebtSummary)
                  .toList();

              summaryList.sort((b, a) => (a.createdDate as DateTime)
                  .compareTo(b.createdDate as DateTime));

              double user1Total = 0;
              double user2Total = 0;
              double user1Pending = 0;
              double user2Pending = 0;

              for (OverallDebtSummary summary in summaryList) {
                double amount = summary.amount;

                if (summary.isReimbursement && !summary.isPending) {
                  amount *= -1;
                }

                if (summary.debtor == debtPair.user1) {
                  if (summary.isPending) {
                    user1Pending += amount;
                  } else {
                    user1Total += amount;
                  }
                } else {
                  if (summary.isPending) {
                    user2Pending += amount;
                  } else {
                    user2Total += amount;
                  }
                }
              }

              User debtor = users[
                  user1Total > user2Total ? debtPair.user1 : debtPair.user2]!;
              User owedTo = users[
                  user1Total > user2Total ? debtPair.user2 : debtPair.user1]!;
              double totalOwed = user1Total > user2Total
                  ? user1Total - user2Total
                  : user2Total - user1Total;
              double totalPending = user1Pending > user2Pending
                  ? user1Pending - user2Pending
                  : user2Pending - user1Pending;

              if (num.parse(totalOwed.toStringAsFixed(2)) == 0) {
                return const SizedBox();
              }

              List<Widget> summaryWidgets = [];
              for (OverallDebtSummary summary in summaryList) {
                double amount = summary.amount;
                if (user1Total > user2Total &&
                        summary.debtor == debtPair.user2 ||
                    user2Total > user1Total &&
                        summary.debtor == debtPair.user1) {
                  amount *= -1;
                }

                Color color = Colors.red;
                if (amount < 0) {
                  color = Colors.green;
                }
                if (summary.isPending) {
                  color = Colors.yellow;
                }

                summaryWidgets.add(ListTile(
                  title: Text(summary.memo),
                  leading: Text(
                    NumberFormat.currency(locale: "en_US", symbol: "\$")
                        .format(summary.amount),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge!
                        .copyWith(color: color),
                  ),
                  trailing: summary.isPending
                      ? const Icon(Icons.hourglass_bottom_rounded)
                      : null,
                ));
              }

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: ExpansionTile(
                  title: Text(
                    debtor.getDisplayString(),
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Owed to: ${owedTo.getDisplayString()}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  leading: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        NumberFormat.currency(locale: "en_US", symbol: "\$")
                            .format(totalOwed),
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ],
                  ),
                  trailing: debtor.id == currentUser!.id &&
                          totalOwed - totalPending > 0
                      ? FilledButton(
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => CreateReimbursementForm(
                                amount: totalOwed,
                                payTo: owedTo.id,
                              ),
                            ),
                          ),
                          child: const Text('Pay'),
                        )
                      : null,
                  children: summaryWidgets,
                ),
              );
            }
          },
        );
      },
    );
  }
}
