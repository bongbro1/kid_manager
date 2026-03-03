import 'package:flutter/material.dart';

class SosConfirmedCard extends StatelessWidget {
  final DateTime? createdAt;
  final DateTime? resolvedAt;
  final String? createdByRole;
  final String? createdByName;
  final num? acc;

  const SosConfirmedCard({
    super.key,
    this.createdAt,
    this.resolvedAt,
    this.createdByRole,
    this.createdByName,
    this.acc,
  });

  String _fmt(DateTime? d) {
    if (d == null) return '--';
    final dd = d.day.toString().padLeft(2, '0');
    final mm = d.month.toString().padLeft(2, '0');
    final yy = d.year.toString();
    final hh = d.hour.toString().padLeft(2, '0');
    final mi = d.minute.toString().padLeft(2, '0');
    return '$dd/$mm/$yy $hh:$mi';
  }

  String _roleLabel(String? r) {
    switch (r) {
      case 'parent':
        return 'Phụ huynh';
      case 'child':
        return 'Trẻ';
      default:
        return (r == null || r.trim().isEmpty) ? '--' : r;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rows = <_InfoRow>[
      if (createdByName != null && createdByName!.trim().isNotEmpty)
        _InfoRow(label: 'Tên', value: createdByName!.trim()),
      _InfoRow(label: 'Người gửi', value: _roleLabel(createdByRole)),
      _InfoRow(label: 'Gửi lúc', value: _fmt(createdAt)),
      _InfoRow(label: 'Xác nhận lúc', value: _fmt(resolvedAt)),
      if (acc != null) _InfoRow(label: 'Độ chính xác', value: '${acc!.toStringAsFixed(0)} m'),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Đã xác nhận SOS',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
                splashRadius: 20,
              ),
            ],
          ),

          const SizedBox(height: 10),
          Divider(color: Colors.grey.shade300, height: 1),
          const SizedBox(height: 12),

          // Body (scroll an toàn nếu nội dung dài)
          // Body (tự co giãn, không overflow)
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: rows
                    .map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: _RowLine(label: r.label, value: r.value),
                ))
                    .toList(),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // Footer button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('ĐÓNG', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow({required this.label, required this.value});
}

class _RowLine extends StatelessWidget {
  final String label;
  final String value;

  const _RowLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: Colors.grey.shade700, fontSize: 13);
    const valueStyle = TextStyle(fontWeight: FontWeight.w700, fontSize: 13);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 105,
          child: Text(label, style: labelStyle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: valueStyle,
            softWrap: true,
          ),
        ),
      ],
    );
  }
}