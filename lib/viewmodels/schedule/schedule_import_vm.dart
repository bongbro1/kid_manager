import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:kid_manager/services/schedule/schedule_import_service.dart';

class ScheduleImportVM extends ChangeNotifier {
  final ScheduleImportService service;

  ScheduleImportVM(this.service);

  bool loading = false;
  String? error;

  String? selectedChildId;
  ImportPreview? preview;

  void setChild(String? id) {
    selectedChildId = id;
    preview = null;
    error = null;
    notifyListeners();
  }

  Future<void> previewFile({
    required Uint8List bytes,
    required String parentUid,
  }) async {
    final childId = selectedChildId;
    if (childId == null) {
      error = await service.selectChildRequiredMessage(parentUid);
      notifyListeners();
      return;
    }

    loading = true;
    error = null;
    preview = null;
    notifyListeners();

    try {
      preview = await service.previewExcelBytes(
        bytes: bytes,
        parentUid: parentUid,
        childId: childId,
      );
    } catch (e) {
      error = _cleanErrorMessage(e);
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void resetPreview() {
    preview = null;
    error = null;
    loading = false;
    notifyListeners();
  }

  void resetAllKeepChild() {
    preview = null;
    error = null;
    loading = false;
    notifyListeners();
  }

  Future<int> importNow({
    required String parentUid,
  }) async {
    final p = preview;
    if (p == null) return 0;

    loading = true;
    error = null;
    notifyListeners();

    try {
      final importedCount = await service.importApproved(
        parentUid: parentUid,
        preview: p,
      );

      preview = null;
      return importedCount;
    } catch (e) {
      error = _cleanErrorMessage(e);
      return 0;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  String _cleanErrorMessage(Object e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }
}
