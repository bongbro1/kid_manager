import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:http/http.dart' as http;
import 'package:kid_manager/models/location/map_place_search_result.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';
import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';

class MapboxPlaceSearchException implements Exception {
  const MapboxPlaceSearchException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class MapboxPlaceSearchService {
  const MapboxPlaceSearchService({
    this.defaultLimit = 8,
    this.defaultLanguage = 'vi,en',
    this.defaultCountry = 'VN',
    this.minQueryLength = 2,
    this.requestTimeout = const Duration(seconds: 8),
    this.httpClient,
    this.useVietnamBbox = true,
    this.vietnamBbox = '102.14441,8.179066,109.4699,23.393395',
    this.featureTypes = const [
      'address',
      'street',
      'postcode',
      'neighborhood',
      'locality',
      'district',
      'place',
      'region',
      'country',
    ],
  });

  final int defaultLimit;
  final String defaultLanguage;
  final String defaultCountry;
  final int minQueryLength;
  final Duration requestTimeout;
  final http.Client? httpClient;

  /// Khóa bbox trong lãnh thổ VN để giảm kết quả lạc sang nước khác.
  final bool useVietnamBbox;
  final String vietnamBbox;

  /// Geocoding v6 không còn hỗ trợ `poi`.
  final List<String> featureTypes;

  Future<List<MapPlaceSearchResult>> search(
    String rawQuery, {
    double? proximityLatitude,
    double? proximityLongitude,
    int? limit,
    String? language,
  }) async {
    final l10n = runtimeL10n();
    final displayQuery = _normalizeWhitespace(rawQuery);
    if (displayQuery.length < minQueryLength) {
      return const [];
    }

    final requestQuery = _normalizeVietnameseAliases(displayQuery);

    final accessToken = await MapboxOptions.getAccessToken();
    if (accessToken.isEmpty) {
      throw MapboxPlaceSearchException(l10n.mapPlaceSearchMissingAccessToken);
    }

    final resolvedLimit = math.min(limit ?? defaultLimit, 10);
    final resolvedLanguage = language ?? defaultLanguage;
    final shouldPreferVietnamBias = _shouldPreferVietnamBias(
      requestQuery,
      proximityLatitude: proximityLatitude,
      proximityLongitude: proximityLongitude,
    );

    final contextual = await _searchOnce(
      requestQuery,
      accessToken: accessToken,
      limit: math.max(resolvedLimit, 8),
      language: resolvedLanguage,
      country: shouldPreferVietnamBias ? defaultCountry : null,
      proximityLatitude: proximityLatitude,
      proximityLongitude: proximityLongitude,
      useBbox: shouldPreferVietnamBias && useVietnamBbox,
    );

    List<_GeocodeCandidate> global = const [];
    if (shouldPreferVietnamBias ||
        contextual.length < resolvedLimit ||
        proximityLatitude != null ||
        proximityLongitude != null) {
      global = await _searchOnce(
        requestQuery,
        accessToken: accessToken,
        limit: math.max(resolvedLimit, 8),
        language: resolvedLanguage,
        country: null,
        useBbox: false,
      );
    }

    final merged = _dedupeCandidates([...contextual, ...global]);

    final ranked = _rerank(
      merged,
      query: displayQuery,
      proximityLatitude: proximityLatitude,
      proximityLongitude: proximityLongitude,
    );

    return ranked
        .take(resolvedLimit)
        .map((candidate) => candidate.item)
        .toList(growable: false);
  }

  Future<List<_GeocodeCandidate>> _searchOnce(
    String query, {
    required String accessToken,
    required int limit,
    required String language,
    required String? country,
    required bool useBbox,
    double? proximityLatitude,
    double? proximityLongitude,
  }) async {
    final l10n = runtimeL10n();
    final queryParameters = <String, String>{
      'access_token': accessToken,
      'q': query,
      'autocomplete': 'true',
      'format': 'geojson',
      'limit': '${math.min(limit, 10)}',
      'language': language,
      'types': featureTypes.join(','),
      'routing': 'true',
      'worldview': 'us',
    };

    if (country != null && country.trim().isNotEmpty) {
      queryParameters['country'] = country.trim().toUpperCase();
    }

    if (useBbox) {
      queryParameters['bbox'] = vietnamBbox;
    }

    if (proximityLatitude != null && proximityLongitude != null) {
      queryParameters['proximity'] = '$proximityLongitude,$proximityLatitude';
    }

    final uri = Uri.https(
      'api.mapbox.com',
      '/search/geocode/v6/forward',
      queryParameters,
    );

    final client = httpClient ?? http.Client();
    final shouldCloseClient = httpClient == null;

    try {
      final response = await client.get(uri).timeout(requestTimeout);

      if (response.statusCode != 200) {
        throw MapboxPlaceSearchException(
          l10n.mapPlaceSearchRequestFailed(response.statusCode),
        );
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        throw MapboxPlaceSearchException(l10n.mapPlaceSearchInvalidResponse);
      }

      final rawFeatures = decoded['features'];
      if (rawFeatures is! List) {
        return const [];
      }

      return rawFeatures
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map(_fromFeature)
          .whereType<_GeocodeCandidate>()
          .toList(growable: false);
    } on TimeoutException catch (error) {
      throw MapboxPlaceSearchException(
        l10n.mapPlaceSearchTimeout,
        cause: error,
      );
    } on FormatException catch (error) {
      throw MapboxPlaceSearchException(
        l10n.mapPlaceSearchDecodeFailed,
        cause: error,
      );
    } catch (error) {
      if (error is MapboxPlaceSearchException) rethrow;
      throw MapboxPlaceSearchException(
        l10n.mapPlaceSearchUnexpectedError,
        cause: error,
      );
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }
  }

  _GeocodeCandidate? _fromFeature(Map<String, dynamic> feature) {
    final l10n = runtimeL10n();
    final propertiesRaw = feature['properties'];
    final properties = propertiesRaw is Map
        ? Map<String, dynamic>.from(propertiesRaw)
        : const <String, dynamic>{};

    final geometryRaw = feature['geometry'];
    final geometry = geometryRaw is Map
        ? Map<String, dynamic>.from(geometryRaw)
        : const <String, dynamic>{};

    double? longitude;
    double? latitude;

    final geometryCoordinates = geometry['coordinates'];
    if (geometryCoordinates is List && geometryCoordinates.length >= 2) {
      longitude = (geometryCoordinates[0] as num?)?.toDouble();
      latitude = (geometryCoordinates[1] as num?)?.toDouble();
    }

    double? routableLatitude;
    double? routableLongitude;

    final propertiesCoordinatesRaw = properties['coordinates'];
    if (propertiesCoordinatesRaw is Map) {
      final propertiesCoordinates = Map<String, dynamic>.from(
        propertiesCoordinatesRaw,
      );
      final routablePoint = _extractRoutablePoint(propertiesCoordinates);
      routableLongitude = routablePoint?.longitude;
      routableLatitude = routablePoint?.latitude;
      longitude ??= (propertiesCoordinates['longitude'] as num?)?.toDouble();
      latitude ??= (propertiesCoordinates['latitude'] as num?)?.toDouble();
    }

    longitude = routableLongitude ?? longitude;
    latitude = routableLatitude ?? latitude;

    if (latitude == null || longitude == null) {
      return null;
    }

    final rawName =
        properties['name_preferred'] ??
        properties['name'] ??
        feature['name'] ??
        feature['text'];

    final name = rawName?.toString().trim();

    final explicitFullAddress = properties['full_address']?.toString().trim();
    final placeFormatted = properties['place_formatted']?.toString().trim();

    final fullAddress = () {
      if (explicitFullAddress != null && explicitFullAddress.isNotEmpty) {
        return explicitFullAddress;
      }
      if (name != null && name.isNotEmpty) {
        if (placeFormatted != null &&
            placeFormatted.isNotEmpty &&
            placeFormatted != name) {
          return '$name, $placeFormatted';
        }
        return name;
      }
      if (placeFormatted != null && placeFormatted.isNotEmpty) {
        return placeFormatted;
      }
      return l10n.mapPlaceSearchNoAddress;
    }();

    final relevance =
        (feature['relevance'] as num?)?.toDouble() ??
        (properties['relevance'] as num?)?.toDouble() ??
        0.0;

    final featureType =
        properties['feature_type']?.toString().trim().toLowerCase() ?? '';

    String? matchConfidence;
    final matchCodeRaw = properties['match_code'];
    if (matchCodeRaw is Map) {
      final matchCode = Map<String, dynamic>.from(matchCodeRaw);
      matchConfidence = matchCode['confidence']
          ?.toString()
          .trim()
          .toLowerCase();
    }

    final result = MapPlaceSearchResult(
      id:
          properties['mapbox_id']?.toString() ??
          feature['id']?.toString() ??
          '$latitude,$longitude',
      name: (name == null || name.isEmpty)
          ? l10n.mapPlaceSearchDefaultName
          : name,
      fullAddress: fullAddress,
      latitude: latitude,
      longitude: longitude,
    );

    return _GeocodeCandidate(
      item: result,
      featureType: featureType,
      relevance: relevance,
      matchConfidence: matchConfidence,
    );
  }

  List<_GeocodeCandidate> _dedupeCandidates(List<_GeocodeCandidate> items) {
    final bestByKey = <String, _GeocodeCandidate>{};

    for (final item in items) {
      final key =
          '${item.item.latitude.toStringAsFixed(5)}|'
          '${item.item.longitude.toStringAsFixed(5)}|'
          '${_normalizeForCompare(item.item.fullAddress)}';

      final existing = bestByKey[key];
      if (existing == null) {
        bestByKey[key] = item;
        continue;
      }

      final currentQuality =
          item.relevance + _featureTypeWeight(item.featureType);
      final existingQuality =
          existing.relevance + _featureTypeWeight(existing.featureType);

      if (currentQuality > existingQuality) {
        bestByKey[key] = item;
      }
    }

    return bestByKey.values.toList(growable: false);
  }

  List<_GeocodeCandidate> _rerank(
    List<_GeocodeCandidate> items, {
    required String query,
    double? proximityLatitude,
    double? proximityLongitude,
  }) {
    final normalizedQuery = _normalizeForCompare(query);
    final queryTokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    double score(_GeocodeCandidate candidate) {
      final item = candidate.item;
      final normalizedName = _normalizeForCompare(item.name);
      final normalizedAddress = _normalizeForCompare(item.fullAddress);

      var total = 0.0;

      // Mapbox v6 đã sắp theo relevance, mình giữ lại tín hiệu này.
      total += candidate.relevance * 600;
      total += _featureTypeWeight(candidate.featureType);

      switch (candidate.matchConfidence) {
        case 'exact':
          total += 120;
          break;
        case 'high':
          total += 70;
          break;
        case 'medium':
          total += 30;
          break;
        case 'low':
          total += 5;
          break;
      }

      if (normalizedName == normalizedQuery) total += 1000;
      if (normalizedAddress == normalizedQuery) total += 850;

      if (normalizedName.startsWith(normalizedQuery)) total += 320;
      if (normalizedAddress.startsWith(normalizedQuery)) total += 180;

      if (normalizedName.contains(normalizedQuery)) total += 140;
      if (normalizedAddress.contains(normalizedQuery)) total += 90;

      for (final token in queryTokens) {
        if (normalizedName.split(' ').contains(token)) {
          total += 45;
        } else if (normalizedName.contains(token)) {
          total += 20;
        }

        if (normalizedAddress.contains(token)) {
          total += 10;
        }
      }

      if (proximityLatitude != null && proximityLongitude != null) {
        final distanceKm = _distanceKm(
          proximityLatitude,
          proximityLongitude,
          item.latitude,
          item.longitude,
        );

        if (distanceKm <= 1) {
          total += 60;
        } else if (distanceKm <= 3) {
          total += 42;
        } else if (distanceKm <= 10) {
          total += 24;
        } else if (distanceKm <= 20) {
          total += 10;
        }
      }

      total -= item.name.length * 0.12;
      return total;
    }

    final sorted = [...items];
    sorted.sort((a, b) => score(b).compareTo(score(a)));
    return sorted;
  }

  double _featureTypeWeight(String featureType) {
    switch (featureType) {
      case 'address':
        return 80;
      case 'street':
        return 58;
      case 'neighborhood':
        return 28;
      case 'locality':
        return 24;
      case 'district':
        return 18;
      case 'place':
        return 14;
      case 'region':
        return 8;
      default:
        return 0;
    }
  }

  bool _shouldPreferVietnamBias(
    String query, {
    double? proximityLatitude,
    double? proximityLongitude,
  }) {
    final normalized = _normalizeForCompare(query);
    if (_looksLikeVietnamQuery(normalized)) {
      return true;
    }

    if (proximityLatitude == null || proximityLongitude == null) {
      return false;
    }

    return _isInsideVietnam(proximityLatitude, proximityLongitude);
  }

  bool _looksLikeVietnamQuery(String normalizedQuery) {
    const vietnamTokens = <String>[
      'viet nam',
      'vietnam',
      'ho chi minh',
      'ha noi',
      'da nang',
      'hai phong',
      'can tho',
      'thanh pho',
      'quan ',
      'phuong ',
      'huyen ',
      'xa ',
      'tinh ',
    ];

    for (final token in vietnamTokens) {
      if (normalizedQuery.contains(token)) {
        return true;
      }
    }

    return false;
  }

  bool _isInsideVietnam(double latitude, double longitude) {
    return latitude >= 8.179066 &&
        latitude <= 23.393395 &&
        longitude >= 102.14441 &&
        longitude <= 109.4699;
  }

  String _normalizeWhitespace(String value) {
    return value.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  String _normalizeVietnameseAliases(String value) {
    var text = _normalizeWhitespace(value);

    text = text.replaceAll(
      RegExp(r'\btp\.?\s*hcm\b', caseSensitive: false),
      ' thanh pho ho chi minh ',
    );
    text = text.replaceAll(
      RegExp(r'\btphcm\b', caseSensitive: false),
      ' thanh pho ho chi minh ',
    );
    text = text.replaceAll(
      RegExp(r'\bhcmc\b', caseSensitive: false),
      ' thanh pho ho chi minh ',
    );
    text = text.replaceAll(
      RegExp(r'\bsai\s+gon\b', caseSensitive: false),
      ' thanh pho ho chi minh ',
    );
    text = text.replaceAll(
      RegExp(r'\bsg\b', caseSensitive: false),
      ' thanh pho ho chi minh ',
    );
    text = text.replaceAll(RegExp(r'\bhn\b', caseSensitive: false), ' ha noi ');

    text = text.replaceAll(
      RegExp(r'\btp\.?\b', caseSensitive: false),
      ' thanh pho ',
    );
    text = text.replaceAllMapped(
      RegExp(r'\bq\.?\s*(\d+)\b', caseSensitive: false),
      (m) => ' quan ${m[1]} ',
    );
    text = text.replaceAll(RegExp(r'\bq\.?\b', caseSensitive: false), ' quan ');
    text = text.replaceAllMapped(
      RegExp(r'\bp\.?\s*(\d+)\b', caseSensitive: false),
      (m) => ' phuong ${m[1]} ',
    );
    text = text.replaceAll(
      RegExp(r'\bp\.?\b', caseSensitive: false),
      ' phuong ',
    );

    return _normalizeWhitespace(text);
  }

  String _normalizeForCompare(String value) {
    var text = value.toLowerCase().trim();

    const replacements = <String, String>{
      'à': 'a',
      'á': 'a',
      'ạ': 'a',
      'ả': 'a',
      'ã': 'a',
      'â': 'a',
      'ầ': 'a',
      'ấ': 'a',
      'ậ': 'a',
      'ẩ': 'a',
      'ẫ': 'a',
      'ă': 'a',
      'ằ': 'a',
      'ắ': 'a',
      'ặ': 'a',
      'ẳ': 'a',
      'ẵ': 'a',
      'è': 'e',
      'é': 'e',
      'ẹ': 'e',
      'ẻ': 'e',
      'ẽ': 'e',
      'ê': 'e',
      'ề': 'e',
      'ế': 'e',
      'ệ': 'e',
      'ể': 'e',
      'ễ': 'e',
      'ì': 'i',
      'í': 'i',
      'ị': 'i',
      'ỉ': 'i',
      'ĩ': 'i',
      'ò': 'o',
      'ó': 'o',
      'ọ': 'o',
      'ỏ': 'o',
      'õ': 'o',
      'ô': 'o',
      'ồ': 'o',
      'ố': 'o',
      'ộ': 'o',
      'ổ': 'o',
      'ỗ': 'o',
      'ơ': 'o',
      'ờ': 'o',
      'ớ': 'o',
      'ợ': 'o',
      'ở': 'o',
      'ỡ': 'o',
      'ù': 'u',
      'ú': 'u',
      'ụ': 'u',
      'ủ': 'u',
      'ũ': 'u',
      'ư': 'u',
      'ừ': 'u',
      'ứ': 'u',
      'ự': 'u',
      'ử': 'u',
      'ữ': 'u',
      'ỳ': 'y',
      'ý': 'y',
      'ỵ': 'y',
      'ỷ': 'y',
      'ỹ': 'y',
      'đ': 'd',
    };

    replacements.forEach((source, target) {
      text = text.replaceAll(source, target);
    });

    text = text.replaceAll(RegExp(r'[,\-_/]+'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    return text;
  }

  _RoutableCoordinate? _extractRoutablePoint(Map<String, dynamic> coordinates) {
    final routablePointsRaw = coordinates['routable_points'];
    if (routablePointsRaw is! List || routablePointsRaw.isEmpty) {
      return null;
    }

    final firstPointRaw = routablePointsRaw.first;
    if (firstPointRaw is! Map) {
      return null;
    }

    final firstPoint = Map<String, dynamic>.from(firstPointRaw);
    final latitude = (firstPoint['latitude'] as num?)?.toDouble();
    final longitude = (firstPoint['longitude'] as num?)?.toDouble();
    if (latitude == null || longitude == null) {
      return null;
    }

    return _RoutableCoordinate(latitude: latitude, longitude: longitude);
  }

  double _distanceKm(double lat1, double lon1, double lat2, double lon2) {
    const earthRadiusKm = 6371.0;

    double toRadians(double degree) => degree * math.pi / 180.0;

    final dLat = toRadians(lat2 - lat1);
    final dLon = toRadians(lon2 - lon1);

    final a =
        math.pow(math.sin(dLat / 2), 2) +
        math.cos(toRadians(lat1)) *
            math.cos(toRadians(lat2)) *
            math.pow(math.sin(dLon / 2), 2);

    final c =
        2 * math.atan2(math.sqrt(a.toDouble()), math.sqrt(1 - a.toDouble()));

    return earthRadiusKm * c;
  }
}

class _RoutableCoordinate {
  const _RoutableCoordinate({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

class _GeocodeCandidate {
  const _GeocodeCandidate({
    required this.item,
    required this.featureType,
    required this.relevance,
    this.matchConfidence,
  });

  final MapPlaceSearchResult item;
  final String featureType;
  final double relevance;
  final String? matchConfidence;
}
