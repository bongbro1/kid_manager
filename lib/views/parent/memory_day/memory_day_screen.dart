import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../viewmodels/memory_day_vm.dart';
import '../../../models/memory_day.dart';
import 'memory_day_sheet.dart';

class MemoryDayScreen extends StatefulWidget {
  const MemoryDayScreen({super.key});

  @override
  State<MemoryDayScreen> createState() => _MemoryDayScreenState();
}

class _MemoryDayScreenState extends State<MemoryDayScreen> {
  bool _didInit = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInit) return;
    _didInit = true;

    // đảm bảo đã có ownerUid trước khi vào screen
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<MemoryDayViewModel>();
      await vm
.loadAll(); // load tất cả memories để hiển thị list "tất cả kỷ niệm"
    });
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.6,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const MemoryDaySheet(), // add mode
        ),
      ),
    );
  }

  void _openEditSheet(BuildContext context, MemoryDay memory) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.6,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: MemoryDaySheet(memory: memory), // edit mode
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<MemoryDayViewModel>();

    // Lấy tất cả memories để hiển thị list "tất cả kỷ niệm"
    final all = vm.allMemories.toList();
    all.sort(
      (a, b) => vm
          .daysUntilNextOccurrence(a)
          .compareTo(vm.daysUntilNextOccurrence(b)),
    );

    // sort theo “còn X ngày” tăng dần
    all.sort(
      (a, b) => vm
          .daysUntilNextOccurrence(a)
          .compareTo(vm.daysUntilNextOccurrence(b)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ngày đáng nhớ',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openAddSheet(context),
          ),
        ],
      ),
      body: vm.isAllLoading
          ? const Center(child: CircularProgressIndicator())
          : vm.allError != null
          ? Center(child: Text(vm.allError!))
          : all.isEmpty
          ? const Center(child: Text('Chưa có ngày đáng nhớ'))
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: all.length,
              itemBuilder: (_, i) {
                final m = all[i];
                final daysLeft = vm.daysUntilNextOccurrence(m);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MemoryDayCard(
                    memory: m,
                    daysLeft: daysLeft,
                    onEdit: () => _openEditSheet(context, m),
                    onDelete: () async {
                      final ok = await _confirmDelete(context);
                      if (ok != true) return;
                      await vm.deleteMemory(m.id);
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xóa ngay đáng nhớ'),
        content: const Text('Bạn có chắc muốn xóa?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _MemoryDayCard extends StatelessWidget {
  final MemoryDay memory;
  final int daysLeft;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _MemoryDayCard({
    required this.memory,
    required this.daysLeft,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateText = DateFormat('dd/MM/yyyy').format(memory.date);

    final text = daysLeft < 0
        ? 'Đã qua ${daysLeft.abs()} ngày'
        : (daysLeft == 0 ? 'Hôm nay' : 'Còn $daysLeft ngày');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 18,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.star, size: 20, color: Color(0xFFF4B400)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  memory.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  memory.repeatYearly
                      ? 'Ngày: $dateText (lặp lại hằng năm)'
                      : 'Ngày: $dateText',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF6B6B6B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF8A6D00),
                  ),
                ),
                if ((memory.note ?? '').isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    memory.note!,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF3A3A3A),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            children: [
              IconButton(
                icon: const Icon(Icons.edit, size: 18),
                onPressed: onEdit,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                onPressed: onDelete,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
