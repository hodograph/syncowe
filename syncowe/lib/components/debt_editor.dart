import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:syncowe/components/calculator_keyboard.dart';
import 'package:syncowe/components/user_selector.dart';
import 'package:syncowe/models/debt.dart';

class DebtEditor extends ConsumerStatefulWidget {
  final Debt debt;
  final Function(DebtEditor) deleteAction;
  final Function(DebtEditor) splitAction;

  const DebtEditor(
      {super.key,
      required this.debt,
      required this.deleteAction,
      required this.splitAction});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DebtEditor();
}

class _DebtEditor extends ConsumerState<DebtEditor> {
  late TextEditingController _memoController;
  // late final MathFieldEditingController _amountController =
  //     MathFieldEditingController();

  final TextEditingController _amountController = TextEditingController();

  late UserSelector _userSelector;

  @override
  void initState() {
    _memoController = TextEditingController(text: widget.debt.memo);
    // amountController = CurrencyTextFieldController(currencySymbol: '\$',
    //   thousandSymbol: ',',
    //   decimalSymbol: '.',
    //   enableNegative: false,
    //   showZeroValue: true,
    //   initDoubleValue: widget.debt.amount);

    _amountController.text =
        ShuntingYardParser().parse("${widget.debt.amount}").toString();

    _userSelector = UserSelector(
      onSelectedUserChanged: (user) => setState(() {
        widget.debt.debtor = user?.id ?? "";
      }),
      label: "Debtor",
      initialUser: widget.debt.debtor,
    );

    super.initState();
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  bool calculateAmount() {
    bool successfullyCalculated = false;

    try {
      widget.debt.amount = TeXParser(_amountController.text)
          .parse()
          .evaluate(EvaluationType.REAL, ContextModel());
      _amountController.text = ShuntingYardParser()
          .parse(widget.debt.amount.toStringAsFixed(2))
          .toString();
      widget.debt.amount = TeXParser(_amountController.text)
          .parse()
          .evaluate(EvaluationType.REAL, ContextModel());
      successfullyCalculated = true;
      setState(() {});
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              "An amount could not be parsed. ${widget.debt.memo.isNotEmpty ? " Debt: ${widget.debt.memo}" : ""}")));
      successfullyCalculated = false;
    }

    return successfullyCalculated;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                    controller: _memoController,
                    onChanged: (value) => widget.debt.memo = value,
                    decoration: InputDecoration(
                      labelText: "Memo",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'delete') {
                      widget.deleteAction(widget);
                    } else if (value == 'split') {
                      widget.splitAction(widget);
                    }
                  },
                  itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                    const PopupMenuItem<String>(
                      value: 'split',
                      child: ListTile(
                        leading: Icon(Icons.call_split_rounded),
                        title: Text('Split'),
                      ),
                    ),
                    const PopupMenuItem<String>(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete_outline),
                        title: Text('Delete'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _userSelector,
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: CalculatorKeyboardWidget(
                    controller: _amountController,
                    decimalPrecision: 2,
                    onCalculationResult: (value) =>
                        widget.debt.amount = double.parse(value),
                    decoration: InputDecoration(
                      labelText: "Amount",
                      prefixText: "\$",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
