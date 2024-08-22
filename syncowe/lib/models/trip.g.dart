// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Trip _$TripFromJson(Map<String, dynamic> json) => Trip(
      name: json['name'] as String,
      owner: json['owner'] as String,
      sharedWith: (json['sharedWith'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      isArchived: json['isArchived'] as bool? ?? false,
    );

Map<String, dynamic> _$TripToJson(Trip instance) => <String, dynamic>{
      'name': instance.name,
      'owner': instance.owner,
      'sharedWith': instance.sharedWith,
      'isArchived': instance.isArchived,
    };
