import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class BottomTab {
  final IconData icon;
  final String label;
  final Widget Function() builder;

  BottomTab({
    required this.icon,
    required this.label,
    required this.builder,
  });
}

class BottomTabConfig {
  final String iconAsset;
  final Widget root;
  final bool showBadge;
  final Stream<int> Function(BuildContext context)? badgeCountStreamBuilder;
  const BottomTabConfig({
    required this.iconAsset,
    required this.root,
    this.showBadge = false,
    this.badgeCountStreamBuilder,
  });


}

