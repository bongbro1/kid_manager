import 'dart:ui';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class SosApi {
  SosApi({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  AppLocalizations _fallbackL10n() {
    final lang = PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    return lookupAppLocalizations(Locale(lang == 'en' ? 'en' : 'vi'));
  }

  Future<CreateSosResult> createSos({
    required double lat,
    required double lng,
    double? acc,
    required String createdByName,
  }) async {
    final eventId = const Uuid().v4();
    final fn = _functions.httpsCallable('createSos');
    final res = await fn.call({
      'eventId': eventId,
      'lat': lat,
      'lng': lng,
      'acc': acc,
      'createdByName': createdByName,
    });
    debugPrint('created: $res');

    final data = Map<String, dynamic>.from(res.data as Map);

    return CreateSosResult(
      ok: data['ok'] == true,
      sosId: (data['sosId'] ?? eventId).toString(),
      created: data['created'] == true,
      familyId: (data['familyId'] ?? '').toString(),
    );
  }

  Future<void> resolveSos({
    required String familyId,
    required String sosId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: _fallbackL10n().authLoginRequired,
      );
    }

    final fn = _functions.httpsCallable('resolveSos');
    await fn.call({'familyId': familyId, 'sosId': sosId});
  }
}

class CreateSosResult {
  final bool ok;
  final String sosId;
  final bool created;
  final String familyId;

  CreateSosResult({
    required this.ok,
    required this.sosId,
    required this.created,
    required this.familyId,
  });
}
