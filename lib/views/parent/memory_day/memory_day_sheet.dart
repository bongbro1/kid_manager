import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    final dateText = _date == null ? '' : DateFormat('dd/MM/yyyy').format(_date!);

    return Container(
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
                      label: 'Tiêu đề',
                      maxLength: 50,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    _readonlyField(
                      label: 'Ngày',
                      value: dateText,
                      onTap: _pickDate,
                    ),
                    const SizedBox(height: 16),
                    _input(
                      controller: _noteCtrl,
                      label: 'Ghi chú',
                      maxLines: 3,
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Lặp lại hàng năm',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
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
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Text(
            _isEdit ? 'Chỉnh sửa ngày đáng nhớ' : 'Thêm ngày đáng nhớ',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _submit(BuildContext context) {
    final vm = context.read<MemoryDayViewModel>();

    return Padding(
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        height: 52,
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _isValid
              ? () async {
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
                    await vm.loadMonth();
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
                    await vm.loadMonth(); // reload để hiện chấm vàng trên calendar ngay lập tức
                  }

                  if (!mounted) return;
                  Navigator.pop(context);
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3F7CFF),
            disabledBackgroundColor: Colors.grey.shade300,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          ),
          child: Text(
            _isEdit ? 'Lưu thay đổi' : 'Thêm ngày đáng nhớ',
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