import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:syncowe/models/server_timestamp_converter.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification
{
  final String title;
  final String message;
  final String? transactionId;
  final String? reimbursementId;
  final String tripId;
  
  @JsonKey(
    toJson: ServerTimestampConverter.toJson,
    fromJson: ServerTimestampConverter.fromJson
  )
  final Object? createdDate;

  Notification({
    required this.title,
    required this.message,
    required this.tripId,
    this.transactionId,
    this.reimbursementId,
    this.createdDate
    });

  factory Notification.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => Notification.fromJson(snapshot.data()!);

  factory Notification.fromJson(Map<String, dynamic> json) => _$NotificationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationToJson(this);

}