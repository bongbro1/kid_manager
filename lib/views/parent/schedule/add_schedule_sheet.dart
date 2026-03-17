import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import '../../../models/schedule.dart';
import '../../../viewmodels/schedule/schedule_vm.dart';
import '../../../widgets/parent/schedule/schedule_form_sheet.dart';

class AddScheduleScreen extends StatelessWidget {
  final String childId;
  final DateTime selectedDate;

  const AddScheduleScreen({
    super.key,
    required this.childId,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return ScheduleFormSheet(
      headerTitle: l10n.scheduleAddHeaderTitle,
      submitButtonText: l10n.scheduleAddSubmitButton,
      successMessage: l10n.scheduleAddSuccessMessage,
      fieldStyle: ScheduleFormFieldStyle.hint,
      allowDateEditing: true,
      requireChangesToSubmit: false,
      initialData: ScheduleFormData.create(date: selectedDate),
      onSubmit: (formData) async {
        final vm = context.read<ScheduleViewModel>();
        final now = DateTime.now();

        final schedule = Schedule(
          id: '',
          childId: childId,
          parentUid: vm.scheduleOwnerUid,
          title: formData.title,
          description: formData.description,
          date: formData.date,
          startAt: combineScheduleDateTime(formData.date, formData.startTime!),
          endAt: combineScheduleDateTime(formData.date, formData.endTime!),
          period: formData.period!,
          createdAt: now,
          updatedAt: now,
        );

        await vm.addSchedule(schedule);
      },
    );
  }
}
