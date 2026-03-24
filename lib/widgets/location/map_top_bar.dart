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
    final topInset = MediaQuery.paddingOf(context).top;
    final displayTitle = title ?? AppLocalizations.of(context).mapTopBarTitle;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      height: topInset + 48,
      decoration: BoxDecoration(
        color: locationPanelColor(scheme),
        border: Border(
          bottom: BorderSide(color: locationPanelBorderColor(scheme)),
        ),
      ),
      child: Column(
        children: [
          SizedBox(height: topInset),
          SizedBox(
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: InkWell(
                    onTap: onMenuTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Icon(
                        Icons.menu,
                        size: 22,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                ),
                Text(
                  displayTitle,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
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
                      margin: const EdgeInsets.only(right: 10),
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
        ],
      ),
    );
  }
}
