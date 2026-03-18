import 'dart:math';

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
  int? selectedDotIndex;
  DateTime? fromDate;
  DateTime? toDate;
  late List<double> randomHeights;

  List<_UsageAppRow> get sortedUsageApps {
    if (activeIndex == 0) {
      final rows = widget.apps
          .map(
            (app) => _UsageAppRow(
              app: app,
              minutes: parseUsageTimeToMinutes(app.usageTime),
            ),
          )
          .toList();

      rows.sort((a, b) {
        final byUsage = b.minutes.compareTo(a.minutes);
        if (byUsage != 0) return byUsage;
        return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
      });

      return rows;
    }

    final appsByPackage = <String, AppItemModel>{
      for (final app in widget.apps) app.packageName: app,
    };
    final rows = <_UsageAppRow>[];
    final addedPackages = <String>{};

    for (final entry in widget.vm.appUsageMap.entries) {
      final pkg = entry.key;
      final minutes = getUsageForApp(pkg);

      // debugPrint("DATE: ${entry.key} VALUE: ${entry.value}");

      if (minutes <= 0) continue;

      final app =
          appsByPackage[pkg] ??
          AppItemModel(packageName: pkg, name: pkg, iconBase64: null);

      rows.add(_UsageAppRow(app: app, minutes: minutes));
      addedPackages.add(pkg);
    }

    for (final app in widget.apps) {
      if (addedPackages.contains(app.packageName)) continue;

      final minutes = getUsageForApp(app.packageName);
      if (minutes <= 0) continue;

      rows.add(_UsageAppRow(app: app, minutes: minutes));
    }

    if (rows.isEmpty) {
      for (final app in widget.apps) {
        rows.add(
          _UsageAppRow(app: app, minutes: getUsageForApp(app.packageName)),
        );
      }
    }

    rows.sort((a, b) {
      final byUsage = b.minutes.compareTo(a.minutes);
      if (byUsage != 0) return byUsage;
      return a.app.name.toLowerCase().compareTo(b.app.name.toLowerCase());
    });

    return rows;
  }

  List<_UsageAppRow> get visibleUsageApps =>
      showAll ? sortedUsageApps : sortedUsageApps.take(5).toList();

  int getUsageForApp(String package) {
    Map<DateTime, int>? appMap = widget.vm.appUsageMap[package];

    if (appMap == null) {
      final normalizedPackage = package.trim().toLowerCase();
      for (final entry in widget.vm.appUsageMap.entries) {
        if (entry.key.trim().toLowerCase() == normalizedPackage) {
          appMap = entry.value;
          break;
        }
      }
    }

    if (appMap == null) return 0;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // ===== TODAY =====
    if (activeIndex == 0) {
      return _sumUsageInDateRange(appMap, today, today);
    }

    // ===== WEEK =====
    if (activeIndex == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      // Week mode should not include future dates.
      final endOfWeek = start.add(const Duration(days: 6));
      final end = endOfWeek.isAfter(today) ? today : endOfWeek;

      return _sumUsageInDateRange(appMap, start, end);
    }

    // ===== RANGE =====
    if (activeIndex == 2 && fromDate != null && toDate != null) {
      final a = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
      final b = DateTime(toDate!.year, toDate!.month, toDate!.day);

      final start = a.isBefore(b) ? a : b;
      final end = a.isBefore(b) ? b : a;

      return _sumUsageInDateRange(appMap, start, end);
    }

    return 0;
  }

  int _sumUsageInDateRange(
    Map<DateTime, int> appMap,
    DateTime start,
    DateTime end,
  ) {
    return appMap.entries
        .where((e) {
          final d = DateTime(e.key.year, e.key.month, e.key.day);
          return !d.isBefore(start) && !d.isAfter(end);
        })
        .fold(0, (sum, e) => sum + e.value);
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
      hourlyMap: widget.vm.hourlyUsage,
      fromDate: fromDate,
      toDate: toDate,
    );

    chartBars = ChartUiBuilder.build(points, mode);

    final random = Random();

    randomHeights = chartBars.map((bar) {
      if (bar.minutes == 0) {
        return 40 + random.nextDouble() * (150 - 40);
      }
      return 0.0;
    }).toList();
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
                        child: _resolveMode() == ChartMode.today
                            ? _buildLineChart()
                            : _buildBarChart(),
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

                /// List apps
                ...visibleUsageApps.map((row) {
                  final app = row.app;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: AppItem(
                      key: ValueKey('stats_${app.packageName}'),
                      appName: app.name,
                      app: app,
                      usageTimeText: formatMinutes(row.minutes),
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

  Widget _buildLineChart() {
    final maxMinutes = chartBars.fold<int>(
      0,
      (m, e) => e.minutes > m ? e.minutes : m,
    );

    const stepX = 40.0;
    final chartWidth = chartBars.length * stepX;

    return SingleChildScrollView(
      controller: _chartScrollController,
      scrollDirection: Axis.horizontal,
      child: SizedBox(
        width: chartWidth,
        height: 220,
        child: GestureDetector(
          onTapDown: (details) {
            final index = (details.localPosition.dx / stepX).round();

            if (index >= 0 && index < chartBars.length) {
              setState(() {
                selectedDotIndex = index;
              });
            }
          },
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(chartWidth, 200),
                painter: _LineChartPainter(
                  bars: chartBars,
                  maxMinutes: maxMinutes,
                  selectedIndex: selectedDotIndex,
                ),
              ),

              if (selectedDotIndex != null) _buildDotTooltip(stepX, chartWidth),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDotTooltip(double stepX, double chartWidth) {
    final bar = chartBars[selectedDotIndex!];

    final maxMinutes = chartBars.fold<int>(
      0,
      (m, e) => e.minutes > m ? e.minutes : m,
    );

    final x = selectedDotIndex! * stepX;

    final normalized = maxMinutes == 0 ? 0 : bar.minutes / maxMinutes;
    final y = 200 - (normalized * 200);

    const tooltipHeight = 40;
    const tooltipWidth = 60;

    final showRight = y - tooltipHeight < 0;

    final clampedLeft = (showRight ? x + 8 : x - tooltipWidth / 2)
        .clamp(0.0, chartWidth - tooltipWidth)
        .toDouble();

    final top = (y - tooltipHeight + 20)
        .clamp(0.0, 200 - tooltipHeight)
        .toDouble();

    return Positioned(
      left: clampedLeft,
      top: top,
      child: TooltipWidget(value: bar.minutes),
    );
  }

  Widget _buildBarChart() {
    const maxChartHeight = 150.0;

    final maxMinutes = chartBars.isEmpty
        ? 0
        : chartBars.map((e) => e.minutes).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = chartBars.length;

        double barWidth;

        if (count <= 7) {
          barWidth = (constraints.maxWidth / count) - 12;
        } else {
          barWidth = 40;
        }

        return SingleChildScrollView(
          controller: _chartScrollController,
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(chartBars.length, (i) {
              final bar = chartBars[i];

              /// chiều cao cột xám
              double greyHeight;

              if (bar.minutes == 0) {
                greyHeight = randomHeights[i];
              } else {
                greyHeight = (bar.minutes / maxMinutes) * maxChartHeight;
              }

              greyHeight = greyHeight.clamp(40, maxChartHeight);

              /// chiều cao thanh xanh
              double blueHeight = bar.minutes == 0 ? 4 : greyHeight * 0.7;

              final tooltipBottom = (blueHeight + 30).clamp(
                0.0,
                maxChartHeight + 25,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedBarIndex = i;
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      /// BAR
                      BarWidget(
                        width: barWidth,
                        greyHeight: greyHeight,
                        blueHeight: blueHeight,
                        label: bar.label,
                        active: selectedBarIndex == i,
                        faded: bar.isFuture,
                      ),

                      /// TOOLTIP
                      if (selectedBarIndex == i)
                        Positioned(
                          bottom: tooltipBottom.toDouble(),
                          child: TooltipWidget(value: bar.minutes),
                        ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
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

class _LineChartPainter extends CustomPainter {
  final List<ChartBarUi> bars;
  final int maxMinutes;
  final int? selectedIndex;

  _LineChartPainter({
    required this.bars,
    required this.maxMinutes,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = Colors.orange
      ..style = PaintingStyle.fill;

    final path = Path();

    const stepX = 40.0;
    const topPadding = 20.0;
    const bottomPadding = 28.0;

    final chartHeight = size.height - topPadding - bottomPadding;

    for (int i = 0; i < bars.length; i++) {
      final value = bars[i].minutes.toDouble();

      final normalized = maxMinutes == 0 ? 0 : value / maxMinutes;

      final x = i * stepX;
      final y = size.height - bottomPadding - (normalized * chartHeight);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }

      final paint = i == selectedIndex ? selectedPaint : pointPaint;

      canvas.drawCircle(Offset(x, y), 4, paint);

      /// DRAW HOUR LABEL
      final textPainter = TextPainter(
        text: TextSpan(
          text: bars[i].label, // ví dụ "0h", "1h"
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      final labelX = x - textPainter.width / 2;
      final labelY = size.height - 16;

      textPainter.paint(canvas, Offset(labelX, labelY));
    }

    canvas.drawPath(path, linePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class _UsageAppRow {
  final AppItemModel app;
  final int minutes;

  _UsageAppRow({required this.app, required this.minutes});
}
