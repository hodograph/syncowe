import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncowe/models/server_timestamp_converter.dart';

part 'overall_debt_summary.g.dart';

@JsonSerializable()
class OverallDebtSummary
{
  final String debtor;
  final String payer;
  final double amount;
  final String memo;
  final String transactionId;
  final bool isReimbursement;

  @JsonKey(
    toJson: ServerTimestampConverter.toJson,
    fromJson: ServerTimestampConverter.fromJson
  )
  final Object? createdDate;

  OverallDebtSummary({required this.debtor,
    required this.payer,
    required this.amount, 
    required this.memo, 
    required this.transactionId, 
    required this.isReimbursement,
    this.createdDate});

  factory OverallDebtSummary.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => OverallDebtSummary.fromJson(snapshot.data()!);

  factory OverallDebtSummary.fromJson(Map<String, dynamic> json) => _$OverallDebtSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$OverallDebtSummaryToJson(this);
}