import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/app_page_transitions.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/views/parent/dashboard/no_child_screen.dart';
import 'package:kid_manager/views/parent/dashboard/statistics_tab.dart';
import 'package:kid_manager/views/parent/dashboard/usage_time_edit_screen.dart';
import 'package:kid_manager/views/parent/dashboard/user_carousel_card.dart';
import 'package:kid_manager/widgets/app/app_scroll_effects.dart';
import 'package:kid_manager/widgets/parent/app_item.dart';
import 'package:provider/provider.dart';
import 'package:skeletonizer/skeletonizer.dart';

class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _currentTabIndex = 0;

  // sau chuyển ra flash screen
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _currentTabIndex = _tabController.index;
    _tabController.addListener(_handleTabChanged);
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChanged() {
    if (!mounted) return;

    final nextIndex = _tabController.index;
    if (nextIndex == _currentTabIndex) return;

    setState(() {
      _currentTabIndex = nextIndex;
    });
  }

  Future<void> openUsageTimeEdit({
    required BuildContext context,
    required AppItemModel app,
    required VoidCallback onUpdated,
  }) async {
    final selectedChildId = context.read<AppManagementVM>().selectedChildId;

    if (selectedChildId == null) {
      debugPrint("❌ No child selected");
      return;
    }
    final changed = await Navigator.of(context, rootNavigator: true).push<bool>(
      PageRouteBuilder<bool>(
        opaque: false,
        barrierColor: Colors.black.withValues(alpha: 0.12),
        transitionDuration: AppPageTransitions.forwardDuration,
        reverseTransitionDuration: AppPageTransitions.reverseDuration,
        pageBuilder: (_, animation, secondaryAnimation) {
          return UsageTimeEditScreen(
            appId: app.packageName,
            childId: selectedChildId,
          );
        },
        transitionsBuilder: AppPageTransitions.buildModalTransition,
      ),
    );

    if (!context.mounted) return;

    // ✅ chỉ refresh khi có thay đổi
    if (changed == true) {
      onUpdated();
    }
  }

  Future<void> _reloadApps() async {
    await context.read<AppManagementVM>().loadAppsForSelectedChild(
      forceRefresh: true,
    );
  }

  void _goTab(int index) {
    if (_tabController.index == index && !_tabController.indexIsChanging) {
      return;
    }

    _tabController.animateTo(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final appVm = context.watch<AppManagementVM>();

    if (!appVm.loading && !appVm.hasChild) {
      return const NoChildScreen();
    }

    return Skeletonizer(
      enabled: appVm.loading,
      enableSwitchAnimation: true,
      child: _buildMain(context, appVm),
    );
  }

  Widget _buildMain(BuildContext context, AppManagementVM appVm) {
    final apps = context.watch<AppManagementVM>().apps;
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final horizontalPadding = context.adaptiveHorizontalPadding(
      compact: 12,
      regular: 18,
    );
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isSkeleton = appVm.loading;

    final displayApps = isSkeleton && apps.isEmpty
        ? List.generate(
            6,
            (index) => AppItemModel(
              packageName: 'skeleton_$index',
              name: 'Loading app',
              iconBase64: null,
              usageTime: '0h 0m',
              lastSeen: null,
              dailyLimitMinutes: 0,
            ),
          )
        : apps;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // 🔵 Header + Carousel (background xanh)
            Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                screenHeight < 700 ? 44 : 50,
                horizontalPadding,
                16, // 👈 khoảng cách với carousel
              ),
              decoration: BoxDecoration(
                color: scheme.primary,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    children: [
                      if (isSkeleton)
                        SizedBox(
                          width: 24,
                          height: 24,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.all(
                                Radius.circular(12),
                              ),
                              color: scheme.outlineVariant.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                        )
                      else
                        SvgPicture.asset(
                          'assets/icons/icon_setting.svg',
                          width: 24,
                          height: 24,
                          colorFilter: const ColorFilter.mode(
                            Colors.white,
                            BlendMode.srcIn,
                          ),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        l10n.parentDashboardTitle,
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontSize: Theme.of(
                            context,
                          ).appTypography.screenTitle.fontSize,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 👇 Carousel
                  Center(
                    child: UserCarouselCard(
                      currentIndex: _currentTabIndex,
                      onTapApps: () => _goTab(0),
                      onTapStats: () => _goTab(1),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // 🔽 Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    RefreshIndicator(
                      color: scheme.primary,
                      backgroundColor: scheme.surface,
                      onRefresh: _reloadApps,
                      child: SingleChildScrollView(
                        physics: AppScrollEffects.physics,
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Column(
                          children: [
                            ...displayApps.asMap().entries.map((entry) {
                              final index = entry.key;
                              final app = entry.value;

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: AppScrollReveal(
                                  index: index,
                                  child: AppItem(
                                    key: ValueKey(app.packageName),
                                    app: app,
                                    usageTimeText: app.usageTime ?? "0h 0m",
                                    onTap: () => openUsageTimeEdit(
                                      context: context,
                                      app: app,
                                      onUpdated: _reloadApps,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    StatisticsTab(
                      vm: appVm,
                      apps: apps,
                      onRefresh: _reloadApps,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
