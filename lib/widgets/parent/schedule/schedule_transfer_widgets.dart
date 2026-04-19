import 'package:dropdown_button2/dropdown_button2.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';

class ScheduleTransferSectionCard extends StatelessWidget {
  const ScheduleTransferSectionCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withOpacity(0.6)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ScheduleTransferLockedChildBox extends StatelessWidget {
  const ScheduleTransferLockedChildBox({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typography = Theme.of(context).appTypography;

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: scheme.primary.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outline),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_outline, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: typography.body.copyWith(color: scheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class ScheduleTransferChildDropdown extends StatelessWidget {
  const ScheduleTransferChildDropdown({
    super.key,
    required this.children,
    required this.selectedId,
    required this.onChanged,
  });

  final List<AppUser> children;
  final String? selectedId;
  final ValueChanged<String?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final typography = Theme.of(context).appTypography;

    if (children.isEmpty) {
      return Text(
        l10n.scheduleNoChild,
        style: typography.body.copyWith(color: scheme.onSurface),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 12.0;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: horizontalPadding),
          decoration: BoxDecoration(
            color: scheme.primary.withOpacity(0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton2<String>(
              isExpanded: true,
              value: selectedId ?? children.last.uid,
              dropdownStyleData: DropdownStyleData(
                width: constraints.maxWidth,
                offset: const Offset(-horizontalPadding, -5),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              iconStyleData: IconStyleData(iconEnabledColor: scheme.onSurface),
              style: typography.body.copyWith(color: scheme.onSurface),
              items: children
                  .map(
                    (c) => DropdownMenuItem<String>(
                      value: c.uid,
                      child: Text(
                        c.displayName ?? c.email ?? c.uid,
                        style: typography.body.copyWith(
                          color: scheme.onSurface,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        );
      },
    );
  }
}

class ScheduleTransferPrimaryButton extends StatelessWidget {
  const ScheduleTransferPrimaryButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typography = Theme.of(context).appTypography;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onTap == null && isLoading)
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        scheme.onPrimary,
                      ),
                    ),
                  )
                else
                  Icon(icon, color: scheme.onPrimary, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: scheme.onPrimary,
                      fontSize: typography.body.fontSize,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleTransferOutlineButton extends StatelessWidget {
  const ScheduleTransferOutlineButton({
    super.key,
    required this.text,
    required this.icon,
    required this.onTap,
  });

  final String text;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typography = Theme.of(context).appTypography;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.primary),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: scheme.primary, size: 18),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    text,
                    style: typography.body.copyWith(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ScheduleTransferDateBox extends StatelessWidget {
  const ScheduleTransferDateBox({
    super.key,
    required this.text,
    required this.onTap,
  });

  final String text;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final typography = Theme.of(context).appTypography;

    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.5 : 1,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: scheme.background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: scheme.outline),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: scheme.onSurface.withOpacity(0.65),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: typography.body.copyWith(color: scheme.onSurface),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showScheduleTransferSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmText,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      final dialogScheme = Theme.of(dialogCtx).colorScheme;
      final typography = Theme.of(dialogCtx).appTypography;

      return Dialog(
        backgroundColor: dialogScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 26, 22, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  color: dialogScheme.primary.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    Icons.check,
                    size: 42,
                    color: dialogScheme.primary,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  fontSize: typography.screenTitle.fontSize,
                  fontWeight: FontWeight.w700,
                  color: dialogScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: typography.body.fontSize,
                  color: dialogScheme.onSurface.withOpacity(0.7),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: dialogScheme.background,
                    foregroundColor: dialogScheme.onBackground,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () => Navigator.of(dialogCtx).pop(),
                  child: Text(
                    confirmText,
                    style: TextStyle(
                      fontSize: typography.itemTitle.fontSize,
                      fontWeight: FontWeight.w600,
                      color: dialogScheme.onBackground,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
