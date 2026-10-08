import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import 'balyn_shader_system.dart';

class FinanceTrendPoint {
  const FinanceTrendPoint({
    required this.date,
    required this.primary,
    required this.secondary,
  });

  final DateTime date;
  final double primary;
  final double secondary;
}

class FinanceDonutSegment {
  const FinanceDonutSegment({
    required this.label,
    required this.value,
    required this.color,
    this.icon,
  });

  final String label;
  final double value;
  final Color color;
  final IconData? icon;
}

/// Shared dual-series chart used by the analytics surfaces.
///
/// The chart intentionally keeps the visual language light: no enclosing card,
/// a quiet grid, curved lines, a soft area fill and touch-first tooltips.
class FinanceTrendChart extends StatelessWidget {
  const FinanceTrendChart({
    required this.points,
    required this.primaryLabel,
    required this.secondaryLabel,
    required this.primaryColor,
    required this.secondaryColor,
    required this.valueFormatter,
    this.height = 220,
    this.showLegend = true,
    super.key,
  });

  final List<FinanceTrendPoint> points;
  final String primaryLabel;
  final String secondaryLabel;
  final Color primaryColor;
  final Color secondaryColor;
  final String Function(double value) valueFormatter;
  final double height;
  final bool showLegend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Servono più dati per disegnare il grafico',
            style: theme.textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final values = <double>[
      ...points.map((item) => item.primary),
      ...points.map((item) => item.secondary),
    ];
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    if (minY == maxY) {
      final padding = minY == 0 ? 1.0 : minY.abs() * .12;
      minY -= padding;
      maxY += padding;
    } else {
      final padding = (maxY - minY) * .10;
      minY = math.min(0, minY - padding);
      maxY += padding;
    }

    final totalDays =
        points.last.date.difference(points.first.date).inDays.abs() + 1;
    final labelStep = math.max(1, (points.length / 4).ceil());

    Widget bottomTitle(double value, TitleMeta meta) {
      final index = value.round();
      if (index < 0 ||
          index >= points.length ||
          (index % labelStep != 0 && index != points.length - 1)) {
        return const SizedBox.shrink();
      }
      final format = totalDays > 120
          ? DateFormat('MMM', AppI18n.intlLocale)
          : totalDays > 31
          ? DateFormat('d MMM', AppI18n.intlLocale)
          : DateFormat('d MMM', AppI18n.intlLocale);
      return SideTitleWidget(
        meta: meta,
        space: 8,
        child: Text(
          format.format(points[index].date),
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    final grid = theme.colorScheme.onSurface.withValues(
      alpha: theme.brightness == Brightness.dark ? .10 : .07,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLegend) ...[
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _LegendDot(label: primaryLabel, color: primaryColor),
              _LegendDot(label: secondaryLabel, color: secondaryColor),
            ],
          ),
          const SizedBox(height: 14),
        ],
        SizedBox(
          height: height,
          child: BalynShaderMotionBuilder(
            builder: (context, shaderPhase, shaderEnabled) => LineChart(
              LineChartData(
                minX: 0,
                maxX: (points.length - 1).toDouble(),
                minY: minY,
                maxY: maxY,
                clipData: const FlClipData.all(),
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: (maxY - minY) / 4,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: grid,
                    strokeWidth: 1,
                    dashArray: const [3, 7],
                  ),
                ),
                extraLinesData: ExtraLinesData(
                  horizontalLines: minY <= 0 && maxY >= 0
                      ? [
                          HorizontalLine(
                            y: 0,
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: .16,
                            ),
                            strokeWidth: 1.2,
                          ),
                        ]
                      : const [],
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 34,
                      interval: 1,
                      getTitlesWidget: bottomTitle,
                    ),
                  ),
                ),
                lineTouchData: LineTouchData(
                  enabled: true,
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (spots) {
                      if (spots.isEmpty) return const [];
                      final index = spots.first.x
                          .round()
                          .clamp(0, points.length - 1)
                          .toInt();
                      final date = DateFormat(
                        'd MMM',
                        AppI18n.intlLocale,
                      ).format(points[index].date);
                      return [
                        for (var i = 0; i < spots.length; i++)
                          LineTooltipItem(
                            i == 0 ? '$date\n' : '',
                            theme.textTheme.labelMedium!.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                            ),
                            children: [
                              TextSpan(
                                text:
                                    '${i == 0 ? primaryLabel : secondaryLabel}: ${valueFormatter(spots[i].y)}',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                      ];
                    },
                  ),
                  getTouchedSpotIndicator: (barData, indexes) => [
                    for (final _ in indexes)
                      TouchedSpotIndicatorData(
                        FlLine(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: .20,
                          ),
                          strokeWidth: 1,
                          dashArray: const [3, 4],
                        ),
                        FlDotData(
                          getDotPainter: (spot, percent, bar, itemIndex) =>
                              FlDotCirclePainter(
                                radius: 4,
                                color: theme.colorScheme.onSurface,
                                strokeWidth: 2,
                                strokeColor: theme.colorScheme.surface,
                              ),
                        ),
                      ),
                  ],
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].primary),
                    ],
                    isCurved: true,
                    curveSmoothness: .18,
                    color: shaderEnabled ? null : primaryColor,
                    gradient: shaderEnabled
                        ? balynAnimatedGradient(primaryColor, shaderPhase)
                        : null,
                    barWidth: 2.6,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: shaderEnabled
                          ? null
                          : primaryColor.withValues(alpha: .08),
                      gradient: shaderEnabled
                          ? balynAnimatedGradient(
                              primaryColor,
                              shaderPhase,
                              opacity: .08,
                            )
                          : null,
                    ),
                  ),
                  LineChartBarData(
                    spots: [
                      for (var i = 0; i < points.length; i++)
                        FlSpot(i.toDouble(), points[i].secondary),
                    ],
                    isCurved: true,
                    curveSmoothness: .18,
                    color: shaderEnabled ? null : secondaryColor,
                    gradient: shaderEnabled
                        ? balynAnimatedGradient(secondaryColor, shaderPhase)
                        : null,
                    barWidth: 2,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
              duration: const Duration(milliseconds: 480),
              curve: Curves.easeOutCubic,
            ),
          ),
        ),
      ],
    );
  }
}

class FinanceDonutChart extends StatefulWidget {
  const FinanceDonutChart({
    required this.segments,
    required this.centerLabel,
    required this.centerValue,
    required this.valueFormatter,
    this.size = 210,
    super.key,
  });

  final List<FinanceDonutSegment> segments;
  final String centerLabel;
  final String centerValue;
  final String Function(double value) valueFormatter;
  final double size;

  @override
  State<FinanceDonutChart> createState() => _FinanceDonutChartState();
}

class _FinanceDonutChartState extends State<FinanceDonutChart> {
  int _selected = -1;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = widget.segments.fold<double>(
      0,
      (sum, item) => sum + item.value.abs(),
    );
    final hasData = total > 0 && widget.segments.isNotEmpty;
    final selected = _selected >= 0 && _selected < widget.segments.length
        ? widget.segments[_selected]
        : null;

    return Column(
      children: [
        SizedBox.square(
          dimension: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              BalynShaderMotionBuilder(
                builder: (context, shaderPhase, shaderEnabled) => PieChart(
                  PieChartData(
                    startDegreeOffset: -90,
                    centerSpaceRadius: widget.size * .31,
                    sectionsSpace: hasData ? 3 : 0,
                    borderData: FlBorderData(show: false),
                    pieTouchData: PieTouchData(
                      enabled: hasData,
                      touchCallback: (event, response) {
                        if (!event.isInterestedForInteractions) return;
                        final next =
                            response?.touchedSection?.touchedSectionIndex ?? -1;
                        if (next < 0 || next >= widget.segments.length) {
                          if (_selected != -1) {
                            setState(() => _selected = -1);
                          }
                          return;
                        }
                        if (event is FlTapUpEvent || event is FlTapDownEvent) {
                          setState(() {
                            _selected = _selected == next ? -1 : next;
                          });
                        }
                      },
                    ),
                    sections: hasData
                        ? [
                            for (var i = 0; i < widget.segments.length; i++)
                              PieChartSectionData(
                                color: shaderEnabled
                                    ? null
                                    : widget.segments[i].color.withValues(
                                        alpha: _selected == -1 || _selected == i
                                            ? 1
                                            : .22,
                                      ),
                                gradient: shaderEnabled
                                    ? balynAnimatedGradient(
                                        widget.segments[i].color,
                                        shaderPhase,
                                        opacity:
                                            _selected == -1 || _selected == i
                                            ? 1
                                            : .22,
                                      )
                                    : null,
                                value: widget.segments[i].value.abs(),
                                title: '',
                                showTitle: false,
                                radius:
                                    widget.size *
                                    (_selected == i ? .155 : .132),
                              ),
                          ]
                        : [
                            PieChartSectionData(
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: .10,
                              ),
                              value: 1,
                              title: '',
                              showTitle: false,
                              radius: widget.size * .132,
                            ),
                          ],
                  ),
                  duration: const Duration(milliseconds: 360),
                  curve: Curves.easeOutCubic,
                ),
              ),
              IgnorePointer(
                child: Container(
                  width: widget.size * .62,
                  height: widget.size * .62,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOutCubic,
                child: selected == null
                    ? _DonutCenter(
                        key: const ValueKey('total'),
                        label: widget.centerLabel,
                        value: widget.centerValue,
                      )
                    : _DonutCenter(
                        key: ValueKey(_selected),
                        label: selected.label,
                        value: widget.valueFormatter(selected.value),
                        color: selected.color,
                        detail: total <= 0
                            ? null
                            : '${(selected.value.abs() / total * 100).round()}%',
                      ),
              ),
            ],
          ),
        ),
        if (hasData) ...[
          const SizedBox(height: 14),
          Wrap(
            spacing: 14,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < widget.segments.length; i++)
                InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: () => setState(() {
                    _selected = _selected == i ? -1 : i;
                  }),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 4,
                    ),
                    child: _LegendDot(
                      label: widget.segments[i].label,
                      color: widget.segments[i].color,
                      selected: _selected == i,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class FinanceSparkline extends StatelessWidget {
  const FinanceSparkline({
    required this.values,
    required this.color,
    this.height = 72,
    super.key,
  });

  final List<double> values;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (values.length < 2) return const SizedBox.shrink();
    var minY = values.reduce(math.min);
    var maxY = values.reduce(math.max);
    if (minY == maxY) {
      minY -= 1;
      maxY += 1;
    }

    return SizedBox(
      height: height,
      child: BalynShaderMotionBuilder(
        builder: (context, shaderPhase, shaderEnabled) => LineChart(
          LineChartData(
            minY: minY,
            maxY: maxY,
            titlesData: const FlTitlesData(show: false),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
            lineTouchData: const LineTouchData(enabled: false),
            lineBarsData: [
              LineChartBarData(
                spots: [
                  for (var i = 0; i < values.length; i++)
                    FlSpot(i.toDouble(), values[i]),
                ],
                isCurved: true,
                curveSmoothness: .18,
                barWidth: 2.4,
                color: shaderEnabled ? null : color,
                gradient: shaderEnabled
                    ? balynAnimatedGradient(color, shaderPhase)
                    : null,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: shaderEnabled ? null : color.withValues(alpha: .08),
                  gradient: shaderEnabled
                      ? balynAnimatedGradient(color, shaderPhase, opacity: .08)
                      : null,
                ),
              ),
            ],
          ),
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutCubic,
        ),
      ),
    );
  }
}

class _DonutCenter extends StatelessWidget {
  const _DonutCenter({
    required this.label,
    required this.value,
    this.color,
    this.detail,
    super.key,
  });

  final String label;
  final String value;
  final Color? color;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 108),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          color == null
              ? Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w800,
                  ),
                )
              : BalynShaderText(
                  label,
                  seed: color!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: color == null
                ? Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  )
                : BalynShaderText(
                    value,
                    seed: color!,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
          ),
          if (detail != null)
            Text(
              detail!,
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.color,
    this.selected = false,
  });

  final String label;
  final Color color;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedDefaultTextStyle(
      duration: const Duration(milliseconds: 180),
      style: theme.textTheme.labelMedium!.copyWith(
        color: selected
            ? theme.colorScheme.onSurface
            : theme.colorScheme.onSurfaceVariant,
        fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BalynShaderInk(
            seed: color,
            feature: BalynShaderFeature.chart,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: selected ? 10 : 8,
              height: selected ? 10 : 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: .18,
                          ),
                          blurRadius: 8,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(label),
        ],
      ),
    );
  }
}
