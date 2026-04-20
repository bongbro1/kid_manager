class BlockedAppData {
  final String studentName;
  final String appName;
  final String blockedAt;
  final String allowedFrom;
  final String allowedTo;

  BlockedAppData({
    required this.studentName,
    required this.appName,
    required this.blockedAt,
    required this.allowedFrom,
    required this.allowedTo,
  });

  factory BlockedAppData.fromMap(Map<String, dynamic> map) {
    return BlockedAppData(
      studentName: map["studentName"] ?? "",
      appName: map["appName"] ?? "",
      blockedAt: map["blockedAt"] ?? "",
      allowedFrom: map["allowedFrom"] ?? "",
      allowedTo: map["allowedTo"] ?? "",
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "studentName": studentName,
      "appName": appName,
      "blockedAt": blockedAt,
      "allowedFrom": allowedFrom,
      "allowedTo": allowedTo,
    };
  }
}
