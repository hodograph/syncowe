// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'overall_debt_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OverallDebtSummary _$OverallDebtSummaryFromJson(Map<String, dynamic> json) =>
    OverallDebtSummary(
      debtor: json['debtor'] as String,
      payer: json['payer'] as String,
      amount: (json['amount'] as num).toDouble(),
      memo: json['memo'] as String,
      transactionId: json['transactionId'] as String,
      isReimbursement: json['isReimbursement'] as bool,
      createdDate: ServerTimestampConverter.fromJson(json['createdDate']),
    );

Map<String, dynamic> _$OverallDebtSummaryToJson(OverallDebtSummary instance) =>
    <String, dynamic>{
      'debtor': instance.debtor,
      'payer': instance.payer,
      'amount': instance.amount,
      'memo': instance.memo,
      'transactionId': instance.transactionId,
      'isReimbursement': instance.isReimbursement,
      'createdDate': ServerTimestampConverter.toJson(instance.createdDate),
    };
