import 'package:currency_textfield/currency_textfield.dart';
import 'package:flutter/material.dart';
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

  SplitType _splitType = SplitType.evenSplit;
  String? _payer;

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

  @override
  Widget build(BuildContext context) {
    return SafeArea
    (
      child: Scaffold(
        appBar: AppBar(
          title: Text("${widget.transactionId == null ? "Create" : "Edit"} Transaction"),
          centerTitle: true,
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
                      title: TextField(
                        controller: memoController,
                        onChanged: (value) => debt.memo = value,
                        decoration: const InputDecoration(label: Text("Memo")),
                      ),
                      subtitle: Row(
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
                      trailing: IconButton(
                        onPressed: () => setState(() => _debts.removeAt(index)),
                        icon: const Icon(Icons.delete),
                      ),
                    );
                  }
                )
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