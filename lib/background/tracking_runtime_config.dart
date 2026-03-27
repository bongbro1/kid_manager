class TrackingRoutingContext {
  const TrackingRoutingContext({
    required this.userId,
    this.parentUid,
    this.familyId,
  });

  final String userId;
  final String? parentUid;
  final String? familyId;

  bool get isComplete =>
      (parentUid?.trim().isNotEmpty ?? false) &&
      (familyId?.trim().isNotEmpty ?? false);
}

class TrackingRuntimeConfig {
  const TrackingRuntimeConfig({
    required this.userId,
    required this.enabled,
    required this.requireBackground,
    this.parentUid,
    this.familyId,
    this.displayName,
  });

  final String userId;
  final bool enabled;
  final bool requireBackground;
  final String? parentUid;
  final String? familyId;
  final String? displayName;

  TrackingRuntimeConfig copyWith({
    String? userId,
    bool? enabled,
    bool? requireBackground,
    String? parentUid,
    String? familyId,
    String? displayName,
  }) {
    return TrackingRuntimeConfig(
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      requireBackground: requireBackground ?? this.requireBackground,
      parentUid: parentUid ?? this.parentUid,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
    );
  }
}
