import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/widgets/parent/schedule/schedule_period_selector.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/utils/ui_helpers.dart';

import '../../../models/schedule.dart';
import '../../../viewmodels/schedule_vm.dart';
import 'package:kid_manager/widgets/common/app_popup.dart';
import 'package:kid_manager/utils/exceptions.dart';


class EditScheduleScreen extends StatefulWidget {
  final Schedule schedule;

  const EditScheduleScreen({super.key, required this.schedule});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late TextEditingController _titleCtrl;
  late TextEditingController _descCtrl;

  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  SchedulePeriod? _period;

// để tránh submit nhiều lần khi user bấm liên tục, hoặc bấm khi đang loading
  bool _submitting = false;

  @override
  void initState() {
    super.initState();

    _titleCtrl = TextEditingController(text: widget.schedule.title);
    _descCtrl = TextEditingController(text: widget.schedule.description);

    _startTime = TimeOfDay.fromDateTime(widget.schedule.startAt);
    _endTime = TimeOfDay.fromDateTime(widget.schedule.endAt);
    _period = widget.schedule.period;

    // ✅ nếu muốn period luôn theo start time:
    _syncPeriodFromTime();
  }

  bool get _hasChanged {
    final initialTitle = widget.schedule.title;
    final initialDesc = (widget.schedule.description ?? '').trim();
    final currentTitle = _titleCtrl.text.trim();
    final currentDesc = _descCtrl.text.trim();

    final initialStart = TimeOfDay.fromDateTime(widget.schedule.startAt);
    final initialEnd = TimeOfDay.fromDateTime(widget.schedule.endAt);

    return currentTitle != initialTitle ||
        currentDesc != initialDesc ||
        _startTime != initialStart ||
        _endTime != initialEnd ||
        _period != widget.schedule.period;
  }

  bool get _isValid {
  if (_titleCtrl.text.trim().isEmpty) return false;
  if (_titleCtrl.text.length > 50) return false;
  if (_startTime == null || _endTime == null) return false;

  final start = _startTime!.hour * 60 + _startTime!.minute;
  final end = _endTime!.hour * 60 + _endTime!.minute;
  return end > start;
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

  Future<bool> _onBack() async {
    if (!_hasChanged) return true;
    if (!mounted) return true;

    final shouldExit = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Chưa lưu'),
        content: const Text('Bạn chưa lưu, bạn có chắc muốn thoát?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false), // ✅ pop dialog đúng context
            child: const Text('Ở lại'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true), // ✅ pop dialog đúng context
            child: const Text('Thoát'),
          ),
        ],
      ),
    );

    return shouldExit ?? false;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                        label: 'Tên lịch trình',
                        maxLength: 50,
                        onChanged: (_) => setState(() {}),
                      ),
                      _counter(),
                      const SizedBox(height: 16),
                      _input(
                        controller: _descCtrl,
                        label: 'Mô tả',
                        maxLines: 3,
                        onChanged: (_) => setState(() {}),
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
                if (await _onBack()) {
                  if (mounted) Navigator.pop(context);
                }
              },
            ),
          ),
          const Text(
            'Chỉnh sửa lịch trình',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
  final vm = context.read<ScheduleViewModel>();

  return Padding(
    padding: const EdgeInsets.all(20),
    child: SizedBox(
      height: 52,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_isValid && _hasChanged && !_submitting)
          ? () async {
              setState(() => _submitting = true);

              try {
                final ok = await runWithLoading<bool>(context, () async {
                final startAt = DateTime(
                  widget.schedule.date.year,
                  widget.schedule.date.month,
                  widget.schedule.date.day,
                  _startTime!.hour,
                  _startTime!.minute,
                );

                final endAt = DateTime(
                  widget.schedule.date.year,
                  widget.schedule.date.month,
                  widget.schedule.date.day,
                  _endTime!.hour,
                  _endTime!.minute,
                );

                final updatedSchedule = widget.schedule.copyWith(
                  title: _titleCtrl.text.trim(),
                  description: _descCtrl.text.trim(),
                  startAt: startAt,
                  endAt: endAt,
                  period: _period ?? _inferPeriod(_startTime!),
                  updatedAt: DateTime.now(),
                );

                await vm.updateSchedule(updatedSchedule);
                return true;
              });

              if (ok != true || !mounted) return;

              final res = await AppPopup.show<bool>(
                context,
                type: AppPopupType.success,
                title: 'Hoàn thành',
                message: 'Bạn đã chỉnh sửa lịch trình thành công',
                primaryText: 'Tiếp tục',
                primaryResult: true,
              );

              if (res == true && mounted) Navigator.pop(context);
            } on ScheduleOverlapException catch (e) {
              if (!mounted) return;
              await AppPopup.show<void>(
                context,
                type: AppPopupType.warning,
                title: 'Cảnh báo',
                message: e.message,
                primaryText: 'Tiếp tục',
              );
            } catch (_) {
              if (!mounted) return;
              await AppPopup.show<void>(
                context,
                type: AppPopupType.error,
                title: 'Thất bại',
                message: 'Đã có lỗi xảy ra, vui lòng thử lại',
                primaryText: 'Tiếp tục',
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
        child: Text(_submitting ? 'Đang lưu...' : 'Lưu lịch trình',
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
      // auto = có text thì label nổi lên, đúng chuẩn edit

      filled: true,
      fillColor: const Color(0xFFF5F6F8),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF3F7CFF),
          width: 1.2,
        ),
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
    return _readonlyField(
    label: 'Ngày',
    value: DateFormat('dd/MM/yyyy').format(widget.schedule.date),
  );
  }

  bool get _isTimeInvalid {
  if (_startTime == null || _endTime == null) return false;

  final start = _startTime!.hour * 60 + _startTime!.minute;
  final end = _endTime!.hour * 60 + _endTime!.minute;

  return end <= start;
}

  Widget _timeRow() {
  return Row(
    children: [
      Expanded(
        child: _timePicker(
          label: 'Giờ bắt đầu',
          time: _startTime,
          onPick: (t) => setState(() {
            _startTime = t;
            _syncPeriodFromTime();
          }),
        ),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: _timePicker(
          label: 'Giờ kết thúc',
          time: _endTime,
          errorText: _isTimeInvalid
              ? 'Giờ kết thúc phải lớn hơn'
              : null,
          onPick: (t) => setState(() {
            _endTime = t;
            _syncPeriodFromTime();
          }),
        ),
      ),
    ],
  );
}

Widget _timePicker({
  required String label,
  required TimeOfDay? time,
  required ValueChanged<TimeOfDay> onPick,
  String? errorText,
}) {
  return TextFormField(
    readOnly: true,
    controller: TextEditingController(
      text: time == null ? '' : time.format(context),
    ),
    onTap: () async {
      final t = await showTimePicker(
        context: context,
        initialTime: time ?? TimeOfDay.now(),
      );
      if (t != null) onPick(t);
    },
    decoration: InputDecoration(
      labelText: label,
      errorText: errorText,
      floatingLabelBehavior: FloatingLabelBehavior.auto,
      filled: true,
      fillColor: const Color(0xFFF5F6F8),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Color(0xFF3F7CFF),
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.red,
          width: 1.5,
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
          borderSide: const BorderSide(
            color: Color(0xFF3F7CFF),
            width: 1.2,
          ),
        ),
      ),
    );
  }
}
