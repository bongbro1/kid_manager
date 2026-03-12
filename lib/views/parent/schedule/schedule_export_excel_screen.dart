import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/core/app_text_styles.dart';
import 'package:kid_manager/core/storage_keys.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/services/schedule/schedule_excel_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';

class ScheduleExportExcelScreen extends StatefulWidget {
  final String? initialChildId;
  final bool lockChildSelection;

  const ScheduleExportExcelScreen({
    super.key,
    this.initialChildId,
    this.lockChildSelection = false,
  });

  @override
  State<ScheduleExportExcelScreen> createState() =>
      _ScheduleExportExcelScreenState();
}

class _ScheduleExportExcelScreenState extends State<ScheduleExportExcelScreen> {
  final ScheduleExcelService _excelService = ScheduleExcelService();

  bool _didInit = false;
  bool _loading = false;

  String? _selectedChildId;
  String? _currentUid;
  String? _role;
  String? _ownerParentUid;
  String? _lockedChildName;

  DateTime _fromDate = _normalize(DateTime.now());
  DateTime _toDate = _normalize(DateTime.now());

  bool get _isChildMode => widget.lockChildSelection || _role == 'child';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _initSession();
    });
  }

  Future<void> _initSession() async {
    final l10n = AppLocalizations.of(context);
    final storage = context.read<StorageService>();
    final userVm = context.read<UserVm>();
    final scheduleVm = context.read<ScheduleViewModel>();

    final currentUid = storage.getString(StorageKeys.uid);
    final role = storage.getString(StorageKeys.role);

    if (currentUid == null) return;

    _currentUid = currentUid;
    _role = role;

    if (_isChildMode) {
      if (userVm.profile == null || userVm.profile!.id != currentUid) {
        await userVm.loadProfile();
      }

      final ownerParentUid = userVm.profile?.parentUid;
      if (ownerParentUid == null || ownerParentUid.isEmpty) return;

      _ownerParentUid = ownerParentUid;
      scheduleVm.setScheduleOwnerUid(ownerParentUid);

      _selectedChildId = widget.initialChildId ?? currentUid;

      final name = (userVm.profile?.name ?? '').trim();
      _lockedChildName = name.isEmpty ? l10n.scheduleYourChild : name;
    } else {
      _ownerParentUid = currentUid;
      scheduleVm.setScheduleOwnerUid(currentUid);
      userVm.watchChildren(currentUid);

      final children = userVm.children;
      if (widget.initialChildId != null && widget.initialChildId!.isNotEmpty) {
        _selectedChildId = widget.initialChildId;
      } else if (children.isNotEmpty) {
        _selectedChildId = children.first.uid;
      }
    }

    if (mounted) {
      setState(() {});
    }
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  Future<void> _pickFromDate() async {
    if (_loading) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _fromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _fromDate = _normalize(picked);
      if (_fromDate.isAfter(_toDate)) {
        _toDate = _fromDate;
      }
    });
  }

  Future<void> _pickToDate() async {
    if (_loading) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _toDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _toDate = _normalize(picked);
      if (_toDate.isBefore(_fromDate)) {
        _fromDate = _toDate;
      }
    });
  }

  Future<void> _showSuccessDialog(BuildContext context, int count) async {
    final l10n = AppLocalizations.of(context);
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 86,
                  height: 86,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE8F0FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check,
                      size: 42,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.updateSuccessTitle,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.scheduleExportSuccessMessage(count),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    onPressed: () => Navigator.of(dialogCtx).pop(),
                    child: Text(
                      l10n.authContinueButton,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportExcel() async {
    const tag = '[SCHEDULE_EXPORT]';
    final l10n = AppLocalizations.of(context);

    if (_selectedChildId == null || _selectedChildId!.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.schedulePleaseSelectChild)));
      return;
    }

    if (_fromDate.isAfter(_toDate)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleExportInvalidDateRange)),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      final scheduleVm = context.read<ScheduleViewModel>();

      final List<Schedule> schedules = await scheduleVm.getSchedulesForExport(
        childId: _selectedChildId!,
        fromDate: _fromDate,
        toDate: _toDate,
      );

      if (!mounted) return;

      if (schedules.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scheduleExportNoDataInRange)),
        );
        return;
      }

      final File tempFile = await _excelService.exportSchedulesToExcel(
        schedules: schedules,
        fromDate: _fromDate,
        toDate: _toDate,
        localeCode: Localizations.localeOf(context).languageCode,
      );

      debugPrint('$tag tempFile.path = ${tempFile.path}');
      debugPrint('$tag tempFile.length = ${await tempFile.length()}');

      final savedPath = await FlutterFileDialog.saveFile(
        params: SaveFileDialogParams(
          sourceFilePath: tempFile.path,
          fileName:
              'schedule_export_${_yyyyMmDd(_fromDate)}_to_${_yyyyMmDd(_toDate)}.xlsx',
        ),
      );

      debugPrint('$tag savedPath = $savedPath');

      if (!mounted) return;

      if (savedPath == null || savedPath.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.scheduleExportSaveCanceled)),
        );
        return;
      }

      await _showSuccessDialog(context, schedules.length);
      if (!mounted) return;

      final result = await OpenFilex.open(savedPath);
      debugPrint(
        '$tag open result: type=${result.type} message=${result.message}',
      );
    } catch (e, s) {
      debugPrint('$tag ERROR = $e');
      debugPrint('$tag STACK = $s');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.scheduleExportFailed(e.toString()))),
      );
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _ddMmYyyy(DateTime d) => '${_two(d.day)}/${_two(d.month)}/${d.year}';

  String _yyyyMmDd(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final userVm = context.watch<UserVm>();
    final children = userVm.children;

    if (!_isChildMode && _selectedChildId == null && children.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _selectedChildId =
              widget.initialChildId != null && widget.initialChildId!.isNotEmpty
              ? widget.initialChildId
              : children.first.uid;
        });
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          l10n.scheduleExportTitle,
          style: AppTextStyles.scheduleAppBarTitle,
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkText),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.scheduleSelectChildLabel, style: AppTextStyles.body),
                const SizedBox(height: 10),
                _isChildMode
                    ? _LockedChildBox(
                        label: _lockedChildName ?? l10n.scheduleYourChild,
                      )
                    : _ChildDropdown(
                        children: children,
                        selectedId: _selectedChildId,
                        onChanged: _loading
                            ? null
                            : (id) {
                                setState(() {
                                  _selectedChildId = id;
                                });
                              },
                      ),
                const SizedBox(height: 14),
                Text(
                  l10n.scheduleExportDateRangeLabel,
                  style: AppTextStyles.body,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _DateBox(
                        text: _ddMmYyyy(_fromDate),
                        onTap: _loading ? null : _pickFromDate,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_forward,
                        color: AppColors.secondaryText,
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: _DateBox(
                        text: _ddMmYyyy(_toDate),
                        onTap: _loading ? null : _pickToDate,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F8FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    l10n.scheduleExportColumnsHint,
                    style: AppTextStyles.scheduleItemTime,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PrimaryButton(
            text: _loading
                ? l10n.scheduleExportLoadingButton
                : l10n.scheduleExportSubmitButton,
            icon: Icons.download,
            onTap: _loading ? null : _exportExcel,
            isLoading: _loading,
          ),
        ],
      ),
    );
  }
}

class _LockedChildBox extends StatelessWidget {
  final String label;

  const _LockedChildBox({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.body,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _ChildDropdown extends StatelessWidget {
  final List<AppUser> children;
  final String? selectedId;
  final ValueChanged<String?>? onChanged;

  const _ChildDropdown({
    required this.children,
    required this.selectedId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (children.isEmpty) {
      return Text(l10n.scheduleNoChild, style: AppTextStyles.body);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: selectedId ?? children.first.uid,
          items: children
              .map(
                (c) => DropdownMenuItem(
                  value: c.uid,
                  child: Text(
                    (c.displayName ?? c.email ?? c.uid),
                    style: AppTextStyles.body,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;

  const _DateBox({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: AppColors.secondaryText,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: AppTextStyles.body,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  const _PrimaryButton({
    required this.text,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (onTap == null && isLoading)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              else
                Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(text, style: AppTextStyles.scheduleCreateButton),
            ],
          ),
        ),
      ),
    );
  }
}
