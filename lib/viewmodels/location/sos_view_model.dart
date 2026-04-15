import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kid_manager/api/sos_api.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class SosViewModel extends ChangeNotifier {
  SosViewModel({SosApi? api}) : _api = api ?? SosApi();

  final SosApi _api;

  bool _sending = false;
  bool get sending => _sending;

  String? _error;
  String? get error => _error;

  String? _lastSosId;
  String? get lastSosId => _lastSosId;

  AppLocalizations _fallbackL10n() {
    final lang = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return lookupAppLocalizations(Locale(lang == 'en' ? 'en' : 'vi'));
  }

  String _mapTriggerFunctionsError(
    FirebaseFunctionsException error,
    AppLocalizations l10n,
  ) {
    final code = error.code.trim().toLowerCase();
    final details = '${error.details ?? ''}'.trim();
    final raw = '${error.message ?? ''} $details'.toLowerCase();

    if (code == 'resource-exhausted') {
      if (raw.contains('daily sos limit reached')) {
        return l10n.sosDailyLimitReached;
      }

      if (raw.contains('sos too frequent')) {
        final seconds = RegExp(r'(\d+)\s*s').firstMatch(raw);
        final waitSeconds = int.tryParse(seconds?.group(1) ?? '') ?? 30;
        return l10n.sosRateLimitWaitSeconds(waitSeconds);
      }

      return l10n.sosRateLimitWaitSeconds(30);
    }

    if (code == 'unauthenticated') {
      return l10n.sosLoginRequired;
    }

    if (code == 'unavailable' || code == 'deadline-exceeded') {
      return l10n.sosNetworkError;
    }

    if (code == 'permission-denied') {
      return l10n.sosPermissionDenied;
    }

    return l10n.sosSendFailed;
  }

  String _mapResolveFunctionsError(
    FirebaseFunctionsException error,
    AppLocalizations l10n,
  ) {
    final code = error.code.trim().toLowerCase();

    if (code == 'unauthenticated') {
      return l10n.sosResolveLoginRequired;
    }

    if (code == 'unavailable' || code == 'deadline-exceeded') {
      return l10n.sosResolveNetworkError;
    }

    if (code == 'permission-denied') {
      return l10n.sosResolvePermissionDenied;
    }

    return l10n.sosResolveFailed;
  }

  Future<String?> triggerSos({
    required double lat,
    required double lng,
    double? acc,
    required String createdByName,
  }) async {
    final l10n = _fallbackL10n();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _error = l10n.sosLoginRequired;
      notifyListeners();
      return null;
    }
    final name = createdByName.trim().isNotEmpty
        ? createdByName.trim()
        : (user.email ?? l10n.parentLocationUnknownUser);

    if (_sending) return null;

    _sending = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.createSos(
        lat: lat,
        lng: lng,
        acc: acc,
        createdByName: name,
      );

      _lastSosId = res.sosId;
      return res.sosId;
    } on FirebaseFunctionsException catch (e) {
      debugPrint('CODE: ${e.code}');
      debugPrint('MESSAGE: ${e.message}');
      debugPrint('DETAILS: ${e.details}');
      _error = _mapTriggerFunctionsError(e, l10n);
      return null;
    } catch (e) {
      debugPrint('ERROR SOS: $e');
      _error = l10n.sosSendFailed;
      return null;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }

  Future<void> resolve({
    required String familyId,
    required String sosId,
  }) async {
    final l10n = _fallbackL10n();
    _error = null;
    notifyListeners();

    try {
      await _api.resolveSos(familyId: familyId, sosId: sosId);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('RESOLVE CODE: ${e.code}');
      debugPrint('RESOLVE MESSAGE: ${e.message}');
      debugPrint('RESOLVE DETAILS: ${e.details}');
      _error = _mapResolveFunctionsError(e, l10n);
      notifyListeners();
      rethrow;
    } catch (e) {
      debugPrint('RESOLVE ERROR SOS: $e');
      _error = l10n.sosResolveFailed;
      notifyListeners();
      rethrow;
    }
  }
}
