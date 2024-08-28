import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncowe/models/calculated_debt_summary_entry.dart';
part 'calculated_debt.g.dart';

@JsonSerializable(explicitToJson: true)
class CalculatedDebt
{
  final String debtor;
  double amount;
  final String owedTo;
  final List<CalculatedDebtSummaryEntry> summary;

  CalculatedDebt({required this.debtor,
    required this.owedTo,
    this.amount = 0,
    List<CalculatedDebtSummaryEntry>? summary}): summary = summary ?? [];

  factory CalculatedDebt.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => CalculatedDebt.fromJson(snapshot.data()!);

  factory CalculatedDebt.fromJson(Map<String, dynamic> json) => _$CalculatedDebtFromJson(json);

  Map<String, dynamic> toJson() => _$CalculatedDebtToJson(this);
}