import 'dart:js_interop';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:syncowe/components/user_selector.dart';
import 'package:syncowe/models/debt.dart';

class DebtEditor extends ConsumerStatefulWidget {
  final Debt debt;
  final Function(DebtEditor) deleteAction;
  final Function(DebtEditor) splitAction;
  String equation = "0";

  DebtEditor(
      {super.key,
      required this.debt,
      required this.deleteAction,
      required this.splitAction});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _DebtEditor();
}

class _DebtEditor extends ConsumerState<DebtEditor> {
  late TextEditingController _memoController;
  late final MathFieldEditingController _amountController =
      MathFieldEditingController();

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

    _amountController.updateValue(Parser().parse("${widget.debt.amount}"));

    _userSelector = UserSelector(
      onSelectedUserChanged: (user) => setState(() {
        widget.debt.debtor = user?.id ?? "";
      }),
      label: "Debtor",
      initialUser: widget.debt.debtor,
    );

    widget.equation = widget.debt.amount.toString();

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
      widget.debt.amount = TeXParser(_amountController.currentEditingValue())
          .parse()
          .evaluate(EvaluationType.REAL, ContextModel());
      _amountController
          .updateValue(Parser().parse(widget.debt.amount.toStringAsFixed(2)));
      widget.debt.amount = TeXParser(_amountController.currentEditingValue())
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
    return ListTile(
        title: Row(
      children: [
        Expanded(
          child: Column(
            children: [
              TextField(
                controller: _memoController,
                onChanged: (value) => widget.debt.memo = value,
                decoration: const InputDecoration(label: Text("Memo")),
              ),
              Row(
                children: [
                  Expanded(child: _userSelector),
                  const SizedBox(
                    width: 15,
                  ),
                  Expanded(
                    // child: TextField(
                    //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    //   controller: amountController,
                    //   onChanged: (value) => widget.debt.amount = amountController.doubleValue,
                    //   decoration: const InputDecoration(label: Text("Amount")),
                    // ),
                    child: MathField(
                        keyboardType: MathKeyboardType.expression,
                        variables: const [],
                        decoration: const InputDecoration(
                            label: Text("Amount"),
                            prefix: Icon(Icons.attach_money)),
                        controller: _amountController,
                        onChanged: (value) => widget.equation = value,
                        onSubmitted: (value) => calculateAmount()),
                  ),
                ],
              ),
            ],
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              onPressed: () => widget.deleteAction(widget),
              icon: const Icon(Icons.delete),
            ),
            IconButton(
              onPressed: () => widget.splitAction(widget),
              icon: const Icon(Icons.call_split_rounded),
            )
          ],
        )
      ],
    ));
  }
}
