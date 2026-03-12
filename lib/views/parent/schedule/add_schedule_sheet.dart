import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/utils/exceptions.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/parent/schedule/schedule_period_selector.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/utils/ui_helpers.dart';
import 'package:kid_manager/utils/cupertino_time_picker.dart';
import 'package:kid_manager/utils/confirm_exit_dialog.dart';

import '../../../models/schedule.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';

class AddScheduleScreen extends StatefulWidget {
  final String childId;
  final DateTime selectedDate;

  const AddScheduleScreen({
    super.key,
    required this.childId,
    required this.selectedDate,
  });

  @override
  State<AddScheduleScreen> createState() => _AddScheduleScreenState();
}

class _AddScheduleScreenState extends State<AddScheduleScreen> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  SchedulePeriod? _period;

  late DateTime _selectedDate;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;

  // để tránh submit nhiều lần khi user bấm liên tục
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;

    _startCtrl = TextEditingController();
    _endCtrl = TextEditingController();

    // // optional: set giờ mặc định cho đẹp UX
    // final now = TimeOfDay.now();
    // _startTime = now;
    // _endTime = TimeOfDay(hour: (now.hour + 1) % 24, minute: now.minute);

    _startCtrl.text = _startTime == null ? '' : formatTime24(_startTime!);
    _endCtrl.text = _endTime == null ? '' : formatTime24(_endTime!);

    _syncPeriodFromTime();
  }

  bool get _hasChanged =>
      _titleCtrl.text.isNotEmpty ||
      _descCtrl.text.isNotEmpty ||
      _startTime != null ||
      _endTime != null ||
      _period != null;

  bool get _isValid {
    if (_titleCtrl.text.trim().isEmpty) return false;
    if (_titleCtrl.text.length > 50) return false;
    if (_startTime == null || _endTime == null) return false;

    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    return end > start;
  }

  Future<bool> _onBack() async {
    if (!_hasChanged) return true;
    if (!mounted) return true;

    return await confirmExitUnsavedChanges(context);
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onBack,
      child: Container(
        height: 622,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _input(
                        controller: _titleCtrl,
                        hint: l10n.scheduleFormTitleHint,
                        maxLength: 50,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(),
                      const SizedBox(height: 16),
                      _input(
                        controller: _descCtrl,
                        hint: l10n.scheduleFormDescriptionHint,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _dateField(),
                      const SizedBox(height: 16),
                      _timeRow(),
                      const SizedBox(height: 24),
                      _periodRow(),
                    ],
                  ),
                ),
              ),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () async {
                final ok = await _onBack();
                if (!mounted) return;
                if (ok) Navigator.of(context).pop(); // pop bottomsheet/screen
              },
            ),
          ),
          Text(
            l10n.scheduleAddHeaderTitle,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _input({
    required TextEditingController controller,
    required String hint,
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
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF5F6F8),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        counterText: "",
      ),
    );
  }

  Widget _counter() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '${_titleCtrl.text.length}/50',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _dateField() {
    final l10n = AppLocalizations.of(context);
    return _readonlyField(
      hint: l10n.scheduleFormDateLabel,
      value: DateFormat('dd/MM/yyyy').format(_selectedDate),
      onTap: _pickDate, // ✅ NEW
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      _selectedDate = DateTime(picked.year, picked.month, picked.day);
    });
  }

  bool get _isTimeInvalid {
    if (_startTime == null || _endTime == null) return false;

    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;

    return end <= start;
  }

  Widget _timeRow() {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _timePicker(
            label: l10n.scheduleFormStartTimeLabel,
            controller: _startCtrl,
            time: _startTime,
            errorText: null,
            onPick: (t) => setState(() {
              _startTime = t;
              _startCtrl.text = formatTime24(t);
              _syncPeriodFromTime();
            }),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _timePicker(
            label: l10n.scheduleFormEndTimeLabel,
            controller: _endCtrl,
            time: _endTime,
            errorText: _isTimeInvalid ? l10n.scheduleFormEndTimeInvalid : null,
            onPick: (t) => setState(() {
              _endTime = t;
              _endCtrl.text = formatTime24(t);
            }),
          ),
        ),
      ],
    );
  }

  String formatTime24(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget _timePicker({
    required String label,
    required TextEditingController controller,
    required TimeOfDay? time,
    required ValueChanged<TimeOfDay> onPick,
    String? errorText,
  }) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      onTap: () async {
        final t = await AppWheelTimePicker.show(
          context,
          title: label,
          initial: time,
          primaryColor: const Color(0xFF3F7CFF),
          minuteInterval: 1,
        );
        if (t != null) onPick(t);
      },
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,

        helperText: ' ',
        helperStyle: const TextStyle(fontSize: 1, height: 0.1),

        suffixIcon: const Padding(
          padding: EdgeInsets.only(right: 4),
          child: Icon(Icons.access_time_rounded, size: 18, color: Colors.grey),
        ),

        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),

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

        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red),
        ),

        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
    );
  }

  Widget _readonlyField({
    required String hint,
    required String value,
    VoidCallback? onTap,
  }) {
    final isEmpty = value.isEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            isEmpty ? hint : value,
            style: TextStyle(
              fontSize: 14,
              color: isEmpty ? Colors.grey : Colors.black,
            ),
          ),
        ),
      ),
    );
  }

  Widget _periodRow() {
    return SchedulePeriodSelector(
      value: _period,
      onChanged: null,
      enabled: false,
    );
  }

  Widget _submitButton() {
    final vm = context.read<ScheduleViewModel>();
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

                  try {
                    final ok = await runWithLoading<bool>(context, () async {
                      final startAt = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _startTime!.hour,
                        _startTime!.minute,
                      );

                      final endAt = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                        _endTime!.hour,
                        _endTime!.minute,
                      );

                      final normalizedDate = DateTime(
                        _selectedDate.year,
                        _selectedDate.month,
                        _selectedDate.day,
                      );

                      final schedule = Schedule(
                        id: '',
                        childId: widget.childId,
                        parentUid: vm.scheduleOwnerUid,
                        title: _titleCtrl.text.trim(),
                        description: _descCtrl.text.trim(),
                        date: normalizedDate,
                        startAt: startAt,
                        endAt: endAt,
                        period: _period ?? _inferPeriod(_startTime!),
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      );

                      await vm.addSchedule(schedule);
                      return true;
                    });

                    if (ok != true || !mounted) return;

                    // ✅ show success dialog, bấm "Tiếp tục" => đóng dialog + đóng sheet
                    final rootCtx = Navigator.of(
                      context,
                      rootNavigator: true,
                    ).context; // dùng B nếu bạn không sửa show()
                    await NotificationDialog.show(
                      rootCtx,
                      type: DialogType.success,
                      title: l10n.updateSuccessTitle,
                      message: l10n.scheduleAddSuccessMessage,
                      onConfirm: () {
                        // dialog tự pop trong NotificationDialog rồi callback mới chạy
                        if (mounted) Navigator.pop(context); // pop sheet
                      },
                    );
                  } on ScheduleOverlapException catch (e) {
                    if (!mounted) return;

                    final rootCtx = Navigator.of(
                      context,
                      rootNavigator: true,
                    ).context;
                    await NotificationDialog.show(
                      rootCtx,
                      type: DialogType.error,
                      title: l10n.scheduleDialogWarningTitle,
                      message: e.message,
                      onConfirm: null,
                    );
                  } catch (_) {
                    if (!mounted) return;

                    final rootCtx = Navigator.of(
                      context,
                      rootNavigator: true,
                    ).context;
                    await NotificationDialog.show(
                      rootCtx,
                      type: DialogType.error,
                      title: l10n.updateErrorTitle,
                      message: l10n.authGenericError,
                      onConfirm: null,
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
                ? l10n.scheduleFormSavingButton
                : l10n.scheduleAddSubmitButton,
            style: TextStyle(
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

  SchedulePeriod _inferPeriod(TimeOfDay start) {
    final h = start.hour;
    if (h < 12) return SchedulePeriod.morning;
    if (h < 18) return SchedulePeriod.afternoon;
    return SchedulePeriod.evening;
  }

  void _syncPeriodFromTime() {
    if (_startTime == null) return;
    final inferred = _inferPeriod(_startTime!);
    if (_period != inferred) {
      _period = inferred;
    }
  }
}
