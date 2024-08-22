// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) => User(
      displayName: json['displayName'] as String?,
      email: json['email'] as String,
      id: json['id'] as String,
      picture: json['picture'] as String?,
    );

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
      'displayName': instance.displayName,
      'email': instance.email,
      'id': instance.id,
      'picture': instance.picture,
    };
