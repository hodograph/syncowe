import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nameof_annotation/nameof_annotation.dart';
import 'package:syncowe/models/server_timestamp_converter.dart';
part 'trip.g.dart';
part 'trip.nameof.dart';

@JsonSerializable()
@nameof
class Trip {
  final String name;

  final String owner;

  /// List of all users who have access to this Trip. Must include owner.
  final List<String> sharedWith;

  bool isArchived;

  @JsonKey(
      toJson: ServerTimestampConverter.toJson,
      fromJson: ServerTimestampConverter.fromJson)
  final Object? createdDate;

  Trip(
      {required this.name,
      required this.owner,
      this.sharedWith = const <String>[],
      this.isArchived = false,
      Object? createdDate})
      : createdDate = createdDate ?? FieldValue.serverTimestamp();

  factory Trip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot,
          SnapshotOptions? options) =>
      Trip.fromJson(snapshot.data()!);

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);

  Map<String, dynamic> toJson() => _$TripToJson(this);
}
