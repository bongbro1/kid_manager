import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/birthday_event.dart';
import 'package:kid_manager/models/memory_day.dart';
import 'package:kid_manager/models/schedule.dart';
import 'package:kid_manager/utils/confirm_delete_dialog.dart';
import 'package:kid_manager/utils/notify_dialog.dart';
import 'package:kid_manager/utils/ui_helpers.dart';
import 'package:kid_manager/viewmodels/birthday_vm.dart';
import 'package:kid_manager/viewmodels/memory_day_vm.dart';
import 'package:kid_manager/viewmodels/schedule/schedule_vm.dart';
import 'package:provider/provider.dart';

import '../../../views/chat/family_group_chat_screen.dart';
import '../../../views/parent/memory_day/memory_day_sheet.dart';
import '../../../views/parent/schedule/edit_schedule_sheet.dart';
import '../../../views/parent/schedule/schedule_history_screen.dart';

sealed class ScheduleTimelineItem {
  final double bottomSpacing;

  const ScheduleTimelineItem({required this.bottomSpacing});
}

class ScheduleBirthdayTimelineItem extends ScheduleTimelineItem {
  final BirthdayEvent birthday;
  final DateTime selectedDate;

  const ScheduleBirthdayTimelineItem({
    required this.birthday,
    required this.selectedDate,
  }) : super(bottomSpacing: 24);
}

class ScheduleMemoryTimelineItem extends ScheduleTimelineItem {
  final MemoryDay memory;

  const ScheduleMemoryTimelineItem({required this.memory})
    : super(bottomSpacing: 16);
}

class ScheduleEventTimelineItem extends ScheduleTimelineItem {
  final Schedule schedule;

  const ScheduleEventTimelineItem({required this.schedule})
    : super(bottomSpacing: 16);
}

class ScheduleListStateData {
  final bool isLoading;
  final String? error;
  final String? emptyMessage;
  final List<ScheduleTimelineItem> items;

  const ScheduleListStateData({
    required this.isLoading,
    required this.error,
    required this.emptyMessage,
    required this.items,
  });

  factory ScheduleListStateData.fromData({
    required AppLocalizations l10n,
    required bool isScheduleLoading,
    required bool isMemoryLoading,
    required bool isBirthdayLoading,
    required String? scheduleError,
    required String? selectedChildId,
    required DateTime selectedDate,
    required List<BirthdayEvent> birthdays,
    required List<MemoryDay> memories,
    required List<Schedule> schedules,
  }) {
    final items = <ScheduleTimelineItem>[
      ...birthdays.map(
        (birthday) => ScheduleBirthdayTimelineItem(
          birthday: birthday,
          selectedDate: selectedDate,
        ),
      ),
      ...memories.map((memory) => ScheduleMemoryTimelineItem(memory: memory)),
      ...schedules.map(
        (schedule) => ScheduleEventTimelineItem(schedule: schedule),
      ),
    ];

    if (isScheduleLoading || isMemoryLoading || isBirthdayLoading) {
      return const ScheduleListStateData(
        isLoading: true,
        error: null,
        emptyMessage: null,
        items: <ScheduleTimelineItem>[],
      );
    }

    if (scheduleError != null) {
      return ScheduleListStateData(
        isLoading: false,
        error: scheduleError,
        emptyMessage: null,
        items: const <ScheduleTimelineItem>[],
      );
    }

    if (items.isEmpty && selectedChildId == null) {
      return ScheduleListStateData(
        isLoading: false,
        error: null,
        emptyMessage: l10n.schedulePleaseSelectChild,
        items: const <ScheduleTimelineItem>[],
      );
    }

    if (items.isEmpty) {
      return ScheduleListStateData(
        isLoading: false,
        error: null,
        emptyMessage: l10n.scheduleNoEventsInDay,
        items: const <ScheduleTimelineItem>[],
      );
    }

    return ScheduleListStateData(
      isLoading: false,
      error: null,
      emptyMessage: null,
      items: items,
    );
  }
}

List<Schedule> scheduleListSnapshot(ScheduleViewModel vm) =>
    List<Schedule>.unmodifiable(vm.schedules);

List<MemoryDay> memoryListSnapshot(MemoryDayViewModel vm) =>
    List<MemoryDay>.unmodifiable(vm.memoriesOfSelectedDay);

List<BirthdayEvent> birthdayListSnapshot(BirthdayViewModel vm) =>
    List<BirthdayEvent>.unmodifiable(vm.birthdaysOfSelectedDay);

class ScheduleTimelineActions {
  const ScheduleTimelineActions();

  Future<void> openBirthdayChat(
    BuildContext context, {
    required BirthdayEvent birthday,
    required String wishText,
  }) {
    return Navigator.of(context).push(
      AppPageTransitions.route(
        builder: (_) => FamilyGroupChatScreen(
          initialFamilyId: birthday.familyId,
          initialComposerText: wishText,
        ),
      ),
    );
  }

  Future<void> openScheduleEditSheet(
    BuildContext context, {
    required Schedule schedule,
  }) {
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

  Future<void> deleteSchedule(
    BuildContext context, {
    required Schedule schedule,
  }) async {
    final l10n = AppLocalizations.of(context);
    final vm = context.read<ScheduleViewModel>();

    final confirm = await confirmDelete(
      context,
      title: l10n.scheduleDeleteTitle,
      message: l10n.scheduleDeleteConfirmMessage,
    );

    if (confirm != true || !context.mounted) return;

    try {
      await runWithLoading<void>(context, () async {
        await vm.deleteSchedule(schedule.id);
      });

      if (!context.mounted) return;

      await showSuccessDialog(
        context,
        title: l10n.updateSuccessTitle,
        message: l10n.scheduleDeleteSuccessMessage,
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

  Future<void> openScheduleHistory(
    BuildContext context, {
    required Schedule schedule,
  }) {
    return Navigator.push(
      context,
      AppPageTransitions.route(
        builder: (_) => ScheduleHistoryScreen(schedule: schedule),
      ),
    );
  }

  Future<void> openMemoryEditSheet(
    BuildContext context, {
    required MemoryDay memory,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.6,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: MemoryDaySheet(memory: memory),
        ),
      ),
    );
  }

  Future<void> deleteMemory(
    BuildContext context, {
    required MemoryDay memory,
  }) async {
    final l10n = AppLocalizations.of(context);
    final vm = context.read<MemoryDayViewModel>();

    final confirm = await confirmDelete(
      context,
      title: l10n.memoryDayDeleteTitle,
      message: l10n.memoryDayDeleteConfirmMessage,
    );

    if (confirm != true || !context.mounted) return;

    try {
      await runWithLoading<void>(context, () async {
        await vm.deleteMemory(memory.id);
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
