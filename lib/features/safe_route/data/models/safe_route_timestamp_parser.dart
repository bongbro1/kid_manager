DateTime parseRequiredSafeRouteTimestamp(
  Object? raw, {
  required String fieldName,
}) {
  final epochMillis = _parseSafeRouteTimestampMillis(
    raw,
    fieldName: fieldName,
    required: true,
  )!;
  return DateTime.fromMillisecondsSinceEpoch(epochMillis);
}

DateTime? parseOptionalSafeRouteTimestamp(
  Object? raw, {
  required String fieldName,
}) {
  final epochMillis = _parseSafeRouteTimestampMillis(
    raw,
    fieldName: fieldName,
  );
  if (epochMillis == null) {
    return null;
  }
  return DateTime.fromMillisecondsSinceEpoch(epochMillis);
}

int? _parseSafeRouteTimestampMillis(
  Object? raw, {
  required String fieldName,
  bool required = false,
}) {
  if (raw == null) {
    if (required) {
      throw FormatException('Missing required safe-route timestamp: $fieldName');
    }
    return null;
  }

  final parsed = switch (raw) {
    final num value => value.toInt(),
    _ => int.tryParse(raw.toString()),
  };

  if (parsed == null || parsed <= 0) {
    throw FormatException(
      'Invalid safe-route timestamp for $fieldName: $raw',
    );
  }

  return parsed;
}
