import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/statical_utils.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/views/parent/dashboard/statical_widget.dart';
import 'package:kid_manager/views/parent/dashboard/usage_time_edit_screen.dart';
import 'package:kid_manager/views/parent/dashboard/user_carousel_card.dart';
import 'package:kid_manager/widgets/common/loading_view.dart';
import 'package:kid_manager/widgets/parent/app_item.dart';
import 'package:provider/provider.dart';

class AppManagementScreen extends StatefulWidget {
  const AppManagementScreen({super.key});

  @override
  State<AppManagementScreen> createState() => _AppManagementScreenState();
}

class _AppManagementScreenState extends State<AppManagementScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  int _tabIndex = 0;

  // sau chuyển ra flash screen
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabIndex = _tabController.index;
    _tabController.addListener(() {
      // chỉ rebuild khi đã đổi tab thật sự
      if (!_tabController.indexIsChanging && mounted) {
        setState(() => _tabIndex = _tabController.index);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await context.read<AppInitVM>().init();
      if (!mounted) return;
      await context.read<AppManagementVM>().loadAppsForSelectedChild();
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
        pageBuilder: (_, __, ___) => UsageTimeEditScreen(
          appId: app.packageName!,
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
    await context.read<AppManagementVM>().loadAppsForSelectedChild();
  }

  void _goTab(int index) {
    _tabController.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final app_vm = context.watch<AppManagementVM>();

    final apps = app_vm.apps;
    return Stack(
      children: [
        // ✅ UI chính của bạn (giữ nguyên)
        _buildMain(context, app_vm),

        // ✅ overlay loading phủ lên toàn bộ
        if (app_vm.loading)
          const Positioned.fill(
            child: AbsorbPointer(
              absorbing: true, // chặn tap/scroll
              child: LoadingOverlay(),
            ),
          ),
      ],
    );
  }

  Widget _buildMain(BuildContext context, AppManagementVM app_vm) {
    final apps = context.watch<AppManagementVM>().apps;

    return Container(
      color: const Color(0xFFF2F2F7),
      child: SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 290,
              decoration: const BoxDecoration(
                color: Color(0xFF3A7DFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
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
                          fontSize: 18,
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w500,
                          height: 1.33,
                          letterSpacing: 0.50,
                        ),
                      ),
                    ],
                  ),
                ),

                // ⭐ quan trọng: cho phần content chiếm phần còn lại
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 18, right: 18),
                    child: Column(
                      children: [
                        const SizedBox(height: 14),
                        Center(
                          child: UserCarouselCard(
                            currentIndex: _tabController.index,
                            onTapApps: () => _goTab(0),
                            onTapStats: () => _goTab(1),
                          ),
                        ),

                        const SizedBox(height: 24),
                        Expanded(
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                              // TAB 1
                              RefreshIndicator(
                                onRefresh: _reloadApps,
                                child: ListView.builder(
                                  padding: const EdgeInsets.only(
                                    top: 0,
                                    bottom: 16,
                                  ),
                                  itemCount: apps.length,
                                  itemBuilder: (context, index) {
                                    final app = apps[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 12,
                                      ),
                                      child: AppItem(
                                        key: ValueKey(app.packageName),
                                        appName: app.name,
                                        app: app,
                                        usageTimeText: app.usageTime ?? "0h 0m",
                                        iconBase64: app.iconBase64,
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

                              // TAB 2
                              StatisticsTab(
                                vm: app_vm,
                                apps: apps,
                                onRefresh: _reloadApps,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
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

class StatisticsTab extends StatefulWidget {
  final AppManagementVM vm;
  final List<AppItemModel> apps;
  final Future<void> Function() onRefresh;

  const StatisticsTab({
    super.key,
    required this.vm,
    required this.apps,
    required this.onRefresh,
  });

  @override
  State<StatisticsTab> createState() => _StatisticsTabState();
}

class _StatisticsTabState extends State<StatisticsTab> {
  late List<ChartBarUi> chartBars;
  bool showAll = false;
  List<AppItemModel> get sortedApps {
    final sorted = [...widget.apps];
    sorted.sort((a, b) {
      final aMin = getUsageForApp(a.packageName);
      final bMin = getUsageForApp(b.packageName);
      return bMin.compareTo(aMin);
    });
    return sorted;
  }

  List<AppItemModel> get visibleApps =>
      showAll ? sortedApps : sortedApps.take(5).toList();

  int getUsageForApp(String package) {
    final appMap = widget.vm.appUsageMap[package];
    if (appMap == null) return 0;

    final now = DateTime.now();

    if (activeIndex == 0) {
      // TODAY
      return appMap.entries
          .where(
            (e) =>
                e.key.year == now.year &&
                e.key.month == now.month &&
                e.key.day == now.day,
          )
          .fold(0, (sum, e) => sum + e.value);
    }

    if (activeIndex == 1) {
      // WEEK
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));

      return appMap.entries
          .where(
            (e) =>
                e.key.isAfter(
                  DateTime(
                    startOfWeek.year,
                    startOfWeek.month,
                    startOfWeek.day,
                  ).subtract(const Duration(seconds: 1)),
                ) &&
                e.key.isBefore(
                  DateTime(
                    now.year,
                    now.month,
                    now.day,
                  ).add(const Duration(days: 1)),
                ),
          )
          .fold(0, (sum, e) => sum + e.value);
    }

    // MONTH
    return appMap.entries
        .where((e) => e.key.year == now.year && e.key.month == now.month)
        .fold(0, (sum, e) => sum + e.value);
  }

  int activeIndex = 0;

  int _lastUsageVersion = -1;

  @override
  void initState() {
    super.initState();
    widget.vm.addListener(_onVmChanged);
    _buildChart();
  }

  void _onVmChanged() {
    _buildChart();
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant StatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_lastUsageVersion != widget.vm.usageVersion) {
      _lastUsageVersion = widget.vm.usageVersion;

      WidgetsBinding.instance.addPostFrameCallback((_) {
        _buildChart();
      });
    }
  }

  @override
  void dispose() {
    widget.vm.removeListener(_onVmChanged);
    super.dispose();
  }

  void _buildChart() {
    final mode = ChartMode.values[activeIndex];

    final points = ChartDataHelper.generate(
      mode: mode,
      usageMap: widget.vm.usageMap,
    );

    chartBars = ChartUiBuilder.build(points, mode);
  }

  int? selectedBarIndex;

  int get totalMinutes {
    if (chartBars.isEmpty) return 0;
    return chartBars.fold(0, (sum, e) => sum + e.minutes);
  }

  String get totalTitle {
    switch (activeIndex) {
      case 0:
        return "TỔNG THỜI GIAN HÔM NAY";
      case 1:
        return "TỔNG THỜI GIAN TUẦN NÀY";
      case 2:
        return "TỔNG THỜI GIAN THÁNG NÀY";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 6),

        /// ===== SEGMENT KHÔNG SCROLL =====
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.8),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0C000000),
                blurRadius: 2,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              buildSegment('Ngày', 0),
              buildSegment('Tuần', 1),
              buildSegment('Tháng', 2),
            ],
          ),
        ),

        const SizedBox(height: 16),

        /// ===== NỘI DUNG SCROLL =====
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x0C000000),
                        blurRadius: 2,
                        offset: Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// HEADER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                totalTitle,
                                style: TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                formatMinutes(totalMinutes),
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 30,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      /// CHART
                      SizedBox(
                        height: 200,
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final count = chartBars.length;

                            double barWidth;

                            if (count <= 7) {
                              // Tuần → fit full
                              barWidth = (constraints.maxWidth / count) - 12;
                            } else {
                              // Ngày + Tháng → scroll
                              barWidth = 20;
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                /// SCROLL BARS
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: List.generate(chartBars.length, (
                                      i,
                                    ) {
                                      final bar = chartBars[i];

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                        ),
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              selectedBarIndex = i;
                                            });
                                          },
                                          child: BarWidget(
                                            width: barWidth,
                                            height: bar.uiHeight,
                                            valueHeight: bar.valueHeight,
                                            label: bar.label,
                                            active: bar.isToday,
                                            faded: bar.isFuture,
                                          ),
                                        ),
                                      );
                                    }),
                                  ),
                                ),

                                /// FLOATING TOOLTIP
                                if (selectedBarIndex != null)
                                  Positioned(
                                    left:
                                        selectedBarIndex! * (barWidth + 12) + 6,
                                    bottom:
                                        chartBars[selectedBarIndex!].uiHeight +
                                        30,
                                    child: TooltipWidget(
                                      value:
                                          chartBars[selectedBarIndex!].minutes,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Chi tiết ứng dụng',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          height: 1.56,
                        ),
                      ),

                      GestureDetector(
                        onTap: () {
                          setState(() => showAll = !showAll);
                        },
                        child: Text(
                          showAll ? 'THU GỌN' : 'XEM TẤT CẢ',
                          style: TextStyle(
                            color: Color(0xFF3B82F6),
                            fontSize: 12,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                /// List apps
                ...visibleApps.map((app) {
                  final minutes = getUsageForApp(app.packageName);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppItem(
                      key: ValueKey("stats_${app.packageName}"),
                      appName: app.name,
                      app: app,
                      usageTimeText: formatMinutes(minutes),
                      iconBase64: app.iconBase64,
                      showRightIcon: false,
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSegment(String text, int index) {
    final isActive = activeIndex == index;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            activeIndex = index;
            _buildChart();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          alignment: Alignment.center,
          decoration: isActive
              ? BoxDecoration(
                  color: const Color(0xFFEFF8FF),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0C000000),
                      blurRadius: 2,
                      offset: Offset(0, 1),
                    ),
                  ],
                )
              : null,
          child: Text(
            text,
            style: TextStyle(
              color: isActive
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF64748B),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w600,
              height: 1.43,
            ),
          ),
        ),
      ),
    );
  }
}
