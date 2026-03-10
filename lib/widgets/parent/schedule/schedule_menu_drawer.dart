import 'package:flutter/material.dart';
import 'package:kid_manager/views/parent/memory_day/memory_day_screen.dart';
import 'package:kid_manager/views/parent/schedule/schedule_export_excel_screen.dart';
import 'package:kid_manager/views/parent/schedule/schedule_import_excel_screen.dart';

class ScheduleMenuDrawer extends StatelessWidget {
  final String? selectedChildId;
  final bool lockChildSelection;
  final Future<void> Function()? onImportSuccess;

  const ScheduleMenuDrawer({
    super.key,
    required this.selectedChildId,
    required this.lockChildSelection,
    this.onImportSuccess,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const ListTile(
              leading: Icon(
                Icons.menu,
                color: Color.fromARGB(255, 0, 0, 0),
              ),
              title: Text(
                'Menu',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Color(0xFFF4B400)),
              title: const Text('Ngày đáng nhớ'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MemoryDayScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.upload_file,
                color: Color.fromARGB(255, 0, 224, 49),
              ),
              title: const Text('Thêm file Excel'),
              onTap: () async {
                Navigator.pop(context);

                final needReload = await Navigator.push<bool>(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleImportExcelScreen(
                      initialChildId: selectedChildId,
                      lockChildSelection: lockChildSelection,
                    ),
                  ),
                );

                if (needReload == true && onImportSuccess != null) {
                  await onImportSuccess!.call();
                }
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.file_download,
                color: Color.fromARGB(255, 0, 238, 255),
              ),
              title: const Text('Xuất file Excel'),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ScheduleExportExcelScreen(
                      initialChildId: selectedChildId,
                      lockChildSelection: lockChildSelection,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}