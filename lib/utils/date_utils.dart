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
  try {
    final parts = dobString.split('/');
    if (parts.length != 3) return 0;

    final day = int.parse(parts[0]);
    final month = int.parse(parts[1]);
    final year = int.parse(parts[2]);

    final birthDate = DateTime(year, month, day);
    final today = DateTime.now();

    int age = today.year - birthDate.year;

    if (today.month < birthDate.month ||
        (today.month == birthDate.month && today.day < birthDate.day)) {
      age--;
    }

    return age;
  } catch (_) {
    return 0;
  }
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
