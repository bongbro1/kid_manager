import 'package:flutter/material.dart';
import 'package:kid_manager/models/app_user.dart';

class MapBottomControls extends StatelessWidget {
  final List<AppUser> children;
  final void Function(AppUser child)? onTapChild;
  final VoidCallback? onMore;
  final VoidCallback? onMyLocation;

  const MapBottomControls({
    super.key,
    required this.children,
    this.onTapChild,
    this.onMore,
    this.onMyLocation,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        /// ===== LEFT GROUP (CHILD + MORE) =====
        if ((onTapChild != null && children.isNotEmpty) || onMore != null)
          _LeftGroup(
            children: children,
            onTapChild: onTapChild,
            onMore: onMore,
          ),

        const Spacer(),

        /// ===== MY LOCATION (PRIMARY) =====
        if (onMyLocation != null)
          _PrimaryCircleButton(
            icon: Icons.gps_fixed,
            onTap: onMyLocation!,
          ),
      ],
    );
  }
}

/* ============================================================
   LEFT GROUP
============================================================ */

class _LeftGroup extends StatelessWidget {
  final List<AppUser> children;
  final void Function(AppUser child)? onTapChild;
  final VoidCallback? onMore;

  const _LeftGroup({
    required this.children,
    this.onTapChild,
    this.onMore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          /// CHILD PICKER
          if (onTapChild != null && children.isNotEmpty)
            PopupMenuButton<AppUser>(
              tooltip: 'Chọn con',
              icon: const Icon(Icons.people, size: 20),
              onSelected: onTapChild!,
              itemBuilder: (_) => children
                  .map(
                    (c) => PopupMenuItem(
                  value: c,
                  child: Text(c.displayLabel),
                ),
              )
                  .toList(),
            ),

          if (onTapChild != null && onMore != null)
            const SizedBox(width: 4),

          /// MORE
          if (onMore != null)
            InkWell(
              onTap: onMore,
              borderRadius: BorderRadius.circular(16),
              child: const Padding(
                padding: EdgeInsets.all(6),
                child: Icon(Icons.more_horiz, size: 20),
              ),
            ),
        ],
      ),
    );
  }
}

/* ============================================================
   PRIMARY BUTTON (MY LOCATION)
============================================================ */

class _PrimaryCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _PrimaryCircleButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 6,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: const Padding(
          padding: EdgeInsets.all(14),
          child: Icon(
            Icons.gps_fixed,
            color: Colors.blue,
            size: 25,
          ),
        ),
      ),
    );
  }
}
