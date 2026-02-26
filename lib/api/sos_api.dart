import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

class SosApi {
  SosApi(this._functions);
  final FirebaseFunctions _functions;

  Future<CreateSosResult> createSos({
    required double lat,
    required double lng,
    double? acc,
  }) async {
    final eventId = const Uuid().v4(); // idempotent key

    final fn = _functions.httpsCallable('createSos');

    try {
      final res = await fn.call({
        'eventId': eventId,
        'lat': lat,
        'lng': lng,
        'acc': acc,
      });

      final d = Map<String, dynamic>.from(res.data as Map);
      return CreateSosResult(
        ok: d['ok'] == true,
        sosId: (d['sosId'] ?? eventId).toString(),
        created: d['created'] == true,
        familyId: (d['familyId'] ?? '').toString(),
      );
    } on FirebaseFunctionsException catch (e) {
      // resource-exhausted => vượt 20/ngày hoặc bấm quá nhanh <10s
      rethrow;
    }
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
