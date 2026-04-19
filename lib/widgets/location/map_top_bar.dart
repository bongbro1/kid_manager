import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';

class MapTopBar extends StatelessWidget {
  final String? title;
  final VoidCallback onMenuTap;
  final VoidCallback onAvatarTap;

  const MapTopBar({
    super.key,
    this.title,
    required this.onMenuTap,
    required this.onAvatarTap,
  });

  @override
  Widget build(BuildContext context) {
    final displayTitle = title ?? AppLocalizations.of(context).mapTopBarTitle;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(color: locationPanelColor(scheme)),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: onMenuTap,
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.menu, size: 26),
                    ),
                  ),
                ),
                Text(
                  displayTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w600,
                    fontSize: 18,
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: InkWell(
                    onTap: onAvatarTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: locationPanelHighlightColor(scheme),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        Icons.person,
                        size: 18,
                        color: scheme.primary,
                      ),
                    ),
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
