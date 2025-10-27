import 'package:cloud_firestore/cloud_firestore.dart';

// Convert various date/time representations to DateTime
extension DateTimeConvert on Object? {
  DateTime toDateTime() {
    final v = this;
    if (v == null) return DateTime.fromMillisecondsSinceEpoch(0);
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    if (v is String) {
      return DateTime.tryParse(v) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
