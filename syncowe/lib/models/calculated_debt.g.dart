// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'calculated_debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CalculatedDebt _$CalculatedDebtFromJson(Map<String, dynamic> json) =>
    CalculatedDebt(
      debtor: json['debtor'] as String,
      owedTo: json['owedTo'] as String,
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      summary: (json['summary'] as List<dynamic>?)
          ?.map((e) =>
              CalculatedDebtSummaryEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$CalculatedDebtToJson(CalculatedDebt instance) =>
    <String, dynamic>{
      'debtor': instance.debtor,
      'amount': instance.amount,
      'owedTo': instance.owedTo,
      'summary': instance.summary.map((e) => e.toJson()).toList(),
    };
