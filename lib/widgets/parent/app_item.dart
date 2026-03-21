import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
class AppItem extends StatelessWidget {
  final String appName;
  final String usageTimeText;

  /// Icon app bên trái
  final String? iconBase64;

  /// Actions
  final VoidCallback? onTap;

  /// Optional styling
  final double width;
  final double height;
  final Color? backgroundColor;
  final EdgeInsetsGeometry padding;

  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;
  final AppItemModel app;
  final bool showRightIcon;

  const AppItem({
    super.key,
    required this.appName,
    required this.usageTimeText,
    required this.app,
    this.iconBase64,
    this.onTap,
    this.width = 366,
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
      color: scheme.onSurface.withOpacity(0.7),
      fontFamily: "Poppins",
      height: 1.33,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          height: height,
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
                color: scheme.shadow.withOpacity(0.08),
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
                        )
                      : Icon(
                          Icons.apps,
                          size: 24,
                          color: scheme.onSurface.withOpacity(0.5),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: SizedBox.expand(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              appName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: titleStyle ?? defaultTitleStyle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            usageTimeText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: subtitleStyle ?? defaultSubtitleStyle,
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: scheme.outline.withOpacity(0.18),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          scheme.primary,
                        ),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ],
                  ),
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
                      color: scheme.onSurface.withOpacity(0.65),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}