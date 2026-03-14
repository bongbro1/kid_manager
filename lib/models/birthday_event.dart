import 'package:kid_manager/utils/date_utils.dart';

class BirthdayEvent {
  final String memberUid;
  final String familyId;
  final String displayName;
  final String avatarUrl;
  final String role;
  final DateTime birthDate;

  const BirthdayEvent({
    required this.memberUid,
    required this.familyId,
    required this.displayName,
    required this.avatarUrl,
    required this.role,
    required this.birthDate,
  });

  DateTime occurrenceOnYear(int year) {
    return resolveBirthdayOccurrence(birthDate, year);
  }

  bool occursOn(DateTime day) {
    return sameDay(occurrenceOnYear(day.year), day);
  }

  int ageOn(DateTime day) {
    return calculateAgeOnDate(birthDate, day);
  }
}
