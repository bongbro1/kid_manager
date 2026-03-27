import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_file_dialog/flutter_file_dialog.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';

import 'package:kid_manager/core/app_text_styles.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/services/schedule/schedule_excel_service.dart';
import 'package:kid_manager/services/storage_service.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/views/parent/schedule/schedule_session_resolver.dart';
import 'package:kid_manager/widgets/parent/schedule/schedule_transfer_widgets.dart';

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

  bool _loading = false;
  bool _resolvingDefaultChild = false;

  String? _selectedChildId;
  DateTime _fromDate = _normalize(DateTime.now());
  DateTime _toDate = _normalize(DateTime.now());
  late final UserVm _userVm;
  late final ScheduleSessionResolver _sessionResolver;
  ScheduleSessionState? _session;

  bool get _isChildMode => _session?.isChildMode ?? widget.lockChildSelection;
  String? get _lockedChildName {
    final name = (_session?.lockedChildName ?? '').trim();
    return name.isEmpty ? null : name;
  }

  @override
  void initState() {
    super.initState();
    _userVm = context.read<UserVm>();
    _sessionResolver = ScheduleSessionResolver(
      storage: context.read<StorageService>(),
      userVm: _userVm,
    );
    _userVm.addListener(_handleUserVmChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _initSession();
    });
  }

  @override
  void dispose() {
    _userVm.removeListener(_handleUserVmChanged);
    super.dispose();
  }

  void _handleUserVmChanged() {
    if (!mounted || _session == null) return;
    _ensureSelectedChild();
  }

  Future<void> _initSession() async {
    final scheduleVm = context.read<ScheduleViewModel>();

    final resolved = await _sessionResolver.resolve(
      initialChildId: widget.initialChildId,
      lockChildSelection: widget.lockChildSelection,
      watchChildrenForParent: true,
    );
    if (resolved == null) return;

    _session = resolved;

    // Phase 2: Handle owner mapping for guardian. Export must read from the
    // resolved parent owner namespace instead of the logged-in guardian uid.
    scheduleVm.setScheduleOwnerUid(_session!.ownerParentUid);
    _selectedChildId = _session!.selectedChildId;

    if (mounted) {
      setState(() {});
    }

    _ensureSelectedChild();
  }

  static DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  void _ensureSelectedChild() {
    if (_resolvingDefaultChild) return;
    if (_session == null || _isChildMode || _selectedChildId != null) return;

    // Phase 2: The export child selector follows the resolved ownerParentUid
    // stream so guardian and parent see the same eligible children.
    final children = context.read<UserVm>().children;
    if (children.isEmpty) return;

    final fallbackChildId = ScheduleSessionResolver.resolveDefaultChildId(
      initialChildId: widget.initialChildId,
      children: children,
    );

    if (fallbackChildId == null || fallbackChildId.isEmpty) return;

    _resolvingDefaultChild = true;
    try {
      if (!mounted) return;
      setState(() {
        _selectedChildId = fallbackChildId;
      });
    } finally {
      _resolvingDefaultChild = false;
    }
  }

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

      await showScheduleTransferSuccessDialog(
        context,
        title: l10n.updateSuccessTitle,
        message: l10n.scheduleExportSuccessMessage(schedules.length),
        confirmText: l10n.authContinueButton,
      );
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
    final scheme = Theme.of(context).colorScheme;

    final children = context.select<UserVm, List<AppUser>>(
      (vm) => List<AppUser>.unmodifiable(vm.children),
    );

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        title: Text(
          l10n.scheduleExportTitle,
          style: AppTextStyles.scheduleAppBarTitle.copyWith(
            color: scheme.onSurface,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: scheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          ScheduleTransferSectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.scheduleSelectChildLabel,
                  style: AppTextStyles.body.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 10),
                _isChildMode
                    ? ScheduleTransferLockedChildBox(
                        label: _lockedChildName ?? l10n.scheduleYourChild,
                      )
                    : ScheduleTransferChildDropdown(
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
                  style: AppTextStyles.body.copyWith(color: scheme.onSurface),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: ScheduleTransferDateBox(
                        text: _ddMmYyyy(_fromDate),
                        onTap: _loading ? null : _pickFromDate,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(
                        Icons.arrow_forward,
                        color: scheme.onSurface.withOpacity(0.65),
                        size: 20,
                      ),
                    ),
                    Expanded(
                      child: ScheduleTransferDateBox(
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
                    color: scheme.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: scheme.primary.withOpacity(0.18)),
                  ),
                  child: Text(
                    l10n.scheduleExportColumnsHint,
                    style: AppTextStyles.scheduleItemTime.copyWith(
                      color: scheme.onSurface.withOpacity(0.75),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ScheduleTransferPrimaryButton(
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
