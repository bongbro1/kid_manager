class RemovedAppData {
  final String childId;
  final String packageName;
  final String childName;
  final String appName;
  final String removedAt;

  RemovedAppData({
    required this.childId,
    required this.childName,
    required this.packageName,
    required this.appName,
    required this.removedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "childId": childId,
      "childName": childName,
      "packageName": packageName,
      "appName": appName,
      "removedAt": removedAt,
    };
  }
}
