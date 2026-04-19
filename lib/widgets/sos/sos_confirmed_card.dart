import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/user/user_types.dart';

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

  String _roleLabel(AppLocalizations l10n, String? role) {
    final parsedRole = tryParseUserRole(role);
    switch (parsedRole) {
      case UserRole.parent:
        return l10n.sosConfirmedRoleParent;
      case UserRole.guardian:
        return l10n.sosConfirmedRoleParent;
      case UserRole.child:
        return l10n.sosConfirmedRoleChild;
      case null:
        return (role == null || role.trim().isEmpty) ? '--' : role;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final rows = <_InfoRow>[
      if (createdByName != null && createdByName!.trim().isNotEmpty)
        _InfoRow(
          label: l10n.sosConfirmedNameLabel,
          value: createdByName!.trim(),
        ),
      _InfoRow(
        label: l10n.sosConfirmedSenderLabel,
        value: _roleLabel(l10n, createdByRole),
      ),
      _InfoRow(label: l10n.sosConfirmedSentAtLabel, value: _fmt(createdAt)),
      _InfoRow(
        label: l10n.sosConfirmedConfirmedAtLabel,
        value: _fmt(resolvedAt),
      ),
      if (acc != null)
        _InfoRow(
          label: l10n.sosConfirmedAccuracyLabel,
          value: '${acc!.toStringAsFixed(0)} m',
        ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 40),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  l10n.sosConfirmedTitle,
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
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                children: rows
                    .map(
                      (row) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: _RowLine(label: row.label, value: row.value),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(context),
              child: Text(
                l10n.sosConfirmedCloseButton,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
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
        SizedBox(width: 105, child: Text(label, style: labelStyle)),
        const SizedBox(width: 8),
        Expanded(child: Text(value, style: valueStyle, softWrap: true)),
      ],
    );
  }
}
