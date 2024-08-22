import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
part 'debt.g.dart';

@JsonSerializable()
class Debt
{
  String debtor;
  String memo;
  double amount;

  Debt({required this.debtor, required this.memo, required this.amount});

  factory Debt.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => Debt.fromJson(snapshot.data()!);

  factory Debt.fromJson(Map<String, dynamic> json) => _$DebtFromJson(json);

  Map<String, dynamic> toJson() => _$DebtToJson(this);
}