import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncowe/models/calculated_debt.dart';
import 'package:syncowe/models/debt.dart';
import 'package:syncowe/models/server_timestamp_converter.dart';
import 'package:syncowe/models/split_type.dart';
part 'transaction.g.dart';

@JsonSerializable(explicitToJson: true)
class Transaction
{
  final String transactionName;
  final String payer;
  final double total;
  final SplitType splitType;
  final List<Debt> debts;
  final List<CalculatedDebt> calculatedDebts;

  @JsonKey(
    toJson: ServerTimestampConverter.toJson,
    fromJson: ServerTimestampConverter.fromJson
  )
  final Object? createdDate;

  Transaction({
    required this.transactionName, 
    required this.payer, 
    required this.total,
    this.splitType = SplitType.evenSplit,
    List<Debt>? debts,
    List<CalculatedDebt>? calculatedDebts,
    Object? createdDate}): debts = debts ?? [], calculatedDebts = calculatedDebts ?? [], createdDate = createdDate ?? FieldValue.serverTimestamp();

  factory Transaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => Transaction.fromJson(snapshot.data()!);

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}