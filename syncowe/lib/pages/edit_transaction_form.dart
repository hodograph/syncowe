import 'dart:convert';
import 'dart:io';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:currency_textfield/currency_textfield.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:syncowe/components/spin_edit.dart';
import 'package:syncowe/components/user_selector.dart';
import 'package:syncowe/models/calculated_debt.dart';
import 'package:syncowe/models/calculated_debt_summary_entry.dart';
import 'package:syncowe/models/debt.dart';
import 'package:syncowe/models/split_type.dart';
import 'package:syncowe/models/transaction.dart';
import 'package:syncowe/models/trip.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';

class EditTransactionForm extends StatefulWidget
{
  final String tripId;
  final String? transactionId;
  const EditTransactionForm({super.key, required this.tripId, this.transactionId});

  @override
  State<StatefulWidget> createState() => _EditTransactionForm();
}

class _EditTransactionForm extends State<EditTransactionForm>
{
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  Transaction? _transactionToEdit;
  Trip? parentTrip;

  final TextEditingController _nameController = TextEditingController();

  CurrencyTextFieldController _totalAmountController = CurrencyTextFieldController(currencySymbol: '\$',
    thousandSymbol: ',',
    decimalSymbol: '.',
    enableNegative: false,
    showZeroValue: true);

  final List<Debt> _debts = <Debt>[];

  bool processingImage = false;

  SplitType _splitType = SplitType.evenSplit;
  String? _payer;

  void splitDebt(Debt debt) async
  {
    if(debt.amount > 0)
    {
      int? split = await showDialog<int>
      (
        context: context, 
        builder: (context) 
        {
          int amount = 0;
          return AlertDialog
          (
            icon: const Icon(Icons.call_split_rounded),
            title: const Text("Split Debt"),
            content: SpinEdit
            (
              minValue: 2,
              initialValue: 2,
              onChange: (value) => setState(() => amount = value)
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(amount),
                child: const Text("Split")
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(null),
                child: const Text("Cancel")
              )
            ],
          );
        }
      );

      if (split != null && split > 1)
      {
        double amount = debt.amount / split;
        int originalDebtIndex = _debts.indexOf(debt);
        _debts.remove(debt);
        for (int i = 0; i < split; i++)
        {
          _debts.insert(originalDebtIndex, Debt
          (
            amount: amount,
            memo: "${debt.memo} / $split",
            debtor: ""
          ));
        }
        setState(() {});
      }
    }
  }

  @override
  void initState() {
    initTransactionData();
    super.initState();
  }

  Future<void> initTransactionData() async
  {
    if (widget.transactionId != null)
    {
      _transactionToEdit = await _tripFirestoreService.getTransaction(widget.tripId, widget.transactionId!);
      _nameController.text = _transactionToEdit!.transactionName;
      _payer = _transactionToEdit!.payer;
      _totalAmountController = CurrencyTextFieldController(currencySymbol: '\$',
        thousandSymbol: ',',
        decimalSymbol: '.',
        enableNegative: false,
        showZeroValue: true,
        initDoubleValue: _transactionToEdit!.total);
      _splitType = _transactionToEdit!.splitType;

      var debts = _transactionToEdit!.debts;
      for (Debt debt in debts)
      {
        _debts.add(debt);
      }
    }

    Trip? trip = await _tripFirestoreService.getTrip(widget.tripId);
    setState(() {
      parentTrip = trip;
    });
  }

  void calculateDebts(Transaction transaction)
  {
    for (Debt debt in transaction.debts)
    {
      CalculatedDebt calculatedDebt = transaction.calculatedDebts.firstWhere((x) => x.debtor == debt.debtor,
        orElse: () => CalculatedDebt(debtor: debt.debtor, owedTo: transaction.payer));
        
      calculatedDebt.amount += debt.amount;
      String memo = debt.memo;

      if (memo.isEmpty)
      {
        memo = "Item${transaction.debts.indexOf(debt)}";
      }

      calculatedDebt.summary.add(CalculatedDebtSummaryEntry(memo: memo, amount: debt.amount));

      // Ther is no addOrUpdate method so remove in case this calculated debt already existed.
      transaction.calculatedDebts.remove(calculatedDebt);
      transaction.calculatedDebts.add(calculatedDebt);
    }

    if (!transaction.calculatedDebts.any((x) => x.debtor == transaction.payer))
    {
      transaction.calculatedDebts.add(CalculatedDebt(debtor: transaction.payer, owedTo: transaction.payer));
    }

    double totalDebts = transaction.calculatedDebts.fold(0, (a, b) => a + b.amount);
    double remainder = transaction.total - totalDebts;

    if (transaction.splitType == SplitType.evenSplit)
    {
      for (CalculatedDebt calculatedDebt in transaction.calculatedDebts)
      {
        double remainderSplit = remainder/transaction.calculatedDebts.length;
        calculatedDebt.amount += remainderSplit;
        calculatedDebt.summary.add(CalculatedDebtSummaryEntry(memo: "Remainder Split", amount: remainderSplit));
      }
    }
    else if (transaction.splitType == SplitType.proportionalSplit)
    {
      for (CalculatedDebt calculatedDebt in transaction.calculatedDebts)
      {
        double proportionalPercent = calculatedDebt.amount / totalDebts;
        double remainderSplit = remainder * proportionalPercent;
        calculatedDebt.amount += remainderSplit;
        calculatedDebt.summary.add(CalculatedDebtSummaryEntry(memo: "Remainder Split", amount: remainderSplit));
      }
    }
    else if(transaction.splitType == SplitType.payerPays)
    {
      CalculatedDebt payerDebt = transaction.calculatedDebts.firstWhere((x) => x.debtor == transaction.payer);
      payerDebt.amount += remainder;
      payerDebt.summary.add(CalculatedDebtSummaryEntry(memo: "Remainder", amount: remainder));
    }
  }

  Future<void> submitTransaction() async
  {
    // TODO: error logging.
    if(_nameController.text.isNotEmpty)
    {
      if(_payer != null)
      {
        if(_debts.isNotEmpty)
        {
          if(_totalAmountController.text.isNotEmpty)
          {
            var transaction = Transaction(
              transactionName: _nameController.text,
              payer: _payer!, 
              total: _totalAmountController.doubleValue,
              splitType: _splitType,
              debts: _debts,
              createdDate: widget.transactionId == null ? null : _transactionToEdit!.createdDate);

            calculateDebts(transaction);

            String docId = await _tripFirestoreService.addOrUpdateTransaction(transaction, widget.tripId, widget.transactionId);

            if (mounted)
            {
              // If this is editing a transaction, go up one page before pushing replacement.
              // Pushing replacement forces a refresh of the summary page.
              if(widget.transactionId != null)
              {
                Navigator.of(context).pop();
              }
              
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => TransactionSummaryPage(tripId: widget.tripId, transactionId: docId)));
            }
          }
        }
      }
    }
  }

  Future<void> populateFromReceipt() async
  {
    FilePickerResult? result = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);

    if (result != null)
    {
      processingImage = true;
      setState(() {});

      try
      {
        final callResult = await FirebaseFunctions.instance.httpsCallable("readReceipt").call(base64Encode(result.files.single.bytes!.toList()));

        final transaction = Transaction.fromJson(callResult.data);
        _nameController.text = transaction.transactionName;
        _splitType = transaction.splitType;
        _totalAmountController.text = transaction.total.toString();

        _debts.clear();
        _debts.addAll(transaction.debts);
      }
      catch(e)
      {
        if(mounted)
        {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
        }
      }
      finally
      {
        processingImage = false;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea
    (
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.transactionId == null ? "Create" : "Edit"} Transaction"),
          centerTitle: true,
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: FilledButton.icon(
                onPressed: populateFromReceipt, 
                label: const Text("Auto-Populate"),
                icon: processingImage? CircularProgressIndicator(color: Theme.of(context).primaryColor, strokeAlign: -1,) : const Icon(Icons.camera_alt),
              )
            )
          ],
        ),
        body: 
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25.0),
          child: SingleChildScrollView(
            child:  Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(label: Text("Transaction Name")),
                ),
                const SizedBox(height: 15,),
                UserSelector(
                  availableUserIds: parentTrip?.sharedWith ?? <String>[],
                  onSelectedUserChanged: (user)
                  { 
                    _payer = user.id;
                  },
                  label: "Payer",
                  initialUser: _payer 
                ),
                const SizedBox(height: 15,),
                TextField(
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  controller: _totalAmountController,
                  decoration: const InputDecoration(label: Text("Total")),
                ),
                const SizedBox(height: 15,),
                DropdownButtonFormField<SplitType>(
                  isExpanded: true,
                  value: _splitType,
                  items: SplitType.values.map((SplitType splitType) => DropdownMenuItem<SplitType>(
                    value: splitType,
                    child: Text(splitType.name))).toList(), 
                  onChanged: (value)
                  {
                    if(value != null){
                      setState(() {
                        _splitType = value;
                      });
                    }
                  },
                  decoration: const InputDecoration(label: Text("Split Type")),
                ),
                
                const SizedBox(height: 15,),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children:
                  [
                    const Text("Debts"),
                    OutlinedButton.icon(
                      onPressed: ()
                      {
                        setState(() {
                          _debts.add(Debt(debtor: "", memo: "", amount: 0));
                        });
                      }, 
                      label: const Text("Add Debt"), 
                      icon: const Icon(Icons.add),
                    )
                  ]
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _debts.length,
                  itemBuilder: (context, index)
                  {
                    Debt debt = _debts[index];

                    final memoController = TextEditingController(text: debt.memo);
                    final amountController = CurrencyTextFieldController(currencySymbol: '\$',
                      thousandSymbol: ',',
                      decimalSymbol: '.',
                      enableNegative: false,
                      showZeroValue: true,
                      initDoubleValue: debt.amount);
                    return ListTile(
                      title: Column(
                        children: 
                        [
                          TextField(
                            controller: memoController,
                            onChanged: (value) => debt.memo = value,
                            decoration: const InputDecoration(label: Text("Memo")),
                          ),
                          Row(
                            children: [
                              Expanded(
                                child: UserSelector(
                                  availableUserIds: parentTrip?.sharedWith ?? <String>[], 
                                  onSelectedUserChanged: (user) => 
                                    setState(() {
                                      debt.debtor = user.id;
                                    }),
                                  label: "Debtor",
                                  initialUser: debt.debtor,
                                  openDirection: OptionsViewOpenDirection.up,
                                ),
                              ),
                              const SizedBox(width: 15,),
                              Expanded(
                                child: TextField(
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  controller: amountController,
                                  onChanged: (value) => debt.amount = amountController.doubleValue,
                                  decoration: const InputDecoration(label: Text("Amount")),
                                ),
                              ),
                            ],
                          ),
                        ]
                      ),
                      trailing: Wrap(
                        children: 
                        [
                          IconButton(
                            onPressed: () => setState(() => _debts.removeAt(index)),
                            icon: const Icon(Icons.delete),
                          ),
                          IconButton(
                            onPressed: () => splitDebt(debt),
                            icon: const Icon(Icons.call_split_rounded),
                          )
                              // IconButton
                              // (
                              //   onPressed: () => setState(() => _debts.removeAt(index)),
                              //   icon: const Icon(Icons.delete),
                              //   padding: const EdgeInsets.all(0),
                              //   constraints: const BoxConstraints(),
                              // ),
                              

                        ]
                      )
                    );
                  }
                ),
              ],
            ),
          ),
        ),
        floatingActionButton: FilledButton.icon(
          onPressed: submitTransaction, 
          label: const Text("Submit"),
          icon: const Icon(Icons.navigate_next_rounded),
        ),
      ),
    );
  }
}