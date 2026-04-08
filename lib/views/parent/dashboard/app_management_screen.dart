import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/views/parent/dashboard/no_child_screen.dart';
import 'package:kid_manager/views/parent/dashboard/statistics_tab.dart';
import 'package:kid_manager/views/parent/dashboard/usage_time_edit_screen.dart';
import 'package:kid_manager/views/parent/dashboard/user_carousel_card.dart';
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

  // sau chuyển ra flash screen
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
    final changed = await Navigator.of(context).push<bool>(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.transparent,
        pageBuilder: (_, _, _) => UsageTimeEditScreen(
          appId: app.packageName,
          childId: selectedChildId,
        ),
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
    setState(() {
      _tabController.animateTo(index);
    });
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

    return Container(
      color: theme.scaffoldBackgroundColor,
      child: SafeArea(
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
                          fontWeight: FontWeight.w500,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 14),

                  // 👇 Carousel
                  Center(
                    child: UserCarouselCard(
                      currentIndex: _tabController.index,
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
                  children: [
                    RefreshIndicator(
                      color: scheme.primary,
                      backgroundColor: scheme.surface,
                      onRefresh: _reloadApps,
                      child: ListView.builder(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: apps.length,
                        itemBuilder: (context, index) {
                          final app = apps[index];
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
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
                          );
                        },
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
