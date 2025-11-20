import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:syncowe/components/user_selector.dart';
import 'package:syncowe/models/reimbursement.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class CreateReimbursementForm extends ConsumerStatefulWidget {
  final String? payTo;
  final double? amount;

  const CreateReimbursementForm({super.key, this.payTo, this.amount});

  @override
  ConsumerState<CreateReimbursementForm> createState() =>
      _CreateReimbursementForm();
}

class _CreateReimbursementForm extends ConsumerState<CreateReimbursementForm> {
  final UserFirestoreService _userFirestoreService = UserFirestoreService();
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  CurrencyTextFieldController _totalAmountController =
      CurrencyTextFieldController(
          currencySymbol: '\$',
          thousandSymbol: ',',
          decimalSymbol: '.',
          enableNegative: false,
          showZeroValue: true);

  String? payTo;

  bool _submittingReimbursement = false;

  @override
  void initState() {
    if (widget.amount != null) {
      _totalAmountController = CurrencyTextFieldController(
          currencySymbol: '\$',
          thousandSymbol: ',',
          decimalSymbol: '.',
          enableNegative: false,
          showZeroValue: true,
          initDoubleValue: widget.amount);
    }

    payTo = widget.payTo;

    super.initState();
  }

  Future<void> submitReimbursement() async {
    String? tripId = ref.watch(currentTripIdProvider);

    // TODO: Error handling.
    if (tripId != null) {
      if (payTo != null) {
        if (_totalAmountController.doubleValue > 0) {
          Reimbursement reimbursement = Reimbursement(
              payer: _userFirestoreService.currentUserId(),
              recipient: payTo!,
              amount: _totalAmountController.doubleValue);

          setState(() => _submittingReimbursement = true);

          await _tripFirestoreService.addOrUpdateReimbursement(
              reimbursement, tripId, null);

          setState(() => _submittingReimbursement = false);

          if (mounted) {
            Navigator.of(context).pop();
          }
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
      body: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 15),
                UserSelector(
                  onSelectedUserChanged: (userId) => payTo = userId?.id ?? "",
                  label: "Pay To",
                  initialUser: payTo,
                ),
                TextField(
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  controller: _totalAmountController,
                  decoration: const InputDecoration(label: Text("Amount")),
                )
              ],
            ),
          )),
      floatingActionButton: FilledButton.icon(
        onPressed: _submittingReimbursement ? null : submitReimbursement,
        label: const Text("Submit"),
        icon: _submittingReimbursement
            ? CircularProgressIndicator(
                color: Theme.of(context).colorScheme.onPrimary,
                strokeWidth: 2,
              )
            : const Icon(Icons.navigate_next_rounded),
      ),
    ));
  }
}
