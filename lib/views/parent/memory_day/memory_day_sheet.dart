import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/utils/ui_helpers.dart';
import 'package:kid_manager/utils/notification_helper.dart';
import '../../../models/memory_day.dart';
import '../../../viewmodels/memory_day_vm.dart';

class MemoryDaySheet extends StatefulWidget {
  final MemoryDay? memory; // null = add, not null = edit

  const MemoryDaySheet({super.key, this.memory});

  @override
  State<MemoryDaySheet> createState() => _MemoryDaySheetState();
}

class _MemoryDaySheetState extends State<MemoryDaySheet> {
  late TextEditingController _titleCtrl;
  late TextEditingController _noteCtrl;

  DateTime? _date;
  bool _repeatYearly = true;

  bool get _isEdit => widget.memory != null;

  bool _submitting = false;

  bool get _hasChanged {
    final initTitle = (widget.memory?.title ?? '').trim();
    final initNote = (widget.memory?.note ?? '').trim();
    final initDate = _normalize(widget.memory?.date ?? DateTime.now());
    final initRepeat = widget.memory?.repeatYearly ?? true;

    final curTitle = _titleCtrl.text.trim();
    final curNote = _noteCtrl.text.trim();
    final curDate = _normalize(_date ?? DateTime.now());
    final curRepeat = _repeatYearly;

    return curTitle != initTitle ||
        curNote != initNote ||
        curDate != initDate ||
        curRepeat != initRepeat;
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

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.memory?.title ?? '');
    _noteCtrl = TextEditingController(text: widget.memory?.note ?? '');

    _date = widget.memory?.date ?? DateTime.now();
    _repeatYearly = widget.memory?.repeatYearly ?? true;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_titleCtrl.text.trim().length > 50) return false;
    if (_date == null) return false;
    return true;
  }

  DateTime _normalize(DateTime d) => DateTime(d.year, d.month, d.day);

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final dateText = _date == null
        ? ''
        : DateFormat('dd/MM/yyyy').format(_date!);

    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onBack,
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _header(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _input(
                        controller: _titleCtrl,
                        label: l10n.memoryDayFormTitleLabel,
                        maxLength: 50,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      _readonlyField(
                        label: l10n.memoryDayFormDateLabel,
                        value: dateText,
                        onTap: _pickDate,
                      ),
                      const SizedBox(height: 16),
                      _input(
                        controller: _noteCtrl,
                        label: l10n.memoryDayFormNoteLabel,
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Text(
                            l10n.memoryDayRepeatYearlyLabel,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: _repeatYearly,
                            onChanged: (v) => setState(() => _repeatYearly = v),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              _submit(context),
            ],
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

  Widget _submit(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
                      final d = _normalize(_date!);

                      if (_isEdit) {
                        final updated = widget.memory!.copyWith(
                          title: _titleCtrl.text.trim(),
                          note: _noteCtrl.text.trim(),
                          date: d,
                          repeatYearly: _repeatYearly,
                          updatedAt: DateTime.now(),
                        );
                        await vm.updateMemory(updated);
                      } else {
                        final created = MemoryDay(
                          id: '',
                          ownerParentUid: vm.ownerUid,
                          title: _titleCtrl.text.trim(),
                          note: _noteCtrl.text.trim(),
                          date: d,
                          repeatYearly: _repeatYearly,
                          month: d.month,
                          day: d.day,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        );
                        await vm.addMemory(created);
                      }
                    });

                    if (!mounted) return;

                    // ✅ success: Tiếp tục => đóng dialog + đóng sheet
                    await Notify.show(
                      context,
                      type: DialogType.success,
                      title: l10n.updateSuccessTitle,
                      message: _isEdit
                          ? l10n.memoryDayEditSuccessMessage
                          : l10n.memoryDayAddSuccessMessage,
                      onConfirm: () {
                        // NotificationDialog đã pop dialog trước rồi mới gọi callback
                        if (mounted && Navigator.of(context).canPop()) {
                          Navigator.of(context).pop(); // đóng sheet
                        }
                      },
                    );
                  } catch (e) {
                    if (!mounted) return;

                    // ✅ lỗi: Tiếp tục => chỉ đóng dialog, ở lại sheet
                    await Notify.show(
                      context,
                      type: DialogType.error,
                      title: l10n.updateErrorTitle,
                      message: l10n.memoryDaySaveFailedMessage,
                    );
                  } finally {
                    if (mounted) setState(() => _submitting = false);
                  }
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F7CFF),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: Text(
            _submitting
                ? l10n.memoryDaySavingButton
                : (_isEdit
                      ? l10n.memoryDaySaveChangesButton
                      : l10n.memoryDayAddButton),
            style: const TextStyle(
              fontFamily: 'Poppins',
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    int? maxLength,
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3F7CFF), width: 1.2),
        ),
        counterText: "",
      ),
    );
  }

  Widget _readonlyField({
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      readOnly: true,
      controller: TextEditingController(text: value),
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF3F7CFF), width: 1.2),
        ),
        suffixIcon: const Icon(Icons.calendar_month),
      ),
    );
  }
}
