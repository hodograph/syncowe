import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncowe/models/debt.dart';
import 'package:syncowe/models/split_type.dart';
part 'transaction.g.dart';

@JsonSerializable()
class Transaction
{
  final String transactionName;
  final String payer;
  final double total;
  final SplitType splitType;

  Transaction({
    required this.transactionName, 
    required this.payer, 
    required this.total,
    this.splitType = SplitType.evenSplit});

  factory Transaction.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => Transaction.fromJson(snapshot.data()!);

  factory Transaction.fromJson(Map<String, dynamic> json) => _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);
}