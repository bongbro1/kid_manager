import 'package:flutter/material.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/app/app_icon.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 16,
      regular: 20,
    );
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: scheme.surface,
        surfaceTintColor: scheme.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: AppIcon(
                path: 'assets/icons/back.svg',
                type: AppIconType.svg,
                size: 16,
              ),
            ),
          ),
        ),
        title: Text(
          l10n.aboutAppTitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
          horizontalPadding,
          12,
          horizontalPadding,
          bottomInset + 12,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _AboutHeroCard(
              appName: l10n.aboutAppName,
              versionText: l10n.aboutAppVersionLabel('1.0.0'),
              description: l10n.aboutAppDescription,
            ),
            const SizedBox(height: 24),

            Text(
              'Các gói tài khoản',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            _PackageCard(
              title: 'Gói Cơ bản',
              price: 'Miễn phí',
              iconPath: 'assets/icons/info.svg',
              features: const [
                'Quản lý thông tin trẻ',
                'Theo dõi hoạt động cơ bản',
                'Xem thông báo trong ứng dụng',
              ],
              highlight: false,
            ),
            const SizedBox(height: 12),

            _PackageCard(
              title: 'Gói Premium',
              price: '99.000đ / tháng',
              iconPath: 'assets/icons/color_palette.svg',
              features: const [
                'Toàn bộ tính năng của gói Cơ bản',
                'Báo cáo nâng cao',
                'Lưu trữ dữ liệu dài hạn',
                'Ưu tiên hỗ trợ khách hàng',
              ],
              highlight: true,
            ),
            const SizedBox(height: 12),

            _PackageCard(
              title: 'Gói Trường học / Tổ chức',
              price: 'Liên hệ',
              iconPath: 'assets/icons/info.svg',
              features: const [
                'Quản lý nhiều lớp / nhiều tài khoản',
                'Phân quyền giáo viên và quản trị viên',
                'Thống kê tập trung',
                'Tùy chỉnh theo nhu cầu tổ chức',
              ],
              highlight: false,
            ),

            const SizedBox(height: 24),

            Text(
              'Hỗ trợ',
              style: textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: scheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),

            _InfoCard(
              title: 'Liên hệ & hỗ trợ',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow(label: 'Email', value: 'support@kidmanager.app'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Hotline', value: '1900 1234'),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Website', value: 'www.kidmanager.app'),
                ],
              ),
            ),

            const SizedBox(height: 24),

            Center(
              child: Text(
                l10n.aboutAppCopyright,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(color: scheme.outline),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AboutHeroCard extends StatelessWidget {
  final String appName;
  final String versionText;
  final String description;

  const _AboutHeroCard({
    required this.appName,
    required this.versionText,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.45),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            appName,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            versionText,
            style: textTheme.bodyMedium?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: textTheme.bodyLarge?.copyWith(
              height: 1.45,
              color: scheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  final String title;
  final String price;
  final String iconPath;
  final List<String> features;
  final bool highlight;

  const _PackageCard({
    required this.title,
    required this.price,
    required this.iconPath,
    required this.features,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final bgColor = highlight
        ? scheme.primaryContainer.withOpacity(0.75)
        : scheme.surface.withOpacity(0.45);

    final borderColor = highlight
        ? scheme.primary.withOpacity(0.35)
        : scheme.outlineVariant.withOpacity(0.5);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderColor),
        boxShadow: highlight
            ? [
                BoxShadow(
                  color: scheme.primary.withOpacity(0.08),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: AppIcon(
                    path: iconPath,
                    type: AppIconType.svg,
                    size: 20,
                    color: highlight ? scheme.primary : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
              ),
              Text(
                price,
                style: textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: highlight ? scheme.primary : scheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...features.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Icon(
                      Icons.check_circle_rounded,
                      size: 18,
                      color: highlight
                          ? scheme.primary
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurface,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface.withOpacity(0.4),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: scheme.outlineVariant.withOpacity(0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: textTheme.bodyMedium?.copyWith(color: scheme.onSurface),
          ),
        ),
      ],
    );
  }
}
