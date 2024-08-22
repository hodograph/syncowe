// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reimbursement.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reimbursement _$ReimbursementFromJson(Map<String, dynamic> json) =>
    Reimbursement(
      id: json['id'] as String,
      tripId: json['tripId'] as String,
      payer: json['payer'] as String,
      recipient: json['recipient'] as String,
      amount: (json['amount'] as num).toDouble(),
      confirmed: json['confirmed'] as bool? ?? false,
    );

Map<String, dynamic> _$ReimbursementToJson(Reimbursement instance) =>
    <String, dynamic>{
      'id': instance.id,
      'tripId': instance.tripId,
      'payer': instance.payer,
      'recipient': instance.recipient,
      'amount': instance.amount,
      'confirmed': instance.confirmed,
    };
