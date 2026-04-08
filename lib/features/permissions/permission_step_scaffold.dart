import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';

class PermissionStepScaffold extends StatelessWidget {
  const PermissionStepScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.title,
    required this.description,
    required this.primaryLabel,
    required this.settingsLabel,
    required this.icon,
    required this.color,
    required this.busy,
    required this.onPrimary,
    required this.onOpenSettings,
    required this.onSkip,
    this.optional = true,
    this.statusMessage,
    this.media,
    this.showSettingsButton = true,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final String title;
  final String description;
  final String primaryLabel;
  final String settingsLabel;
  final IconData icon;
  final Color color;
  final bool busy;
  final bool optional;
  final bool showSettingsButton;
  final String? statusMessage;
  final VoidCallback onPrimary;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;
  final Widget? media;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _TopProgress(currentStep: currentStep, totalSteps: totalSteps),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 12),
                child: Column(
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      description,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Expanded(
                      child: Center(
                        child: _MediaFrame(
                          color: color,
                          icon: icon,
                          child: media,
                        ),
                      ),
                    ),
                    if (statusMessage != null) ...[
                      const SizedBox(height: 16),
                      _StatusMessage(message: statusMessage!),
                    ],
                  ],
                ),
              ),
            ),
            _BottomActions(
              color: color,
              primaryLabel: primaryLabel,
              settingsLabel: settingsLabel,
              busy: busy,
              optional: optional,
              showSettingsButton: showSettingsButton,
              onPrimary: onPrimary,
              onOpenSettings: onOpenSettings,
              onSkip: onSkip,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopProgress extends StatelessWidget {
  const _TopProgress({required this.currentStep, required this.totalSteps});

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: List.generate(totalSteps, (index) {
          final active = index < currentStep;
          return Expanded(
            child: Container(
              height: 8,
              margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF1D8FFF)
                    : const Color(0xFFA7D3FF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MediaFrame extends StatelessWidget {
  const _MediaFrame({required this.color, required this.icon, this.child});

  final Color color;
  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 720, maxHeight: 360),
      decoration: BoxDecoration(
        border: Border.all(
          color: const Color(0xFF7EC3FF),
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(26),
        child: child ?? _DefaultMedia(icon: icon, color: color),
      ),
    );
  }
}

class _DefaultMedia extends StatelessWidget {
  const _DefaultMedia({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF9FCFF),
      child: Center(
        child: Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 56, color: color),
        ),
      ),
    );
  }
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF9A3412),
          height: 1.4,
        ),
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  const _BottomActions({
    required this.color,
    required this.primaryLabel,
    required this.settingsLabel,
    required this.busy,
    required this.optional,
    required this.showSettingsButton,
    required this.onPrimary,
    required this.onOpenSettings,
    required this.onSkip,
  });

  final Color color;
  final String primaryLabel;
  final String settingsLabel;
  final bool busy;
  final bool optional;
  final bool showSettingsButton;
  final VoidCallback onPrimary;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1683F2),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(58),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                textStyle: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              child: busy
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(primaryLabel),
            ),
          ),
          if (showSettingsButton) ...[
            const SizedBox(height: 10),
            TextButton(
              onPressed: busy ? null : onOpenSettings,
              child: Text(
                settingsLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF667085),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          TextButton(
            onPressed: busy ? null : onSkip,
            child: Text(
              optional ? l10n.permissionLaterButton : l10n.permissionSkipButton,
              style: const TextStyle(fontSize: 15, color: Color(0xFF667085)),
            ),
          ),
        ],
      ),
    );
  }
}
