import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/viewmodels/notification_vm.dart';
import 'package:provider/provider.dart';

class AppBottomNav extends StatelessWidget {
  final List<BottomNavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const AppBottomNav({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewPadding.bottom;
    final scheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottomInset > 0 ? bottomInset : 20,
      ),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(
          top: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
          bottom: BorderSide(color: scheme.outline.withValues(alpha: 0.3)),
        ),
      ),
      child: SizedBox(
        height: 50,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => onTap(index),
              child: SizedBox(
                width: 48,
                height: 48,
                child: Center(
                  child: _buildTabIcon(context, item, isActive: isActive),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTabIcon(
    BuildContext context,
    BottomNavItem item, {
    required bool isActive,
  }) {
    final scheme = Theme.of(context).colorScheme;
    final icon = SvgPicture.asset(
      item.iconAsset,
      width: 24,
      height: 24,
      colorFilter: ColorFilter.mode(
        isActive ? scheme.primary : scheme.onSurface,
        BlendMode.srcIn,
      ),
    );

    if (!item.showBadge) {
      return SizedBox(width: 24, height: 24, child: icon);
    }

    if (item.badgeCountStreamBuilder != null) {
      return SizedBox(
        width: 24,
        height: 24,
        child: StreamBuilder<int>(
          stream: item.badgeCountStreamBuilder!(context),
          builder: (_, snapshot) {
            final count = snapshot.data ?? 0;

            return Stack(
              clipBehavior: Clip.none,
              children: [
                icon,
                if (count > 0)
                  Positioned(right: -6, top: -6, child: _Badge(count: count)),
              ],
            );
          },
        ),
      );
    }

    return SizedBox(
      width: 24,
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          icon,
          Positioned(
            right: -6,
            top: -6,
            child: Selector<NotificationVM, int>(
              selector: (_, vm) => vm.unreadCount,
              builder: (_, count, __) {
                if (count == 0) return const SizedBox.shrink();
                return _Badge(count: count);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final int count;

  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: scheme.error, shape: BoxShape.circle),
      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
      child: Text(
        count > 99 ? '99+' : count.toString(),
        style: TextStyle(
          color: scheme.onError,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class BottomNavItem {
  final String iconAsset;
  final bool showBadge;
  final Stream<int> Function(BuildContext context)? badgeCountStreamBuilder;

  const BottomNavItem({
    required this.iconAsset,
    this.showBadge = false,
    this.badgeCountStreamBuilder,
  });
}
