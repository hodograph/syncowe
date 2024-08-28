// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map<String, dynamic> json) => Transaction(
      transactionName: json['transactionName'] as String,
      payer: json['payer'] as String,
      total: (json['total'] as num).toDouble(),
      splitType: $enumDecodeNullable(_$SplitTypeEnumMap, json['splitType']) ??
          SplitType.evenSplit,
      debts: (json['debts'] as List<dynamic>?)
          ?.map((e) => Debt.fromJson(e as Map<String, dynamic>))
          .toList(),
      calculatedDebts: (json['calculatedDebts'] as List<dynamic>?)
          ?.map((e) => CalculatedDebt.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdDate: ServerTimestampConverter.fromJson(json['createdDate']),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'transactionName': instance.transactionName,
      'payer': instance.payer,
      'total': instance.total,
      'splitType': _$SplitTypeEnumMap[instance.splitType]!,
      'debts': instance.debts.map((e) => e.toJson()).toList(),
      'calculatedDebts':
          instance.calculatedDebts.map((e) => e.toJson()).toList(),
      'createdDate': ServerTimestampConverter.toJson(instance.createdDate),
    };

const _$SplitTypeEnumMap = {
  SplitType.evenSplit: 'evenSplit',
  SplitType.proportionalSplit: 'proportionalSplit',
  SplitType.payerPays: 'payerPays',
};
