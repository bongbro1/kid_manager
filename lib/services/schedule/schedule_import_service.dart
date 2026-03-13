import 'dart:io';

import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/repositories/user_repository.dart';
import 'package:kid_manager/utils/app_localizations_loader.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/repositories/schedule_repository.dart';

class ImportRowResult {
  final int rowIndex;
  final Schedule? schedule;
  final String? error;
  final bool isDuplicateInFile;
  final bool isDuplicateInDb;

  const ImportRowResult({
    required this.rowIndex,
    this.schedule,
    this.error,
    this.isDuplicateInFile = false,
    this.isDuplicateInDb = false,
  });
}

class ImportPreview {
  final List<ImportRowResult> rows;
  final int okCount;
  final int errorCount;
  final int duplicateCount;
  final String? warning;

  const ImportPreview({
    required this.rows,
    required this.okCount,
    required this.errorCount,
    required this.duplicateCount,
    this.warning,
  });
}

class ScheduleImportService {
  final ScheduleRepository repo;
  final UserRepository _userRepo;

  ScheduleImportService(this.repo, this._userRepo);

  Future<String> selectChildRequiredMessage(String parentUid) async {
    final l10n = await _loadL10nForParent(parentUid);
    return l10n.schedulePleaseSelectChild;
  }

  Future<File> generateTemplateExcel({String? localeCode}) async {
    const tag = '[SCHEDULE_TEMPLATE]';
    final l10n = await _loadL10nForLanguageCode(localeCode);

    final excel = Excel.createExcel();

    final existingNames = excel.tables.keys.toList();
    debugPrint('$tag existing sheets: $existingNames');

    if (!excel.tables.containsKey('schedule')) {
      if (excel.tables.isNotEmpty) {
        final firstName = excel.tables.keys.first;
        if (firstName != 'schedule') {
          excel.rename(firstName, 'schedule');
        }
      } else {
        excel['schedule'];
      }
    }

    final namesAfter = excel.tables.keys.toList();
    for (final name in namesAfter) {
      if (name != 'schedule') {
        excel.delete(name);
      }
    }

    final sheet = excel['schedule'];

    sheet.appendRow([
      TextCellValue('title'),
      TextCellValue('description'),
      TextCellValue('date'),
      TextCellValue('start'),
      TextCellValue('end'),
    ]);

    sheet.appendRow([
      TextCellValue(l10n.scheduleImportTemplateSampleTitle1),
      TextCellValue(l10n.scheduleImportTemplateSampleDescription1),
      TextCellValue('2026-03-03'),
      TextCellValue('10:05'),
      TextCellValue('11:05'),
    ]);

    sheet.appendRow([
      TextCellValue(l10n.scheduleImportTemplateSampleTitle2),
      TextCellValue(''),
      TextCellValue('2026-03-03'),
      TextCellValue('14:00'),
      TextCellValue('15:00'),
    ]);

    excel.setDefaultSheet('schedule');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception(l10n.scheduleImportErrorCreateExcelBytes);
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/schedule_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    debugPrint('$tag saved temp: ${file.path} size=${await file.length()}');
    debugPrint('$tag final sheets: ${excel.tables.keys.toList()}');

    return file;
  }

  List<Sheet> _pickSheetsToImport(Excel excel) {
    if (excel.tables.isEmpty) return [];

    final scheduleKey = excel.tables.keys.firstWhere(
      (k) => k.toLowerCase() == 'schedule',
      orElse: () => '',
    );
    if (scheduleKey.isNotEmpty) {
      return [excel.tables[scheduleKey]!];
    }

    return excel.tables.values.toList();
  }

  Future<ImportPreview> previewExcelBytes({
    required List<int> bytes,
    required String parentUid,
    required String childId,
  }) async {
    const tag = '[SCHEDULE_IMPORT]';
    final l10n = await _loadL10nForParent(parentUid);

    final excel = Excel.decodeBytes(bytes);
    final sheets = _pickSheetsToImport(excel);

    if (sheets.isEmpty) {
      return const ImportPreview(
        rows: [],
        okCount: 0,
        errorCount: 0,
        duplicateCount: 0,
      );
    }

    debugPrint('$tag sheets=${excel.tables.keys.toList()}');
    debugPrint('$tag usingSheets=${sheets.map((s) => s.sheetName).toList()}');

    final results = <ImportRowResult>[];
    final fileKeys = <String>{};

    DateTime? minStart;
    DateTime? maxStart;

    for (final sheet in sheets) {
      debugPrint('$tag sheet=${sheet.sheetName} rows=${sheet.maxRows}');
      if (sheet.maxRows <= 1) continue;

      debugPrint(
        '$tag headerRow(${sheet.sheetName})=${sheet.row(0).map((c) => c?.value).toList()}',
      );
      if (sheet.maxRows > 1) {
        debugPrint(
          '$tag sampleRow1(${sheet.sheetName})=${sheet.row(1).map((c) => c?.value).toList()}',
        );
      }

      for (var r = 1; r < sheet.maxRows; r++) {
        final row = sheet.row(r);
        if (_isRowEmpty(row)) continue;

        try {
          final titleRaw = row.isNotEmpty ? row[0]?.value : null;
          final descRaw = row.length > 1 ? row[1]?.value : null;
          final dateRaw = row.length > 2 ? row[2]?.value : null;
          final startRaw = row.length > 3 ? row[3]?.value : null;
          final endRaw = row.length > 4 ? row[4]?.value : null;

          final title = (_cellToString(titleRaw) ?? '').trim();
          if (title.isEmpty) {
            throw Exception(l10n.scheduleImportErrorMissingTitle);
          }

          final date = _parseDateCell(dateRaw, l10n);
          final startTod = _parseTimeCell(startRaw, l10n);
          final endTod = _parseTimeCell(endRaw, l10n);

          final startAt = _combine(date, startTod);
          final endAt = _combine(date, endTod);

          if (!endAt.isAfter(startAt)) {
            throw Exception(l10n.scheduleImportErrorEndAfterStart);
          }

          final normalizedDate = DateTime(date.year, date.month, date.day);
          final period = _inferPeriod(startAt);

          final key = _makeDupKey(
            date: normalizedDate,
            startAt: startAt,
            endAt: endAt,
            title: title,
          );

          final dupInFile = fileKeys.contains(key);
          if (!dupInFile) fileKeys.add(key);

          final desc = (_cellToString(descRaw) ?? '').trim();

          final s = Schedule(
            id: 'tmp_${sheet.sheetName}_${r + 1}',
            childId: childId,
            parentUid: parentUid,
            title: title,
            description: desc.isEmpty ? null : desc,
            date: normalizedDate,
            startAt: startAt,
            endAt: endAt,
            period: period,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );

          minStart =
              (minStart == null || startAt.isBefore(minStart))
              ? startAt
              : minStart;
          maxStart =
              (maxStart == null || startAt.isAfter(maxStart))
              ? startAt
              : maxStart;

          results.add(
            ImportRowResult(
              rowIndex: r + 1,
              schedule: s,
              isDuplicateInFile: dupInFile,
            ),
          );
        } catch (e) {
          results.add(
            ImportRowResult(
              rowIndex: r + 1,
              error: '[${sheet.sheetName}] ${_errorMessage(e)}',
            ),
          );
        }
      }
    }

    final dbKeys = <String>{};
    String? warning;

    if (minStart != null && maxStart != null) {
      final startRange = DateTime(minStart.year, minStart.month, minStart.day);
      final endRangeExclusive = DateTime(
        maxStart.year,
        maxStart.month,
        maxStart.day + 1,
      );

      try {
        final existing = await repo.getSchedulesByRange(
          parentUid: parentUid,
          childId: childId,
          start: startRange,
          end: endRangeExclusive,
        );

        for (final s in existing) {
          final key = _makeDupKey(
            date: DateTime(s.date.year, s.date.month, s.date.day),
            startAt: s.startAt,
            endAt: s.endAt,
            title: s.title,
          );
          dbKeys.add(key);
        }
      } catch (e) {
        warning = l10n.scheduleImportWarningDbCheckFailed(_errorMessage(e));
        debugPrint('$tag DB dedupe error: $e');
      }
    }

    final rows2 = results.map((rr) {
      if (rr.schedule == null) return rr;
      final s = rr.schedule!;
      final key = _makeDupKey(
        date: s.date,
        startAt: s.startAt,
        endAt: s.endAt,
        title: s.title,
      );

      return ImportRowResult(
        rowIndex: rr.rowIndex,
        schedule: s,
        error: rr.error,
        isDuplicateInFile: rr.isDuplicateInFile,
        isDuplicateInDb: dbKeys.contains(key),
      );
    }).toList();

    int ok = 0;
    int err = 0;
    int dup = 0;

    for (final row in rows2) {
      if (row.error != null) {
        err++;
      } else if (row.isDuplicateInFile || row.isDuplicateInDb) {
        dup++;
      } else {
        ok++;
      }
    }

    return ImportPreview(
      rows: rows2,
      okCount: ok,
      errorCount: err,
      duplicateCount: dup,
      warning: warning,
    );
  }

  Future<int> importApproved({
    required String parentUid,
    required ImportPreview preview,
  }) async {
    final items = preview.rows
        .where((r) => r.error == null && !r.isDuplicateInFile && !r.isDuplicateInDb)
        .map((r) => r.schedule!)
        .toList();

    if (items.isEmpty) return 0;

    await repo.createSchedulesBatch(parentUid: parentUid, items: items);
    return items.length;
  }

  bool _isRowEmpty(List<Data?> row) {
    for (final c in row) {
      final v = c?.value;
      if (v == null) continue;
      if (v.toString().trim().isNotEmpty) return false;
    }
    return true;
  }

  String? _cellToString(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  DateTime _parseDateCell(dynamic v, AppLocalizations l10n) {
    if (v == null) throw Exception(l10n.scheduleImportErrorMissingDate);

    if (v is DateTime) {
      return DateTime(v.year, v.month, v.day);
    }

    if (v is num) {
      final base = DateTime(1899, 12, 30);
      final days = v.floor();
      final date = base.add(Duration(days: days));
      return DateTime(date.year, date.month, date.day);
    }

    final raw = _cellToString(v);
    if (raw == null) throw Exception(l10n.scheduleImportErrorMissingDate);

    var s = raw.trim();

    if ((s.startsWith('"') && s.endsWith('"')) || (s.startsWith("'") && s.endsWith("'"))) {
      s = s.substring(1, s.length - 1).trim();
    }
    if (s.startsWith("'")) s = s.substring(1).trim();

    if (s.isEmpty) throw Exception(l10n.scheduleImportErrorMissingDate);

    final iso = DateTime.tryParse(s);
    if (iso != null) {
      return DateTime(iso.year, iso.month, iso.day);
    }

    final ymd = RegExp(r'^(\d{4})[-/](\d{1,2})[-/](\d{1,2})$');
    final mYmd = ymd.firstMatch(s);
    if (mYmd != null) {
      final y = int.parse(mYmd.group(1)!);
      final m = int.parse(mYmd.group(2)!);
      final d = int.parse(mYmd.group(3)!);
      _validateDate(y, m, d, raw, l10n);
      return DateTime(y, m, d);
    }

    final dmyOrMdy = RegExp(r'^(\d{1,2})[-/](\d{1,2})[-/](\d{4})$');
    final m2 = dmyOrMdy.firstMatch(s);
    if (m2 != null) {
      final a = int.parse(m2.group(1)!);
      final b = int.parse(m2.group(2)!);
      final y = int.parse(m2.group(3)!);

      if (a > 12) {
        _validateDate(y, b, a, raw, l10n);
        return DateTime(y, b, a);
      }
      if (b > 12) {
        _validateDate(y, a, b, raw, l10n);
        return DateTime(y, a, b);
      }

      if (_isValidDate(y, b, a)) return DateTime(y, b, a);
      if (_isValidDate(y, a, b)) return DateTime(y, a, b);

      throw Exception(l10n.scheduleImportErrorInvalidDate(raw));
    }

    throw Exception(l10n.scheduleImportErrorInvalidDateSupported(raw));
  }

  bool _isValidDate(int y, int m, int d) {
    if (m < 1 || m > 12) return false;
    if (d < 1 || d > 31) return false;
    try {
      final dt = DateTime(y, m, d);
      return dt.year == y && dt.month == m && dt.day == d;
    } catch (_) {
      return false;
    }
  }

  void _validateDate(int y, int m, int d, String raw, AppLocalizations l10n) {
    if (!_isValidDate(y, m, d)) {
      throw Exception(l10n.scheduleImportErrorInvalidDate(raw));
    }
  }

  TimeOfDay _parseTimeCell(dynamic v, AppLocalizations l10n) {
    if (v == null) throw Exception(l10n.scheduleImportErrorMissingTime);

    if (v is DateTime) {
      return TimeOfDay(hour: v.hour, minute: v.minute);
    }

    if (v is num) {
      return _excelNumberToTime(v);
    }

    final raw = _cellToString(v);
    if (raw == null) throw Exception(l10n.scheduleImportErrorMissingTime);

    final s = raw.trim().toLowerCase();

    final ampm = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(am|pm)$');
    final m1 = ampm.firstMatch(s);
    if (m1 != null) {
      var hour = int.parse(m1.group(1)!);
      final minute = int.parse(m1.group(2)!);
      final ap = m1.group(4)!;

      if (ap == 'pm' && hour != 12) hour += 12;
      if (ap == 'am' && hour == 12) hour = 0;

      return TimeOfDay(hour: hour, minute: minute);
    }

    final hhmm = RegExp(r'^(\d{1,2}):(\d{2})(?::(\d{2}))?$');
    final m2 = hhmm.firstMatch(s);
    if (m2 != null) {
      final hour = int.parse(m2.group(1)!);
      final minute = int.parse(m2.group(2)!);
      return TimeOfDay(hour: hour, minute: minute);
    }

    final asNum = num.tryParse(s.replaceAll(',', '.'));
    if (asNum != null) {
      return _excelNumberToTime(asNum);
    }

    throw Exception(l10n.scheduleImportErrorInvalidTimeSupported(raw));
  }

  TimeOfDay _excelNumberToTime(num v) {
    final totalMinutes = (v * 24 * 60).round();
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _combine(DateTime date, TimeOfDay tod) {
    return DateTime(date.year, date.month, date.day, tod.hour, tod.minute);
  }

  SchedulePeriod _inferPeriod(DateTime startAt) {
    final h = startAt.hour;
    if (h < 12) return SchedulePeriod.morning;
    if (h < 18) return SchedulePeriod.afternoon;
    return SchedulePeriod.evening;
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _makeDupKey({
    required DateTime date,
    required DateTime startAt,
    required DateTime endAt,
    required String title,
  }) {
    final d = '${date.year}-${_two(date.month)}-${_two(date.day)}';
    final s = '${_two(startAt.hour)}:${_two(startAt.minute)}';
    final e = '${_two(endAt.hour)}:${_two(endAt.minute)}';
    final t = title.trim().toLowerCase();
    return '$d|$s-$e|$t';
  }

  String _errorMessage(Object e) {
    return e.toString().replaceFirst('Exception: ', '').trim();
  }

  Future<AppLocalizations> _loadL10nForParent(String parentUid) {
    return AppLocalizationsLoader.loadForUser(
      userRepository: _userRepo,
      uid: parentUid,
    );
  }

  Future<AppLocalizations> _loadL10nForLanguageCode(String? localeCode) {
    final lang = (localeCode ?? 'vi').toLowerCase();
    final locale = Locale(lang == 'en' ? 'en' : 'vi');
    return AppLocalizations.delegate.load(locale);
  }
}
