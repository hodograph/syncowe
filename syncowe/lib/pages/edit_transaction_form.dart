import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:currency_textfield/currency_textfield.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:math_expressions/math_expressions.dart';
import 'package:math_keyboard/math_keyboard.dart';
import 'package:syncowe/components/calculator_keyboard.dart';
import 'package:syncowe/components/calculator_keyboard_insets_widget.dart';
import 'package:syncowe/components/debt_editor.dart';
import 'package:syncowe/components/multi_user_selector.dart';
import 'package:syncowe/components/spin_edit.dart';
import 'package:syncowe/components/user_selector.dart';
import 'package:syncowe/models/calculated_debt.dart';
import 'package:syncowe/models/calculated_debt_summary_entry.dart';
import 'package:syncowe/models/debt.dart';
import 'package:syncowe/models/split_type.dart';
import 'package:syncowe/models/transaction.dart';
import 'package:syncowe/pages/transaction_summary_page.dart';
import 'package:syncowe/services/firestore/current_transaction.dart';
import 'package:syncowe/services/firestore/current_trip.dart';
import 'package:syncowe/services/firestore/trip_firestore.dart';
import 'package:syncowe/services/firestore/user_firestore.dart';

class EditTransactionForm extends ConsumerStatefulWidget {
  const EditTransactionForm({super.key});

  @override
  ConsumerState<EditTransactionForm> createState() => _EditTransactionForm();
}

class _EditTransactionForm extends ConsumerState<EditTransactionForm> {
  final TripFirestoreService _tripFirestoreService = TripFirestoreService();

  final TextEditingController _nameController = TextEditingController();

  // CurrencyTextFieldController _totalAmountController = CurrencyTextFieldController(currencySymbol: '\$',
  //   thousandSymbol: ',',
  //   decimalSymbol: '.',
  //   enableNegative: false,
  //   showZeroValue: true);

  // final MathFieldEditingController _totalAmountController =
  //     MathFieldEditingController();
  final TextEditingController _totalAmountController = TextEditingController();

  double _total = 0;

  final List<DebtEditor> _debts = <DebtEditor>[];

  bool _processingImage = false;

  bool _submittingTransaction = false;

  SplitType _splitType = SplitType.evenSplit;
  String? _payer;

  DebtEditor createEmptyDebt() {
    return createDebtEditor(Debt(debtor: "", memo: "", amount: 0));
  }

  DebtEditor createDebtEditor(Debt debt) {
    return DebtEditor(
        key: UniqueKey(),
        debt: debt,
        deleteAction: deleteDebt,
        splitAction: splitDebt);
  }

  void deleteDebt(DebtEditor debt) {
    setState(() {
      _debts.remove(debt);
    });
  }

  Future<void> addDebt() async {
    if (_splitType == SplitType.evenSplit) {
      var tripUsers =
          ref.watch(tripUsersProvider).entries.map((x) => x.key).toList();
      List<String>? userDebtsToAdd = await showDialog<List<String>?>(
          context: context,
          builder: (context) {
            List<String> selectedUsers = tripUsers;
            return AlertDialog(
              title: const Text("Add Debtors"),
              content: SizedBox(
                  width: double.maxFinite,
                  child: MultiUserSelector(
                      usersChanged: (value) => selectedUsers = value)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(selectedUsers),
                    child: const Text("Add")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text("Cancel"))
              ],
            );
          });

      if (userDebtsToAdd != null) {
        setState(() {
          for (String userId in userDebtsToAdd) {
            _debts.add(
                createDebtEditor(Debt(debtor: userId, memo: "", amount: 0)));
          }
        });
      }
    } else {
      setState(() {
        _debts.add(createEmptyDebt());
      });
    }
  }

  void splitDebt(DebtEditor debt) async {
    if (debt.debt.amount > 0) {
      List<String>? usersToSplitBetween = await showDialog<List<String>>(
          context: context,
          builder: (context) {
            List<String> selectedUsers = [];
            return AlertDialog(
              icon: const Icon(Icons.call_split_rounded),
              title: const Text("Split Debt"),
              content: SizedBox(
                  width: double.maxFinite,
                  child: MultiUserSelector(
                      usersChanged: (value) => selectedUsers = value)),
              actions: [
                TextButton(
                    onPressed: () => Navigator.of(context).pop(selectedUsers),
                    child: const Text("Split")),
                TextButton(
                    onPressed: () => Navigator.of(context).pop(null),
                    child: const Text("Cancel"))
              ],
            );
          });

      if (usersToSplitBetween != null) {
        if (usersToSplitBetween.length > 1) {
          double amount = debt.debt.amount / usersToSplitBetween.length;
          int originalDebtIndex = _debts.indexOf(debt);
          _debts.remove(debt);
          for (int i = 0; i < usersToSplitBetween.length; i++) {
            String userId = usersToSplitBetween[i];
            DebtEditor newDebt = createDebtEditor(Debt(
                debtor: userId,
                memo: "${debt.debt.memo} / ${usersToSplitBetween.length}",
                amount: amount));
            setState(() {
              _debts.insert(originalDebtIndex + i, newDebt);
            });
          }
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content:
                    Text("Please select at least 2 users to split the debt.")));
          }
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    initTransactionData();
    super.didChangeDependencies();
  }

  Future<void> initTransactionData() async {
    Transaction? currentTransaction = ref.read(currentTransactionProvider);
    if (currentTransaction != null) {
      _nameController.text = currentTransaction.transactionName;
      _payer = currentTransaction.payer;
      _total = currentTransaction.total;
      // _totalAmountController = CurrencyTextFieldController(currencySymbol: '\$',
      //   thousandSymbol: ',',
      //   decimalSymbol: '.',
      //   enableNegative: false,
      //   showZeroValue: true,
      //   initDoubleValue: currentTransaction.total);
      _splitType = currentTransaction.splitType;

      var debts = currentTransaction.debts;
      for (Debt debt in debts) {
        _debts.add(createDebtEditor(debt));
      }
    } else {
      _payer = UserFirestoreService().currentUserId();
    }

    _totalAmountController.text =
        ShuntingYardParser().parse("$_total").toString();

    setState(() {});
  }

  bool calculateDebts(Transaction transaction) {
    for (Debt debt in transaction.debts) {
      CalculatedDebt calculatedDebt = transaction.calculatedDebts.firstWhere(
          (x) => x.debtor == debt.debtor,
          orElse: () =>
              CalculatedDebt(debtor: debt.debtor, owedTo: transaction.payer));

      calculatedDebt.amount += debt.amount;
      String memo = debt.memo;

      if (memo.isEmpty) {
        memo = "Item${transaction.debts.indexOf(debt)}";
      }

      calculatedDebt.summary
          .add(CalculatedDebtSummaryEntry(memo: memo, amount: debt.amount));

      // Ther is no addOrUpdate method so remove in case this calculated debt already existed.
      transaction.calculatedDebts.remove(calculatedDebt);
      transaction.calculatedDebts.add(calculatedDebt);
    }

    if (!transaction.calculatedDebts
        .any((x) => x.debtor == transaction.payer)) {
      transaction.calculatedDebts.add(
          CalculatedDebt(debtor: transaction.payer, owedTo: transaction.payer));
    }

    double totalDebts =
        transaction.calculatedDebts.fold(0, (a, b) => a + b.amount);
    double remainder = transaction.total - totalDebts;

    if (transaction.splitType == SplitType.evenSplit) {
      for (CalculatedDebt calculatedDebt in transaction.calculatedDebts) {
        double remainderSplit = remainder / transaction.calculatedDebts.length;
        calculatedDebt.amount += remainderSplit;
        calculatedDebt.summary.add(CalculatedDebtSummaryEntry(
            memo: "Remainder Split", amount: remainderSplit));
      }
    } else if (transaction.splitType == SplitType.proportionalSplit) {
      for (CalculatedDebt calculatedDebt in transaction.calculatedDebts) {
        double proportionalPercent = calculatedDebt.amount / totalDebts;
        double remainderSplit = remainder * proportionalPercent;
        calculatedDebt.amount += remainderSplit;
        calculatedDebt.summary.add(CalculatedDebtSummaryEntry(
            memo: "Remainder Split", amount: remainderSplit));
      }
    } else if (transaction.splitType == SplitType.payerPays) {
      CalculatedDebt payerDebt = transaction.calculatedDebts
          .firstWhere((x) => x.debtor == transaction.payer);
      payerDebt.amount += remainder;
      payerDebt.summary.add(
          CalculatedDebtSummaryEntry(memo: "Remainder", amount: remainder));
    }

    if (transaction.calculatedDebts.any((x) => x.amount.isNaN)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                "Error calculating debts. Calculation resulted in a non-numeric result.")));
      }
      return false;
    } else {
      return true;
    }
  }

  bool calculateAmount(DebtEditor debt) {
    bool successfullyCalculated = false;
    try {
      double value = TeXParser(debt.equation)
          .parse()
          .evaluate(EvaluationType.REAL, ContextModel());
      debt.debt.amount = value;
      successfullyCalculated = true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Amount could not be parsed.")));
      successfullyCalculated = false;
    }

    return successfullyCalculated;
  }

  bool calculateTotal() {
    bool successfullyCalculated = false;

    try {
      _total = TeXParser(_totalAmountController.text)
          .parse()
          .evaluate(EvaluationType.REAL, ContextModel());
      _totalAmountController.text =
          ShuntingYardParser().parse(_total.toStringAsFixed(2)).toString();
      _total = TeXParser(_totalAmountController.text)
          .parse()
          .evaluate(EvaluationType.REAL, ContextModel());
      setState(() {});
      successfullyCalculated = true;
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Total amount could not be parsed.")));
      successfullyCalculated = false;
    }

    return successfullyCalculated;
  }

  bool parseDebts() {
    List<bool> parsed = _debts.map((x) => calculateAmount(x)).toList();

    return !parsed.contains(false);
  }

  Future<void> submitTransaction() async {
    Transaction? transactionToEdit = ref.watch(currentTransactionProvider);
    String? currentTripId = ref.watch(currentTripIdProvider);
    String? currentTransactionId = ref.watch(currentTransactionIdProvider);

    String? error;
    if (calculateTotal() && parseDebts()) {
      if (_nameController.text.isNotEmpty) {
        if (_payer?.isNotEmpty ?? false) {
          if (_debts.isNotEmpty) {
            if (_debts.every((debt) => debt.debt.debtor.isNotEmpty)) {
              if (_total > 0) {
                var transaction = Transaction(
                    transactionName: _nameController.text,
                    payer: _payer!,
                    total: _total,
                    splitType: _splitType,
                    debts: _debts.map((x) => x.debt).toList(),
                    createdDate: transactionToEdit?.createdDate);

                if (calculateDebts(transaction)) {
                  _submittingTransaction = true;
                  setState(() {});

                  String docId =
                      await _tripFirestoreService.addOrUpdateTransaction(
                          transaction, currentTripId!, currentTransactionId);

                  _submittingTransaction = false;
                  setState(() {});

                  if (mounted) {
                    // If this is editing a transaction, go up one page before pushing replacement.
                    // Pushing replacement forces a refresh of the summary page.
                    if (currentTransactionId != null) {
                      Navigator.of(context).pop();
                    }
                    // If this is a new transaction, set the transaction ID.
                    else {
                      ref
                          .read(currentTransactionIdProvider.notifier)
                          .setTransactionId(docId);
                    }

                    Navigator.of(context).pushReplacement(MaterialPageRoute(
                        builder: (context) => const TransactionSummaryPage()));
                  }
                }
              } else {
                error = "Total must be greater than \$0";
              }
            } else {
              error = "All Debts must have a debtor defined.";
            }
          } else {
            error = "One or more Debts must be defined.";
          }
        } else {
          error = "Payer cannot be None";
        }
      } else {
        error = "Transaction name cannot be empty.";
      }
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error)));
    }
  }

  Future<void> populateFromReceipt() async {
    FilePickerResult? result = await FilePicker.platform
        .pickFiles(type: FileType.image, withData: true);

    if (result != null) {
      _processingImage = true;
      setState(() {});

      try {
        final callResult = await FirebaseFunctions.instance
            .httpsCallable("readReceipt")
            .call(base64Encode(result.files.single.bytes!.toList()));

        final transaction = Transaction.fromJson(callResult.data);
        _nameController.text = transaction.transactionName;
        _splitType = transaction.splitType;
        _totalAmountController.text = ShuntingYardParser()
            .parse(transaction.total.toStringAsFixed(2))
            .toString();
        _total = transaction.total;

        _debts.clear();
        _debts
            .addAll(transaction.debts.map((x) => createDebtEditor(x)).toList());
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(e.toString())));
        }
      } finally {
        _processingImage = false;
        setState(() {});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String? transactionId = ref.watch(currentTransactionIdProvider);

    return PopScope(
      child: SafeArea(
        child: CalculatorKeyboardInsetsWidget(
          // Wrap with our new insets widget
          child: Scaffold(
            appBar: AppBar(
              title: Text(
                  "${transactionId == null ? "Create" : "Edit"} Transaction"),
              centerTitle: true,
              actions: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25.0),
                    child: FilledButton.icon(
                      onPressed: _processingImage ? null : populateFromReceipt,
                      label: const Text("Auto-Populate"),
                      icon: _processingImage
                          ? CircularProgressIndicator(
                              color: Theme.of(context).primaryColor,
                              strokeAlign: -1,
                            )
                          : const Icon(Icons.camera_alt),
                    ))
              ],
            ),
            resizeToAvoidBottomInset:
                false, // Important for custom keyboard handling
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                          label: Text("Transaction Name")),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    UserSelector(
                        onSelectedUserChanged: (user) {
                          setState(() {
                            _payer = user?.id ?? "";
                          });
                        },
                        label: "Payer",
                        initialUser: _payer),
                    const SizedBox(
                      height: 15,
                    ),
                    // TextField(
                    //   keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    //   controller: _totalAmountController,
                    //   decoration: const InputDecoration(label: Text("Total")),
                    // ),
                    // MathField(
                    //   keyboardType: MathKeyboardType.expression,
                    //   variables: const [],
                    //   decoration: const InputDecoration(
                    //       label: Text("Total"),
                    //       prefix: Icon(Icons.attach_money)),
                    //   controller: _totalAmountController,
                    //   onSubmitted: (value) => calculateTotal(),
                    // ),
                    CalculatorKeyboardWidget(
                      decoration: const InputDecoration(
                        labelText: "Total",
                        prefixText: "\$",
                      ),
                      decimalPrecision: 2,
                      controller: _totalAmountController,
                    ),
                    const SizedBox(
                      height: 15,
                    ),
                    DropdownButtonFormField<SplitType>(
                      isExpanded: true,
                      value: _splitType,
                      items: SplitType.values
                          .map((SplitType splitType) =>
                              DropdownMenuItem<SplitType>(
                                  value: splitType,
                                  child: Text(splitType.name)))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _splitType = value;
                          });
                        }
                      },
                      decoration: const InputDecoration(
                          label: Text("Remainder Split Method")),
                    ),

                    const SizedBox(
                      height: 15,
                    ),
                    const Divider(),
                    Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Debts"),
                          OutlinedButton.icon(
                            onPressed: addDebt,
                            label: const Text("Add Debt"),
                            icon: const Icon(Icons.add),
                          )
                        ]),
                    ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _debts.length + 1,
                        itemBuilder: (context, index) {
                          if (index == _debts.length) {
                            return const SizedBox(
                              height:
                                  75, // Space for the floating action button
                            );
                          }
                          return _debts[index];
                        }),
                  ],
                ),
              ),
            ),
            floatingActionButton: FilledButton.icon(
              onPressed: _submittingTransaction ? null : submitTransaction,
              label: const Text("Submit"),
              icon: _submittingTransaction
                  ? CircularProgressIndicator(
                      color: Theme.of(context).primaryColor,
                      strokeAlign: -1,
                    )
                  : const Icon(Icons.navigate_next_rounded),
            ),
          ),
        ),
      ),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // If pop was prevented by CalculatorKeyboardInsetsWidget or similar,
          // ensure we manually pop if necessary or handle state.
          // For now, assuming default behavior or that it's handled.
          // If using a custom keyboard that traps back button, this might need more logic.
          // However, our keyboard is an overlay, so system back should work.
          // If `didPop` is false, it means something else prevented the pop.
          // If `didPop` is true, it means the pop happened.
          // The `PopScope` is mainly to handle system back gestures.
          // If the keyboard is open and user hits system back, we might want to close keyboard first.
          // For now, this is okay.
          // The original onPopInvokedWithResult was:
          // if (!didPop) {
          //   Navigator.of(context).pop();
          // }
          // This seems to force a pop if it was prevented. Let's keep it.
          if (!didPop) {
            Navigator.of(context).pop();
          }
        }
      },
    );
  }
}
