import 'package:cloud_functions/cloud_functions.dart';
import 'package:kid_manager/models/location/map_place_search_result.dart';

const String _mapboxFunctionsRegion = 'asia-southeast1';

class MapboxGatewayException implements Exception {
  const MapboxGatewayException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class MapboxTracePointInput {
  const MapboxTracePointInput({
    required this.latitude,
    required this.longitude,
    this.accuracy,
    this.timestamp,
  });

  final double latitude;
  final double longitude;
  final double? accuracy;
  final int? timestamp;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'latitude': latitude,
      'longitude': longitude,
      if (accuracy != null) 'accuracy': accuracy,
      if (timestamp != null) 'timestamp': timestamp,
    };
  }
}

class MapboxTraceMatchResult {
  const MapboxTraceMatchResult({
    required this.routeCoordinates,
    required this.snappedPoints,
    required this.nullTracepoints,
    required this.distanceMeters,
    required this.durationSeconds,
  });

  final List<List<double>> routeCoordinates;
  final List<MapboxTracePointInput> snappedPoints;
  final int nullTracepoints;
  final double distanceMeters;
  final double durationSeconds;

  factory MapboxTraceMatchResult.fromMap(Map<String, dynamic> data) {
    List<List<double>> parseCoordinates(dynamic raw) {
      if (raw is! Iterable) {
        return const <List<double>>[];
      }

      return raw
          .whereType<Iterable>()
          .map(
            (coordinate) => coordinate
                .map((value) => (value as num).toDouble())
                .toList(growable: false),
          )
          .where((coordinate) => coordinate.length >= 2)
          .toList(growable: false);
    }

    List<MapboxTracePointInput> parseSnappedPoints(dynamic raw) {
      if (raw is! Iterable) {
        return const <MapboxTracePointInput>[];
      }

      return raw
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(
            (item) => MapboxTracePointInput(
              latitude: (item['latitude'] as num).toDouble(),
              longitude: (item['longitude'] as num).toDouble(),
            ),
          )
          .toList(growable: false);
    }

    return MapboxTraceMatchResult(
      routeCoordinates: parseCoordinates(data['routeCoordinates']),
      snappedPoints: parseSnappedPoints(data['snappedPoints']),
      nullTracepoints: (data['nullTracepoints'] as num?)?.toInt() ?? 0,
      distanceMeters: (data['distanceMeters'] as num?)?.toDouble() ?? 0,
      durationSeconds: (data['durationSeconds'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MapboxPlaceCandidate {
  const MapboxPlaceCandidate({
    required this.item,
    required this.featureType,
    required this.relevance,
    this.matchConfidence,
  });

  final MapPlaceSearchResult item;
  final String featureType;
  final double relevance;
  final String? matchConfidence;

  factory MapboxPlaceCandidate.fromMap(
    Map<String, dynamic> data, {
    required String fallbackName,
    required String fallbackAddress,
  }) {
    final rawName = data['name']?.toString().trim() ?? '';
    final rawAddress = data['fullAddress']?.toString().trim() ?? '';

    return MapboxPlaceCandidate(
      item: MapPlaceSearchResult(
        id: data['id']?.toString() ?? '',
        name: rawName.isEmpty ? fallbackName : rawName,
        fullAddress: rawAddress.isEmpty ? fallbackAddress : rawAddress,
        latitude: (data['latitude'] as num).toDouble(),
        longitude: (data['longitude'] as num).toDouble(),
      ),
      featureType: data['featureType']?.toString().trim().toLowerCase() ?? '',
      relevance: (data['relevance'] as num?)?.toDouble() ?? 0,
      matchConfidence: data['matchConfidence']?.toString().trim().toLowerCase(),
    );
  }
}

class MapboxGatewayService {
  MapboxGatewayService({FirebaseFunctions? functions})
    : _functions =
          functions ??
          FirebaseFunctions.instanceFor(region: _mapboxFunctionsRegion);

  final FirebaseFunctions _functions;

  Future<MapboxTraceMatchResult?> matchTrace({
    required List<MapboxTracePointInput> points,
    required String profile,
    bool tidy = true,
  }) async {
    if (points.length < 2) {
      return null;
    }

    try {
      final callable = _functions.httpsCallable('matchMapTrace');
      final response = await callable.call(<String, dynamic>{
        'points': points.map((point) => point.toMap()).toList(growable: false),
        'profile': profile,
        'tidy': tidy,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      return MapboxTraceMatchResult.fromMap(data);
    } on FirebaseFunctionsException catch (error) {
      throw MapboxGatewayException(
        error.message ?? 'Map matching request failed',
        cause: error,
      );
    } catch (error) {
      throw MapboxGatewayException('Map matching request failed', cause: error);
    }
  }

  Future<List<MapboxPlaceCandidate>> searchPlaces({
    required String query,
    required int limit,
    required String language,
    required String fallbackName,
    required String fallbackAddress,
    String? country,
    String? bbox,
    double? proximityLatitude,
    double? proximityLongitude,
    List<String> featureTypes = const <String>[],
  }) async {
    try {
      final callable = _functions.httpsCallable('searchMapPlaces');
      final response = await callable.call(<String, dynamic>{
        'query': query,
        'limit': limit,
        'language': language,
        if (country != null && country.trim().isNotEmpty) 'country': country,
        if (bbox != null && bbox.trim().isNotEmpty) 'bbox': bbox,
        'proximityLatitude': ?proximityLatitude,
        'proximityLongitude': ?proximityLongitude,
        if (featureTypes.isNotEmpty) 'featureTypes': featureTypes,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      final rawResults = data['results'];
      if (rawResults is! Iterable) {
        return const <MapboxPlaceCandidate>[];
      }

      return rawResults
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(
            (item) => MapboxPlaceCandidate.fromMap(
              item,
              fallbackName: fallbackName,
              fallbackAddress: fallbackAddress,
            ),
          )
          .toList(growable: false);
    } on FirebaseFunctionsException catch (error) {
      throw MapboxGatewayException(
        error.message ?? 'Map place search failed',
        cause: error,
      );
    } catch (error) {
      throw MapboxGatewayException('Map place search failed', cause: error);
    }
  }
}
