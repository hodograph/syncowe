import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

part 'debt_pair.g.dart';

@JsonSerializable()
class DebtPair
{
  final String user1;
  final String user2;

  DebtPair({required this.user1, required this.user2});

  factory DebtPair.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => DebtPair.fromJson(snapshot.data()!);

  factory DebtPair.fromJson(Map<String, dynamic> json) => _$DebtPairFromJson(json);

  Map<String, dynamic> toJson() => _$DebtPairToJson(this);
}