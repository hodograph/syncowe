import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:nameof_annotation/nameof_annotation.dart';
part 'user.g.dart';
part 'user.nameof.dart';

@JsonSerializable()
@nameof
class User 
{
  String? displayName;
  final String email;
  final String id;
  String? picture;

  User({required this.displayName, required this.email, required this.id, required this.picture});

  bool matches(String searchString)
  {
    searchString = searchString.toLowerCase();
    if (displayName != null)
    {
      return displayName!.toLowerCase().contains(searchString) || email.toLowerCase().contains(searchString);
    }
    else
    {
      return email.toLowerCase().contains(searchString);
    }
  }

  factory User.fromFirestore(DocumentSnapshot<Map<String, dynamic>> snapshot, SnapshotOptions? options) => User.fromJson(snapshot.data()!);

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  Map<String, dynamic> toJson() => _$UserToJson(this);
}