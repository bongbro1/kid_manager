import 'dart:math';

import 'package:flutter/material.dart';
import 'package:kid_manager/core/app_theme.dart';
import 'package:kid_manager/core/responsive.dart';
import 'package:kid_manager/l10n/app_localizations.dart';
import 'package:kid_manager/models/app_item_model.dart';
import 'package:kid_manager/utils/date_utils.dart';
import 'package:kid_manager/utils/statical_utils.dart';
import 'package:kid_manager/viewmodels/app_management_vm.dart';
import 'package:kid_manager/views/parent/dashboard/statical_widget.dart';
import 'package:kid_manager/widgets/app/app_scroll_effects.dart';
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
  DateTime? selectedUsageDate;
  DateTime? fromDate;
  DateTime? toDate;
  late List<double> randomHeights;

  DateTime? _dateForBarIndex(int index) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    if (activeIndex == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );

      final date = start.add(Duration(days: index));
      return date.isAfter(today) ? today : date;
    }

    if (activeIndex == 2 && fromDate != null && toDate != null) {
      final a = DateTime(fromDate!.year, fromDate!.month, fromDate!.day);
      final b = DateTime(toDate!.year, toDate!.month, toDate!.day);
      final start = a.isBefore(b) ? a : b;

      return start.add(Duration(days: index));
    }

    return null;
  }

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

    if (selectedUsageDate != null && activeIndex != 0) {
      final d = DateTime(
        selectedUsageDate!.year,
        selectedUsageDate!.month,
        selectedUsageDate!.day,
      );
      return _sumUsageInDateRange(appMap, d, d);
    }

    if (activeIndex == 0) {
      return _sumUsageInDateRange(appMap, today, today);
    }

    if (activeIndex == 1) {
      final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      final start = DateTime(
        startOfWeek.year,
        startOfWeek.month,
        startOfWeek.day,
      );
      final endOfWeek = start.add(const Duration(days: 6));
      final end = endOfWeek.isAfter(today) ? today : endOfWeek;

      return _sumUsageInDateRange(appMap, start, end);
    }

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

    widget.vm.addListener(_onVmChanged);
    _buildChart();
  }

  void _onVmChanged() {
    if (!mounted) return;
    _buildChart(l10n: AppLocalizations.of(context));
    setState(() {});
  }

  @override
  void didUpdateWidget(covariant StatisticsTab oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (_lastUsageVersion != widget.vm.usageVersion) {
      _lastUsageVersion = widget.vm.usageVersion;
      final l10n = AppLocalizations.of(context);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _buildChart(l10n: l10n);
      });
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _buildChart(l10n: AppLocalizations.of(context));
  }

  @override
  void dispose() {
    _chartScrollController.dispose();
    widget.vm.removeListener(_onVmChanged);
    super.dispose();
  }

  ChartMode _resolveMode() {
    if (activeIndex == 0) return ChartMode.today;
    if (activeIndex == 1) return ChartMode.week;

    // activeIndex == 2
    return ChartMode.range;
  }

  void _buildChart({AppLocalizations? l10n}) {
    final mode = _resolveMode();
    final points = ChartDataHelper.generate(
      mode: mode,
      usageMap: widget.vm.usageMap,
      hourlyMap: widget.vm.hourlyUsage,
      fromDate: fromDate,
      toDate: toDate,
      l10n: l10n,
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
        selectedBarIndex = null;
        selectedUsageDate = null;
      });

      _buildChart(l10n: AppLocalizations.of(context));
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isCompactPhone = context.isCompactPhone;
    final chartContainerPadding = isCompactPhone
        ? const EdgeInsets.fromLTRB(16, 20, 16, 24)
        : const EdgeInsets.fromLTRB(24, 24, 24, 32);
    final chartHeight = isCompactPhone ? 180.0 : 200.0;
    final headerHorizontalPadding = isCompactPhone ? 4.0 : 8.0;

    return Column(
      children: [
        const SizedBox(height: 6),

        /// ===== SEGMENT KHÔNG SCROLL =====
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: scheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: scheme.shadow.withValues(alpha: 0.08),
                blurRadius: 2,
                offset: const Offset(0, 1),
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
            child: SingleChildScrollView(
              physics: AppScrollEffects.physics,
              padding: const EdgeInsets.fromLTRB(0, 0, 0, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (activeIndex == 2) ...[
                    const SizedBox(height: 12),
                    AppScrollReveal(
                      index: 0,
                      child: CustomRangeCalendar(
                        fromDate: fromDate,
                        toDate: toDate,
                        onFromChanged: (d) => _updateRange(d, toDate),
                        onToChanged: (d) => _updateRange(fromDate, d),
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),

                  AppScrollReveal(
                    index: 1,
                    child: Container(
                      width: double.infinity,
                      padding: chartContainerPadding,
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: scheme.outline.withValues(alpha: 0.2),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.shadow.withValues(alpha: 0.08),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _totalTitle(l10n),
                                    style: textTheme.labelSmall?.copyWith(
                                      color: scheme.onSurface.withValues(
                                        alpha: 0.6,
                                      ),
                                      fontSize: Theme.of(
                                        context,
                                      ).appTypography.supporting.fontSize!,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.6,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    formatMinutes(totalMinutes, l10n: l10n),
                                    style: textTheme.headlineMedium?.copyWith(
                                      color: scheme.onSurface,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          SizedBox(
                            height: chartHeight,
                            child: _resolveMode() == ChartMode.today
                                ? _buildLineChart(context: context)
                                : _buildBarChart(),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  AppScrollReveal(
                    index: 2,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: headerHorizontalPadding,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.parentStatsAppDetailsTitle,
                            style: textTheme.titleSmall?.copyWith(
                              color: scheme.onSurface,
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
                              style: textTheme.labelSmall?.copyWith(
                                color: scheme.primary,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  ...visibleUsageApps.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    final app = row.app;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: AppScrollReveal(
                        index: index + 3,
                        child: AppItem(
                          key: ValueKey('stats_${app.packageName}'),
                          app: app,
                          usageTimeText: formatMinutes(row.minutes, l10n: l10n),
                          showRightIcon: false,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLineChart({required BuildContext context}) {
    final scheme = Theme.of(context).colorScheme;
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
                  lineColor: scheme.primary,
                  pointColor: scheme.primary,
                  selectedPointColor: scheme.tertiary,
                  labelColor: scheme.onSurface.withValues(alpha: 0.6),
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
    if (chartBars.isEmpty) {
      return const SizedBox.shrink();
    }

    final maxMinutes = chartBars.isEmpty
        ? 0
        : chartBars.map((e) => e.minutes).reduce((a, b) => a > b ? a : b);

    return LayoutBuilder(
      builder: (context, constraints) {
        final count = chartBars.length;
        if (count == 0) {
          return const SizedBox.shrink();
        }

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

              double greyHeight;

              if (bar.minutes == 0) {
                greyHeight = randomHeights[i];
              } else {
                greyHeight = (bar.minutes / maxMinutes) * maxChartHeight;
              }

              greyHeight = greyHeight.clamp(40, maxChartHeight);

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
                      selectedUsageDate = _dateForBarIndex(i);
                    });
                  },
                  child: Stack(
                    clipBehavior: Clip.none,
                    alignment: Alignment.bottomCenter,
                    children: [
                      BarWidget(
                        width: barWidth,
                        greyHeight: greyHeight,
                        blueHeight: blueHeight,
                        label: bar.label,
                        active: selectedBarIndex == i,
                        faded: bar.isFuture,
                      ),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          setState(() {
            activeIndex = index;
            selectedBarIndex = null;
            selectedDotIndex = null;
            selectedUsageDate = null;
            _buildChart(l10n: AppLocalizations.of(context));
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isActive ? scheme.primary.withValues(alpha: 0.12) : null,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelLarge?.copyWith(
              color: isActive ? scheme.primary : scheme.onSurfaceVariant,
              fontSize: Theme.of(context).appTypography.body.fontSize!,
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

  final Color lineColor;
  final Color pointColor;
  final Color selectedPointColor;
  final Color labelColor;

  _LineChartPainter({
    required this.bars,
    required this.maxMinutes,
    this.selectedIndex,
    required this.lineColor,
    required this.pointColor,
    required this.selectedPointColor,
    required this.labelColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (bars.isEmpty) return;

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = pointColor
      ..style = PaintingStyle.fill;

    final selectedPaint = Paint()
      ..color = selectedPointColor
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

      final textPainter = TextPainter(
        text: TextSpan(
          text: bars[i].label,
          style: TextStyle(
            fontSize: 10,
            color: labelColor,
            fontFamily: 'Poppins',
          ),
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
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.bars != bars ||
        oldDelegate.maxMinutes != maxMinutes ||
        oldDelegate.selectedIndex != selectedIndex ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.pointColor != pointColor ||
        oldDelegate.selectedPointColor != selectedPointColor ||
        oldDelegate.labelColor != labelColor;
  }
}

class _UsageAppRow {
  final AppItemModel app;
  final int minutes;

  _UsageAppRow({required this.app, required this.minutes});
}
