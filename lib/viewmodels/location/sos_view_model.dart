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

  Future<String?> triggerSos({
    required double lat,
    required double lng,
    double? acc,
    required String createdByName,
  }) async {
    final l10n = _fallbackL10n();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      _error = l10n.authLoginRequired;
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
      debugPrint('CODE: ${e.message}');
      debugPrint('DETAILS: ${e.details}');
      return null;
    } catch (e) {
      debugPrint('ERROR SOS: $e');
      _error = e.toString();
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
    try {
      await _api.resolveSos(familyId: familyId, sosId: sosId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }
}
