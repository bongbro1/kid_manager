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
      children: [
        /// CHILD PICKER
        if (onTapChild != null && children.isNotEmpty)
          PopupMenuButton<AppUser>(
            icon: const Icon(Icons.people),
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

        const Spacer(),

        if (onMore != null)
          IconButton(
            icon: const Icon(Icons.more_horiz),
            onPressed: onMore,
          ),

        if (onMyLocation != null)
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: onMyLocation,
          ),
      ],
    );
  }
}

