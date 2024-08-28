import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
part 'calculated_debt_summary_entry.g.dart';

@JsonSerializable()
class CalculatedDebtSummaryEntry
{
  final String memo;
  final double amount;

  CalculatedDebtSummaryEntry({required this.memo,
    required this.amount});

  factory CalculatedDebtSummaryEntry.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => CalculatedDebtSummaryEntry.fromJson(snapshot.data()!);

  factory CalculatedDebtSummaryEntry.fromJson(Map<String, dynamic> json) => _$CalculatedDebtSummaryEntryFromJson(json);

  Map<String, dynamic> toJson() => _$CalculatedDebtSummaryEntryToJson(this);
}