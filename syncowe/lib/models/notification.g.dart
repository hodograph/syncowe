// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) => Notification(
      title: json['title'] as String,
      message: json['message'] as String,
      tripId: json['tripId'] as String,
      transactionId: json['transactionId'] as String?,
      reimbursementId: json['reimbursementId'] as String?,
      timestamp: ServerTimestampConverter.fromJson(json['timestamp']),
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'title': instance.title,
      'message': instance.message,
      'transactionId': instance.transactionId,
      'reimbursementId': instance.reimbursementId,
      'tripId': instance.tripId,
      'timestamp': ServerTimestampConverter.toJson(instance.timestamp),
    };
