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
    );

Map<String, dynamic> _$TransactionToJson(Transaction instance) =>
    <String, dynamic>{
      'transactionName': instance.transactionName,
      'payer': instance.payer,
      'total': instance.total,
      'splitType': _$SplitTypeEnumMap[instance.splitType]!,
    };

const _$SplitTypeEnumMap = {
  SplitType.evenSplit: 'evenSplit',
  SplitType.proportionalSplit: 'proportionalSplit',
  SplitType.payerPays: 'payerPays',
};
