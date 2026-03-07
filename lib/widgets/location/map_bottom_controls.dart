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

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 60, maxWidth: 220),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: const [
            BoxShadow(
              color: Color(0x40000000),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ✅ AVATARS: chỉ xử lý onTapChild
            Stack(
              clipBehavior: Clip.none,
              children: [
                for (final child in visible)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap:
                      onTapChild == null ? null : () => onTapChild!(child),
                      child: AppAvatar(
                        user: child,
                        size: 44,
                        isOnline: locationVm.isChildOnline(child.uid),
                      ),
                    ),
                  ),
                if (remaining > 0)
                  Positioned(
                    left: visible.length * 22,
                    child: CircleAvatar(
                      radius: 16,
                      backgroundColor: Colors.grey.shade300,
                      child: Text(
                        '+$remaining',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(width: 8),

            // ✅ MORE BUTTON: chỉ nút này mở list
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(
                    color: const Color(0xFF1A73E8),
                    width: 1.5,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.more_horiz,
                  size: 22,
                  color: Color(0xFF1A73E8),
                ),
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
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 8,
      shadowColor: const Color(0x40000000),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(
            Icons.my_location,
            size: 26,
            color: Color(0xFF1A73E8),
          ),
        ),
      ),
    );
  }
}