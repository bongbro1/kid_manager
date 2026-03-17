import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/birthday_event.dart';
import 'package:kid_manager/utils/ui_helpers.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_vm.dart';
import 'package:provider/provider.dart';
import 'package:kid_manager/utils/confirm_delete_dialog.dart';
import 'package:kid_manager/utils/notify_dialog.dart';

import '../../../../../core/app_text_styles.dart';
import '../../../../../models/schedule.dart';
import '../../../../../utils/date_utils.dart';
import '../../../views/parent/schedule/edit_schedule_sheet.dart';
import '../../../../../viewmodels/memory_day_vm.dart';
import '../../../../../models/memory_day.dart';
import '../../../views/parent/memory_day/memory_day_sheet.dart';
import '../../../views/parent/schedule/schedule_history_screen.dart';
import '../../../views/chat/family_group_chat_screen.dart';

class ScheduleList extends StatelessWidget {
  const ScheduleList({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheduleVm = context.watch<ScheduleViewModel>();
    final memoryVm = context.watch<MemoryDayViewModel>();
    final birthdayVm = context.watch<BirthdayViewModel>();

    final birthdays = birthdayVm.birthdaysOfSelectedDay;
    final memories = memoryVm.memoriesOfSelectedDay;
    final schedules = scheduleVm.schedules;
    final total = birthdays.length + memories.length + schedules.length;

    if (scheduleVm.isLoading || memoryVm.isLoading || birthdayVm.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (scheduleVm.error != null) {
      return Center(child: Text(scheduleVm.error!));
    }

    if (total == 0 && scheduleVm.selectedChildId == null) {
      return Center(
        child: Text(l10n.schedulePleaseSelectChild, style: AppTextStyles.body),
      );
    }

    if (total == 0) {
      return Center(
        child: Text(l10n.scheduleNoEventsInDay, style: AppTextStyles.body),
      );
    }

    return Builder(
      builder: (screenContext) {
        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          itemCount: total,
          itemBuilder: (_, i) {
            if (i < birthdays.length) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: BirthdayItem(
                  birthday: birthdays[i],
                  selectedDate: scheduleVm.selectedDate,
                ),
              );
            }

            if (i < birthdays.length + memories.length) {
              final memoryIndex = i - birthdays.length;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: MemoryDayItem(
                  memory: memories[memoryIndex],
                  screenContext: screenContext,
                ),
              );
            }

            final sIndex = i - birthdays.length - memories.length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ScheduleItem(
                schedule: schedules[sIndex],
                screenContext: screenContext,
              ),
            );
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
  });

  final BirthdayEvent birthday;
  final DateTime selectedDate;

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

  Future<void> _openBirthdayChat(BuildContext context, String wishText) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FamilyGroupChatScreen(
          initialFamilyId: birthday.familyId,
          initialComposerText: wishText,
        ),
      ),
    );
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
                                onTap: () =>
                                    _openBirthdayChat(context, wishText),
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
  final Schedule schedule;
  final BuildContext screenContext;

  const ScheduleItem({
    super.key,
    required this.schedule,
    required this.screenContext,
  });

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
                  onTap: () => _openHistoryScreen(context),
                ),
                const SizedBox(width: 10),
              ],

              _ActionIcon(
                asset: 'assets/images/edit.png',
                width: 18,
                height: 18,
                onTap: () => _openEditSheet(context),
              ),
              const SizedBox(width: 10),
              _ActionIcon(
                asset: 'assets/images/delete.png',
                onTap: () => _deleteSchedule(screenContext),
              ),
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

  Future<void> _openEditSheet(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.75,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: EditScheduleScreen(schedule: schedule),
        ),
      ),
    );
  }

  Future<void> _deleteSchedule(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final vm = context.read<ScheduleViewModel>();

    final confirm = await confirmDelete(
      context,
      title: l10n.scheduleDeleteTitle,
      message: l10n.scheduleDeleteConfirmMessage,
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      await runWithLoading<void>(context, () async {
        await vm.deleteSchedule(schedule.id);
      });

      if (!context.mounted) return;

      await showSuccessDialog(
        context,
        title: l10n.updateSuccessTitle,
        message: l10n.scheduleDeleteSuccessMessage,
        // Nếu bạn muốn xoá xong tự đóng sheet/detail luôn:
        // onConfirm: () { if (context.mounted) Navigator.pop(context); },
      );
    } catch (e) {
      if (!context.mounted) return;

      await showErrorDialog(
        context,
        title: l10n.updateErrorTitle,
        message: l10n.scheduleDeleteFailed(e.toString()),
      );
    }
  }

  Future<void> _openHistoryScreen(BuildContext context) {
    return Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScheduleHistoryScreen(schedule: schedule),
      ),
    );
  }
}

class MemoryDayItem extends StatelessWidget {
  final MemoryDay memory;
  final BuildContext screenContext;

  const MemoryDayItem({
    super.key,
    required this.memory,
    required this.screenContext,
  });

  bool _canEdit(BuildContext context) {
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final canEdit = _canEdit(context);

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

              // ✅ chỉ parent mới hiện icon edit/delete
              if (canEdit) ...[
                _ActionIcon(
                  asset: 'assets/images/edit.png',
                  width: 18,
                  height: 18,
                  onTap: () {
                    showModalBottomSheet(
                      context: screenContext,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      barrierColor: Colors.black.withValues(alpha: 0.3),
                      builder: (_) => FractionallySizedBox(
                        heightFactor: 0.6,
                        child: Padding(
                          padding: EdgeInsets.only(
                            bottom: MediaQuery.of(
                              screenContext,
                            ).viewInsets.bottom,
                          ),
                          child: MemoryDaySheet(memory: memory),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 10),
                _ActionIcon(
                  asset: 'assets/images/delete.png',
                  onTap: () => _deleteMemory(screenContext),
                ),
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
              style: TextStyle(fontSize: 12, color: Color(0xFF8A6D00)),
            ),
        ],
      ),
    );
  }

  Future<void> _deleteMemory(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final vm = context.read<MemoryDayViewModel>();

    final confirm = await confirmDelete(
      context,
      title: l10n.memoryDayDeleteTitle,
      message: l10n.memoryDayDeleteConfirmMessage,
    );

    if (confirm != true) return;
    if (!context.mounted) return;

    try {
      await runWithLoading<void>(context, () async {
        await vm.deleteMemory(memory.id);
        await vm.loadMonth();
      });

      if (!context.mounted) return;

      await showSuccessDialog(
        context,
        title: l10n.updateSuccessTitle,
        message: l10n.memoryDayDeleteSuccessMessage,
      );
    } catch (e) {
      if (!context.mounted) return;

      await showErrorDialog(
        context,
        title: l10n.updateErrorTitle,
        message: l10n.memoryDayDeleteFailedWithError(e.toString()),
      );
    }
  }
}

class _ActionIcon extends StatelessWidget {
  final String asset;
  final double width;
  final double height;
  final VoidCallback onTap;

  const _ActionIcon({
    required this.asset,
    required this.onTap,
    this.width = 22,
    this.height = 22,
  });

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
      return const Color(0xFF8B5CF6); // tím
    case SchedulePeriod.afternoon:
      return const Color(0xFF00B383); // xanh lá
    case SchedulePeriod.evening:
      return const Color(0xFF3B82F6); // xanh dương
  }
}
