enum TransportMode { still, walking, bicycle, vehicle, unknown }
TransportMode parseTransport(dynamic v) {
  final s = (v ?? '').toString().trim();
  return TransportMode.values.firstWhere(
        (e) => e.name == s,
    orElse: () => TransportMode.unknown,
  );
}

String transportLabel(TransportMode t) {
  switch (t) {
    case TransportMode.walking:
      return "Đi bộ";
    case TransportMode.bicycle:
      return "Xe đạp";
    case TransportMode.vehicle:
      return "Đi xe";
    case TransportMode.still:
      return "Đứng yên";
    default:
      return "Không rõ";
  }
}

