// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculated_debt_summary_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalculatedDebtSummaryEntry _$CalculatedDebtSummaryEntryFromJson(
        Map<String, dynamic> json) =>
    CalculatedDebtSummaryEntry(
      memo: json['memo'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$CalculatedDebtSummaryEntryToJson(
        CalculatedDebtSummaryEntry instance) =>
    <String, dynamic>{
      'memo': instance.memo,
      'amount': instance.amount,
    };
