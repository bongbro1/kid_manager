import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/models/location/location_data.dart';
import 'package:kid_manager/models/user/app_user_extensions.dart';

class ChildrenPickerSheet extends StatelessWidget {
  final List<AppUser> children;
  final Map<String, LocationData> latestMap;

  final void Function(AppUser child, LocationData latest) onPick;

  const ChildrenPickerSheet({
    super.key,
    required this.children,
    required this.latestMap,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return SafeArea(
      top: false,
      child: Material(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.all(12),
          itemCount: children.length,
          separatorBuilder: (_, index) => const Divider(height: 1),
          itemBuilder: (context, i) {
            final child = children[i];
            final latest = latestMap[child.uid];

            return ListTile(
              title: Text(child.displayLabel),
              subtitle: latest == null
                  ? Text(l10n.locationNoLocationYet)
                  : Text(
                      l10n.locationCoordinatesSummary(
                        latest.latitude.toStringAsFixed(4),
                        latest.longitude.toStringAsFixed(4),
                      ),
                    ),
              onTap: latest == null ? null : () => onPick(child, latest),
            );
          },
        ),
      ),
    );
  }
}
