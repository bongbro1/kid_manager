import 'package:cloud_firestore/cloud_firestore.dart';

/// Parse "Xh Ym" -> total minutes
int parseUsageTimeToMinutes(String? text) {
  if (text == null || text.isEmpty) return 0;

  final hourMatch = RegExp(r'(\d+)h').firstMatch(text);
  final minMatch = RegExp(r'(\d+)m').firstMatch(text);

  final hours = hourMatch != null ? int.parse(hourMatch.group(1)!) : 0;
  final minutes = minMatch != null ? int.parse(minMatch.group(1)!) : 0;

  return hours * 60 + minutes;
}

/// Format minutes -> "Xh Ym"
String formatUsageMinutes(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return "${h}h ${m}m";
}

int calculateAgeFromDateString(String dobString) {
  final birthDate = parseFlexibleBirthDate(dobString);
  if (birthDate == null) return 0;
  return calculateAgeOnDate(birthDate, DateTime.now());
}

// convert text to datetime
DateTime? parseDateFromText(String text) {
  if (text.trim().isEmpty) return null;

  try {
    final parts = text.split('/');
    if (parts.length != 3) return null;

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    // 1️⃣ Chặn năm vô lý
    final now = DateTime.now();
    if (year < 1900 || year > now.year) return null;

    final date = DateTime(year, month, day);

    // 2️⃣ Validate ngược lại (31/02, 30/02...)
    if (date.day != day || date.month != month || date.year != year) {
      return null;
    }

    // 3️⃣ Không cho ngày trong tương lai
    if (date.isAfter(now)) return null;

    return date;
  } catch (_) {
    return null;
  }
}

DateTime? parseFlexibleBirthDate(dynamic rawDob) {
  if (rawDob == null) return null;

  DateTime? parsed;

  if (rawDob is Timestamp) {
    parsed = rawDob.toDate();
  } else if (rawDob is DateTime) {
    parsed = rawDob;
  } else if (rawDob is int) {
    parsed = DateTime.fromMillisecondsSinceEpoch(rawDob);
  } else if (rawDob is String) {
    final value = rawDob.trim();
    if (value.isEmpty) return null;

    parsed = parseDateFromText(value);
    parsed ??= _parseIsoDateOnly(value);
    parsed ??= DateTime.tryParse(value);
  }

  if (parsed == null) return null;
  return DateTime(parsed.year, parsed.month, parsed.day);
}

Map<String, dynamic> buildBirthdayStorageFields(DateTime? birthDate) {
  if (birthDate == null) return const <String, dynamic>{};

  final normalized = DateTime(birthDate.year, birthDate.month, birthDate.day);
  final timestampDate = DateTime.utc(
    normalized.year,
    normalized.month,
    normalized.day,
    12,
  );

  return <String, dynamic>{
    'dob': Timestamp.fromDate(timestampDate),
    'dobIso': _formatIsoDateOnly(normalized),
    'birthMonth': normalized.month,
    'birthDay': normalized.day,
  };
}

DateTime? _parseIsoDateOnly(String value) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
  if (match == null) return null;

  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final parsed = DateTime(year, month, day);

  if (parsed.year != year || parsed.month != month || parsed.day != day) {
    return null;
  }

  return parsed;
}

String _formatIsoDateOnly(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}

bool isLeapYear(int year) {
  if (year % 400 == 0) return true;
  if (year % 100 == 0) return false;
  return year % 4 == 0;
}

DateTime resolveBirthdayOccurrence(DateTime birthDate, int year) {
  final normalized = DateTime(birthDate.year, birthDate.month, birthDate.day);

  if (normalized.month == DateTime.february &&
      normalized.day == 29 &&
      !isLeapYear(year)) {
    return DateTime(year, DateTime.february, 28);
  }

  return DateTime(year, normalized.month, normalized.day);
}

int calculateAgeOnDate(DateTime birthDate, DateTime atDate) {
  final normalizedBirth = DateTime(
    birthDate.year,
    birthDate.month,
    birthDate.day,
  );
  final normalizedAtDate = DateTime(atDate.year, atDate.month, atDate.day);
  final birthdayInYear = resolveBirthdayOccurrence(
    normalizedBirth,
    normalizedAtDate.year,
  );

  var age = normalizedAtDate.year - normalizedBirth.year;
  if (normalizedAtDate.isBefore(birthdayInYear)) {
    age--;
  }

  return age < 0 ? 0 : age;
}

bool isChildAgeValid(DateTime dob) {
  final now = DateTime.now();
  final age =
      now.year -
      dob.year -
      ((now.month < dob.month || (now.month == dob.month && now.day < dob.day))
          ? 1
          : 0);

  return age <= 18;
}

// for management app
String dayKey(DateTime d) {
  final y = d.year.toString().padLeft(4, '0');
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '$y$m$day';
}

DateTime startOfDay(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime endOfDayExclusive(DateTime d) =>
    startOfDay(d).add(const Duration(days: 1));

String formatDuration(int ms) {
  if (ms <= 0) return "0m";

  final totalSeconds = ms ~/ 1000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;

  if (hours > 0) {
    return "${hours}h ${minutes}m";
  }
  return "${minutes}m";
}

String formatMinutes(int minutes) {
  if (minutes <= 0) return "0m";

  final h = minutes ~/ 60;
  final m = minutes % 60;

  if (h == 0) return "${m}m";
  if (m == 0) return "${h}h";
  return "${h}h ${m}m";
}

String formatMinutes2(int minutes) {
  final h = minutes ~/ 60;
  final m = minutes % 60;
  return "${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}";
}

String formatDateDDMMYYYY(DateTime date) {
  final d = date.toLocal(); // tránh lệch timezone do Z (UTC)

  final day = d.day.toString().padLeft(2, '0');
  final month = d.month.toString().padLeft(2, '0');
  final year = d.year.toString();

  return "$day/$month/$year";
}

bool sameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

class TimeUtils {
  static int nowMin() {
    final now = DateTime.now();
    return now.hour * 60 + now.minute;
  }

  static int todayWeekday() {
    return DateTime.now().weekday; // 1-7
  }

  static String todayKey() {
    final now = DateTime.now();
    return "${now.year.toString().padLeft(4, '0')}-"
        "${now.month.toString().padLeft(2, '0')}-"
        "${now.day.toString().padLeft(2, '0')}";
  }
}
