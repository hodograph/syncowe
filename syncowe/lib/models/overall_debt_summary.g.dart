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
      isPending: json['isPending'] as bool,
      createdDate: ServerTimestampConverter.fromJson(json['createdDate']),
      archived: json['archived'] as bool? ?? false,
    );

Map<String, dynamic> _$OverallDebtSummaryToJson(OverallDebtSummary instance) =>
    <String, dynamic>{
      'debtor': instance.debtor,
      'payer': instance.payer,
      'amount': instance.amount,
      'memo': instance.memo,
      'transactionId': instance.transactionId,
      'isReimbursement': instance.isReimbursement,
      'isPending': instance.isPending,
      'archived': instance.archived,
      'createdDate': ServerTimestampConverter.toJson(instance.createdDate),
    };
