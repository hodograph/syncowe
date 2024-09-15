import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:syncowe/components/user_selector.dart';
import 'package:syncowe/models/reimbursement.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class CreateReimbursementForm extends StatefulWidget
{
  final String tripId;
  final String? payTo;
  final double? amount;

  const CreateReimbursementForm({super.key, required this.tripId, this.payTo, this.amount});

  @override
  State<StatefulWidget> createState() => _CreateReimbursementForm();
}

class _CreateReimbursementForm extends State<CreateReimbursementForm>
{
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  CurrencyTextFieldController _totalAmountController = CurrencyTextFieldController(currencySymbol: '\$',
    thousandSymbol: ',',
    decimalSymbol: '.',
    enableNegative: false,
    showZeroValue: true);

  String? payTo;

  @override
  void initState() {
    if(widget.amount != null)
    {
      _totalAmountController = CurrencyTextFieldController(currencySymbol: '\$',
        thousandSymbol: ',',
        decimalSymbol: '.',
        enableNegative: false,
        showZeroValue: true,
        initDoubleValue: widget.amount);
    }

    payTo = widget.payTo;

    super.initState();
  }

  Future<void> submitReimbursement() async
  {
    // TODO: Error handling.
    if(payTo != null)
    {
      if(_totalAmountController.doubleValue > 0)
      {
        Reimbursement reimbursement = Reimbursement(
          payer: _userFirestoreService.currentUserId(),
          recipient: payTo!,
          amount: _totalAmountController.doubleValue
        );

        await _tripFirestoreService.addOrUpdateReimbursement(reimbursement, widget.tripId, null);

        if (mounted)
        {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Submit Reimbursement"),
          centerTitle: true,
        ),
        body: 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: StreamBuilder(
            stream: _tripFirestoreService.listenToTrip(widget.tripId), 
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
                Trip trip = snapshot.data as Trip;

                return SingleChildScrollView(
                  child: Column(
                    children: [
                      UserSelector(
                        availableUserIds: trip.sharedWith, 
                        onSelectedUserChanged: (userId) => payTo = userId?.id ?? "",
                        label: "Pay To",
                        initialUser: payTo,
                      ),
                      TextField(
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        controller: _totalAmountController,
                        decoration: const InputDecoration(label: Text("Amount")),
                      )
                    ],
                  ),
                );
              } 
            }
          ),
        ),
        floatingActionButton: FilledButton.icon(
          onPressed: submitReimbursement, 
          label: const Text("Submit"),
          icon: const Icon(Icons.navigate_next_rounded),
        ),
      )
    );
  }
}