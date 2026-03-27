import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/birthday_event.dart';
import 'package:kid_manager/models/memory_day.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_vm.dart';
import 'package:provider/provider.dart';

import '../../../../../core/app_text_styles.dart';
import '../../../../../utils/date_utils.dart';
import 'schedule_timeline_support.dart';

enum _ScheduleMemoryAction { edit, delete }

class ScheduleList extends StatelessWidget {
  const ScheduleList({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isScheduleLoading = context.select<ScheduleViewModel, bool>(
      (vm) => vm.isLoading,
    );
    final isMemoryLoading = context.select<MemoryDayViewModel, bool>(
      (vm) => vm.isLoading,
    );
    final isBirthdayLoading = context.select<BirthdayViewModel, bool>(
      (vm) => vm.isLoading,
    );
    final scheduleError = context.select<ScheduleViewModel, String?>(
      (vm) => vm.error,
    );
    final selectedChildId = context.select<ScheduleViewModel, String?>(
      (vm) => vm.selectedChildId,
    );
    final selectedDate = context.select<ScheduleViewModel, DateTime>(
      (vm) => vm.selectedDate,
    );
    final schedules = context.select<ScheduleViewModel, List<Schedule>>(
      scheduleListSnapshot,
    );
    final memories = context.select<MemoryDayViewModel, List<MemoryDay>>(
      memoryListSnapshot,
    );
    final birthdays = context.select<BirthdayViewModel, List<BirthdayEvent>>(
      birthdayListSnapshot,
    );
    const actions = ScheduleTimelineActions();

    final state = ScheduleListStateData.fromData(
      l10n: l10n,
      isScheduleLoading: isScheduleLoading,
      isMemoryLoading: isMemoryLoading,
      isBirthdayLoading: isBirthdayLoading,
      scheduleError: scheduleError,
      selectedChildId: selectedChildId,
      selectedDate: selectedDate,
      birthdays: birthdays,
      memories: memories,
      schedules: schedules,
    );

    if (state.isLoading) {
      return Center(child: CircularProgressIndicator(color: scheme.primary));
    }

    if (state.error != null) {
      return Center(
        child: Text(
          state.error!,
          style: textTheme.bodyMedium?.copyWith(
            color: scheme.error,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (state.emptyMessage != null) {
      return Center(
        child: Text(
          state.emptyMessage!,
          style: AppTextStyles.body.copyWith(
            color: scheme.onSurface.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: state.items.length,
      itemBuilder: (_, index) {
        final item = state.items[index];

        return Padding(
          padding: EdgeInsets.only(bottom: item.bottomSpacing),
          child: switch (item) {
            ScheduleBirthdayTimelineItem(
              :final birthday,
              :final selectedDate,
            ) =>
              BirthdayItem(
                birthday: birthday,
                selectedDate: selectedDate,
                onOpenChat: (wishText) {
                  actions.openBirthdayChat(
                    context,
                    birthday: birthday,
                    wishText: wishText,
                  );
                },
              ),
            ScheduleMemoryTimelineItem(:final memory) => MemoryDayItem(
              memory: memory,
              canEdit: true,
              onEdit: () {
                actions.openMemoryEditSheet(context, memory: memory);
              },
              onDelete: () {
                actions.deleteMemory(context, memory: memory);
              },
            ),
            ScheduleEventTimelineItem(:final schedule) => ScheduleItem(
              schedule: schedule,
              onEdit: () {
                actions.openScheduleEditSheet(context, schedule: schedule);
              },
              onDelete: () {
                actions.deleteSchedule(context, schedule: schedule);
              },
              onOpenHistory: () {
                actions.openScheduleHistory(context, schedule: schedule);
              },
            ),
          },
        );
      },
    );
  }
}

class BirthdayItem extends StatelessWidget {
  const BirthdayItem({
    super.key,
    required this.birthday,
    required this.selectedDate,
    required this.onOpenChat,
  });

  final BirthdayEvent birthday;
  final DateTime selectedDate;
  final void Function(String wishText) onOpenChat;

  String _headlineText(AppLocalizations l10n) {
    return l10n.birthdaySpecialDayHeadline(birthday.displayName);
  }

  bool get _isBirthdayToday {
    final now = DateTime.now();
    return now.day == birthday.birthDate.day &&
        now.month == birthday.birthDate.month;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final age = birthday.ageOn(selectedDate);
    final avatar = birthday.avatarUrl.trim();
    final headline = _headlineText(l10n);
    final showGiftAction = _isBirthdayToday;
    final wishText = age > 0
        ? l10n.birthdayWishOtherWithAge(birthday.displayName, age)
        : l10n.birthdayWishOtherDefault(birthday.displayName);

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF2F8), Color(0xFFFFFBF0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFBFD8FF), width: 1.1),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFED5FA6).withValues(alpha: 0.12),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          const Positioned(
            top: 14,
            left: 132,
            child: _BirthdayConfettiCluster(),
          ),
          if (showGiftAction)
            const Positioned(
              left: -8,
              bottom: 18,
              child: _BirthdayGlowBubble(size: 44, color: Color(0x22F59E0B)),
            ),
          const Positioned(
            right: 42,
            bottom: -8,
            child: _BirthdayGlowBubble(size: 58, color: Color(0x1FE879F9)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BirthdayAvatarFrame(avatarUrl: avatar),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.82),
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: const Color(0xFFF8D3E5),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.celebration_rounded,
                                    size: 11,
                                    color: Color(0xFFDB2777),
                                  ),
                                  const SizedBox(width: 5),
                                  Expanded(
                                    child: Text(
                                      headline,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: AppTextStyles.scheduleItemTime
                                          .copyWith(
                                            color: const Color(0xFF7C3AED),
                                            fontWeight: FontWeight.w600,
                                            fontSize: 10.5,
                                            height: 1.1,
                                            letterSpacing: 0,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (showGiftAction) ...[
                            const SizedBox(width: 8),
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => onOpenChat(wishText),
                                borderRadius: BorderRadius.circular(16),
                                child: Ink(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.92),
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: const Color(0xFFE7EEFF),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF2563EB,
                                        ).withValues(alpha: 0.10),
                                        blurRadius: 10,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.card_giftcard_rounded,
                                    color: Color(0xFF2563EB),
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(
                            Icons.cake_rounded,
                            size: 16,
                            color: Color(0xFFEC4899),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              birthday.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.scheduleItemTitle.copyWith(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.1,
                                color: const Color(0xFF1F2A44),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${l10n.birthDateLabel}: ${formatDateDDMMYYYY(birthday.birthDate)}',
                        style: AppTextStyles.scheduleItemTime.copyWith(
                          fontSize: 12,
                          height: 1.2,
                          color: const Color(0xFF6B7280),
                          letterSpacing: 0.05,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFB7185),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 7),
                          Text(
                            l10n.yearsOld.replaceFirst('%d', age.toString()),
                            style: AppTextStyles.scheduleItemTime.copyWith(
                              fontSize: 14,
                              color: const Color(0xFFE11D48),
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.05,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BirthdayAvatarFrame extends StatelessWidget {
  const _BirthdayAvatarFrame({required this.avatarUrl});

  final String avatarUrl;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF9A8D4), Color(0xFFFDE68A), Color(0xFF93C5FD)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFEC4899).withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
        ),
        Container(
          width: 54,
          height: 54,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: CircleAvatar(
            radius: 23,
            foregroundImage: avatarUrl.isNotEmpty
                ? NetworkImage(avatarUrl)
                : null,
            onForegroundImageError: avatarUrl.isNotEmpty ? (_, _) {} : null,
            backgroundColor: const Color(0xFFFBCFE8),
            child: avatarUrl.isEmpty
                ? const Icon(
                    Icons.cake_rounded,
                    color: Color(0xFFBE185D),
                    size: 24,
                  )
                : null,
          ),
        ),
        const Positioned(right: -1, bottom: 2, child: _BirthdayMiniBadge()),
      ],
    );
  }
}

class _BirthdayMiniBadge extends StatelessWidget {
  const _BirthdayMiniBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFDE68A), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(
        Icons.auto_awesome_rounded,
        size: 14,
        color: Color(0xFFF59E0B),
      ),
    );
  }
}

class _BirthdayGlowBubble extends StatelessWidget {
  const _BirthdayGlowBubble({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _BirthdayConfettiCluster extends StatelessWidget {
  const _BirthdayConfettiCluster();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 42,
      child: Stack(
        children: const [
          Positioned(
            left: 0,
            top: 10,
            child: _BirthdayConfettiDot(size: 7, color: Color(0xFFF472B6)),
          ),
          Positioned(
            left: 12,
            top: 2,
            child: _BirthdayConfettiDot(size: 5, color: Color(0xFF60A5FA)),
          ),
          Positioned(
            left: 26,
            top: 16,
            child: _BirthdayConfettiDot(size: 6, color: Color(0xFFF59E0B)),
          ),
          Positioned(
            left: 40,
            top: 6,
            child: Icon(
              Icons.auto_awesome_rounded,
              color: Color(0x66EC4899),
              size: 15,
            ),
          ),
          Positioned(
            right: 6,
            top: 12,
            child: _BirthdayConfettiDot(size: 8, color: Color(0xFFA78BFA)),
          ),
        ],
      ),
    );
  }
}

class _BirthdayConfettiDot extends StatelessWidget {
  const _BirthdayConfettiDot({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(size / 2),
      ),
    );
  }
}

class ScheduleItem extends StatelessWidget {
  const ScheduleItem({
    super.key,
    required this.schedule,
    this.onEdit,
    this.onDelete,
    this.onOpenHistory,
  });

  final Schedule schedule;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onOpenHistory;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    String two(int n) => n.toString().padLeft(2, '0');

    final duration =
        '${two(schedule.startAt.hour)}:${two(schedule.startAt.minute)}-'
        '${two(schedule.endAt.hour)}:${two(schedule.endAt.minute)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.08),
            blurRadius: 30,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _periodColor(schedule.period),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                duration,
                style: AppTextStyles.scheduleItemTimeRange.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              const Spacer(),
              if (schedule.editCount > 0) ...[
                _ActionIcon(
                  asset: 'assets/images/icon_history.png',
                  onTap: onOpenHistory,
                ),
                const SizedBox(width: 10),
              ],
              _ActionIcon(
                asset: 'assets/images/edit.png',
                width: 18,
                height: 18,
                onTap: onEdit,
              ),
              const SizedBox(width: 10),
              _ActionIcon(asset: 'assets/images/delete.png', onTap: onDelete),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            schedule.title,
            style: AppTextStyles.scheduleItemTitle.copyWith(
              color: scheme.onSurface,
            ),
          ),
          if ((schedule.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              schedule.description!,
              style: AppTextStyles.scheduleItemTime.copyWith(
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class MemoryDayItem extends StatelessWidget {
  const MemoryDayItem({
    super.key,
    required this.memory,
    required this.canEdit,
    this.onEdit,
    this.onDelete,
  });

  final MemoryDay memory;
  final bool canEdit;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final memoryVm = context.read<MemoryDayViewModel>();
    final daysLeft = memoryVm.daysUntilNextOccurrence(memory);
    final dateText = DateFormat('dd/MM/yyyy').format(memory.date);
    final noteText = (memory.note ?? '').trim();
    final countdownText = daysLeft < 0
        ? l10n.memoryDayDaysPassed(daysLeft.abs())
        : daysLeft == 0
        ? l10n.memoryDayToday
        : l10n.memoryDayDaysLeft(daysLeft);
    final badgeStyle = _memoryBadgeStyleFor(context, daysLeft);

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: const Border(
          left: BorderSide(
            color: Color(0xFFE2B53B), 
            width: 3
            ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
                child: const Icon(
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
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
              if (canEdit)
                PopupMenuButton<_ScheduleMemoryAction>(
                  tooltip: '',
                  position: PopupMenuPosition.under,
                  elevation: 6,
                  color: colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  onSelected: (value) {
                    if (value == _ScheduleMemoryAction.edit) {
                      onEdit?.call();
                      return;
                    }
                    onDelete?.call();
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem<_ScheduleMemoryAction>(
                      value: _ScheduleMemoryAction.edit,
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
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem<_ScheduleMemoryAction>(
                      value: _ScheduleMemoryAction.delete,
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
                            style: theme.textTheme.bodyMedium?.copyWith(
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
                        color: colorScheme.outline.withOpacity(0.5)
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
              style: theme.textTheme.labelMedium?.copyWith(
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
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12.5,
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
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12.5,
                height: 1.35,
                color: colorScheme.onSurface.withOpacity(0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }

  _MemoryDayBadgeStyle _memoryBadgeStyleFor(BuildContext context, int daysLeft) {

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

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.asset,
    required this.onTap,
    this.width = 22,
    this.height = 22,
    this.color,
  });

  final String asset;
  final double width;
  final double height;
  final VoidCallback? onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    final iconColor = color ?? scheme.onSurface.withOpacity(0.8);

    return GestureDetector(
      onTap: onTap,
      child: ColorFiltered(
        colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        child: Image.asset(asset, width: width, height: height),
      ),
    );
  }
}

Color _periodColor(SchedulePeriod p) {
  switch (p) {
    case SchedulePeriod.morning:
      return const Color(0xFF8B5CF6);
    case SchedulePeriod.afternoon:
      return const Color(0xFF00B383);
    case SchedulePeriod.evening:
      return const Color(0xFF3B82F6);
  }
}
