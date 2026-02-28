import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:kid_manager/api/sos_api.dart';

class SosViewModel extends ChangeNotifier {
  SosViewModel({SosApi? api}) : _api = api ?? SosApi();

  final SosApi _api;

  bool _sending = false;
  bool get sending => _sending;

  String? _error;
  String? get error => _error;

  String? _lastSosId;
  String? get lastSosId => _lastSosId;

  Future<String?> triggerSos({
    required double lat,
    required double lng,
    double? acc,
  }) async {
    final u = FirebaseAuth.instance.currentUser;
    debugPrint('AUTH user=${u?.uid} email=${u?.email}');

    if (u == null) {
      _error = 'Chưa đăng nhập';
      notifyListeners();
      return null;
    }

    final idToken = await u.getIdToken();

    if (_sending) return null;

    _sending = true;
    _error = null;
    notifyListeners();

    try {
      final res = await _api.createSos(lat: lat, lng: lng, acc: acc);

      debugPrint("✅ SOS SUCCESS");
      debugPrint("sosId: ${res.sosId}");
      debugPrint("familyId: ${res.familyId}");
      debugPrint("created: ${res.created}");

      _lastSosId = res.sosId;
      return res.sosId;
    } on FirebaseFunctionsException catch (e) {
      debugPrint("CODE: ${e.code}");
      debugPrint("CODE: ${e.message}");
      debugPrint("DETAILS: ${e.details}");
      return null;
    } catch (e) {
      print("ERROR SOS : ${e}");
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
    }
  }
}
