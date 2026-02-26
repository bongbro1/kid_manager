import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uuid/uuid.dart';

class SosViewModel extends ChangeNotifier {
  SosViewModel({FirebaseFunctions? functions})
    : _functions = functions ?? FirebaseFunctions.instance;

  final FirebaseFunctions _functions;

  bool _sending = false;
  bool get sending => _sending;

  String? _error;
  String? get error => _error;

  String? _lastSosId;
  String? get lastSosId => _lastSosId;

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<String?> triggerSos({
    required double lat,
    required double lng,
    double? acc,
  }) async {
    if (_sending) return null;

    _sending = true;
    _error = null;
    notifyListeners();

    final eventId = const Uuid().v4();

    try {
      final fn = _functions.httpsCallable('createSos');
      final res = await fn.call({
        'eventId': eventId,
        'lat': lat,
        'lng': lng,
        'acc': acc,
      });

      final data = Map<String, dynamic>.from(res.data as Map);
      final sosId = (data['sosId'] ?? eventId).toString();

      _lastSosId = sosId;
      return sosId;
    } on FirebaseFunctionsException catch (e) {
      // resource-exhausted: vượt 20/ngày hoặc bấm quá nhanh <10s
      _error = e.message ?? '${e.code}: ${e.details ?? ''}';
      return null;
    } catch (e) {
      _error = e.toString();
      return null;
    } finally {
      _sending = false;
      notifyListeners();
    }
  }
}
