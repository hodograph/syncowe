import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
part 'reimbursement.g.dart';

@JsonSerializable()
class Reimbursement
{
  final String id;
  final String tripId;
  final String payer;
  final String recipient;
  final double amount;
  final bool confirmed;

  Reimbursement({required this.id, required this.tripId, required this.payer, required this.recipient, required this.amount, this.confirmed = false});

  factory Reimbursement.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => Reimbursement.fromJson(snapshot.data()!);

  factory Reimbursement.fromJson(Map<String, dynamic> json) => _$ReimbursementFromJson(json);

  Map<String, dynamic> toJson() => _$ReimbursementToJson(this);
}