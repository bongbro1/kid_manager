class TrackingRoutingContext {
  const TrackingRoutingContext({
    required this.userId,
    this.parentUid,
    this.familyId,
    this.timeZone,
  });

  final String userId;
  final String? parentUid;
  final String? familyId;
  final String? timeZone;

  bool get isComplete =>
      (parentUid?.trim().isNotEmpty ?? false) &&
      (familyId?.trim().isNotEmpty ?? false);

  TrackingRoutingContext copyWith({
    String? userId,
    String? parentUid,
    String? familyId,
    String? timeZone,
  }) {
    return TrackingRoutingContext(
      userId: userId ?? this.userId,
      parentUid: parentUid ?? this.parentUid,
      familyId: familyId ?? this.familyId,
      timeZone: timeZone ?? this.timeZone,
    );
  }
}

class TrackingRuntimeConfig {
  const TrackingRuntimeConfig({
    required this.userId,
    required this.enabled,
    required this.requireBackground,
    this.currentOnly = false,
    this.parentUid,
    this.familyId,
    this.displayName,
    this.timeZone,
  });

  final String userId;
  final bool enabled;
  final bool requireBackground;
  final bool currentOnly;
  final String? parentUid;
  final String? familyId;
  final String? displayName;
  final String? timeZone;

  TrackingRuntimeConfig copyWith({
    String? userId,
    bool? enabled,
    bool? requireBackground,
    bool? currentOnly,
    String? parentUid,
    String? familyId,
    String? displayName,
    String? timeZone,
  }) {
    return TrackingRuntimeConfig(
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      requireBackground: requireBackground ?? this.requireBackground,
      currentOnly: currentOnly ?? this.currentOnly,
      parentUid: parentUid ?? this.parentUid,
      familyId: familyId ?? this.familyId,
      displayName: displayName ?? this.displayName,
      timeZone: timeZone ?? this.timeZone,
    );
  }
}
