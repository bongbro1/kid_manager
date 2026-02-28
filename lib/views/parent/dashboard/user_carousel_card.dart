import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/models/user/user_types.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/viewmodels/user_vm.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/common/tappable_photo.dart';
import 'package:provider/provider.dart';

class UserCarouselCard extends StatefulWidget {
  final int currentIndex;
  final VoidCallback onTapApps;
  final VoidCallback onTapStats;

  const UserCarouselCard({
    super.key,
    required this.currentIndex,
    required this.onTapApps,
    required this.onTapStats,
  });

  @override
  State<UserCarouselCard> createState() => _UserCarouselCardState();
}

class _UserCarouselCardState extends State<UserCarouselCard> {
  final _pageController = PageController();
  int _page = 0;
  int _pageCount(List users) => (users.length / 3).ceil();

  void _goPrev() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _goNext() {
    final users = context.read<AppManagementVM>().children;
    final pageCount = _pageCount(users);

    if (_page < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppManagementVM>().loadChildren();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppManagementVM>();
    final users = vm.children;
    final selectedId = vm.selectedChildId;

    final pageCount = (users.length / 3).ceil();
    if (vm.error != null) {
      return Center(child: Text(vm.error!));
    }

    return Container(
      // width: 380,
      height: 190,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 3,
            offset: Offset(0, 1),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: Color(0x4C000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: 0,
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              // Left arrow
              _ArrowBtn(
                asset: 'assets/icons/chevron_left.svg',
                enabled: _page > 0,
                onTap: _goPrev,
              ),

              // 3 users in the middle (paged)
              Expanded(
                child: SizedBox(
                  height: 120,
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pageCount,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemBuilder: (context, pageIndex) {
                      final start = pageIndex * 3;
                      final end = (start + 3).clamp(0, users.length);
                      final slice = users.sublist(start, end);

                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(3, (i) {
                          if (i >= slice.length) {
                            return const SizedBox(width: 70);
                          }
                          final user = slice[i];
                          return SizedBox(
                            width: 70,
                            child: GestureDetector(
                              onTap: () {
                                context.read<AppManagementVM>().selectChild(
                                  user.id,
                                );
                              },
                              child: UserItem(
                                name: slice[i].name,
                                avatarUrl: slice[i].avatarUrl,
                                isOnline: slice[i].isOnline,
                                isSelected: selectedId == user.id,
                              ),
                            ),
                          );
                        }),
                      );
                    },
                  ),
                ),
              ),
              // Right arrow
              _ArrowBtn(
                asset: 'assets/icons/chevron_right.svg',
                enabled: _page < pageCount - 1,
                onTap: _goNext,
              ),
            ],
          ),

          Container(
            width: 301,
            decoration: ShapeDecoration(
              shape: RoundedRectangleBorder(
                side: BorderSide(
                  width: 1,
                  strokeAlign: BorderSide.strokeAlignCenter,
                  color: const Color(0xFFF2F2F7),
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          SizedBox(
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  width: 147,
                  height: 40,
                  text: 'Ứng dụng',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  onPressed: widget.onTapApps,
                  backgroundColor: widget.currentIndex == 0
                      ? AppColors.primary
                      : const Color(0xFFE8DEF8),
                  foregroundColor: widget.currentIndex == 0
                      ? Colors.white
                      : const Color(0xFF4A4459),
                  fontFamily: "Roboto",
                  lineHeight: 1.43,
                  letterSpacing: 0.10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  icon: SvgPicture.asset(
                    'assets/icons/apps.svg',
                    width: 18,
                    height: 18,
                  ),
                ),

                AppButton(
                  width: 147,
                  height: 40,
                  text: 'Thống kê',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  onPressed: widget.onTapStats,
                  backgroundColor: widget.currentIndex == 1
                      ? AppColors.primary
                      : const Color(0xFFE8DEF8),
                  foregroundColor: widget.currentIndex == 1
                      ? Colors.white
                      : const Color(0xFF4A4459),
                  fontFamily: "Roboto",
                  lineHeight: 1.43,
                  letterSpacing: 0.10,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  icon: SvgPicture.asset(
                    'assets/icons/stats-chart.svg',
                    width: 18,
                    height: 18,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ArrowBtn extends StatelessWidget {
  final String asset;
  final bool enabled;
  final VoidCallback onTap;

  const _ArrowBtn({
    required this.asset,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: SizedBox(
          width: 32,
          height: 32,
          child: Center(child: SvgPicture.asset(asset, width: 18, height: 18)),
        ),
      ),
    );
  }
}

class UserItem extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final double size;
  final bool isSelected;

  const UserItem({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
    this.size = 56,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<UserVm>();
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      // crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Avatar (safe)
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  width: 2,
                  color: isSelected
                      ? const Color(0xFF3A7DFF)
                      : Colors.transparent,
                ),
              ),
              child: ClipOval(
                child: Image(
                  image: ((avatarUrl).trim().isNotEmpty)
                      ? NetworkImage((avatarUrl).trim())
                      : const AssetImage("assets/images/avatar_default.png")
                            as ImageProvider,
                  width: 500,
                  height: 230,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            // Status dot
            Positioned(
              right: 2,
              bottom: -2,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: isOnline
                      ? const Color(0xFF34C759)
                      : const Color(0xFFB0B0B0),
                  shape: BoxShape.circle,
                  border: Border.all(width: 2, color: Colors.white),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        SizedBox(
          height: 32, // đủ 2 dòng
          child: Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            softWrap: true,

            strutStyle: const StrutStyle(
              fontSize: 13,
              height: 1.2,
              forceStrutHeight: true,
            ),
            style: const TextStyle(
              color: Color(0xFF4A4A4A),
              fontSize: 13,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ],
    );
  }
}
