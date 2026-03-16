import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';

class FcmInstallationService {
  static const String _installationIdKey = 'fcm_installation_id';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const Uuid _uuid = Uuid();

  static String? _cachedInstallationId;

  static Future<String> getInstallationId() async {
    final cached = _cachedInstallationId?.trim();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    final stored = (await _storage.read(key: _installationIdKey))?.trim();
    if (stored != null && stored.isNotEmpty) {
      _cachedInstallationId = stored;
      return stored;
    }

    final created = _uuid.v4();
    await _storage.write(key: _installationIdKey, value: created);
    _cachedInstallationId = created;
    return created;
  }
}
