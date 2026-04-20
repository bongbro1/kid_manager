import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/app/app_scroll_effects.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 20,
    );
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final versionText = l10n.aboutAppVersionLabel('1.0.0');

    const featureItems = [
      _AboutFeatureData(
        icon: Icons.shield_rounded,
        title: 'An toàn và rõ ràng',
        description:
            'Tập trung các tín hiệu quan trọng để phụ huynh theo dõi gia đình dễ hơn mỗi ngày.',
      ),
      _AboutFeatureData(
        icon: Icons.notifications_active_rounded,
        title: 'Phản hồi theo thời gian thực',
        description:
            'Thông báo, cập nhật và các mốc hoạt động được trình bày trực tiếp trong ứng dụng.',
      ),
      _AboutFeatureData(
        icon: Icons.insights_rounded,
        title: 'Quản lý có chiều sâu',
        description:
            'Gộp theo dõi, báo cáo và kiểm soát vào cùng một trải nghiệm nhất quán.',
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18,
            color: scheme.onSurface,
          ),
        ),
        title: Text(
          l10n.aboutAppTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: typography.screenTitle.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: const [0, 0.32, 1],
            colors: [
              scheme.primary.withValues(alpha: 0.07),
              theme.scaffoldBackgroundColor,
              theme.scaffoldBackgroundColor,
            ],
          ),
        ),
        child: SingleChildScrollView(
          physics: AppScrollEffects.physics,
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            12,
            horizontalPadding,
            bottomInset + 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppScrollReveal(
                index: 0,
                child: _AboutHeroCard(
                  appName: l10n.aboutAppName,
                  versionText: versionText,
                  description: l10n.aboutAppDescription,
                ),
              ),
              const SizedBox(height: 28),
              const AppScrollReveal(
                index: 1,
                child: _SectionHeader(
                  eyebrow: 'ỨNG DỤNG',
                  title: 'Điểm nổi bật',
                  description:
                      'Kid Manager được xây dựng để việc theo dõi, kết nối và quản lý gia đình trở nên gọn gàng hơn.',
                ),
              ),
              const SizedBox(height: 14),
              ...featureItems.indexed.map((entry) {
                final index = entry.$1;
                final item = entry.$2;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == featureItems.length - 1 ? 0 : 14,
                  ),
                  child: AppScrollReveal(
                    index: index + 2,
                    child: _AboutFeatureCard(item: item),
                  ),
                );
              }),
              const SizedBox(height: 28),
              AppScrollReveal(
                index: featureItems.length + 2,
                child: const _SectionHeader(
                  eyebrow: 'THÔNG TIN',
                  title: 'Thông tin ứng dụng',
                  description:
                      'Một vài thông tin nhanh để bạn nhận diện phiên bản và phạm vi sử dụng hiện tại của ứng dụng.',
                ),
              ),
              const SizedBox(height: 14),
              AppScrollReveal(
                index: featureItems.length + 3,
                child: _AboutInfoCard(versionText: versionText),
              ),
              const SizedBox(height: 24),
              AppScrollReveal(
                index: featureItems.length + 4,
                child: Center(
                  child: Text(
                    l10n.aboutAppCopyright,
                    textAlign: TextAlign.center,
                    style: typography.supporting.copyWith(
                      color: scheme.outline,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AboutHeroCard extends StatelessWidget {
  const _AboutHeroCard({
    required this.appName,
    required this.versionText,
    required this.description,
  });

  final String appName;
  final String versionText;
  final String description;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;

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
      child: Stack(
        children: [
          Positioned(
            top: -10,
            right: -4,
            child: Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 26,
            right: 40,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary.withValues(alpha: 0.18),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: scheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      Icons.family_restroom_rounded,
                      color: scheme.onPrimary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surface.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(
                              color: scheme.primary.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Text(
                            versionText,
                            style: typography.meta.copyWith(
                              color: scheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          appName,
                          style: typography.screenTitle.copyWith(
                            color: scheme.onSurface,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                description,
                style: typography.body.copyWith(
                  color: scheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 18),
              const Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _HeroFactChip(
                    icon: Icons.shield_rounded,
                    label: 'An toàn gia đình',
                  ),
                  _HeroFactChip(
                    icon: Icons.notifications_active_rounded,
                    label: 'Thông báo tức thời',
                  ),
                  _HeroFactChip(
                    icon: Icons.insights_rounded,
                    label: 'Báo cáo rõ ràng',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroFactChip extends StatelessWidget {
  const _HeroFactChip({required this.icon, required this.label});

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

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
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
            fontWeight: FontWeight.w800,
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

class _AboutFeatureCard extends StatelessWidget {
  const _AboutFeatureCard({required this.item});

  final _AboutFeatureData item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outline.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(item.icon, size: 24, color: scheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: typography.title.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.description,
                  style: typography.body.copyWith(
                    color: scheme.onSurfaceVariant,
                    height: 1.55,
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

class _AboutInfoCard extends StatelessWidget {
  const _AboutInfoCard({required this.versionText});

  final String versionText;

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
          _InfoRow(
            icon: Icons.info_outline_rounded,
            label: 'Phiên bản',
            value: versionText,
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            icon: Icons.family_restroom_rounded,
            label: 'Đối tượng sử dụng',
            value: 'Phụ huynh, người giám hộ và gia đình',
          ),
          const SizedBox(height: 12),
          const _InfoRow(
            icon: Icons.track_changes_rounded,
            label: 'Mục tiêu',
            value: 'Theo dõi, kết nối và quản lý thông tin gia đình hằng ngày',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
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
        crossAxisAlignment: CrossAxisAlignment.start,
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
                    height: 1.5,
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

class _AboutFeatureData {
  const _AboutFeatureData({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}
