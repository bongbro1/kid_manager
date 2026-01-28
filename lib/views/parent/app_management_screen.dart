import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
import 'package:kid_manager/widgets/parent/app_item.dart';

class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen> {
  final apps = [
    {
      "name": "Facebook",
      "time": "Đã dùng 2 giờ 15 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "Facebook",
      "time": "Đã dùng 2 giờ 15 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "Facebook",
      "time": "Đã dùng 2 giờ 15 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "Facebook",
      "time": "Đã dùng 2 giờ 15 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "Facebook",
      "time": "Đã dùng 2 giờ 15 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "Facebook",
      "time": "Đã dùng 2 giờ 15 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "Facebook",
      "time": "Đã dùng 2 giờ 15 phút",
      "icon": "assets/icons/facebook.svg",
    },
    {
      "name": "YouTube",
      "time": "Đã dùng 1 giờ 40 phút",
      "icon": "assets/icons/facebook.svg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF2F2F7),
      body: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 151,
              decoration: const BoxDecoration(
                color: Color(0xFF3A7DFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
            ),

            Column(
              children: [
                const SizedBox(height: 50),

                Padding(
                  padding: const EdgeInsets.only(left: 26),
                  child: Row(
                    mainAxisSize: MainAxisSize.max,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'assets/icons/icon_setting.svg',
                        width: 24,
                        height: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dashboard',
                        style: TextStyle(
                          color: Colors.white /* Schemes-On-Error */,
                          fontSize: 12,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                          letterSpacing: 0.50,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),
                Center(child: UserCarouselCard()),

                const SizedBox(height: 14),

                // DANH SÁCH APP
                Expanded(
                  child: ListView.builder(
                    itemCount: apps.length,
                    itemBuilder: (context, index) {
                      final app = apps[index];
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: 12,
                          left: 16,
                          right: 16,
                        ),
                        child: AppItem(
                          appName: app["name"]!,
                          usageTimeText: app["time"]!,
                          appIconAsset: app["icon"]!,
                          editIconAsset: Image.asset(
                            "assets/images/source_edit.png",
                            width: 18,
                            height: 18,
                            color: const Color(0xFF6B6778),
                          ),
                          onTap: () {},
                          onEdit: () {},
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class UserCarouselCard extends StatefulWidget {
  const UserCarouselCard({super.key});

  @override
  State<UserCarouselCard> createState() => _UserCarouselCardState();
}

class _UserCarouselCardState extends State<UserCarouselCard> {
  final _pageController = PageController();
  int _page = 0;

  // Demo data
  final users = const [
    ('Nguyễn Văn Nam', 'assets/images/u1.png'),
    ('Trần Thị Lan', 'assets/images/u1.png'),
    ('Phạm Minh Hiếu', 'assets/images/u1.png'),
    ('Lê Huy', 'assets/images/u1.png'),
    ('Mai Anh', 'assets/images/u1.png'),
    ('Thuỳ Dương', 'assets/images/u1.png'),
  ];

  int get pageCount => (users.length / 3).ceil();

  void _goPrev() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _goNext() {
    if (_page < pageCount - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 366,
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
                        // crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          for (final u in slice)
                            SizedBox(
                              width: 70, // 👈 giới hạn width mỗi item
                              child: UserItem(
                                name: u.$1,
                                avatarUrl: u.$2,
                                isOnline: true,
                              ),
                            ),
                        ],
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
                  color: const Color(
                    0xFFF2F2F7,
                  ) /* Backgrounds-(Grouped)-Primary */,
                ),
              ),
            ),
          ),

          SizedBox(height: 12),

          SizedBox(
            width: 295,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  width: 147,
                  height: 40,
                  text: 'Ứng dụng',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  onPressed: () {},
                  // Primary
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
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
                  onPressed: () {},
                  // Primary
                  backgroundColor: const Color(0xFFE8DEF8),
                  foregroundColor: Color(0xFF4A4459),
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

  const UserItem({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
    this.size = 56,
  });

  @override
  Widget build(BuildContext context) {
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
                border: Border.all(width: 2, color: const Color(0xFF3A7DFF)),
              ),
              child: ClipOval(child: Image.asset(avatarUrl, fit: BoxFit.cover)),
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
