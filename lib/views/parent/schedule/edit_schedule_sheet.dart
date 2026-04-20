import 'package:flutter/material.dart';
import 'package:kid_manager/core/network/network_action_guard.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../models/schedule.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';
import '../../../widgets/parent/schedule/schedule_form_sheet.dart';

class EditScheduleScreen extends StatelessWidget {
  final Schedule schedule;

  const EditScheduleScreen({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ScheduleFormSheet(
      headerTitle: l10n.scheduleEditHeaderTitle,
      submitButtonText: l10n.scheduleEditSubmitButton,
      successMessage: l10n.scheduleEditSuccessMessage,
      allowDateEditing: false,
      requireChangesToSubmit: true,
      initialData: ScheduleFormData.fromSchedule(schedule),
      onSubmit: (formData) async {
        final vm = context.read<ScheduleViewModel>();

        final updatedSchedule = schedule.copyWith(
          title: formData.title,
          description: formData.description,
          startAt: combineScheduleDateTime(schedule.date, formData.startTime!),
          endAt: combineScheduleDateTime(schedule.date, formData.endTime!),
          period: formData.period!,
          updatedAt: DateTime.now(),
        );

        final ok = await runGuardedNetworkVoidAction(
          context,
          action: () => vm.updateSchedule(updatedSchedule, l10n: l10n),
        );
        if (!ok) {
          return;
        }
      },
    );
  }
}
