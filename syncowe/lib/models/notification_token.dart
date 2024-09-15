import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
part 'notification_token.g.dart';

@JsonSerializable()
class NotificationToken
{
  final String token;
  final bool enabled;

  const NotificationToken({required this.token, required this.enabled});

  factory NotificationToken.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => NotificationToken.fromJson(snapshot.data()!);

  factory NotificationToken.fromJson(Map<String, dynamic> json) => _$NotificationTokenFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationTokenToJson(this);
}