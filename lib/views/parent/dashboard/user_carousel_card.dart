import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:kid_manager/core/responsive.dart';
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
  int _pageCount(List users, int itemsPerPage) =>
      (users.length / itemsPerPage).ceil();

  int _resolveItemsPerPage(double width) {
    if (width < ResponsiveBreakpoints.compactPhone) {
      return 2;
    }
    return 3;
  }

  void _goPrev() {
    if (_page > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _goNext(int itemsPerPage) {
    final users = context.read<AppManagementVM>().children;
    final pageCount = _pageCount(users, itemsPerPage);

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

    if (vm.error != null) {
      return Center(
        child: Text(
          vm.error!,
          style: textTheme.bodyMedium?.copyWith(color: scheme.error),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth;
        final itemsPerPage = _resolveItemsPerPage(cardWidth);
        final pageCount = _pageCount(users, itemsPerPage);
        final horizontalPadding = cardWidth < 360 ? 8.0 : 12.0;
        final itemGap = cardWidth < 360 ? 8.0 : 10.0;
        final availablePageWidth = (cardWidth - (horizontalPadding * 2) - 64)
            .clamp(0.0, cardWidth);
        final itemWidth =
            ((availablePageWidth - itemGap * (itemsPerPage - 1)) / itemsPerPage)
                .clamp(62.0, 84.0);

        if (pageCount == 0 && _page != 0) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _page = 0);
            if (_pageController.hasClients) {
              _pageController.jumpToPage(0);
            }
          });
        } else if (pageCount > 0 && _page > pageCount - 1) {
          final safePage = pageCount - 1;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() => _page = safePage);
            if (_pageController.hasClients) {
              _pageController.jumpToPage(safePage);
            }
          });
        }

        return Container(
          constraints: const BoxConstraints(minHeight: 190),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.15),
                blurRadius: 3,
                offset: const Offset(0, 1),
                spreadRadius: 1,
              ),
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.25),
                blurRadius: 2,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            8,
            horizontalPadding,
            10,
          ),
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
                          final start = pageIndex * itemsPerPage;
                          final end = (start + itemsPerPage).clamp(
                            0,
                            users.length,
                          );
                          final slice = users.sublist(start, end);
                          final rowChildren = <Widget>[];

                          for (int i = 0; i < itemsPerPage; i++) {
                            if (i > 0) {
                              rowChildren.add(SizedBox(width: itemGap));
                            }

                            if (i >= slice.length) {
                              rowChildren.add(SizedBox(width: itemWidth));
                              continue;
                            }

                            final user = slice[i];
                            rowChildren.add(
                              SizedBox(
                                width: itemWidth,
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
                              ),
                            );
                          }

                          return Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: rowChildren,
                          );
                        },
                      ),
                    ),
                  ),
                  _ArrowBtn(
                    asset: 'assets/icons/chevron_right.svg',
                    enabled: _page < pageCount - 1,
                    onTap: () => _goNext(itemsPerPage),
                  ),
                ],
              ),
              Container(
                width: double.infinity,
                height: 1,
                color:
                    theme.dividerTheme.color ??
                    scheme.outline.withValues(alpha: 0.3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      height: 40,
                      text: l10n.parentDashboardTabApps,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      onPressed: widget.onTapApps,
                      backgroundColor: widget.currentIndex == 0
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.12),
                      foregroundColor: widget.currentIndex == 0
                          ? scheme.onPrimary
                          : scheme.onSurface,
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
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      height: 40,
                      text: l10n.parentDashboardTabStatistics,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      onPressed: widget.onTapStats,
                      backgroundColor: widget.currentIndex == 1
                          ? scheme.primary
                          : scheme.primary.withValues(alpha: 0.12),
                      foregroundColor: widget.currentIndex == 1
                          ? scheme.onPrimary
                          : scheme.onSurface,
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
                  ),
                ],
              ),
            ],
          ),
        );
      },
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
        : scheme.onSurface.withValues(alpha: 0.3);

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
