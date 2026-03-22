import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/notifications/dialog_type.dart';
import 'package:provider/provider.dart';

import '../../../models/schedule.dart';
import '../../../models/schedule_history.dart';
import '../../../services/schedule/schedule_notification_service.dart';
import '../../../viewmodels/auth_vm.dart';
import '../../../viewmodels/schedule/schedule_history_vm.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';
import '../../../widgets/app/app_notification_dialog.dart';

class ScheduleHistoryScreen extends StatefulWidget {
  final Schedule schedule;

  const ScheduleHistoryScreen({super.key, required this.schedule});

  @override
  State<ScheduleHistoryScreen> createState() => _ScheduleHistoryScreenState();
}

class _ScheduleHistoryScreenState extends State<ScheduleHistoryScreen> {
  late final ScheduleHistoryViewModel _historyVm;
  bool _restoring = false;

  @override
  void initState() {
    super.initState();
    _historyVm = context.read<ScheduleHistoryViewModel>();
    _historyVm.setScheduleOwnerUid(widget.schedule.parentUid);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _historyVm.loadHistories(
        scheduleId: widget.schedule.id,
      );
    });
  }

  @override
  void dispose() {
    _historyVm.clear(notify: false);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final vm = context.watch<ScheduleHistoryViewModel>();

    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduleHistoryTitle)),
      body: Builder(
        builder: (_) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.error != null) {
            return Center(child: Text(vm.error!));
          }

          if (vm.histories.isEmpty) {
            return Center(child: Text(l10n.scheduleHistoryEmpty));
          }

          final grouped = _groupHistories(vm.histories);

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: grouped.entries.map((entry) {
              return _HistorySection(
                title: entry.key,
                items: entry.value,
                currentTitle: widget.schedule.title,
                restoring: _restoring,
                onRestore: _onRestore,
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Map<String, List<ScheduleHistory>> _groupHistories(
    List<ScheduleHistory> items,
  ) {
    final map = <String, List<ScheduleHistory>>{};

    for (final item in items) {
      final key = _groupTitle(item.historyCreatedAt);
      map.putIfAbsent(key, () => []).add(item);
    }

    return map;
  }

  String _groupTitle(DateTime dt) {
    final l10n = AppLocalizations.of(context);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final date = DateTime(dt.year, dt.month, dt.day);

    if (date == today) return l10n.scheduleHistoryToday;
    if (date == yesterday) return l10n.scheduleHistoryYesterday;
    return DateFormat('dd/MM/yyyy').format(dt);
  }

  Future<void> _onRestore(ScheduleHistory item) async {
    final l10n = AppLocalizations.of(context);
    if (_restoring) return;

    final historyVm = context.read<ScheduleHistoryViewModel>();
    final scheduleVm = context.read<ScheduleViewModel>();
    final authVm = context.read<AuthVM>();
    final notificationService = context.read<ScheduleNotificationService>();
    final pageNavigator = Navigator.of(context);
    final rootNavigator = Navigator.of(context, rootNavigator: true);
    final rootContext = rootNavigator.context;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.scheduleHistoryRestoreDialogTitle),
        content: Text(l10n.scheduleHistoryRestoreDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.cancelButton),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.scheduleHistoryRestoreButton),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!mounted) return;

    setState(() => _restoring = true);

    _showBlockingLoading();

    try {
      await historyVm.restoreHistory(
        scheduleId: widget.schedule.id,
        historyId: item.id,
      );

      final actorUid = authVm.user?.uid;
      if (actorUid != null && actorUid.isNotEmpty) {
        // Phase 4: Restore now participates in the same cross-role
        // notification contract as other schedule CRUD actions.
        await notificationService.notifyRestored(
          actorUid: actorUid,
          scheduleOwnerUid: widget.schedule.parentUid,
          schedule: item.toSchedule(
            currentScheduleId: widget.schedule.id,
            editCount: widget.schedule.editCount + 1,
            updatedAt: DateTime.now(),
          ),
        );
      }

      if (!mounted) return;
      await scheduleVm.loadMonth();

      if (!mounted) return;
      await historyVm.loadHistories(
        scheduleId: widget.schedule.id,
      );

      if (!mounted) return;
      rootNavigator.pop();

      if (!rootContext.mounted) return;
      await NotificationDialog.show(
        rootContext,
        type: DialogType.success,
        title: l10n.updateSuccessTitle,
        message: l10n.scheduleHistoryRestoreSuccessMessage,
        onConfirm: () {
          if (pageNavigator.mounted) pageNavigator.pop(true);
        },
      );
    } catch (e) {
      if (!mounted) return;
      rootNavigator.pop();

      if (!rootContext.mounted) return;
      await NotificationDialog.show(
        rootContext,
        type: DialogType.error,
        title: l10n.updateErrorTitle,
        message: l10n.scheduleHistoryRestoreFailed(e.toString()),
        onConfirm: null,
      );
    } finally {
      if (mounted) {
        setState(() => _restoring = false);
      }
    }
  }

  void _showBlockingLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      useRootNavigator: true,
      builder: (_) => const PopScope(
        canPop: false,
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _HistorySection extends StatelessWidget {
  final String title;
  final List<ScheduleHistory> items;
  final String currentTitle;
  final bool restoring;
  final Future<void> Function(ScheduleHistory item) onRestore;

  const _HistorySection({
    required this.title,
    required this.items,
    required this.currentTitle,
    required this.restoring,
    required this.onRestore,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10, top: 4),
          child: Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _HistoryCard(
              item: item,
              currentTitle: currentTitle,
              restoring: restoring,
              onRestore: restoring ? null : () => onRestore(item),
            ),
          ),
        ),
      ],
    );
  }
}

class _HistoryCard extends StatefulWidget {
  final ScheduleHistory item;
  final String currentTitle;
  final bool restoring;
  final VoidCallback? onRestore;

  const _HistoryCard({
    required this.item,
    required this.currentTitle,
    required this.restoring,
    required this.onRestore,
  });

  @override
  State<_HistoryCard> createState() => _HistoryCardState();
}

class _HistoryCardState extends State<_HistoryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final item = widget.item;
    final currentTitle = widget.currentTitle.trim();
    final historyTitle = item.title.trim();

    final savedTime = DateFormat('HH:mm').format(item.historyCreatedAt);
    final dateText = DateFormat('dd/MM/yyyy').format(item.date);

    String two(int n) => n.toString().padLeft(2, '0');
    final timeText =
        '${two(item.startAt.hour)}:${two(item.startAt.minute)} - ${two(item.endAt.hour)}:${two(item.endAt.minute)}';

    final showOldTitle =
        historyTitle.isNotEmpty && historyTitle != currentTitle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(
                      color: Color(0xFF3F7CFF),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.calendar_month,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currentTitle.isNotEmpty ? currentTitle : historyTitle,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF202124),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.scheduleHistoryEditedAt(savedTime),
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5F6368),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 180),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 26,
                      color: Color(0xFF5F6368),
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 180),
            crossFadeState: _expanded
                ? CrossFadeState.showSecond
                : CrossFadeState.showFirst,
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 14),

                  if (showOldTitle) ...[
                    _InfoRow(
                      label: l10n.scheduleHistoryLabelTitle,
                      value: historyTitle,
                    ),
                    const SizedBox(height: 10),
                  ],

                  if ((item.description ?? '').trim().isNotEmpty) ...[
                    _InfoRow(
                      label: l10n.scheduleHistoryLabelDescription,
                      value: item.description!.trim(),
                    ),
                    const SizedBox(height: 10),
                  ],

                  _InfoRow(
                    label: l10n.scheduleHistoryLabelDate,
                    value: dateText,
                  ),
                  const SizedBox(height: 10),
                  _InfoRow(
                    label: l10n.scheduleHistoryLabelTime,
                    value: timeText,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: SizedBox(
                      height: 40,
                      child: ElevatedButton.icon(
                        onPressed: widget.onRestore,
                        icon: const Icon(Icons.history, size: 18),
                        label: Text(
                          widget.restoring
                              ? l10n.scheduleHistoryRestoringButton
                              : l10n.scheduleHistoryRestoreButton,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: const Color(0xFF3F7CFF),
                          elevation: 0,
                          side: const BorderSide(color: Color(0xFFE0E0E0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 86,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF202124),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF3C4043),
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
