import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/repositories/schedule_repository.dart';

class ImportRowResult {
  final int rowIndex; // 1-based excel row number
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

  /// nếu mất mạng / không query được db để dedupe
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
  ScheduleImportService(this.repo);

  // =========================================================
  // TEMPLATE: chỉ 1 sheet tên schedule
  // Cột theo thứ tự model bạn muốn:
  // title | description | date | start | end
  // =========================================================
  Future<File> generateTemplateExcel() async {
    const tag = '[SCHEDULE_TEMPLATE]';

    final excel = Excel.createExcel();

    // excel.tables là Map<String, Sheet>
    // Excel.createExcel() thường tạo 1 sheet mặc định "Sheet1"
    final existingNames = excel.tables.keys.toList();
    debugPrint('$tag existing sheets: $existingNames');

    // nếu đã có schedule thì dùng luôn; nếu không thì rename sheet đầu sang schedule
    if (!excel.tables.containsKey('schedule')) {
      if (excel.tables.isNotEmpty) {
        final firstName = excel.tables.keys.first;
        if (firstName != 'schedule') {
          excel.rename(firstName, 'schedule');
        }
      } else {
        // cực hiếm, nhưng để chắc: tạo sheet schedule bằng cách truy cập
        excel['schedule'];
      }
    }

    // nếu còn sheet khác (do createExcel tạo + bạn truy cập sheet khác trước đó)
    // thì remove hết, chỉ giữ schedule
    final namesAfter = excel.tables.keys.toList();
    for (final name in namesAfter) {
      if (name != 'schedule') {
        excel.delete(name);
      }
    }

    final sheet = excel['schedule'];

    // excel 4.0.2: TextCellValue không const -> không dùng const []
    sheet.appendRow([
      TextCellValue('title'),
      TextCellValue('description'),
      TextCellValue('date'),  // yyyy-MM-dd hoặc dd/MM/yyyy
      TextCellValue('start'), // HH:mm
      TextCellValue('end'),   // HH:mm
    ]);

    sheet.appendRow([
      TextCellValue('Học Toán'),
      TextCellValue('Làm bài 1-5'),
      TextCellValue('2026-03-03'),
      TextCellValue('10:05'),
      TextCellValue('11:05'),
    ]);

    sheet.appendRow([
      TextCellValue('Đá bóng'),
      TextCellValue(''),
      TextCellValue('2026-03-03'),
      TextCellValue('14:00'),
      TextCellValue('15:00'),
    ]);

    excel.setDefaultSheet('schedule');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Không tạo được bytes excel');
    }

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/schedule_template.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    debugPrint('$tag saved temp: ${file.path} size=${await file.length()}');
    debugPrint('$tag final sheets: ${excel.tables.keys.toList()}');

    return file;
  }

  // =========================================================
  // PREVIEW
  // Cột theo thứ tự:
  // 0 title
  // 1 description
  // 2 date
  // 3 start
  // 4 end
  // =========================================================
  Future<ImportPreview> previewExcelBytes({
    required List<int> bytes,
    required String parentUid,
    required String childId,
  }) async {
    const tag = '[SCHEDULE_IMPORT]';

    final excel = Excel.decodeBytes(bytes);

    // tìm sheet schedule (case-insensitive), fallback sheet đầu
    Sheet? sheet;

    if (excel.tables.containsKey('schedule')) {
      sheet = excel.tables['schedule'];
    } else {
      final key = excel.tables.keys.firstWhere(
        (k) => k.toLowerCase() == 'schedule',
        orElse: () => '',
      );
      if (key.isNotEmpty) sheet = excel.tables[key];
    }

    sheet ??= (excel.tables.isEmpty ? null : excel.tables.values.first);

    if (sheet == null) {
      return const ImportPreview(rows: [], okCount: 0, errorCount: 0, duplicateCount: 0);
    }

    debugPrint('$tag sheets=${excel.tables.keys.toList()}');
    debugPrint('$tag usingSheet=${sheet.sheetName} rows=${sheet.maxRows}');

    if (sheet.maxRows <= 1) {
      return const ImportPreview(rows: [], okCount: 0, errorCount: 0, duplicateCount: 0);
    }

    // log header + sample row
    debugPrint('$tag headerRow=${sheet.row(0).map((c) => c?.value).toList()}');
    debugPrint('$tag sampleRow1=${sheet.row(1).map((c) => c?.value).toList()}');

    final results = <ImportRowResult>[];

    final fileKeys = <String>{};

    DateTime? minStart;
    DateTime? maxStart;

    for (var r = 1; r < sheet.maxRows; r++) {
      final row = sheet.row(r);

      if (_isRowEmpty(row)) continue;

      try {
        final titleRaw = row.length > 0 ? row[0]?.value : null;
        final descRaw = row.length > 1 ? row[1]?.value : null;
        final dateRaw = row.length > 2 ? row[2]?.value : null;
        final startRaw = row.length > 3 ? row[3]?.value : null;
        final endRaw = row.length > 4 ? row[4]?.value : null;

        final title = (_cellToString(titleRaw) ?? '').trim();
        if (title.isEmpty) throw Exception('Thiếu title');

        final date = _parseDateCell(dateRaw);
        final startTod = _parseTimeCell(startRaw);
        final endTod = _parseTimeCell(endRaw);

        final startAt = _combine(date, startTod);
        final endAt = _combine(date, endTod);

        if (!endAt.isAfter(startAt)) {
          throw Exception('Giờ kết thúc phải > giờ bắt đầu');
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
          id: 'tmp_${r + 1}',
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

        minStart = (minStart == null || startAt.isBefore(minStart)) ? startAt : minStart;
        maxStart = (maxStart == null || startAt.isAfter(maxStart)) ? startAt : maxStart;

        results.add(ImportRowResult(
          rowIndex: r + 1,
          schedule: s,
          isDuplicateInFile: dupInFile,
        ));
      } catch (e) {
        results.add(ImportRowResult(
          rowIndex: r + 1,
          error: e.toString(),
        ));
      }
    }

    // dedupe DB theo range
    final dbKeys = <String>{};
    String? warning;

    if (minStart != null && maxStart != null) {
      final startRange = DateTime(minStart!.year, minStart!.month, minStart!.day);
      final endRangeExclusive = DateTime(maxStart!.year, maxStart!.month, maxStart!.day + 1);

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
        warning = 'Không kiểm tra trùng DB do lỗi mạng: $e';
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

    int ok = 0, err = 0, dup = 0;
    for (final r in rows2) {
      if (r.error != null) {
        err++;
      } else if (r.isDuplicateInFile || r.isDuplicateInDb) {
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

  // =========================================================
  // IMPORT
  // =========================================================
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

  // ========================= HELPERS =========================

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

  /// date: hỗ trợ yyyy-MM-dd | yyyy/MM/dd | dd/MM/yyyy
  DateTime _parseDateCell(dynamic v) {
    final raw = _cellToString(v);
    if (raw == null) throw Exception('Thiếu date');

    final parts = raw.split(RegExp(r'[-/]'));
    if (parts.length != 3) throw Exception('Sai date: $raw');

    // yyyy-MM-dd
    if (parts[0].length == 4) {
      final y = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      final d = int.parse(parts[2]);
      return DateTime(y, m, d);
    }

    // dd/MM/yyyy
    final d = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    final y = int.parse(parts[2]);
    return DateTime(y, m, d);
  }

  /// time: "HH:mm" hoặc số excel time 0.5 -> 12:00
  TimeOfDay _parseTimeCell(dynamic v) {
    if (v == null) throw Exception('Thiếu time');

    final s = _cellToString(v);
    if (s != null) {
      final parts = s.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }

      // trường hợp excel trả về dạng số dưới dạng string
      final asNum = num.tryParse(s);
      if (asNum != null) return _excelNumberToTime(asNum);

      throw Exception('Sai time: $s (đúng: HH:mm)');
    }

    if (v is num) return _excelNumberToTime(v);

    throw Exception('Sai time (đúng: HH:mm)');
  }

  TimeOfDay _excelNumberToTime(num v) {
    final totalMinutes = (v * 24 * 60).round();
    final hour = (totalMinutes ~/ 60) % 24;
    final minute = totalMinutes % 60;
    return TimeOfDay(hour: hour, minute: minute);
  }

  DateTime _combine(DateTime date, TimeOfDay tod) =>
      DateTime(date.year, date.month, date.day, tod.hour, tod.minute);

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
}