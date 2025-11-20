import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:syncowe/models/calculated_debt_summary_entry.dart';
import 'package:syncowe/models/transaction.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/edit_transaction_form.dart';
import 'package:syncowe/services/firestore/current_transaction.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class TransactionSummaryPage extends ConsumerStatefulWidget {
  const TransactionSummaryPage({super.key});

  @override
  ConsumerState<TransactionSummaryPage> createState() =>
      _TransactionSummaryPage();
}

class _TransactionSummaryPage extends ConsumerState<TransactionSummaryPage> {
  Future<void> deleteTransaction() async {
    var tripFirestoreService = ref.read(tripFirestoreServiceProvider.notifier);
    String? tripId = ref.watch(currentTripIdProvider);
    String? transactionId = ref.watch(currentTransactionIdProvider);
    Transaction? currentTransaction = ref.watch(currentTransactionProvider);

    bool? delete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Transaction"),
        content: Text(
            "Are you sure you want to delete ${currentTransaction?.transactionName}?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text("No")),
          TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text("Yes")),
        ],
      ),
    );

    if (delete == true && tripId != null && transactionId != null && mounted) {
      tripFirestoreService.deleteTransaction(tripId, transactionId);
      Navigator.of(context).pop();
      ref.read(currentTransactionIdProvider.notifier).setTransactionId(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    Trip? currentTrip = ref.watch(currentTripProvider);
    Transaction? currentTransaction = ref.watch(currentTransactionProvider);
    Map<String, User> users = ref.watch(tripUsersProvider);

    if (currentTransaction == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    List<String> userIds =
        currentTransaction.calculatedDebts.map((x) => x.debtor).toList();

    Map<String, List<CalculatedDebtSummaryEntry>> debtSummaries = {
      for (var calculatedDebt in currentTransaction.calculatedDebts)
        calculatedDebt.debtor: calculatedDebt.summary
    };

    Map<String, double> debts = {
      for (var calculatedDebt in currentTransaction.calculatedDebts)
        calculatedDebt.debtor: calculatedDebt.amount
    };

    List<Color> pieChartColors = [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.secondary,
      Theme.of(context).colorScheme.tertiary,
      Theme.of(context).colorScheme.error,
      Theme.of(context).colorScheme.surfaceVariant,
    ];

    List<PieChartSectionData> data = <PieChartSectionData>[];
    int colorIndex = 0;
    for (MapEntry<String, double> debt in debts.entries) {
      data.add(PieChartSectionData(
          value: debt.value,
          color: pieChartColors[colorIndex % pieChartColors.length],
          title:
              '${(debt.value / currentTransaction.total * 100).toStringAsFixed(1)}%',
          radius: 80,
          titleStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              )));
      colorIndex++;
    }

    DateTime createdDate = currentTransaction.createdDate as DateTime;

    return Scaffold(
      appBar: AppBar(
        title: Text(currentTransaction.transactionName),
        centerTitle: true,
        actions: [
          Visibility(
            visible: !currentTrip!.isArchived,
            child: IconButton(
                onPressed: deleteTransaction,
                icon: const Icon(Icons.delete_forever)),
          ),
          Visibility(
              visible: !currentTrip.isArchived,
              child: IconButton(
                  onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const EditTransactionForm())),
                  icon: const Icon(Icons.edit)))
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentTransaction.transactionName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Total: ${NumberFormat.currency(locale: "en_US", symbol: "\$").format(currentTransaction.total)}",
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    "Paid by: ${users[currentTransaction.payer]!.getDisplayString()}",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    "Date submitted: ${DateFormat.yMMMd().format(createdDate)}",
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
          Card(
            margin: const EdgeInsets.only(bottom: 16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    height: 200,
                    child: PieChart(PieChartData(sections: data)),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8.0,
                    runSpacing: 4.0,
                    children: List.generate(debts.length, (index) {
                      String userId = userIds[index];
                      User user = users[userId]!;
                      return Chip(
                        avatar: CircleAvatar(
                          backgroundColor:
                              pieChartColors[index % pieChartColors.length],
                        ),
                        label: Text(user.getDisplayString()),
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
          Card(
            child: Column(
              children: List.generate(debts.length, (index) {
                String user = userIds[index];
                List<Widget> summaryWidgets = [];

                for (CalculatedDebtSummaryEntry debtSummaryEntry
                    in debtSummaries[user]!) {
                  summaryWidgets.add(ListTile(
                    title: Text(debtSummaryEntry.memo),
                    trailing: Text(
                      NumberFormat.currency(locale: "en_US", symbol: "\$")
                          .format(debtSummaryEntry.amount),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ));
                }

                return ExpansionTile(
                  title: Text(users[user]!.getDisplayString()),
                  subtitle: Text(
                    NumberFormat.currency(locale: "en_US", symbol: "\$")
                        .format(debts[user]!),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor:
                        pieChartColors[index % pieChartColors.length],
                  ),
                  children: summaryWidgets,
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
