class ScheduleOverlapException implements Exception {
  final String message;
  ScheduleOverlapException(this.message);

  @override
  String toString() => message;
}