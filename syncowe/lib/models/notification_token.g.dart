// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_token.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationToken _$NotificationTokenFromJson(Map<String, dynamic> json) =>
    NotificationToken(
      token: json['token'] as String,
      enabled: json['enabled'] as bool,
    );

Map<String, dynamic> _$NotificationTokenToJson(NotificationToken instance) =>
    <String, dynamic>{
      'token': instance.token,
      'enabled': instance.enabled,
    };
