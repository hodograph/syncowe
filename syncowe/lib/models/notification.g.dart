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
      createdDate: ServerTimestampConverter.fromJson(json['createdDate']),
    );

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'title': instance.title,
      'message': instance.message,
      'transactionId': instance.transactionId,
      'reimbursementId': instance.reimbursementId,
      'tripId': instance.tripId,
      'createdDate': ServerTimestampConverter.toJson(instance.createdDate),
    };
