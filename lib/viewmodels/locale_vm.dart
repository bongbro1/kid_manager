import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/services/storage_service.dart';

class LocaleVm extends ChangeNotifier {
  final StorageService _storage;
  Locale _locale;

  LocaleVm(this._storage)
    : _locale = _resolveLocale(_readSavedLocale(_storage));

  Locale get locale => _locale;

  static String? _readSavedLocale(StorageService storage) {
    return storage.getString(StorageKeys.locale) ??
        storage.getString('preferredLocale');
  }

  static Locale _resolveLocale(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'en':
        return const Locale('en');
      case 'vi':
      default:
        return const Locale('vi');
    }
  }

  Future<void> setLocaleCode(String value) async {
    final next = _resolveLocale(value);
    if (_locale.languageCode == next.languageCode) return;

    _locale = next;
    notifyListeners();

    await _storage.setString(StorageKeys.locale, next.languageCode);
    await _storage.setString('preferredLocale', next.languageCode);
  }

  void syncFromProfile(String? value) {
    if (value == null || value.trim().isEmpty) return;
    final next = _resolveLocale(value);
    if (_locale.languageCode == next.languageCode) return;
    _locale = next;
    notifyListeners();
  }
}
