// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'transaction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Transaction _$TransactionFromJson(Map json) => Transaction(
      transactionName: json['transactionName'] as String,
      payer: json['payer'] as String,
      total: (json['total'] as num).toDouble(),
      splitType: $enumDecodeNullable(_$SplitTypeEnumMap, json['splitType']) ??
          SplitType.evenSplit,
      debts: (json['debts'] as List<dynamic>?)
          ?.map((e) => Debt.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      calculatedDebts: (json['calculatedDebts'] as List<dynamic>?)
          ?.map((e) =>
              CalculatedDebt.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      createdDate: ServerTimestampConverter.fromJson(json['createdDate']),
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'transactionName': instance.transactionName,
      'payer': instance.payer,
      'total': instance.total,
      'splitType': _$SplitTypeEnumMap[instance.splitType]!,
      'debts': instance.debts,
      'calculatedDebts': instance.calculatedDebts,
      'createdDate': ServerTimestampConverter.toJson(instance.createdDate),
    };

const _$SplitTypeEnumMap = {
  SplitType.evenSplit: 'evenSplit',
  SplitType.proportionalSplit: 'proportionalSplit',
  SplitType.payerPays: 'payerPays',
};
