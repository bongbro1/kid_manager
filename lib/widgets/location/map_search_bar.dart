import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/widgets/location/location_theme.dart';

class MapSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final double topOffset;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onFilterTap;

  const MapSearchBar({
    super.key,
    required this.controller,
    required this.topOffset,
    required this.onSubmitted,
    required this.onFilterTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return Positioned(
      top: topOffset,
      left: 12,
      right: 12,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: locationPanelColor(scheme),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: locationPanelBorderColor(scheme)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.search, color: scheme.onSurfaceVariant, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.locationSearchHint,
                  hintStyle: TextStyle(color: scheme.onSurfaceVariant),
                  border: InputBorder.none,
                  isDense: true,
                ),
                style: TextStyle(color: scheme.onSurface),
                textInputAction: TextInputAction.search,
                onSubmitted: onSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: onFilterTap,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: locationPanelMutedColor(scheme),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: locationPanelBorderColor(scheme)),
                ),
                child: Icon(Icons.tune, size: 18, color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
