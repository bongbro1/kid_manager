import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_user.dart';
import 'package:kid_manager/viewmodels/location/parent_location_vm.dart';
import 'package:kid_manager/widgets/common/avatar.dart';
import 'package:provider/provider.dart';

class MapBottomControls extends StatelessWidget {
  final List<AppUser> children;
  final VoidCallback? onMore;
  final VoidCallback? onMyLocation;
  final void Function(AppUser child)? onTapChild;

  const MapBottomControls({
    super.key,
    required this.children,
    this.onMore,
    this.onTapChild,
    this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// ===== CHILD PREVIEW GROUP =====
        if (children.isNotEmpty && onMore != null)
          _ChildrenPreviewButton(
            children: children,
            onTapChild: onTapChild,
            onTap: onMore!,
          ),

        const Spacer(),

        /// ===== MY LOCATION BUTTON =====
        if (onMyLocation != null) _MyLocationButton(onTap: onMyLocation!),
      ],
    );
  }
}

class _ChildrenPreviewButton extends StatelessWidget {
  final List<AppUser> children;
  final VoidCallback onTap; // onMore
  final void Function(AppUser child)? onTapChild;

  const _ChildrenPreviewButton({
    required this.children,
    required this.onTap,
    this.onTapChild,
  });
  @override
  Widget build(BuildContext context) {
    final visible = children.take(2).toList();
    final remaining = children.length - visible.length;
    final locationVm = context.watch<ParentLocationVm>();
    final scheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: scheme.outline.withOpacity(0.5)),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withOpacity(0.14),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                for (final child in visible)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onTapChild == null
                          ? null
                          : () => onTapChild!(child),
                      child: AppAvatar(
                        user: child,
                        size: 44,
                        isOnline: locationVm.isChildOnline(child.uid),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.surface,
                  border: Border.all(color: scheme.primary, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Icon(Icons.more_horiz, size: 22, color: scheme.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyLocationButton extends StatelessWidget {
  final VoidCallback onTap;

  const _MyLocationButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: colorScheme.surface,
      shape: const CircleBorder(),
      elevation: 6,
      shadowColor: Colors.black.withOpacity(0.2),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: colorScheme.outline),
          ),
          child: Icon(Icons.my_location, size: 26, color: colorScheme.primary),
        ),
      ),
    );
  }
}
