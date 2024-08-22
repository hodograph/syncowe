// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'debt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Debt _$DebtFromJson(Map<String, dynamic> json) => Debt(
      debtor: json['debtor'] as String,
      memo: json['memo'] as String,
      amount: (json['amount'] as num).toDouble(),
    );

Map<String, dynamic> _$DebtToJson(Debt instance) => <String, dynamic>{
      'debtor': instance.debtor,
      'memo': instance.memo,
      'amount': instance.amount,
    };
