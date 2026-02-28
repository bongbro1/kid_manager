import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:kid_manager/models/app_item_model.dart';
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
    int? initialDailyLimitMinutes,
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
        _buildMain(context),

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

  Widget _buildMain(BuildContext context) {
    final apps = context.watch<AppManagementVM>().apps;

    return Container(
      color: const Color(0xFFF2F2F7),
      child: SafeArea(
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

                        const SizedBox(height: 14),
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
                                        editIconAsset: Image.asset(
                                          "assets/images/source_edit.png",
                                          width: 18,
                                          height: 18,
                                          color: const Color(0xFF6B6778),
                                        ),
                                        onTap: () => openUsageTimeEdit(
                                          context: context,
                                          app: app,
                                          initialDailyLimitMinutes: null,
                                          onUpdated: _reloadApps,
                                        ),
                                        onEdit: () => openUsageTimeEdit(
                                          context: context,
                                          app: app,
                                          initialDailyLimitMinutes: null,
                                          onUpdated: _reloadApps,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),

                              // TAB 2
                              const Center(child: Text("heheheheh")),
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
