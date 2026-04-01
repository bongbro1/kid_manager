import 'package:kid_manager/core/app_route_observer.dart';
import 'package:kid_manager/core/sos/sos_focus_bus.dart';

class SosTapRouter {
  SosTapRouter._();

  static String? _lastHandledKey;
  static DateTime? _lastHandledAt;

  static Future<void> handleTap(Map<String, dynamic> data) async {
    final type = (data['type']?.toString() ?? '').toLowerCase();
    if (type != 'sos') return;

    final familyId = data['familyId']?.toString().trim() ?? '';
    final sosId = data['sosId']?.toString().trim() ?? '';
    final childUid =
        data['createdByUid']?.toString().trim() ??
        data['childUid']?.toString().trim();
    final lat = double.tryParse(data['lat']?.toString() ?? '');
    final lng = double.tryParse(data['lng']?.toString() ?? '');

    final key = '$familyId::$sosId::${childUid ?? ''}::$lat::$lng';
    final now = DateTime.now();
    final isDuplicate =
        _lastHandledKey == key &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2);
    if (isDuplicate) return;

    _lastHandledKey = key;
    _lastHandledAt = now;

    final mapTabIndex = mapTabIndexNotifier.value;
    activeTabNotifier.value = mapTabIndex >= 0 ? mapTabIndex : 0;

    if (lat == null || lng == null || familyId.isEmpty || sosId.isEmpty) {
      return;
    }

    sosFocusNotifier.value = SosFocus(
      lat: lat,
      lng: lng,
      familyId: familyId,
      sosId: sosId,
      childUid: childUid?.isEmpty == true ? null : childUid,
    );
  }
}
