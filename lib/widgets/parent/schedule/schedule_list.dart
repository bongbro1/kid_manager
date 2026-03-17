import 'package:flutter/material.dart';
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

class ScheduleList extends StatelessWidget {
  const ScheduleList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(child: Text(state.error!));
    }

    if (state.emptyMessage != null) {
      return Center(
        child: Text(state.emptyMessage!, style: AppTextStyles.body),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  String _headlineText(BuildContext context) {
    final code = Localizations.localeOf(context).languageCode.toLowerCase();
    if (code.startsWith('en')) {
      return "It's ${birthday.displayName}'s special day!";
    }
    return 'Sinh nhật của ${birthday.displayName}!';
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
    final headline = _headlineText(context);
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
    String two(int n) => n.toString().padLeft(2, '0');

    final duration =
        '${two(schedule.startAt.hour)}:${two(schedule.startAt.minute)}-'
        '${two(schedule.endAt.hour)}:${two(schedule.endAt.minute)}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
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
              Text(duration, style: AppTextStyles.scheduleItemTimeRange),
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
          Text(schedule.title, style: AppTextStyles.scheduleItemTitle),
          if ((schedule.description ?? '').isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(schedule.description!, style: AppTextStyles.scheduleItemTime),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7D6),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.star, size: 16, color: Color(0xFFF4B400)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  memory.title,
                  style: AppTextStyles.scheduleItemTitle,
                ),
              ),
              if (canEdit) ...[
                _ActionIcon(
                  asset: 'assets/images/edit.png',
                  width: 18,
                  height: 18,
                  onTap: onEdit,
                ),
                const SizedBox(width: 10),
                _ActionIcon(asset: 'assets/images/delete.png', onTap: onDelete),
              ],
            ],
          ),
          if ((memory.note ?? '').isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(memory.note!, style: AppTextStyles.scheduleItemTime),
          ],
          const SizedBox(height: 6),
          if (memory.repeatYearly)
            Text(
              l10n.memoryDayRepeatYearlyLabel,
              style: const TextStyle(fontSize: 12, color: Color(0xFF8A6D00)),
            ),
        ],
      ),
    );
  }
}

class _ActionIcon extends StatelessWidget {
  const _ActionIcon({
    required this.asset,
    required this.onTap,
    this.width = 22,
    this.height = 22,
  });

  final String asset;
  final double width;
  final double height;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Image.asset(asset, width: width, height: height),
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
