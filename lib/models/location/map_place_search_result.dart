class MapPlaceSearchResult {
  const MapPlaceSearchResult({
    required this.id,
    required this.name,
    required this.fullAddress,
    required this.latitude,
    required this.longitude,
  });

  final String id;
  final String name;
  final String fullAddress;
  final double latitude;
  final double longitude;
}
