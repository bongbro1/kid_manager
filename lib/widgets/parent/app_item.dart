import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';

class AppItem extends StatelessWidget {
  final String usageTimeText;

  /// Icon app bên trái

  /// Actions
  final VoidCallback? onTap;

  /// Optional styling
  final double? width;
  final double height;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final AppItemModel app;
  final bool showRightIcon;

  const AppItem({
    super.key,
    required this.usageTimeText,
    required this.app,
    this.onTap,
    this.width,
    this.height = 70,
    this.backgroundColor,
    this.padding = const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    this.titleStyle,
    this.subtitleStyle,
    this.showRightIcon = true,
  });

  double calcProgress(String usageText, int maxMinutes) {
    final used = parseUsageTimeToMinutes(usageText);

    if (maxMinutes == 0) return 0;

    return (used / maxMinutes).clamp(0, 1);
  }

  @override
  Widget build(BuildContext context) {
    final progress = calcProgress(usageTimeText, app.dailyLimitMinutes ?? 0);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final defaultTitleStyle = textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: scheme.onSurface,
      fontFamily: "Poppins",
      height: 1.25,
    );

    final defaultSubtitleStyle = textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: scheme.onSurface.withValues(alpha: 0.7),
      fontFamily: "Poppins",
      height: 1.33,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        double? effectiveWidth = width;
        if (effectiveWidth != null && constraints.maxWidth.isFinite) {
          effectiveWidth = effectiveWidth.clamp(0, constraints.maxWidth);
        }

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              width: effectiveWidth ?? double.infinity,
              constraints: BoxConstraints(minHeight: height),
              padding: padding,
              decoration: ShapeDecoration(
                color: backgroundColor ?? scheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                shadows: [
                  BoxShadow(
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                    color: scheme.shadow.withValues(alpha: 0.08),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: app.iconBytes != null
                          ? Image.memory(
                              app.iconBytes!,
                              width: 40,
                              height: 40,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                              filterQuality: FilterQuality.low,
                            )
                          : Icon(
                              Icons.apps,
                              size: 24,
                              color: scheme.onSurface.withValues(alpha: 0.5),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                app.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: titleStyle ?? defaultTitleStyle,
                              ),
                            ),
                            const SizedBox(width: 8),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 88),
                              child: Text(
                                usageTimeText,
                                textAlign: TextAlign.end,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: subtitleStyle ?? defaultSubtitleStyle,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          backgroundColor: scheme.outline.withValues(
                            alpha: 0.18,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            scheme.primary,
                          ),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ],
                    ),
                  ),
                  if (showRightIcon) ...[
                    const SizedBox(width: 6),
                    InkResponse(
                      onTap: onTap,
                      radius: 22,
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: scheme.onSurface.withValues(alpha: 0.65),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
