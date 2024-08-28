import 'package:cloud_firestore/cloud_firestore.dart';

class ServerTimestampConverter {
  static DateTime? fromJson(Object? json) {
    if (json is Timestamp) 
    {
      return json.toDate();
    }
    return null;
  }

  static Object? toJson(Object? fieldValue) {
    if (fieldValue is FieldValue)
    {
      return fieldValue;
    }
    if(fieldValue is DateTime)
    {
      return Timestamp.fromDate(fieldValue);
    }
  }
}