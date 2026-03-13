import 'package:flutter/material.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/statical_utils.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/views/parent/dashboard/statical_widget.dart';
import 'package:kid_manager/widgets/parent/app_item.dart';

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
  final ScrollController _chartScrollController = ScrollController();
  bool showAll = false;

  int activeIndex = 0;
  int _lastUsageVersion = -1;
  int? selectedBarIndex;

  DateTime? fromDate;
  DateTime? toDate;

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

  // ===== TODAY =====
    if (activeIndex == 0) {
      final today = DateTime(now.year, now.month, now.day);
      return appMap.entries
          .where((e) => sameDay(e.key, today))
          .fold(0, (sum, e) => sum + e.value);
    }

  // ===== WEEK =====
    if (activeIndex == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final end = start.add(const Duration(days: 6));

      return appMap.entries
          .where((e) {
            final d = DateTime(e.key.year, e.key.month, e.key.day);
            return !d.isBefore(start) && !d.isAfter(end);
          })
          .fold(0, (sum, e) => sum + e.value);
    }

  // ===== RANGE =====
    if (activeIndex == 2 && fromDate != null && toDate != null) {
      final start = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
      final end = DateTime(toDate!.year, toDate!.month, toDate!.day);

      return appMap.entries
          .where((e) {
            final d = DateTime(e.key.year, e.key.month, e.key.day);
            return !d.isBefore(start) && !d.isAfter(end);
          })
          .fold(0, (sum, e) => sum + e.value);
    }

    return 0;
  }

  int get totalMinutes {
    if (chartBars.isEmpty) return 0;
    return chartBars.fold(0, (sum, e) => sum + e.minutes);
  }

  @override
  void initState() {
    super.initState();

    _chartScrollController.addListener(() {
      if (selectedBarIndex != null) {
        setState(() {});
      }
    });

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

  ChartMode _resolveMode() {
    if (activeIndex == 0) return ChartMode.today;
    if (activeIndex == 1) return ChartMode.week;

    // activeIndex == 2
    return ChartMode.range;
  }

  void _buildChart() {
    final mode = _resolveMode();
    final points = ChartDataHelper.generate(
      mode: mode,
      usageMap: widget.vm.usageMap,
      fromDate: fromDate,
      toDate: toDate,
    );

    chartBars = ChartUiBuilder.build(points, mode);
  }

  void _updateRange(DateTime? a, DateTime? b) {
    // 🟡 Case: user chọn START mới
    if (a != null && b == null) {
      setState(() {
        fromDate = a;
        toDate = null; // reset range cũ
      });

      // debugPrint("🟡 NEW START");
      // debugPrint("FROM: $fromDate");
      // debugPrint("TO  : $toDate");

      return;
    }

    // 🟢 Case: đủ range → normalize
    if (a != null && b != null) {
      DateTime start;
      DateTime end;

      if (a.isBefore(b)) {
        start = a;
        end = b;
      } else {
        start = b;
        end = a;
      }

      setState(() {
        fromDate = start;
        toDate = end;
      });

      _buildChart();
    }
  }

  String _totalTitle(AppLocalizations l10n) {
    switch (activeIndex) {
      case 0:
        return l10n.parentStatsTotalToday;
      case 1:
        return l10n.parentStatsTotalThisWeek;
      case 2:
        if (fromDate == null && toDate == null) {
          return l10n.parentStatsSelectRange;
        }
        if (fromDate != null && toDate == null) {
          return l10n.parentStatsSelectEndDate;
        }
        if (fromDate != null && toDate != null) {
          return l10n.parentStatsTotalFromRange(
            formatDateDDMMYYYY(fromDate!),
            formatDateDDMMYYYY(toDate!),
          );
        }
        return l10n.parentStatsSelectRange;
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

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
              buildSegment(l10n.parentStatsSegmentDay, 0),
              buildSegment(l10n.parentStatsSegmentWeek, 1),
              buildSegment(l10n.parentStatsSegmentRange, 2),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: RefreshIndicator(
            onRefresh: widget.onRefresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              children: [
                if (activeIndex == 2) ...[
                  const SizedBox(height: 12),
                  CustomRangeCalendar(
                    fromDate: fromDate,
                    toDate: toDate,
                    onFromChanged: (d) {
                      _updateRange(d, toDate);
                    },
                    onToChanged: (d) {
                      _updateRange(fromDate, d);
                    },
                  ),
                ],
                const SizedBox(height: 16),
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
                                _totalTitle(l10n),
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontFamily: 'Inter',
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.6,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatMinutes(totalMinutes),
                                style: const TextStyle(
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
                              barWidth = 40;
                            }

                            return Stack(
                              clipBehavior: Clip.none,
                              children: [
                                /// SCROLL BARS
                                SingleChildScrollView(
                                  controller: _chartScrollController,
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
                                if (selectedBarIndex != null &&
                                    selectedBarIndex! < chartBars.length)
                                  Positioned(
                                    left:
                                        selectedBarIndex! * (barWidth + 12) -
                                        _chartScrollController.offset +
                                        6,
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
                        l10n.parentStatsAppDetailsTitle,
                        style: const TextStyle(
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
                          showAll
                              ? l10n.parentStatsCollapse
                              : l10n.parentStatsViewAll,
                          style: const TextStyle(
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
                ...visibleApps.map((app) {
                  final minutes = getUsageForApp(app.packageName);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppItem(
                      key: ValueKey('stats_${app.packageName}'),
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
        behavior: HitTestBehavior.opaque,
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
