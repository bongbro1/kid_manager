import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';

class AppItem extends StatelessWidget {
  final String appName;
  final String usageTimeText;

  /// Icon app bên trái (svg asset path)
  final String? iconBase64;

  /// Actions
  final VoidCallback? onTap;

  /// Optional styling
  final double width;
  final double height;
  final Color backgroundColor;
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
    this.backgroundColor = Colors.white,
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

    final defaultTitleStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: const Color(0xFF4A4A4A),
      fontFamily: "Poppins",
      height: 1.25,
    );

    final defaultSubtitleStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: const Color(0xFF6B6778),
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
            color: backgroundColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadows: const [
              BoxShadow(
                blurRadius: 10,
                offset: Offset(0, 4),
                color: Color(0x0A000000),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // LEFT: app icon
              Container(
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
                      : const Icon(Icons.apps, size: 24, color: Colors.grey),
                ),
              ),

              const SizedBox(width: 12),

              // CENTER: name + usage time
              Expanded(
                child: SizedBox.expand(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 2),

                      /// Dòng trên
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

                      /// Progress bar
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 8,
                        backgroundColor: const Color(0xFFF1F5F9),
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFF3B82F6),
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
                  child: const Padding(
                    padding: EdgeInsets.all(6),
                    child: Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFF6B6778),
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
