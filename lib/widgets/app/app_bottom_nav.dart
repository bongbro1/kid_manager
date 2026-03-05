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
    return Container(
      height: 70,
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(items.length, (index) {
          final isActive = index == currentIndex;

          return InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTap(index),
            child: SizedBox(
              width: 48,
              height: 48,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      SvgPicture.asset(
                        items[index].iconAsset,
                        width: 24,
                        height: 24,
                        colorFilter: ColorFilter.mode(
                          isActive
                              ? const Color(0xFF3A7DFF)
                              : const Color(0xFF9E9E9E),
                          BlendMode.srcIn,
                        ),
                      ),

                      if (items[index].showBadge)
                        Positioned(
                          right: -6,
                          top: -6,
                          child: Selector<NotificationVM, int>(
                            selector: (_, vm) => vm.unreadCount,
                            builder: (_, count, __) {
                              if (count == 0) return const SizedBox.shrink();

                              return Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                child: Text(
                                  count > 99 ? "99+" : count.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

class BottomNavItem {
  final String iconAsset;
  final bool showBadge;

  const BottomNavItem({required this.iconAsset, this.showBadge = false});
}
