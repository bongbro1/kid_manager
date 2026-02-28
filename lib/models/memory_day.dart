import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryDay {
  final String id;
  final String ownerParentUid;

  final String title;
  final String? note;

  /// ngày gốc (00:00)
  final DateTime date;

  /// lặp hàng năm
  final bool repeatYearly;

  /// phục vụ query nhanh theo tháng/ngày
  final int month;
  final int day;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  const MemoryDay({
    required this.id,
    required this.ownerParentUid,
    required this.title,
    this.note,
    required this.date,
    required this.repeatYearly,
    required this.month,
    required this.day,
    this.createdAt,
    this.updatedAt,
  });

  factory MemoryDay.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final date = (d['date'] as Timestamp).toDate();
    return MemoryDay(
      id: doc.id,
      ownerParentUid: (d['ownerParentUid'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      note: d['note'] as String?,
      date: date,
      repeatYearly: (d['repeatYearly'] ?? false) as bool,
      month: (d['month'] ?? date.month) as int,
      day: (d['day'] ?? date.day) as int,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'ownerParentUid': ownerParentUid,
        'title': title,
        'note': note,
        'date': Timestamp.fromDate(date),
        'repeatYearly': repeatYearly,
        'month': month,
        'day': day,
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
      }..removeWhere((k, v) => v == null);

  MemoryDay copyWith({
    String? title,
    String? note,
    DateTime? date,
    bool? repeatYearly,
    DateTime? updatedAt,
  }) {
    final newDate = date ?? this.date;
    return MemoryDay(
      id: id,
      ownerParentUid: ownerParentUid,
      title: title ?? this.title,
      note: note ?? this.note,
      date: newDate,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      month: newDate.month,
      day: newDate.day,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}