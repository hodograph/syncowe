// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reimbursement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reimbursement _$ReimbursementFromJson(Map<String, dynamic> json) =>
    Reimbursement(
      payer: json['payer'] as String,
      recipient: json['recipient'] as String,
      amount: (json['amount'] as num).toDouble(),
      confirmed: json['confirmed'] as bool? ?? false,
      createdDate: ServerTimestampConverter.fromJson(json['createdDate']),
    );

Map<String, dynamic> _$ReimbursementToJson(Reimbursement instance) =>
    <String, dynamic>{
      'payer': instance.payer,
      'recipient': instance.recipient,
      'amount': instance.amount,
      'confirmed': instance.confirmed,
      'createdDate': ServerTimestampConverter.toJson(instance.createdDate),
    };
