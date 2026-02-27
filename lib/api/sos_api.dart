import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';

class SosApi {
  SosApi({FirebaseFunctions? functions})
      : _functions = functions ??
      FirebaseFunctions.instanceFor(region: 'asia-southeast1');

  final FirebaseFunctions _functions;

  Future<CreateSosResult> createSos({
    required double lat,
    required double lng,
    double? acc,
  }) async {
    final eventId = const Uuid().v4();

    final fn = _functions.httpsCallable('createSos');
    final res = await fn.call({
      'eventId': eventId,
      'lat': lat,
      'lng': lng,
      'acc': acc,
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
