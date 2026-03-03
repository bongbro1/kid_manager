import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class SosApi {
  SosApi({FirebaseFunctions? functions})
    : _functions =
          functions ?? FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

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
    debugPrint("created: ${res}");

    final d = Map<String, dynamic>.from(res.data as Map);

    return CreateSosResult(
      ok: d['ok'] == true,
      sosId: (d['sosId'] ?? eventId).toString(),
      created: d['created'] == true,
      familyId: (d['familyId'] ?? '').toString(),
    );
  }

  Future<void> resolveSos({
    required String familyId,
    required String sosId,
  }) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null)
      throw FirebaseFunctionsException(
        code: 'unauthenticated',
        message: 'Chưa đăng nhập',
      );

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
