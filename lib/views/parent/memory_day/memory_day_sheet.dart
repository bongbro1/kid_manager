import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/utils/notification_helper.dart';
import 'package:kid_manager/utils/ui_helpers.dart';
import 'package:provider/provider.dart';

import '../../../models/memory_day.dart';
import '../../../viewmodels/memory_day_vm.dart';

class MemoryDaySheet extends StatefulWidget {
  const MemoryDaySheet({super.key, this.memory});

  final MemoryDay? memory;

  @override
  State<MemoryDaySheet> createState() => _MemoryDaySheetState();
}

class _MemoryDaySheetState extends State<MemoryDaySheet> {
  static const List<int> _allowedReminderOffsets = [1, 3, 7];
  static const int _noReminderValue = 0;

  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;

  DateTime? _date;
  bool _repeatYearly = true;
  int _selectedReminderOffset = 1;
  bool _submitting = false;

  bool get _isEdit => widget.memory != null;

  bool get _hasChanged {
    final initTitle = (widget.memory?.title ?? '').trim();
    final initNote = (widget.memory?.note ?? '').trim();
    final initDate = _normalize(widget.memory?.date ?? DateTime.now());
    final initRepeat = widget.memory?.repeatYearly ?? true;
    final initReminderOffsets = _reminderOffsetsFromSelection(
      widget.memory == null
          ? 1
          : _selectedReminderFromOffsets(widget.memory!.reminderOffsets),
    );

    final curTitle = _titleCtrl.text.trim();
    final curNote = _noteCtrl.text.trim();
    final curDate = _normalize(_date ?? DateTime.now());
    final curRepeat = _repeatYearly;
    final curReminderOffsets = _reminderOffsetsFromSelection(
      _selectedReminderOffset,
    );

    return curTitle != initTitle ||
        curNote != initNote ||
        curDate != initDate ||
        curRepeat != initRepeat ||
        !_sameReminderOffsets(initReminderOffsets, curReminderOffsets);
  }

  bool get _isValid {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_titleCtrl.text.trim().length > 50) return false;
    if (_date == null) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.memory?.title ?? '');
    _noteCtrl = TextEditingController(text: widget.memory?.note ?? '');

    _date = widget.memory?.date ?? DateTime.now();
    _repeatYearly = widget.memory?.repeatYearly ?? true;
    _selectedReminderOffset = widget.memory == null
        ? 1
        : _selectedReminderFromOffsets(widget.memory!.reminderOffsets);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

  List<int> _normalizedReminderOffsets(List<int> offsets) {
    final values =
        offsets
            .where((value) => _allowedReminderOffsets.contains(value))
            .toSet()
            .toList()
          ..sort();
    return values;
  }

  bool _sameReminderOffsets(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  int _selectedReminderFromOffsets(List<int> offsets) {
    final normalized = _normalizedReminderOffsets(offsets);
    if (normalized.isEmpty) return _noReminderValue;
    return normalized.first;
  }

  List<int> _reminderOffsetsFromSelection(int value) {
    if (value == _noReminderValue) return const [];
    return _normalizedReminderOffsets([value]);
  }

  Future<bool> _onBack() async {
    if (!_hasChanged) return true;
    if (!mounted) return true;

    final l10n = AppLocalizations.of(context);
    final ok = await Notify.confirm(
      context,
      title: l10n.memoryDayUnsavedTitle,
      message: l10n.memoryDayUnsavedExitMessage,
    );

    return ok;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? now,
      firstDate: DateTime(2000, 1, 1),
      lastDate: DateTime(2050, 12, 31),
    );
    if (picked != null) {
      setState(() => _date = _normalize(picked));
    }
  }

  String _reminderLabel(AppLocalizations l10n, int value) {
    switch (value) {
      case 1:
        return l10n.memoryDayReminderOneDay;
      case 3:
        return l10n.memoryDayReminderThreeDays;
      case 7:
        return l10n.memoryDayReminderSevenDays;
      default:
        return l10n.memoryDayReminderNone;
    }
  }

  Future<void> _pickReminder() async {
    final l10n = AppLocalizations.of(context);

    final selected = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.28),
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        final colorScheme = theme.colorScheme;
        final textTheme = theme.textTheme;

        Widget optionTile({
          required int value,
          required String label,
          required IconData icon,
          Color? iconColor,
        }) {
          final effectiveIconColor = iconColor ?? colorScheme.primary;
          final isSelected = value == _selectedReminderOffset;

          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(sheetContext).pop(value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? colorScheme.primary.withOpacity(0.12)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.outline.withOpacity(0.5),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: effectiveIconColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, size: 18, color: effectiveIconColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      label,
                      style: textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 160),
                    opacity: isSelected ? 1 : 0,
                    child: Icon(
                      Icons.check_circle_rounded,
                      color: colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SafeArea(
          top: false,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 24,
                  offset: const Offset(0, -8),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outline.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    l10n.memoryDayReminderLabel,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 16),
                  optionTile(
                    value: _noReminderValue,
                    label: l10n.memoryDayReminderNone,
                    icon: Icons.notifications_off_outlined,
                    iconColor: colorScheme.onSurface.withOpacity(0.65),
                  ),
                  const SizedBox(height: 10),
                  optionTile(
                    value: 1,
                    label: l10n.memoryDayReminderOneDay,
                    icon: Icons.notifications_none_rounded,
                  ),
                  const SizedBox(height: 10),
                  optionTile(
                    value: 3,
                    label: l10n.memoryDayReminderThreeDays,
                    icon: Icons.notifications_none_rounded,
                  ),
                  const SizedBox(height: 10),
                  optionTile(
                    value: 7,
                    label: l10n.memoryDayReminderSevenDays,
                    icon: Icons.notifications_none_rounded,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (!mounted || selected == null) return;
    setState(() => _selectedReminderOffset = selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final dateText = _date == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(_date!);

    return WillPopScope(
      onWillPop: _onBack,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _header(context),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _input(
                          context: context,
                          controller: _titleCtrl,
                          label: l10n.memoryDayFormTitleLabel,
                          maxLength: 50,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _readonlyField(
                          context: context,
                          label: l10n.memoryDayFormDateLabel,
                          value: dateText,
                          onTap: _pickDate,
                        ),
                        const SizedBox(height: 12),
                        _input(
                          context: context,
                          controller: _noteCtrl,
                          label: l10n.memoryDayFormNoteLabel,
                          minLines: 2,
                          maxLines: 2,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 12),
                        _repeatYearlyField(context),
                        const SizedBox(height: 12),
                        _reminderDropdown(context),
                      ],
                    ),
                  ),
                ),
                _submit(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () async {
                final ok = await _onBack();
                if (!mounted) return;
                if (ok) Navigator.pop(context);
              },
            ),
          ),
          Text(
            _isEdit
                ? l10n.memoryDayEditHeaderTitle
                : l10n.memoryDayAddHeaderTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _repeatYearlyField(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withOpacity(0.4)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              l10n.memoryDayRepeatYearlyLabel,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          Switch(
            value: _repeatYearly,
            onChanged: (value) => setState(() => _repeatYearly = value),
            activeColor: colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _reminderDropdown(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: _pickReminder,
      child: InputDecorator(
        decoration: _fieldDecoration(
          context: context,
          label: l10n.memoryDayReminderLabel,
          suffixIcon: Icon(
            Icons.expand_more_rounded,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              alignment: Alignment.center,
              child: Icon(
                Icons.notifications_none_rounded,
                size: 16,
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _reminderLabel(l10n, _selectedReminderOffset),
                style: textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: (_isValid && !_submitting)
              ? () async {
                  setState(() => _submitting = true);
                  final vm = context.read<MemoryDayViewModel>();

                  try {
                    await runWithLoading<void>(context, () async {
                      final normalizedDate = _normalize(_date!);
                      final reminderOffsets = _reminderOffsetsFromSelection(
                        _selectedReminderOffset,
                      );

                      if (_isEdit) {
                        final updated = widget.memory!.copyWith(
                          title: _titleCtrl.text.trim(),
                          note: _noteCtrl.text.trim(),
                          date: normalizedDate,
                          repeatYearly: _repeatYearly,
                          reminderOffsets: reminderOffsets,
                          updatedAt: DateTime.now(),
                        );
                        await vm.updateMemory(updated);
                      } else {
                        final created = MemoryDay(
                          id: '',
                          ownerParentUid: vm.ownerUid,
                          title: _titleCtrl.text.trim(),
                          note: _noteCtrl.text.trim(),
                          date: normalizedDate,
                          repeatYearly: _repeatYearly,
                          reminderOffsets: reminderOffsets,
                          month: normalizedDate.month,
                          day: normalizedDate.day,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await vm.addMemory(created);
                      }
                    });

                    if (!mounted) return;

                    await Notify.show(
                      context,
                      type: DialogType.success,
                      title: l10n.updateSuccessTitle,
                      message: _isEdit
                          ? l10n.memoryDayEditSuccessMessage
                          : l10n.memoryDayAddSuccessMessage,
                      onConfirm: () {
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop();
                        }
                      },
                    );
                  } catch (_) {
                    if (!mounted) return;

                    await Notify.show(
                      context,
                      type: DialogType.error,
                      title: l10n.updateErrorTitle,
                      message: l10n.memoryDaySaveFailedMessage,
                    );
                  } finally {
                    if (mounted) {
                      setState(() => _submitting = false);
                    }
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            disabledBackgroundColor: colorScheme.outline.withOpacity(0.25),
            disabledForegroundColor: colorScheme.onSurface.withOpacity(0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            elevation: 0,
          ),
          child: Text(
            _submitting
                ? l10n.memoryDaySavingButton
                : _isEdit
                ? l10n.memoryDaySaveChangesButton
                : l10n.memoryDayAddButton,
            style: textTheme.titleMedium?.copyWith(
              fontFamily: 'Poppins',
              color: (_isValid && !_submitting)
                  ? colorScheme.onPrimary
                  : colorScheme.onSurface.withOpacity(0.5),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    int minLines = 1,
    int maxLines = 1,
    int? maxLength,
    ValueChanged<String>? onChanged,
  }) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    return TextField(
      controller: controller,
      minLines: minLines,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
      decoration: _fieldDecoration(
        context: context,
        label: label,
        counterText: '',
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Widget _readonlyField({
    required BuildContext context,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: InputDecorator(
        decoration: _fieldDecoration(
          context: context,
          label: label,
          suffixIcon: Icon(
            Icons.calendar_month,
            color: colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        child: Text(
          value,
          style: textTheme.bodyMedium?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration({
    required BuildContext context,
    required String label,
    Widget? suffixIcon,
    String? counterText,
    bool alignLabelWithHint = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return InputDecoration(
      labelText: label,
      alignLabelWithHint: alignLabelWithHint,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: colorScheme.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),

      labelStyle: textTheme.bodyMedium?.copyWith(
        color: colorScheme.onSurface.withOpacity(0.7),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.2),
      ),

      suffixIcon: suffixIcon,
      counterText: counterText,
    );
  }
}
