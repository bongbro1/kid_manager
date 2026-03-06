import 'dart:io';

import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';

import 'package:kid_manager/models/schedule.dart';

class ScheduleExcelService {
  Future<File> exportSchedulesToExcel({
    required List<Schedule> schedules,
    required DateTime fromDate,
    required DateTime toDate,
  }) async {
    final excel = Excel.createExcel();

    // Đảm bảo chỉ có 1 sheet tên schedule
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

    // Header
    sheet.appendRow([
      TextCellValue('title'),
      TextCellValue('description'),
      TextCellValue('date'),
      TextCellValue('start'),
      TextCellValue('end'),
    ]);

    // Sort lại cho chắc: date -> startAt
    final sorted = [...schedules]..sort((a, b) {
      final dateCmp = _normalize(a.date).compareTo(_normalize(b.date));
      if (dateCmp != 0) return dateCmp;
      return a.startAt.compareTo(b.startAt);
    });

    for (final s in sorted) {
      sheet.appendRow([
        TextCellValue(s.title.trim()),
        TextCellValue((s.description ?? '').trim()),
        TextCellValue(_yyyyMmDd(s.date)),
        TextCellValue(_hhMm(s.startAt)),
        TextCellValue(_hhMm(s.endAt)),
      ]);
    }

    excel.setDefaultSheet('schedule');

    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Không tạo được file Excel');
    }

    final dir = await getTemporaryDirectory();
    final fileName =
        'schedule_export_${_yyyyMmDd(fromDate)}_to_${_yyyyMmDd(toDate)}.xlsx';
    final file = File('${dir.path}/$fileName');

    await file.writeAsBytes(bytes, flush: true);
    return file;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  String _two(int n) => n.toString().padLeft(2, '0');

  String _yyyyMmDd(DateTime d) =>
      '${d.year}-${_two(d.month)}-${_two(d.day)}';

  String _hhMm(DateTime d) => '${_two(d.hour)}:${_two(d.minute)}';
}