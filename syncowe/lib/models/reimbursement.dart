import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nameof_annotation/nameof_annotation.dart';
import 'package:syncowe/models/server_timestamp_converter.dart';
part 'reimbursement.g.dart';
part 'reimbursement.nameof.dart';

@JsonSerializable()
@nameof
class Reimbursement
{
  final String payer;
  final String recipient;
  final double amount;
  bool confirmed;

  @JsonKey(
    toJson: ServerTimestampConverter.toJson,
    fromJson: ServerTimestampConverter.fromJson
  )
  final Object? createdDate;

  Reimbursement({required this.payer,
    required this.recipient,
    required this.amount,
    this.confirmed = false,
    Object? createdDate}) : createdDate = createdDate ?? FieldValue.serverTimestamp();

  factory Reimbursement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => Reimbursement.fromJson(snapshot.data()!);

  factory Reimbursement.fromJson(Map<String, dynamic> json) => _$ReimbursementFromJson(json);

  Map<String, dynamic> toJson() => _$ReimbursementToJson(this);
}