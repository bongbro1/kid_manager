import 'package:cloud_firestore/cloud_firestore.dart';
import 'schedule.dart';

class ScheduleHistory {
  final String id;
  final String scheduleId;
  final String childId;
  final String parentUid;

  final String title;
  final String? description;

  final DateTime date;
  final DateTime startAt;
  final DateTime endAt;
  final SchedulePeriod period;

  final DateTime? originalCreatedAt;
  final DateTime? originalUpdatedAt;

  /// thời điểm snapshot được lưu vào history
  final DateTime historyCreatedAt;

  const ScheduleHistory({
    required this.id,
    required this.scheduleId,
    required this.childId,
    required this.parentUid,
    required this.title,
    this.description,
    required this.date,
    required this.startAt,
    required this.endAt,
    required this.period,
    this.originalCreatedAt,
    this.originalUpdatedAt,
    required this.historyCreatedAt,
  });

  factory ScheduleHistory.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};

    return ScheduleHistory(
      id: doc.id,
      scheduleId: (d['scheduleId'] ?? '') as String,
      childId: (d['childId'] ?? '') as String,
      parentUid: (d['parentUid'] ?? '') as String,
      title: (d['title'] ?? '') as String,
      description: d['description'] as String?,
      date: (d['date'] as Timestamp).toDate(),
      startAt: (d['startAt'] as Timestamp).toDate(),
      endAt: (d['endAt'] as Timestamp).toDate(),
      period: periodFromKey((d['period'] ?? 'morning') as String),
      originalCreatedAt: (d['originalCreatedAt'] as Timestamp?)?.toDate(),
      originalUpdatedAt: (d['originalUpdatedAt'] as Timestamp?)?.toDate(),
      historyCreatedAt: (d['historyCreatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() => {
        'scheduleId': scheduleId,
        'childId': childId,
        'parentUid': parentUid,
        'title': title,
        'description': description,
        'date': Timestamp.fromDate(date),
        'startAt': Timestamp.fromDate(startAt),
        'endAt': Timestamp.fromDate(endAt),
        'period': periodKey(period),
        'originalCreatedAt': originalCreatedAt == null
            ? null
            : Timestamp.fromDate(originalCreatedAt!),
        'originalUpdatedAt': originalUpdatedAt == null
            ? null
            : Timestamp.fromDate(originalUpdatedAt!),
        'historyCreatedAt': Timestamp.fromDate(historyCreatedAt),
      }..removeWhere((k, v) => v == null);

  factory ScheduleHistory.fromSchedule(
    Schedule schedule, {
    required DateTime historyCreatedAt,
  }) {
    return ScheduleHistory(
      id: '',
      scheduleId: schedule.id,
      childId: schedule.childId,
      parentUid: schedule.parentUid,
      title: schedule.title,
      description: schedule.description,
      date: schedule.date,
      startAt: schedule.startAt,
      endAt: schedule.endAt,
      period: schedule.period,
      originalCreatedAt: schedule.createdAt,
      originalUpdatedAt: schedule.updatedAt,
      historyCreatedAt: historyCreatedAt,
    );
  }

  Schedule toSchedule({
    required String currentScheduleId,
    required int editCount,
    DateTime? updatedAt,
  }) {
    return Schedule(
      id: currentScheduleId,
      childId: childId,
      parentUid: parentUid,
      title: title,
      description: description,
      date: date,
      startAt: startAt,
      endAt: endAt,
      period: period,
      createdAt: originalCreatedAt,
      updatedAt: updatedAt ?? DateTime.now(),
      editCount: editCount,
    );
  }
}
