class RemovedAppData {
  final String childId;
  final String packageName;
  final String removedAt;

  RemovedAppData({
    required this.childId,
    required this.packageName,
    required this.removedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      "childId": childId,
      "packageName": packageName,
      "removedAt": removedAt,
    };
  }
}