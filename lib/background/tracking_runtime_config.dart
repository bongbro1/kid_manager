class TrackingRuntimeConfig {
  const TrackingRuntimeConfig({
    required this.userId,
    required this.enabled,
    required this.requireBackground,
    this.parentUid,
    this.displayName,
  });

  final String userId;
  final bool enabled;
  final bool requireBackground;
  final String? parentUid;
  final String? displayName;

  TrackingRuntimeConfig copyWith({
    String? userId,
    bool? enabled,
    bool? requireBackground,
    String? parentUid,
    String? displayName,
  }) {
    return TrackingRuntimeConfig(
      userId: userId ?? this.userId,
      enabled: enabled ?? this.enabled,
      requireBackground: requireBackground ?? this.requireBackground,
      parentUid: parentUid ?? this.parentUid,
      displayName: displayName ?? this.displayName,
    );
  }
}
