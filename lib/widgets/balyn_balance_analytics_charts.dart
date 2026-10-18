import 'dart:math' as math;

import 'package:balyn/l10n/localized_material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import 'finance_charts.dart';

/// Balanced paired bars with the clean Statistic screen geometry.
class BalynStatisticBars extends StatelessWidget {
  const BalynStatisticBars({
    required this.points,
    required this.hidden,
    super.key,
  });
  final List<FinanceTrendPoint> points;
  final bool hidden;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const purple = Color(0xFF7522ED);
    final dark = Theme.of(context).brightness == Brightness.dark;
    final maxValue = points.fold<double>(
      0,
      (m, p) => math.max(m, math.max(p.primary, p.secondary)),
    );
    final maxY = math.max(1.0, maxValue * 1.17);
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              minY: 0,
              maxY: maxY,
              borderData: FlBorderData(show: false),
              gridData: FlGridData(
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: scheme.onSurface.withValues(alpha: .08),
                  dashArray: const [4, 6],
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: maxY / 4,
                    getTitlesWidget: (value, meta) => SideTitleWidget(
                      meta: meta,
                      child: Text(
                        hidden
                            ? '••'
                            : value >= 1000
                            ? '${(value / 1000).toStringAsFixed(0)}k'
                            : value.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 10,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      final i = value.toInt();
                      if (i < 0 ||
                          i >= points.length ||
                          i % math.max(1, (points.length / 7).ceil()) != 0) {
                        return const SizedBox.shrink();
                      }
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          DateFormat(
                            'MMM',
                            AppI18n.intlLocale,
                          ).format(points[i].date),
                          style: TextStyle(
                            fontSize: 10,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) =>
                      BarTooltipItem(
                        hidden ? '••••' : rod.toY.toStringAsFixed(2),
                        TextStyle(
                          color: scheme.onSurface,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < points.length; i++)
                  BarChartGroupData(
                    x: i,
                    barsSpace: 4,
                    barRods: [
                      BarChartRodData(
                        toY: math.max(0, points[i].secondary),
                        color: dark
                            ? const Color(0xFFBCA4F8)
                            : const Color(0xFF25103C),
                        width: points.length > 10 ? 7 : 11,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                      BarChartRodData(
                        toY: math.max(0, points[i].primary),
                        color: purple,
                        width: points.length > 10 ? 7 : 11,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
            duration: const Duration(milliseconds: 440),
            curve: Curves.easeOutCubic,
          ),
        ),
        const SizedBox(height: 13),
        const Wrap(
          spacing: 18,
          runSpacing: 8,
          children: [
            _Legend(color: Color(0xFF25103C), label: 'Entrate'),
            _Legend(color: purple, label: 'Spese'),
          ],
        ),
      ],
    );
  }
}

class BalynBalanceDonut extends StatefulWidget {
  const BalynBalanceDonut({
    required this.segments,
    required this.valueFormatter,
    required this.hidden,
    super.key,
  });
  final List<FinanceDonutSegment> segments;
  final String Function(double) valueFormatter;
  final bool hidden;
  @override
  State<BalynBalanceDonut> createState() => _BalynBalanceDonutState();
}

class _BalynBalanceDonutState extends State<BalynBalanceDonut> {
  int selected = 0;
  static const colors = <Color>[
    Color(0xFFFF6B5B),
    Color(0xFFB9AEFF),
    Color(0xFFFFB5D2),
    Color(0xFF7D63E6),
    Color(0xFF7BC9BE),
    Color(0xFFFFC978),
    Color(0xFF8493AD),
  ];

  @override
  Widget build(BuildContext context) {
    final slices = widget.segments.where((s) => s.value > 0).toList();
    final total = slices.fold<double>(0, (s, v) => s + v.value);
    if (slices.isEmpty || total <= 0) {
      return const SizedBox(
        height: 180,
        child: Center(child: Text('Nessun dato nel periodo')),
      );
    }
    final active = selected.clamp(0, slices.length - 1);
    final focused = slices[active];
    final percent = focused.value / total * 100;
    return Column(
      children: [
        SizedBox.square(
          dimension: 240,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 750),
            builder: (context, progress, _) => GestureDetector(
              onTapDown: (details) {
                final local = details.localPosition - const Offset(120, 120);
                var angle = math.atan2(local.dy, local.dx) + math.pi / 2;
                if (angle < 0) angle += math.pi * 2;
                var elapsed = 0.0;
                for (var i = 0; i < slices.length; i++) {
                  elapsed += slices[i].value / total;
                  if (angle / (2 * math.pi) <= elapsed) {
                    setState(() => selected = i);
                    break;
                  }
                }
              },
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size.square(240),
                    painter: _RingPainter(
                      weights: slices.map((x) => x.value).toList(),
                      colors: colors,
                      selected: active,
                      progress: progress,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          '${percent.toStringAsFixed(0)}%',
                          key: ValueKey(active),
                          style: Theme.of(context).textTheme.headlineLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                      Text(
                        focused.label,
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 11),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < slices.length; i++)
              InkWell(
                onTap: () => setState(() => selected = i),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 104,
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: i == active
                        ? colors[i % colors.length].withValues(alpha: .10)
                        : Colors.transparent,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Legend(
                        label: slices[i].label,
                        color: colors[i % colors.length],
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          widget.hidden
                              ? '••••'
                              : widget.valueFormatter(slices[i].value),
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.weights,
    required this.colors,
    required this.selected,
    required this.progress,
  });
  final List<double> weights;
  final List<Color> colors;
  final int selected;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final total = weights.fold<double>(0, (a, b) => a + b);
    canvas.drawCircle(
      center,
      86,
      Paint()
        ..color = const Color(0x20888899)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 27,
    );
    var start = -math.pi / 2;
    for (var i = 0; i < weights.length; i++) {
      final part = weights[i] / total * 2 * math.pi;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: 86),
        start + .028,
        math.max(0, part * progress - .055),
        false,
        Paint()
          ..color = colors[i % colors.length]
          ..strokeCap = StrokeCap.round
          ..strokeWidth = i == selected ? 30 : 25
          ..style = PaintingStyle.stroke,
      );
      start += part;
    }
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.selected != selected ||
      old.progress != progress ||
      old.weights != weights;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 6),
      Flexible(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    ],
  );
}
