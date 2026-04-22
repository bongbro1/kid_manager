import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/subscription/subscription_catalog_plan.dart';
import 'package:kid_manager/widgets/app/app_button.dart';

class SubscriptionHeroCard extends StatelessWidget {
  const SubscriptionHeroCard({
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.currentPlanLabel,
    required this.currentStatusLabel,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String currentPlanLabel;
  final String currentStatusLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;
    final l10n = AppLocalizations.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surface,
            scheme.primaryContainer.withValues(alpha: 0.72),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.14)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.10),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.78),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: scheme.primary.withValues(alpha: 0.12)),
            ),
            child: Text(
              eyebrow,
              style: typography.meta.copyWith(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            style: typography.screenTitle.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: typography.body.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 18),
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: HeroStatusTile(
                    label: l10n.subscriptionCurrentPlanLabel,
                    value: currentPlanLabel,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: HeroStatusTile(
                    label: l10n.subscriptionCurrentStatusLabel,
                    value: currentStatusLabel,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              HeroFactChip(
                icon: Icons.family_restroom_rounded,
                label: l10n.subscriptionHeroChipFamily,
              ),
              HeroFactChip(
                icon: Icons.insights_rounded,
                label: l10n.subscriptionHeroChipReports,
              ),
              HeroFactChip(
                icon: Icons.support_agent_rounded,
                label: l10n.subscriptionHeroChipPrioritySupport,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class HeroStatusTile extends StatelessWidget {
  const HeroStatusTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.appTypography.meta.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.appTypography.body.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class HeroFactChip extends StatelessWidget {
  const HeroFactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: scheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: theme.appTypography.supporting.copyWith(
              color: scheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class SubscriptionSectionHeader extends StatelessWidget {
  const SubscriptionSectionHeader({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: typography.meta.copyWith(
            color: scheme.primary,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          title,
          style: typography.title.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          description,
          style: typography.sectionLabel.copyWith(
            color: scheme.onSurfaceVariant,
            height: 1.55,
          ),
        ),
      ],
    );
  }
}

class SelectablePlanCard extends StatelessWidget {
  const SelectablePlanCard({
    required this.plan,
    required this.isSelected,
    required this.isCurrentPlan,
    required this.onTap,
  });

  final LocalizedPlanViewData plan;
  final bool isSelected;
  final bool isCurrentPlan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;

    final baseColor = plan.isHighlighted
        ? scheme.primaryContainer.withValues(alpha: isSelected ? 0.98 : 0.92)
        : scheme.surface.withValues(alpha: isSelected ? 0.98 : 0.90);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: baseColor,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              width: 2,
              color: isSelected
                  ? scheme.primary
                  : plan.isHighlighted
                  ? scheme.primary.withValues(alpha: 0.22)
                  : scheme.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              if (plan.isHighlighted || isSelected)
                BoxShadow(
                  color: scheme.primary.withValues(
                    alpha: isSelected ? 0.14 : 0.10,
                  ),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
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
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: isSelected || plan.isHighlighted
                          ? scheme.primary
                          : scheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      plan.icon,
                      size: 24,
                      color: isSelected || plan.isHighlighted
                          ? scheme.onPrimary
                          : scheme.primary,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              plan.title,
                              style: typography.title.copyWith(
                                color: scheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (plan.isHighlighted)
                              PlanBadge(label: plan.highlightLabel),
                            if (plan.isContactOnly)
                              PlanBadge(label: plan.contactLabel),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          plan.price,
                          style: typography.itemTitle.copyWith(
                            color: isSelected || plan.isHighlighted
                                ? scheme.primary
                                : scheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedScale(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeOutCubic,
                    scale: isSelected ? 1 : 0.9,
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      color: isSelected
                          ? scheme.primary
                          : scheme.onSurfaceVariant.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                plan.subtitle,
                style: typography.sectionLabel.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.55,
                ),
              ),
              if (isCurrentPlan) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 18,
                      color: scheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).subscriptionCurrentPlanLabel,
                      style: typography.supporting.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              ...plan.features.indexed.map((entry) {
                final index = entry.$1;
                final item = entry.$2;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == plan.features.length - 1 ? 0 : 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        margin: const EdgeInsets.only(top: 1),
                        decoration: BoxDecoration(
                          color: isSelected || plan.isHighlighted
                              ? scheme.primary.withValues(alpha: 0.12)
                              : scheme.surface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 14,
                          color: isSelected || plan.isHighlighted
                              ? scheme.primary
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          item,
                          style: typography.body.copyWith(
                            color: scheme.onSurface,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class PlanBadge extends StatelessWidget {
  const PlanBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.appTypography.meta.copyWith(
          color: scheme.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class SupportCard extends StatelessWidget {
  const SupportCard({
    required this.emailLabel,
    required this.phoneLabel,
    required this.hoursLabel,
    required this.hoursValue,
  });

  final String emailLabel;
  final String phoneLabel;
  final String hoursLabel;
  final String hoursValue;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        children: [
          SupportTile(
            icon: Icons.mail_outline_rounded,
            label: emailLabel,
            value: 'support@kidmanager.app',
          ),
          const SizedBox(height: 12),
          SupportTile(
            icon: Icons.call_outlined,
            label: phoneLabel,
            value: '1900 1234',
          ),
          const SizedBox(height: 12),
          SupportTile(
            icon: Icons.schedule_rounded,
            label: hoursLabel,
            value: hoursValue,
          ),
        ],
      ),
    );
  }
}

class SupportTile extends StatelessWidget {
  const SupportTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: scheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: typography.meta.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: typography.body.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
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

class InlineErrorCard extends StatelessWidget {
  const InlineErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.error.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline_rounded, color: scheme.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).appTypography.body.copyWith(
                color: scheme.onErrorContainer,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmptyPlansCard extends StatelessWidget {
  const EmptyPlansCard({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 32, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.appTypography.body.copyWith(
              color: scheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
            fullWidth: false,
            text: retryLabel,
            onPressed: onRetry,
            backgroundColor: scheme.primary,
            foregroundColor: scheme.onPrimary,
            fontSize: theme.appTypography.body.fontSize,
          ),
        ],
      ),
    );
  }
}

class LocalizedPlanViewData {
  const LocalizedPlanViewData({
    required this.id,
    required this.title,
    required this.price,
    required this.subtitle,
    required this.features,
    required this.icon,
    required this.isHighlighted,
    required this.isContactOnly,
    required this.highlightLabel,
    required this.contactLabel,
  });

  final String id;
  final String title;
  final String price;
  final String subtitle;
  final List<String> features;
  final IconData icon;
  final bool isHighlighted;
  final bool isContactOnly;
  final String highlightLabel;
  final String contactLabel;

  factory LocalizedPlanViewData.fromPlan(
    SubscriptionCatalogPlan plan,
    AppLocalizations l10n,
  ) {
    return switch (plan.id) {
      'premium' => LocalizedPlanViewData(
        id: plan.id,
        title: l10n.subscriptionPlanPremiumTitle,
        price: l10n.subscriptionPlanPremiumPrice,
        subtitle: l10n.subscriptionPlanPremiumSubtitle,
        features: [
          l10n.subscriptionPlanPremiumFeature1,
          l10n.subscriptionPlanPremiumFeature2,
          l10n.subscriptionPlanPremiumFeature3,
          l10n.subscriptionPlanPremiumFeature4,
        ],
        icon: Icons.workspace_premium_rounded,
        isHighlighted: plan.isHighlighted,
        isContactOnly: plan.isContactOnly,
        highlightLabel: l10n.subscriptionPopularBadge,
        contactLabel: l10n.subscriptionContactBadge,
      ),
      'school' => LocalizedPlanViewData(
        id: plan.id,
        title: l10n.subscriptionPlanSchoolTitle,
        price: l10n.subscriptionPlanSchoolPrice,
        subtitle: l10n.subscriptionPlanSchoolSubtitle,
        features: [
          l10n.subscriptionPlanSchoolFeature1,
          l10n.subscriptionPlanSchoolFeature2,
          l10n.subscriptionPlanSchoolFeature3,
          l10n.subscriptionPlanSchoolFeature4,
        ],
        icon: Icons.school_rounded,
        isHighlighted: plan.isHighlighted,
        isContactOnly: plan.isContactOnly,
        highlightLabel: l10n.subscriptionPopularBadge,
        contactLabel: l10n.subscriptionContactBadge,
      ),
      _ => LocalizedPlanViewData(
        id: plan.id,
        title: l10n.subscriptionPlanBasicTitle,
        price: l10n.subscriptionPlanBasicPrice,
        subtitle: l10n.subscriptionPlanBasicSubtitle,
        features: [
          l10n.subscriptionPlanBasicFeature1,
          l10n.subscriptionPlanBasicFeature2,
          l10n.subscriptionPlanBasicFeature3,
        ],
        icon: Icons.layers_rounded,
        isHighlighted: plan.isHighlighted,
        isContactOnly: plan.isContactOnly,
        highlightLabel: l10n.subscriptionPopularBadge,
        contactLabel: l10n.subscriptionContactBadge,
      ),
    };
  }
}
