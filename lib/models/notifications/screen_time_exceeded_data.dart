class ScreenTimeExceededData {
  final String studentName;
  final int usedMinutes;
  final int limitMinutes;

  ScreenTimeExceededData({
    required this.studentName,
    required this.usedMinutes,
    required this.limitMinutes,
  });

  factory ScreenTimeExceededData.fromMap(Map<String, dynamic> map) {
    return ScreenTimeExceededData(
      studentName: map["studentName"] ?? "",
      usedMinutes: map["usedMinutes"] ?? 0,
      limitMinutes: map["limitMinutes"] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "studentName": studentName,
      "usedMinutes": usedMinutes,
      "limitMinutes": limitMinutes,
    };
  }
}