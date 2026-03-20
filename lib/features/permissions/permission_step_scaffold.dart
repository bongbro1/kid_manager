import 'package:flutter/material.dart';

class PermissionStepScaffold extends StatelessWidget {
  const PermissionStepScaffold({
    super.key,
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
    required this.title,
    required this.description,
    required this.helper,
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
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;
  final String title;
  final String description;
  final String helper;
  final String primaryLabel;
  final String settingsLabel;
  final IconData icon;
  final Color color;
  final bool busy;
  final bool optional;
  final String? statusMessage;
  final VoidCallback onPrimary;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;
  final Widget? media;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      body: SafeArea(
        child: Column(
          children: [
            _PermissionHeader(
              currentStep: currentStep,
              totalSteps: totalSteps,
              stepLabels: stepLabels,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _PermissionMediaSlot(
                      color: color,
                      icon: icon,
                      child: media,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF101828),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 16,
                        height: 1.6,
                        color: Color(0xFF344054),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _PermissionHelperCard(
                      color: color,
                      text: helper,
                    ),
                    if (statusMessage != null) ...[
                      const SizedBox(height: 16),
                      _PermissionStatusBanner(message: statusMessage!),
                    ],
                  ],
                ),
              ),
            ),
            _PermissionFooter(
              color: color,
              primaryLabel: primaryLabel,
              settingsLabel: settingsLabel,
              busy: busy,
              optional: optional,
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

class _PermissionHeader extends StatelessWidget {
  const _PermissionHeader({
    required this.currentStep,
    required this.totalSteps,
    required this.stepLabels,
  });

  final int currentStep;
  final int totalSteps;
  final List<String> stepLabels;

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thiết lập quyền truy cập',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: Color(0xFF101828),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Bước $currentStep/$totalSteps',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475467),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation(Color(0xFF2D7FF9)),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < stepLabels.length; i++)
                _StepChip(
                  label: stepLabels[i],
                  selected: i == currentStep - 1,
                  completed: i < currentStep - 1,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepChip extends StatelessWidget {
  const _StepChip({
    required this.label,
    required this.selected,
    required this.completed,
  });

  final String label;
  final bool selected;
  final bool completed;

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? const Color(0xFFDBEAFE)
        : completed
            ? const Color(0xFFE8FFF3)
            : const Color(0xFFF2F4F7);
    final foreground = selected
        ? const Color(0xFF175CD3)
        : completed
            ? const Color(0xFF067647)
            : const Color(0xFF475467);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}

class _PermissionMediaSlot extends StatelessWidget {
  const _PermissionMediaSlot({
    required this.color,
    required this.icon,
    this.child,
  });

  final Color color;
  final IconData icon;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            color.withOpacity(0.18),
            const Color(0xFFFFFFFF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: child ?? _DefaultPermissionMedia(icon: icon, color: color),
        ),
      ),
    );
  }
}

class _DefaultPermissionMedia extends StatelessWidget {
  const _DefaultPermissionMedia({
    required this.icon,
    required this.color,
  });

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'assets/images/Illustration.png',
          fit: BoxFit.cover,
          opacity: const AlwaysStoppedAnimation(0.18),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.88),
                Colors.white.withOpacity(0.60),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.28),
                  blurRadius: 28,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: 42,
            ),
          ),
        ),
        const Positioned(
          left: 20,
          top: 18,
          child: _MediaHintChip(label: 'Có thể thay bằng video'),
        ),
      ],
    );
  }
}

class _MediaHintChip extends StatelessWidget {
  const _MediaHintChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.92),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Color(0xFF344054),
        ),
      ),
    );
  }
}

class _PermissionHelperCard extends StatelessWidget {
  const _PermissionHelperCard({
    required this.color,
    required this.text,
  });

  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline_rounded, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: Color(0xFF475467),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionStatusBanner extends StatelessWidget {
  const _PermissionStatusBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFDBA74)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB54708)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 13,
                height: 1.5,
                color: Color(0xFF7A2E0B),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionFooter extends StatelessWidget {
  const _PermissionFooter({
    required this.color,
    required this.primaryLabel,
    required this.settingsLabel,
    required this.busy,
    required this.optional,
    required this.onPrimary,
    required this.onOpenSettings,
    required this.onSkip,
  });

  final Color color;
  final String primaryLabel;
  final String settingsLabel;
  final bool busy;
  final bool optional;
  final VoidCallback onPrimary;
  final VoidCallback onOpenSettings;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEAECF0))),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: busy ? null : onPrimary,
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(primaryLabel),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onOpenSettings,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Text(settingsLabel),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: busy ? null : onSkip,
            child: Text(optional ? 'Thiết lập sau trong app' : 'Bỏ qua'),
          ),
        ],
      ),
    );
  }
}
