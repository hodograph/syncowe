import 'package:currency_textfield/currency_textfield.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:syncowe/models/transaction.dart';
import 'package:syncowe/models/user.dart';
import 'package:syncowe/pages/edit_transaction_form.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class TransactionSummaryPage extends StatefulWidget
{
  final String tripId;
  final String transactionId;

  const TransactionSummaryPage({super.key, required this.tripId, required this.transactionId});

  @override
  State<StatefulWidget> createState() => _TransactionSummaryPage();
}

class _TransactionSummaryPage extends State<TransactionSummaryPage>
{
  late final String _tripId;
  late final String _transactionId;

  final TripFirestoreService _tripFirestoreService = TripFirestoreService();
  final UserFirestoreService _userFirestoreService = UserFirestoreService();

  final List<Color> colorArray = const [
    Color(0xFFFF6633), Color(0xFFFFB399), Color(0xFFFF33FF),
    Color(0xFFFFFF99), Color(0xFF00B3E6), Color(0xFFE6B333),
    Color(0xFF3366E6), Color(0xFF999966), Color(0xFF99FF99),
    Color(0xFFB34D4D), Color(0xFF80B300), Color(0xFF809900),
    Color(0xFFE6B3B3), Color(0xFF6680B3), Color(0xFF66991A),
    Color(0xFFFF99E6), Color(0xFFCCFF1A), Color(0xFFFF1A66),
    Color(0xFFE6331A), Color(0xFF33FFCC), Color(0xFF66994D),
    Color(0xFFB366CC), Color(0xFF4D8000), Color(0xFFB33300),
    Color(0xFFCC80CC), Color(0xFF66664D), Color(0xFF991AFF),
    Color(0xFFE666FF), Color(0xFF4DB3FF), Color(0xFF1AB399),
    Color(0xFFE666B3), Color(0xFF33991A), Color(0xFFCC9999),
    Color(0xFFB3B31A), Color(0xFF00E680), Color(0xFF4D8066),
    Color(0xFF809980), Color(0xFFE6FF80), Color(0xFF1AFF33),
    Color(0xFF999933), Color(0xFFFF3380), Color(0xFFCCCC00),
    Color(0xFF66E64D), Color(0xFF4D80CC), Color(0xFF9900B3),
    Color(0xFFE64D66), Color(0xFF4DB380), Color(0xFFFF4D4D),
    Color(0xFF99E6E6), Color(0xFF6666FF)
  ];

  @override
  void initState() {
    _tripId = widget.tripId;
    _transactionId = widget.transactionId;
    super.initState();
  }
  
  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: _tripFirestoreService.listenToTransaction(_tripId, _transactionId),
      builder: (context, snapshot)
      {
        if (snapshot.hasError)
        {
          return Center(child: Text("${snapshot.error!}"));
        }
        else if(!snapshot.hasData)
        {
          return const Center(child: CircularProgressIndicator(),);
        }
        else
        {
          Transaction transaction = snapshot.data!;
          return SafeArea(
          child: Scaffold(
            appBar: AppBar(
              title: Text(transaction.transactionName),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => EditTransactionForm(tripId: _tripId, transactionId: _transactionId,))), 
                  icon: const Icon(Icons.edit))
              ],
            ),
            body: StreamBuilder(
              stream: _tripFirestoreService.listenToDebts(_tripId, _transactionId), 
              builder: (context, snapshot) 
              {
                if (snapshot.hasError)
                {
                  return Center(child: Text("${snapshot.error!}"));
                }
                else if(!snapshot.hasData)
                {
                  return const Center(child: CircularProgressIndicator(),);
                }
                else
                {
                  return FutureBuilder(
                    future: _tripFirestoreService.calculateDebtsForTransaction(_tripId, _transactionId), 
                    builder: (context, snapshot) 
                    {
                      if (snapshot.hasError)
                      {
                        return Center(child: Text("${snapshot.error!}"));
                      }
                      else if(!snapshot.hasData)
                      {
                        return const Center(child: CircularProgressIndicator(),);
                      }
                      else
                      {
                        Map<String, CurrencyTextFieldController> debts = 
                        {for (var doc in snapshot.data!.entries) doc.key : CurrencyTextFieldController(currencySymbol: '\$',
                          thousandSymbol: ',',
                          decimalSymbol: '.',
                          enableNegative: false,
                          showZeroValue: true,
                          initDoubleValue: doc.value)};

                        List<String> keys = debts.keys.toList();
                        
                        return StreamBuilder(
                          stream: _userFirestoreService.listToUsers(keys), 
                          builder: (context, snapshot)
                          {
                            if (snapshot.hasError)
                            {
                              return Center(child: Text("${snapshot.error!}"));
                            }
                            else if(!snapshot.hasData)
                            {
                              return const Center(child: CircularProgressIndicator(),);
                            }
                            else
                            {
                              Map<String, User> users = { for (var doc in snapshot.data!.docs) doc.id : doc.data() as User };

                              List<PieChartSectionData> data = <PieChartSectionData>[];
                              int counter = 0;

                              for(MapEntry<String, CurrencyTextFieldController> debt in debts.entries)
                              {
                                data.add(PieChartSectionData(
                                  value: debt.value.doubleValue,
                                  color: colorArray[counter % colorArray.length],
                                  showTitle: false
                                ));
                                counter++;
                              }

                              return Column(
                                children: [
                                  Flexible(
                                    child: FractionallySizedBox(
                                      heightFactor: 0.33,
                                      child: PieChart(PieChartData(sections: data)),
                                    ),
                                  ),
                                  ListView.builder(
                                    itemCount: debts.length,
                                    shrinkWrap: true,
                                    itemBuilder: (context, index)
                                    {
                                      String user = keys[index];

                                      return ListTile(
                                        title: Text(users[user]!.displayName ?? users[user]!.email),
                                        subtitle: TextField(
                                          readOnly: true,
                                          controller: debts[user],
                                          decoration: const InputDecoration(
                                            border: InputBorder.none),
                                        ),
                                        leading: Container(
                                          width: 16, 
                                          height: 16,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.rectangle,
                                            color: colorArray[index % colorArray.length]
                                          ),
                                        ),
                                      );
                                    }
                                  )
                                ],
                              );
                            }
                          }
                        );
                      }
                    }
                  );
                }
              }
            )
          )
        );
        }
      });
  }
}