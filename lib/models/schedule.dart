import 'package:cloud_firestore/cloud_firestore.dart';

enum SchedulePeriod { morning, afternoon, evening }

// ✅ Parse dữ liệu từ Firestore (hỗ trợ cả key EN và label VI nếu DB cũ)
SchedulePeriod periodFromKey(String? v) {
  if (v == null) return SchedulePeriod.morning;

  final value = v.trim().toLowerCase();

  switch (value) {
    case 'afternoon':
    case 'chiều':
      return SchedulePeriod.afternoon;

    case 'evening':
    case 'tối':
      return SchedulePeriod.evening;

    case 'morning':
    case 'sáng':
      return SchedulePeriod.morning;

    default:
      throw Exception("Invalid SchedulePeriod value: $v");
  }
}

// ✅ Lưu Firestore bằng key EN
String periodKey(SchedulePeriod p) {
  switch (p) {
    case SchedulePeriod.morning:
      return 'morning';
    case SchedulePeriod.afternoon:
      return 'afternoon';
    case SchedulePeriod.evening:
      return 'evening';
  }
}

// ✅ Hiển thị UI bằng label VI
String periodLabel(SchedulePeriod p) {
  switch (p) {
    case SchedulePeriod.morning:
      return 'Sáng';
    case SchedulePeriod.afternoon:
      return 'Chiều';
    case SchedulePeriod.evening:
      return 'Tối';
  }
}

class Schedule {
  final String id;

  final String childId;
  final String parentUid;

  final String title;
  final String? description;

  /// ngày (00:00) – phục vụ UI
  final DateTime date;

  /// thời gian thật – dùng để query
  final DateTime startAt;
  final DateTime endAt;

  final SchedulePeriod period;

  final DateTime? createdAt;
  final DateTime? updatedAt;

  /// số lần đã có history edit
  final int editCount;

  const Schedule({
    required this.id,
    required this.childId,
    required this.parentUid,
    required this.title,
    this.description,
    required this.date,
    required this.startAt,
    required this.endAt,
    required this.period,
    this.createdAt,
    this.updatedAt,
    this.editCount = 0,
  });

  factory Schedule.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};

    return Schedule(
      id: doc.id,
      childId: (d['childId'] ?? '') as String,
      parentUid: (d['parentUid'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      date: (d['date'] as Timestamp).toDate(),
      startAt: (d['startAt'] as Timestamp).toDate(),
      endAt: (d['endAt'] as Timestamp).toDate(),
      period: periodFromKey((d['period'] ?? 'morning') as String),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate(),
      editCount: (d['editCount'] ?? 0) is int
          ? (d['editCount'] ?? 0) as int
          : int.tryParse('${d['editCount']}') ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'childId': childId,
        'parentUid': parentUid,
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'period': periodKey(period),
        'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
        'updatedAt': updatedAt == null ? null : Timestamp.fromDate(updatedAt!),
        'editCount': editCount,
      }..removeWhere((k, v) => v == null);

  Schedule copyWith({
    String? id,
    String? childId,
    String? parentUid,
    String? title,
    String? description,
    DateTime? date,
    DateTime? startAt,
    DateTime? endAt,
    SchedulePeriod? period,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? editCount,
  }) {
    return Schedule(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      parentUid: parentUid ?? this.parentUid,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      period: period ?? this.period,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      editCount: editCount ?? this.editCount,
    );
  }
}