import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/statical_utils.dart';
import 'package:kid_manager/viewmodels/app_init_vm.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
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
      final aMin = parseUsageTimeToMinutes(a.usageTime);
      final bMin = parseUsageTimeToMinutes(b.usageTime);
      return bMin.compareTo(aMin);
    });
    return sorted;
  }

  List<AppItemModel> get visibleApps => showAll ? sortedApps : sortedApps.take(5).toList();

  int activeIndex = 0;

  @override
  void initState() {
    super.initState();
    _buildChart();
  }

  @override
  void didUpdateWidget(covariant StatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.vm.usageMap != widget.vm.usageMap) {
      _buildChart();
    }
  }

  void _buildChart() {
    final mode = ChartMode.values[activeIndex];

    final points = ChartDataHelper.generate(
      mode: mode,
      usageMap: widget.vm.usageMap,
    );

    chartBars = ChartUiBuilder.build(points, mode);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 16),
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
                            children: const [
                              Text(
                                'TỔNG THỜI GIAN HÔM NAY',
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
                                '4h 45p',
                                style: TextStyle(
                                  color: Color(0xFF1E293B),
                                  fontSize: 30,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),

                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              '-12%',
                              style: TextStyle(
                                color: Color(0xFF16A34A),
                                fontSize: 12,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      /// CHART
                      SizedBox(
                        height: 190,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: chartBars.map((bar) {
                            return _Bar(
                              height: bar.uiHeight,
                              valueHeight: bar.valueHeight,
                              label: bar.label,
                              active: bar.isToday,
                              faded: bar.isFuture,
                            );
                          }).toList(),
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
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppItem(
                      key: ValueKey("stats_${app.packageName}"),
                      appName: app.name,
                      app: app,
                      usageTimeText: app.usageTime ?? "0h 0m",
                      iconBase64: app.iconBase64,
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

class _Bar extends StatelessWidget {
  final double height;
  final double valueHeight;
  final String label;
  final bool active;
  final bool faded;

  const _Bar({
    required this.height,
    required this.valueHeight,
    required this.label,
    this.active = false,
    this.faded = false,
  });

  @override
  Widget build(BuildContext context) {
    final valueColor = active
        ? const Color(0xFF3B82F6)
        : faded
        ? const Color(0xFFE2E8F0)
        : const Color(0x663B82F6);

    final labelColor = active
        ? const Color(0xFF3B82F6)
        : const Color(0xFF94A3B8);

    return SizedBox(
      width: 35,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            height: height,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
            ),
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                height: valueHeight,
                decoration: BoxDecoration(
                  color: valueColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 8),

          Text(
            label,
            style: TextStyle(
              color: labelColor,
              fontSize: 10,
              fontFamily: 'Inter',
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
