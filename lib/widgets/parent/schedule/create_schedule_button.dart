import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

import '../../../../../core/app_colors.dart';
import '../../../../../core/app_text_styles.dart';

class CreateScheduleButton extends StatelessWidget {
  final VoidCallback onTap;

  const CreateScheduleButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: onTap,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.calendarSelection,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
          child: Text(
            l10n.scheduleCreateButtonAddEvent,
            style: AppTextStyles.scheduleCreateButton,
          ),
        ),
      ),
    );
  }
}
