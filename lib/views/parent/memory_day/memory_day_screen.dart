import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:kid_manager/utils/notification_helper.dart';
import 'package:kid_manager/utils/ui_helpers.dart';
import 'package:provider/provider.dart';

import '../../../models/memory_day.dart';
import '../../../viewmodels/memory_day_vm.dart';
import 'memory_day_sheet.dart';

enum _MemoryDayCardAction { edit, delete }

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

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final vm = context.read<MemoryDayViewModel>();
      await vm.loadAll();
    });
  }

  void _openAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withOpacity(0.3),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.63,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: const MemoryDaySheet(),
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
        heightFactor: 0.63,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: MemoryDaySheet(memory: memory),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<MemoryDayViewModel>();
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final all = vm.allMemories.toList()
      ..sort(
        (a, b) => vm
            .daysUntilNextOccurrence(a)
            .compareTo(vm.daysUntilNextOccurrence(b)),
      );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.memoryDayTitle,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onSurface,
            fontSize: Theme.of(context).appTypography.screenTitle.fontSize!,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: colorScheme.onSurface),
            onPressed: () => _openAddSheet(context),
          ),
        ],
      ),
      body: vm.isAllLoading
          ? Center(child: CircularProgressIndicator(color: colorScheme.primary))
          : vm.allError != null
          ? Center(
              child: Text(
                vm.allError!,
                style: textTheme.bodyMedium?.copyWith(color: colorScheme.error),
              ),
            )
          : all.isEmpty
          ? Center(
              child: Text(
                l10n.memoryDayEmpty,
                style: textTheme.bodyLarge?.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.75),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: all.length,
              itemBuilder: (_, i) {
                final memory = all[i];
                final daysLeft = vm.daysUntilNextOccurrence(memory);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _MemoryDayCard(
                    memory: memory,
                    daysLeft: daysLeft,
                    onEdit: () => _openEditSheet(context, memory),
                    onDelete: () async {
                      final ok = await Notify.confirm(
                        context,
                        title: l10n.memoryDayDeleteTitle,
                        message: l10n.memoryDayDeleteConfirmMessage,
                      );

                      if (ok != true) return;

                      try {
                        await runWithLoading<void>(context, () async {
                          await vm.deleteMemory(memory.id);
                        });

                        if (!context.mounted) return;

                        await Notify.show(
                          context,
                          type: DialogType.success,
                          title: l10n.updateSuccessTitle,
                          message: l10n.memoryDayDeleteSuccessMessage,
                        );
                      } catch (_) {
                        if (!context.mounted) return;

                        await Notify.show(
                          context,
                          type: DialogType.error,
                          title: l10n.updateErrorTitle,
                          message: l10n.memoryDayDeleteFailedMessage,
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}

class _MemoryDayCard extends StatelessWidget {
  const _MemoryDayCard({
    required this.memory,
    required this.daysLeft,
    required this.onEdit,
    required this.onDelete,
  });

  final MemoryDay memory;
  final int daysLeft;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final dateText = DateFormat('dd/MM/yyyy').format(memory.date);
    final noteText = (memory.note ?? '').trim();
    final countdownText = daysLeft < 0
        ? l10n.memoryDayDaysPassed(daysLeft.abs())
        : daysLeft == 0
        ? l10n.memoryDayToday
        : l10n.memoryDayDaysLeft(daysLeft);

    final badgeStyle = _badgeStyleFor(context, daysLeft);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border(left: BorderSide(color: Color(0xFFE2B53B), width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                  Icons.star_rounded,
                  size: 18,
                  color: Color(0xFFE2B53B),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    memory.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              PopupMenuButton<_MemoryDayCardAction>(
                tooltip: '',
                position: PopupMenuPosition.under,
                elevation: 6,
                color: colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                onSelected: (value) {
                  if (value == _MemoryDayCardAction.edit) {
                    onEdit();
                    return;
                  }
                  onDelete();
                },
                itemBuilder: (context) => [
                  PopupMenuItem<_MemoryDayCardAction>(
                    value: _MemoryDayCardAction.edit,
                    child: Row(
                      children: [
                        Icon(
                          Icons.edit_outlined,
                          size: 18,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.memoryDayEditAction,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem<_MemoryDayCardAction>(
                    value: _MemoryDayCardAction.delete,
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 18,
                          color: colorScheme.error,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          l10n.memoryDayDeleteAction,
                          style: textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  width: 36,
                  height: 36,
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: colorScheme.outline.withOpacity(0.5),
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.more_vert_rounded,
                    size: 18,
                    color: colorScheme.onSurface.withOpacity(0.65),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: badgeStyle.backgroundColor,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              countdownText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: 0.1,
                color: badgeStyle.textColor,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            memory.repeatYearly
                ? l10n.memoryDayDateRepeatText(dateText)
                : l10n.memoryDayDateText(dateText),
            style: textTheme.bodySmall?.copyWith(
              fontSize: Theme.of(context).appTypography.supporting.fontSize!,
              height: 1.3,
              color: colorScheme.onSurface.withOpacity(0.65),
            ),
          ),
          if (noteText.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              noteText,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: textTheme.bodySmall?.copyWith(
                fontSize: Theme.of(context).appTypography.supporting.fontSize!,
                height: 1.35,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _MemoryDayBadgeStyle _badgeStyleFor(BuildContext context, int daysLeft) {
    final colorScheme = Theme.of(context).colorScheme;

    if (daysLeft < 0) {
      return _MemoryDayBadgeStyle(
        backgroundColor: colorScheme.surfaceContainerHighest,
        textColor: colorScheme.onSurface.withOpacity(0.65),
      );
    }

    if (daysLeft == 0) {
      return const _MemoryDayBadgeStyle(
        backgroundColor: Color(0xFFFFF3D6),
        textColor: Color(0xFF9A6700),
      );
    }

    return const _MemoryDayBadgeStyle(
      backgroundColor: Color(0xFFFFF7E3),
      textColor: Color(0xFF9A6700),
    );
  }
}

class _MemoryDayBadgeStyle {
  const _MemoryDayBadgeStyle({
    required this.backgroundColor,
    required this.textColor,
  });

  final Color backgroundColor;
  final Color textColor;
}
