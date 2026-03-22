import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kid_manager/core/app_colors.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/widgets/app/app_button.dart';
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
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<AppManagementVM>();
    final l10n = AppLocalizations.of(context);
    final users = vm.children;
    final selectedId = vm.selectedChildId;

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final pageCount = (users.length / 3).ceil();

    if (vm.error != null) {
      return Center(
        child: Text(
          vm.error!,
          style: textTheme.bodyMedium?.copyWith(color: scheme.error),
        ),
      );
    }

    return Container(
      height: 190,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withOpacity(0.15),
            blurRadius: 3,
            offset: const Offset(0, 1),
            spreadRadius: 1,
          ),
          BoxShadow(
            color: scheme.shadow.withOpacity(0.25),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Column(
        children: [
          Row(
            children: [
              _ArrowBtn(
                asset: 'assets/icons/chevron_left.svg',
                enabled: _page > 0,
                onTap: _goPrev,
              ),

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
                                widget.onTapApps();
                              },
                              child: UserItemWidget(
                                name: user.name,
                                avatarUrl: user.avatarUrl,
                                isOnline: user.isOnline,
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

              _ArrowBtn(
                asset: 'assets/icons/chevron_right.svg',
                enabled: _page < pageCount - 1,
                onTap: _goNext,
              ),
            ],
          ),

          Container(
            width: 301,
            height: 1,
            color: theme.dividerTheme.color ?? scheme.outline.withOpacity(0.3),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: 300,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                AppButton(
                  width: 147,
                  height: 40,
                  text: l10n.parentDashboardTabApps,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  onPressed: widget.onTapApps,
                  backgroundColor: widget.currentIndex == 0
                      ? scheme.primary
                      : scheme.primary.withOpacity(0.12),
                  foregroundColor: scheme.onSurface,
                  fontFamily: 'Roboto',
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
                  text: l10n.parentDashboardTabStatistics,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  onPressed: widget.onTapStats,
                  backgroundColor: widget.currentIndex == 1
                      ? scheme.primary
                      : scheme.primary.withOpacity(0.12),
                  foregroundColor: scheme.onSurface,
                  fontFamily: 'Roboto',
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
    final scheme = Theme.of(context).colorScheme;

    final iconColor = enabled
        ? scheme.onSurface
        : scheme.onSurface.withOpacity(0.3);

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        width: 32,
        height: 32,
        child: Center(
          child: SvgPicture.asset(
            asset,
            width: 18,
            height: 18,
            colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
          ),
        ),
      ),
    );
  }
}

class UserItemWidget extends StatelessWidget {
  final String name;
  final String avatarUrl;
  final bool isOnline;
  final double size;
  final bool isSelected;

  const UserItemWidget({
    super.key,
    required this.name,
    required this.avatarUrl,
    this.isOnline = false,
    this.size = 56,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final trimmedAvatar = avatarUrl.trim();
    final hasAvatar = trimmedAvatar.isNotEmpty;

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
                  color: isSelected ? scheme.primary : Colors.transparent,
                ),
              ),
              child: ClipOval(
                child: hasAvatar
                    ? Image.network(
                        trimmedAvatar,
                        width: size,
                        height: size,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Image.asset(
                          'assets/images/avatar_default.png',
                          width: size,
                          height: size,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        'assets/images/avatar_default.png',
                        width: size,
                        height: size,
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
          height: 32,
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
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface,
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
