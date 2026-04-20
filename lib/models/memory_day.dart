import 'package:cloud_firestore/cloud_firestore.dart';

class MemoryDay {
  final String id;
  final String ownerParentUid;

  final String title;
  final String? note;

  /// Original event date at 00:00.
  final DateTime date;

  /// Whether this event repeats every year.
  final bool repeatYearly;

  /// Reminder offsets in days before the event.
  final List<int> reminderOffsets;

  /// Indexed fields for month/day queries.
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
    required this.reminderOffsets,
    required this.month,
    required this.day,
    this.createdAt,
    this.updatedAt,
  });

  factory MemoryDay.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final date = (data['date'] as Timestamp).toDate();

    return MemoryDay(
      id: doc.id,
      ownerParentUid: (data['ownerParentUid'] ?? '') as String,
      title: (data['title'] ?? '') as String,
      note: data['note'] as String?,
      date: date,
      repeatYearly: (data['repeatYearly'] ?? false) as bool,
      reminderOffsets: _normalizeReminderOffsets(data['reminderOffsets']),
      month: (data['month'] ?? date.month) as int,
      day: (data['day'] ?? date.day) as int,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
    'ownerParentUid': ownerParentUid,
    'title': title,
    'note': note,
    'date': Timestamp.fromDate(date),
    'repeatYearly': repeatYearly,
    'reminderOffsets': _normalizeReminderOffsets(reminderOffsets),
    'month': month,
    'day': day,
    'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
    'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
  }..removeWhere((key, value) => value == null);

  MemoryDay copyWith({
    String? id,
    String? title,
    String? note,
    DateTime? date,
    bool? repeatYearly,
    List<int>? reminderOffsets,
    DateTime? updatedAt,
  }) {
    final newDate = date ?? this.date;
    return MemoryDay(
      id: id ?? this.id,
      ownerParentUid: ownerParentUid,
      title: title ?? this.title,
      note: note ?? this.note,
      date: newDate,
      repeatYearly: repeatYearly ?? this.repeatYearly,
      reminderOffsets: reminderOffsets ?? this.reminderOffsets,
      month: newDate.month,
      day: newDate.day,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static List<int> _normalizeReminderOffsets(dynamic raw) {
    if (raw is! Iterable) return const [];

    final values =
        raw
            .map((item) {
              if (item is int) return item;
              if (item is num) return item.toInt();
              return int.tryParse(item.toString());
            })
            .whereType<int>()
            .where((value) => value == 1 || value == 3 || value == 7)
            .toSet()
            .toList()
          ..sort();

    return List<int>.unmodifiable(values);
  }
}
