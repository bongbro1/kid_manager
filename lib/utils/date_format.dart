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
