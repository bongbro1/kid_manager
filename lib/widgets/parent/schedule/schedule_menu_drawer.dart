import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
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
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Drawer(
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            ListTile(
              leading: Icon(Icons.menu, color: scheme.onSurface),
              title: Text(
                l10n.scheduleDrawerMenuTitle,
                style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: theme.appTypography.screenTitle.fontSize,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.star, color: Color(0xFFF4B400)),
              title: Text(l10n.memoryDayTitle),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  AppPageTransitions.route(
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
              title: Text(l10n.scheduleImportTitle),
              onTap: () async {
                Navigator.pop(context);

                final needReload = await Navigator.push<bool>(
                  context,
                  AppPageTransitions.route(
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
              title: Text(l10n.scheduleExportTitle),
              onTap: () async {
                Navigator.pop(context);

                await Navigator.push(
                  context,
                  AppPageTransitions.route(
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
