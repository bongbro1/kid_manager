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

    final plans = const [
      _PlanData(
        title: 'Gói Cơ bản',
        price: 'Miễn phí',
        subtitle:
            'Dành cho gia đình muốn bắt đầu với những tính năng thiết yếu.',
        icon: Icons.layers_rounded,
        features: [
          'Quản lý hồ sơ trẻ và người thân',
          'Theo dõi hoạt động cơ bản',
          'Nhận thông báo trực tiếp trong ứng dụng',
        ],
      ),
      _PlanData(
        title: 'Gói Premium',
        price: '99.000đ / tháng',
        subtitle:
            'Mở khóa trải nghiệm đầy đủ với báo cáo sâu và hỗ trợ ưu tiên.',
        icon: Icons.workspace_premium_rounded,
        features: [
          'Bao gồm toàn bộ tính năng của gói Cơ bản',
          'Báo cáo nâng cao và lịch sử dài hạn',
          'Lưu trữ dữ liệu nhiều hơn',
          'Ưu tiên hỗ trợ khách hàng',
        ],
        highlight: true,
      ),
      _PlanData(
        title: 'Gói Trường học',
        price: 'Liên hệ',
        subtitle:
            'Phù hợp cho tổ chức cần quản lý nhiều lớp hoặc nhiều nhóm trẻ.',
        icon: Icons.school_rounded,
        features: [
          'Quản lý nhiều lớp và nhiều tài khoản',
          'Phân quyền giáo viên và quản trị viên',
          'Thống kê tập trung',
          'Tùy chỉnh theo nhu cầu vận hành',
        ],
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
                  versionText: l10n.aboutAppVersionLabel('1.0.0'),
                  description: l10n.aboutAppDescription,
                ),
              ),
              const SizedBox(height: 28),
              const AppScrollReveal(
                index: 1,
                child: _SectionHeader(
                  eyebrow: 'DỊCH VỤ',
                  title: 'Các gói tài khoản',
                  description:
                      'Chọn cấp độ phù hợp với nhu cầu quản lý gia đình hoặc tổ chức của bạn.',
                ),
              ),
              const SizedBox(height: 14),
              ...plans.indexed.map((entry) {
                final index = entry.$1;
                final plan = entry.$2;
                return Padding(
                  padding: EdgeInsets.only(
                    bottom: index == plans.length - 1 ? 0 : 14,
                  ),
                  child: AppScrollReveal(
                    index: index + 2,
                    child: _PlanCard(plan: plan),
                  ),
                );
              }),
              const SizedBox(height: 28),
              const AppScrollReveal(
                index: 5,
                child: _SectionHeader(
                  eyebrow: 'LIÊN HỆ',
                  title: 'Hỗ trợ nhanh',
                  description:
                      'Nếu cần hỗ trợ về tài khoản, tính năng hoặc gói dịch vụ, đội ngũ của chúng tôi luôn sẵn sàng.',
                ),
              ),
              const SizedBox(height: 14),
              const AppScrollReveal(index: 6, child: _SupportCard()),
              const SizedBox(height: 24),
              AppScrollReveal(
                index: 7,
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

class _PlanCard extends StatelessWidget {
  const _PlanCard({required this.plan});

  final _PlanData plan;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final typography = theme.appTypography;

    final baseColor = plan.highlight
        ? scheme.primaryContainer.withValues(alpha: 0.92)
        : scheme.surface.withValues(alpha: 0.84);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: plan.highlight
              ? scheme.primary.withValues(alpha: 0.26)
              : scheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: plan.highlight
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.10),
                  blurRadius: 24,
                  offset: const Offset(0, 14),
                ),
              ]
            : null,
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
                  color: plan.highlight
                      ? scheme.primary
                      : scheme.surface.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  plan.icon,
                  size: 24,
                  color: plan.highlight ? scheme.onPrimary : scheme.primary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: typography.title.copyWith(
                              color: scheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (plan.highlight)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: scheme.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Phổ biến',
                              style: typography.meta.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      plan.price,
                      style: typography.itemTitle.copyWith(
                        color: plan.highlight
                            ? scheme.primary
                            : scheme.onSurface,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
                      color: plan.highlight
                          ? scheme.primary.withValues(alpha: 0.12)
                          : scheme.surface,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: plan.highlight
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
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard();

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
      child: const Column(
        children: [
          _SupportTile(
            icon: Icons.mail_outline_rounded,
            label: 'Email',
            value: 'support@kidmanager.app',
          ),
          SizedBox(height: 12),
          _SupportTile(
            icon: Icons.call_outlined,
            label: 'Hotline',
            value: '1900 1234',
          ),
          SizedBox(height: 12),
          _SupportTile(
            icon: Icons.language_rounded,
            label: 'Website',
            value: 'www.kidmanager.app',
          ),
        ],
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
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

class _PlanData {
  const _PlanData({
    required this.title,
    required this.price,
    required this.subtitle,
    required this.icon,
    required this.features,
    this.highlight = false,
  });

  final String title;
  final String price;
  final String subtitle;
  final IconData icon;
  final List<String> features;
  final bool highlight;
}
