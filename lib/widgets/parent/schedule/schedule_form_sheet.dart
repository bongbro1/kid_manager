import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/utils/confirm_exit_dialog.dart';
import 'package:kid_manager/utils/cupertino_time_picker.dart';
import 'package:kid_manager/utils/exceptions.dart';
import 'package:kid_manager/utils/ui_helpers.dart';
import 'package:kid_manager/widgets/app/app_notification_dialog.dart';
import 'package:kid_manager/widgets/parent/schedule/schedule_period_selector.dart';

import '../../../models/schedule.dart';

enum ScheduleFormFieldStyle { hint, floatingLabel }

class ScheduleFormData {
  final String title;
  final String description;
  final DateTime date;
  final TimeOfDay? startTime;
  final TimeOfDay? endTime;
  final SchedulePeriod? period;

  const ScheduleFormData({
    required this.title,
    required this.description,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.period,
  });

  factory ScheduleFormData.create({required DateTime date}) {
    return ScheduleFormData(
      title: '',
      description: '',
      date: normalizeScheduleDate(date),
      startTime: null,
      endTime: null,
      period: null,
    );
  }

  factory ScheduleFormData.fromSchedule(Schedule schedule) {
    return ScheduleFormData(
      title: schedule.title,
      description: schedule.description ?? '',
      date: normalizeScheduleDate(schedule.date),
      startTime: TimeOfDay.fromDateTime(schedule.startAt),
      endTime: TimeOfDay.fromDateTime(schedule.endAt),
      period: schedule.period,
    );
  }

  ScheduleFormData copyWith({
    String? title,
    String? description,
    DateTime? date,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    SchedulePeriod? period,
    bool clearStartTime = false,
    bool clearEndTime = false,
    bool clearPeriod = false,
  }) {
    return ScheduleFormData(
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      startTime: clearStartTime ? null : (startTime ?? this.startTime),
      endTime: clearEndTime ? null : (endTime ?? this.endTime),
      period: clearPeriod ? null : (period ?? this.period),
    );
  }

  bool get isTimeInvalid {
    if (startTime == null || endTime == null) return false;
    return scheduleTimeToMinutes(endTime!) <=
        scheduleTimeToMinutes(startTime!);
  }

  bool get isValid {
    return title.trim().isNotEmpty &&
        title.length <= 50 &&
        startTime != null &&
        endTime != null &&
        !isTimeInvalid;
  }

  ScheduleFormData normalizedForSubmit() {
    final normalizedStart = startTime;

    return copyWith(
      title: title.trim(),
      description: description.trim(),
      date: normalizeScheduleDate(date),
      period: normalizedStart == null ? period : inferSchedulePeriod(normalizedStart),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ScheduleFormData &&
        other.title == title &&
        other.description == description &&
        other.date == date &&
        other.startTime == startTime &&
        other.endTime == endTime &&
        other.period == period;
  }

  @override
  int get hashCode => Object.hash(
    title,
    description,
    date,
    startTime,
    endTime,
    period,
  );
}

int scheduleTimeToMinutes(TimeOfDay time) => time.hour * 60 + time.minute;

String formatScheduleTime24(TimeOfDay time) =>
    '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

DateTime normalizeScheduleDate(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime combineScheduleDateTime(DateTime date, TimeOfDay time) => DateTime(
  date.year,
  date.month,
  date.day,
  time.hour,
  time.minute,
);

SchedulePeriod inferSchedulePeriod(TimeOfDay start) {
  if (start.hour < 12) return SchedulePeriod.morning;
  if (start.hour < 18) return SchedulePeriod.afternoon;
  return SchedulePeriod.evening;
}

class ScheduleFormSheet extends StatefulWidget {
  final String headerTitle;
  final String submitButtonText;
  final String successMessage;
  final ScheduleFormFieldStyle fieldStyle;
  final bool allowDateEditing;
  final bool requireChangesToSubmit;
  final ScheduleFormData initialData;
  final Future<void> Function(ScheduleFormData data) onSubmit;

  const ScheduleFormSheet({
    super.key,
    required this.headerTitle,
    required this.submitButtonText,
    required this.successMessage,
    required this.fieldStyle,
    required this.allowDateEditing,
    required this.requireChangesToSubmit,
    required this.initialData,
    required this.onSubmit,
  });

  @override
  State<ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends State<ScheduleFormSheet> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _dateCtrl;
  late final TextEditingController _startCtrl;
  late final TextEditingController _endCtrl;

  late DateTime _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialData.title)
      ..addListener(_handleTextChanged);
    _descCtrl = TextEditingController(text: widget.initialData.description)
      ..addListener(_handleTextChanged);
    _dateCtrl = TextEditingController(
      text: DateFormat('dd/MM/yyyy').format(widget.initialData.date),
    );
    _startCtrl = TextEditingController(
      text: widget.initialData.startTime == null
          ? ''
          : formatScheduleTime24(widget.initialData.startTime!),
    );
    _endCtrl = TextEditingController(
      text: widget.initialData.endTime == null
          ? ''
          : formatScheduleTime24(widget.initialData.endTime!),
    );

    _selectedDate = widget.initialData.date;
    _startTime = widget.initialData.startTime;
    _endTime = widget.initialData.endTime;
  }

  @override
  void dispose() {
    _titleCtrl
      ..removeListener(_handleTextChanged)
      ..dispose();
    _descCtrl
      ..removeListener(_handleTextChanged)
      ..dispose();
    _dateCtrl.dispose();
    _startCtrl.dispose();
    _endCtrl.dispose();
    super.dispose();
  }

  void _handleTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  SchedulePeriod? get _period =>
      _startTime == null ? null : inferSchedulePeriod(_startTime!);

  ScheduleFormData get _currentData => ScheduleFormData(
    title: _titleCtrl.text,
    description: _descCtrl.text,
    date: _selectedDate,
    startTime: _startTime,
    endTime: _endTime,
    period: _period,
  );

  bool get _hasChanged => _currentData != widget.initialData;

  bool get _canSubmit =>
      _currentData.isValid &&
      !_submitting &&
      (!widget.requireChangesToSubmit || _hasChanged);

  Future<bool> _onBack() async {
    if (!_hasChanged) return true;
    if (!mounted) return true;

    return confirmExitUnsavedChanges(context);
  }

  Future<void> _pickDate() async {
    if (!widget.allowDateEditing || _submitting) return;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null || !mounted) return;

    setState(() {
      _selectedDate = normalizeScheduleDate(picked);
      _dateCtrl.text = DateFormat('dd/MM/yyyy').format(_selectedDate);
    });
  }

  Future<void> _pickTime({
    required String label,
    required TimeOfDay? initial,
    required ValueChanged<TimeOfDay> onPicked,
  }) async {
    if (_submitting) return;

    final picked = await AppWheelTimePicker.show(
      context,
      title: label,
      initial: initial,
      primaryColor: const Color(0xFF3F7CFF),
      minuteInterval: 1,
    );

    if (picked == null || !mounted) return;
    onPicked(picked);
  }

  Future<void> _showDialog({
    required DialogType type,
    required String title,
    required String message,
    VoidCallback? onConfirm,
  }) async {
    if (!mounted) return;

    final rootContext = Navigator.of(context, rootNavigator: true).context;
    await NotificationDialog.show(
      rootContext,
      type: type,
      title: title,
      message: message,
      onConfirm: onConfirm,
    );
  }

  Future<void> _submit() async {
    if (!_canSubmit) return;

    final l10n = AppLocalizations.of(context);
    setState(() => _submitting = true);

    try {
      await runWithLoading<void>(context, () async {
        await widget.onSubmit(_currentData.normalizedForSubmit());
      });

      await _showDialog(
        type: DialogType.success,
        title: l10n.updateSuccessTitle,
        message: widget.successMessage,
        onConfirm: () {
          if (mounted) {
            Navigator.of(context).pop();
          }
        },
      );
    } on ScheduleOverlapException catch (e) {
      await _showDialog(
        type: DialogType.error,
        title: l10n.scheduleDialogWarningTitle,
        message: e.message,
      );
    } catch (_) {
      await _showDialog(
        type: DialogType.error,
        title: l10n.updateErrorTitle,
        message: l10n.authGenericError,
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final currentData = _currentData;

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
                      _buildInput(
                        controller: _titleCtrl,
                        text: l10n.scheduleFormTitleHint,
                        maxLength: 50,
                      ),
                      _buildCounter(),
                      const SizedBox(height: 16),
                      _buildInput(
                        controller: _descCtrl,
                        text: l10n.scheduleFormDescriptionHint,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),
                      _buildDateField(l10n),
                      const SizedBox(height: 16),
                      _buildTimeRow(l10n, currentData),
                      const SizedBox(height: 24),
                      SchedulePeriodSelector(
                        value: _period,
                        onChanged: null,
                        enabled: false,
                      ),
                    ],
                  ),
                ),
              ),
              _buildSubmitButton(l10n),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                final canPop = await _onBack();
                if (!mounted || !canPop) return;
                Navigator.of(context).pop();
              },
            ),
          ),
          Text(
            widget.headerTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String text,
    int maxLines = 1,
    int? maxLength,
  }) {
    final baseDecoration = InputDecoration(
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
      counterText: '',
    );

    final decoration = widget.fieldStyle == ScheduleFormFieldStyle.hint
        ? baseDecoration.copyWith(hintText: text)
        : baseDecoration.copyWith(
            labelText: text,
            floatingLabelBehavior: FloatingLabelBehavior.auto,
          );

    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: decoration,
    );
  }

  Widget _buildCounter() {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        '${_titleCtrl.text.length}/50',
        style: const TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildDateField(AppLocalizations l10n) {
    final dateText = DateFormat('dd/MM/yyyy').format(_selectedDate);

    if (widget.fieldStyle == ScheduleFormFieldStyle.floatingLabel) {
      return TextFormField(
        readOnly: true,
        controller: _dateCtrl,
        onTap: widget.allowDateEditing ? _pickDate : null,
        decoration: InputDecoration(
          labelText: l10n.scheduleFormDateLabel,
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
        ),
      );
    }

    return InkWell(
      onTap: widget.allowDateEditing ? _pickDate : null,
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
            dateText,
            style: const TextStyle(fontSize: 14, color: Colors.black),
          ),
        ),
      ),
    );
  }

  Widget _buildTimeRow(
    AppLocalizations l10n,
    ScheduleFormData currentData,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _buildTimePicker(
            label: l10n.scheduleFormStartTimeLabel,
            controller: _startCtrl,
            errorText: null,
            onTap: () => _pickTime(
              label: l10n.scheduleFormStartTimeLabel,
              initial: _startTime,
              onPicked: (picked) {
                setState(() {
                  _startTime = picked;
                  _startCtrl.text = formatScheduleTime24(picked);
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildTimePicker(
            label: l10n.scheduleFormEndTimeLabel,
            controller: _endCtrl,
            errorText: currentData.isTimeInvalid
                ? l10n.scheduleFormEndTimeInvalid
                : null,
            onTap: () => _pickTime(
              label: l10n.scheduleFormEndTimeLabel,
              initial: _endTime,
              onPicked: (picked) {
                setState(() {
                  _endTime = picked;
                  _endCtrl.text = formatScheduleTime24(picked);
                });
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTimePicker({
    required String label,
    required TextEditingController controller,
    required VoidCallback onTap,
    String? errorText,
  }) {
    return TextFormField(
      readOnly: true,
      controller: controller,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        helperText: ' ',
        helperStyle: const TextStyle(fontSize: 1, height: 0.1),
        errorStyle: const TextStyle(fontSize: 12, height: 0.9),
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

  Widget _buildSubmitButton(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _canSubmit ? _submit : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F7CFF),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
          ),
          child: Text(
            _submitting ? l10n.scheduleFormSavingButton : widget.submitButtonText,
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
}
