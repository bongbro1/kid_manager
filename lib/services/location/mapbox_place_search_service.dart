import 'dart:math' as math;

import 'package:kid_manager/models/location/map_place_search_result.dart';
import 'package:kid_manager/services/location/mapbox_gateway_service.dart';
import 'package:kid_manager/utils/runtime_l10n.dart';

class MapboxPlaceSearchException implements Exception {
  const MapboxPlaceSearchException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() => message;
}

class MapboxPlaceSearchService {
  MapboxPlaceSearchService({
    this.defaultLimit = 8,
    this.defaultLanguage = 'vi,en',
    this.defaultCountry = 'VN',
    this.minQueryLength = 2,
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
    MapboxGatewayService? gateway,
  }) : _gateway = gateway ?? MapboxGatewayService();

  final int defaultLimit;
  final String defaultLanguage;
  final String defaultCountry;
  final int minQueryLength;
  final bool useVietnamBbox;
  final String vietnamBbox;
  final List<String> featureTypes;
  final MapboxGatewayService _gateway;

  Future<List<MapPlaceSearchResult>> search(
    String rawQuery, {
    double? proximityLatitude,
    double? proximityLongitude,
    int? limit,
    String? language,
  }) async {
    final displayQuery = _normalizeWhitespace(rawQuery);
    if (displayQuery.length < minQueryLength) {
      return const [];
    }

    final requestQuery = _normalizeVietnameseAliases(displayQuery);
    final resolvedLimit = math.min(limit ?? defaultLimit, 10);
    final resolvedLanguage = language ?? defaultLanguage;
    final shouldPreferVietnamBias = _shouldPreferVietnamBias(
      requestQuery,
      proximityLatitude: proximityLatitude,
      proximityLongitude: proximityLongitude,
    );

    final contextual = await _searchOnce(
      requestQuery,
      limit: math.max(resolvedLimit, 8),
      language: resolvedLanguage,
      country: shouldPreferVietnamBias ? defaultCountry : null,
      proximityLatitude: proximityLatitude,
      proximityLongitude: proximityLongitude,
      useBbox: shouldPreferVietnamBias && useVietnamBbox,
    );

    List<MapboxPlaceCandidate> global = const [];
    if (shouldPreferVietnamBias ||
        contextual.length < resolvedLimit ||
        proximityLatitude != null ||
        proximityLongitude != null) {
      global = await _searchOnce(
        requestQuery,
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

  Future<List<MapboxPlaceCandidate>> _searchOnce(
    String query, {
    required int limit,
    required String language,
    required String? country,
    required bool useBbox,
    double? proximityLatitude,
    double? proximityLongitude,
  }) async {
    final l10n = runtimeL10n();

    try {
      return await _gateway.searchPlaces(
        query: query,
        limit: limit,
        language: language,
        fallbackName: l10n.mapPlaceSearchDefaultName,
        fallbackAddress: l10n.mapPlaceSearchNoAddress,
        country: country,
        bbox: useBbox ? vietnamBbox : null,
        proximityLatitude: proximityLatitude,
        proximityLongitude: proximityLongitude,
        featureTypes: featureTypes,
      );
    } on MapboxGatewayException catch (error) {
      throw MapboxPlaceSearchException(error.message, cause: error.cause);
    } catch (error) {
      throw MapboxPlaceSearchException(
        l10n.mapPlaceSearchUnexpectedError,
        cause: error,
      );
    }
  }

  List<MapboxPlaceCandidate> _dedupeCandidates(
    List<MapboxPlaceCandidate> items,
  ) {
    final bestByKey = <String, MapboxPlaceCandidate>{};

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

  List<MapboxPlaceCandidate> _rerank(
    List<MapboxPlaceCandidate> items, {
    required String query,
    double? proximityLatitude,
    double? proximityLongitude,
  }) {
    final normalizedQuery = _normalizeForCompare(query);
    final queryTokens = normalizedQuery
        .split(' ')
        .where((token) => token.isNotEmpty)
        .toList(growable: false);

    double score(MapboxPlaceCandidate candidate) {
      final item = candidate.item;
      final normalizedName = _normalizeForCompare(item.name);
      final normalizedAddress = _normalizeForCompare(item.fullAddress);

      var total = 0.0;
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
      (match) => ' quan ${match[1]} ',
    );
    text = text.replaceAll(RegExp(r'\bq\.?\b', caseSensitive: false), ' quan ');
    text = text.replaceAllMapped(
      RegExp(r'\bp\.?\s*(\d+)\b', caseSensitive: false),
      (match) => ' phuong ${match[1]} ',
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
