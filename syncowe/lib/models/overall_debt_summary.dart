import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nameof_annotation/nameof_annotation.dart';
import 'package:syncowe/models/server_timestamp_converter.dart';

part 'overall_debt_summary.g.dart';
part 'overall_debt_summary.nameof.dart';

@JsonSerializable()
@nameof
class OverallDebtSummary
{
  final String debtor;
  final String payer;
  final double amount;
  final String memo;
  final String transactionId;
  final bool isReimbursement;
  final bool isPending;
  final bool archived;

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
    required this.isPending,
    this.createdDate,
    this.archived = false});

  factory OverallDebtSummary.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => OverallDebtSummary.fromJson(snapshot.data()!);

  factory OverallDebtSummary.fromJson(Map<String, dynamic> json) => _$OverallDebtSummaryFromJson(json);

  Map<String, dynamic> toJson() => _$OverallDebtSummaryToJson(this);
}