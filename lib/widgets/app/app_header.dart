import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:kid_manager/features/presentation/shared/map_mode.dart';

class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final MapMode mode;
  final Widget? right;

  const AppHeader({
    super.key,
    required this.title,
    required this.mode,
    this.right,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(title),
      actions: [
        if (right != null)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: right!,
          )
        else if (mode == MapMode.parent)
          const Icon(Icons.search)
        else
          const SizedBox(width: 12),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
