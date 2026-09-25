import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/account_context_service.dart';
import '../widgets/account_context_selector.dart';
import '../widgets/ui_helpers.dart';
import 'account_management_screen.dart';
import 'transaction_screens.dart';

enum _AnalyticsPeriod { today, week, month, year, custom }

class AccountContextAnalyticsScreen extends StatefulWidget {
  const AccountContextAnalyticsScreen({
    required this.accountId,
    required this.onAccountChanged,
    super.key,
  });

  final int? accountId;
  final ValueChanged<int?> onAccountChanged;

  @override
  State<AccountContextAnalyticsScreen> createState() =>
      _AccountContextAnalyticsScreenState();
}

class _AccountContextAnalyticsScreenState
    extends State<AccountContextAnalyticsScreen> {
  _AnalyticsPeriod period = _AnalyticsPeriod.month;
  int periodOffset = 0;
  DateTimeRange? custom;

  String _periodLabel(_AnalyticsPeriod item) => switch (item) {
    _AnalyticsPeriod.today => 'Oggi',
    _AnalyticsPeriod.week => 'Settimana',
    _AnalyticsPeriod.month => 'Mese',
    _AnalyticsPeriod.year => 'Anno',
    _AnalyticsPeriod.custom => 'Custom',
  };

  Future<void> _selectPeriod(_AnalyticsPeriod next) async {
    if (next != _AnalyticsPeriod.custom) {
      setState(() {
        period = next;
        periodOffset = 0;
      });
      return;
    }

    final now = DateTime.now();
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: now.add(const Duration(days: 3650)),
      initialDateRange:
          custom ??
          DateTimeRange(
            start: DateTime(now.year, now.month),
            end: now,
          ),
    );
    if (result != null && mounted) {
      setState(() {
        custom = result;
        period = _AnalyticsPeriod.custom;
        periodOffset = 0;
      });
    }
  }

  void _shiftPeriod(int delta) {
    setState(() {
      if (period == _AnalyticsPeriod.custom && custom != null) {
        final days = custom!.end.difference(custom!.start).inDays + 1;
        custom = DateTimeRange(
          start: custom!.start.add(Duration(days: delta * days)),
          end: custom!.end.add(Duration(days: delta * days)),
        );
      } else {
        periodOffset += delta;
      }
    });
  }
  String _visibleRangeLabel(DateTime from, DateTime toExclusive) {
    final now = DateTime.now();
    final end = toExclusive.subtract(const Duration(days: 1));
    final oneDay =
        from.year == end.year &&
        from.month == end.month &&
        from.day == end.day;
    final includeYear = from.year != now.year || end.year != now.year;
    final format = DateFormat(includeYear ? 'd MMM yy' : 'd MMM', 'it_IT');
    if (oneDay) return format.format(from);
    return '${format.format(from)} – ${format.format(end)}';
  }


  (DateTime, DateTime) _bounds(AppState state) {
    final now = DateTime.now();
    switch (period) {
      case _AnalyticsPeriod.today:
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).add(Duration(days: periodOffset));
        return (start, start.add(const Duration(days: 1)));
      case _AnalyticsPeriod.week:
        final startWeekday = state.weekStart.clamp(1, 7);
        final offset = (now.weekday - startWeekday) % 7;
        final currentStart = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: offset));
        final start = currentStart.add(Duration(days: periodOffset * 7));
        return (start, start.add(const Duration(days: 7)));
      case _AnalyticsPeriod.month:
        final day = state.financialMonthStart.clamp(1, 28);
        var currentStart = DateTime(now.year, now.month, day);
        if (now.isBefore(currentStart)) {
          currentStart = DateTime(now.year, now.month - 1, day);
        }
        final start = DateTime(
          currentStart.year,
          currentStart.month + periodOffset,
          day,
        );
        return (start, DateTime(start.year, start.month + 1, day));
      case _AnalyticsPeriod.year:
        final start = DateTime(now.year + periodOffset);
        return (start, DateTime(start.year + 1));
      case _AnalyticsPeriod.custom:
        final range = custom;
        if (range == null) {
          return (
            DateTime(now.year, now.month),
            DateTime(now.year, now.month + 1),
          );
        }
        return (
          DateTime(range.start.year, range.start.month, range.start.day),
          DateTime(range.end.year, range.end.month, range.end.day + 1),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selected = state.accountById(widget.accountId);
    final effectiveAccountId =
        selected == null || selected.isArchived || selected.isSystem
        ? null
        : selected.id;
    final (from, to) = _bounds(state);
    final duration = to.difference(from);
    final previousFrom = from.subtract(duration);
    final income = AccountContextService.periodTotal(
      state,
      effectiveAccountId,
      TransactionType.income,
      from,
      to,
    );
    final expense = AccountContextService.periodTotal(
      state,
      effectiveAccountId,
      TransactionType.expense,
      from,
      to,
    );
    final previousExpense = AccountContextService.periodTotal(
      state,
      effectiveAccountId,
      TransactionType.expense,
      previousFrom,
      from,
    );
    final savingsRate = income <= 0
        ? null
        : ((income - expense) / income * 100);
    final transferNet = effectiveAccountId == null
        ? 0.0
        : AccountContextService.transferNetFor(
            state,
            effectiveAccountId,
            from,
            to,
          );
    final accountVariation = income - expense + transferNet;
    final delta = previousExpense == 0
        ? null
        : (expense - previousExpense) / previousExpense * 100;

    final analytic = AccountContextService.analyticTransactionsFor(
      state,
      effectiveAccountId,
      from: from,
      to: to,
    );
    final categoryTotals = <int, double>{};
    for (final item in analytic.where(
      (t) => t.type == TransactionType.expense,
    )) {
      final splits = state.splitsFor(item.id);
      if (splits.isNotEmpty) {
        for (final split in splits) {
          categoryTotals[split.categoryId] =
              (categoryTotals[split.categoryId] ?? 0) +
              state.analyticsAmountForSplit(item.id, split);
        }
      } else if (item.categoryId != null) {
        categoryTotals[item.categoryId!] =
            (categoryTotals[item.categoryId!] ?? 0) +
            state.effectiveExpense(item);
      }
    }
    final categories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final recurringMonthly =
        AccountContextService.recurringFor(state, effectiveAccountId)
            .where((item) => item.type == TransactionType.expense)
            .fold<double>(0, (sum, item) {
              return sum +
                  switch (item.frequency) {
                    'Settimanale' => item.amount * 52 / 12,
                    'Quindicinale' => item.amount * 26 / 12,
                    'Trimestrale' => item.amount / 3,
                    'Annuale' => item.amount / 12,
                    _ => item.amount,
                  };
            });

    return Scaffold(
      appBar: AppBar(
        title: AccountContextSelector(
          accountId: effectiveAccountId,
          onChanged: widget.onAccountChanged,
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Row(
            children: [
              for (final item in _AnalyticsPeriod.values) ...[
                Expanded(
                  child: _PeriodPill(
                    label: _periodLabel(item),
                    selected: period == item,
                    onTap: () => _selectPeriod(item),
                  ),
                ),
                if (item != _AnalyticsPeriod.values.last)
                  const SizedBox(width: 4),
              ],
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'Entrate',
                  value: moneyFor(state, income),
                  color: context.financeColors.positive,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _Metric(
                  label: 'Spese',
                  value: moneyFor(state, expense),
                  color: context.financeColors.negative,
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: _Metric(
                  label: effectiveAccountId == null
                      ? 'Risparmio'
                      : 'Variazione',
                  value: effectiveAccountId == null
                      ? savingsRate == null
                            ? '—'
                            : '${savingsRate.toStringAsFixed(0)}%'
                      : moneyFor(state, accountVariation, signed: true),
                  color: effectiveAccountId == null
                      ? null
                      : accountVariation < 0
                      ? context.financeColors.negative
                      : context.financeColors.positive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SectionTitle(
            effectiveAccountId == null ? 'Andamento patrimonio' : 'Andamento saldo',
          ),
          const SizedBox(height: 12),
          _BalanceTrend(
            state: state,
            account: effectiveAccountId == null ? null : selected,
            from: from,
            to: to,
            period: period,
            rangeLabel: _visibleRangeLabel(from, to),
            onShiftPeriod: _shiftPeriod,
          ),
          const SizedBox(height: 24),
          _AnalyticsLine(
            icon: delta == null
                ? Icons.horizontal_rule_rounded
                : delta <= 0
                ? Icons.trending_down_rounded
                : Icons.trending_up_rounded,
            text: delta == null
                ? 'Servono più dati per confrontare il periodo precedente.'
                : 'Spese ${delta.abs().toStringAsFixed(0)}% '
                      '${delta <= 0 ? 'più basse' : 'più alte'} del periodo precedente.',
          ),
          if (effectiveAccountId != null) ...[
            const SizedBox(height: 10),
            _AnalyticsLine(
              icon: Icons.swap_horiz_rounded,
              text:
                  'Giroconti netti ${moneyFor(state, transferNet, signed: true)} nel periodo.',
            ),
          ],
          const SizedBox(height: 10),
          _AnalyticsLine(
            icon: Icons.repeat_rounded,
            text:
                'Ricorrenti di spesa ≈ ${moneyFor(state, recurringMonthly)}/mese.',
          ),
          const SizedBox(height: 32),
          const SectionTitle('Dove stai spendendo'),
          if (categories.isEmpty)
            const Text('Nessun dato nel periodo')
          else
            ...categories.take(8).map((entry) {
              final category = state.categoryById(entry.key);
              if (category == null) return const SizedBox.shrink();
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  categoryIcon(category.iconKey),
                  color: Color(category.colorValue),
                ),
                title: Text(category.name),
                subtitle: Text(
                  expense <= 0
                      ? ''
                      : '${(entry.value / expense * 100).toStringAsFixed(0)}% delle spese',
                ),
                trailing: Text(
                  moneyFor(state, entry.value),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => _CategoryPeriodPage(
                      title: category.name,
                      accountId: effectiveAccountId,
                      categoryId: category.id,
                      from: from,
                      to: to,
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 28),
          if (effectiveAccountId == null) ...[
            const SectionTitle('Per conto'),
            ...state.activeAccounts.map(
              (account) => FlatMetric(
                label: account.name,
                value: moneyFor(
                  state,
                  AccountContextService.periodTotal(
                        state,
                        account.id,
                        TransactionType.income,
                        from,
                        to,
                      ) -
                      AccountContextService.periodTotal(
                        state,
                        account.id,
                        TransactionType.expense,
                        from,
                        to,
                      ) +
                      AccountContextService.transferNetFor(
                        state,
                        account.id,
                        from,
                        to,
                      ),
                  signed: true,
                ),
                icon: accountIcon(account.iconKey),
                color: Color(account.colorValue),
                onTap: () => widget.onAccountChanged(account.id),
              ),
            ),
          ] else ...[
            const SectionTitle('Conto selezionato'),
            FlatMetric(
              label: selected!.name,
              value: state.hideBalance
                  ? '••••'
                  : moneyFor(state, selected.balance),
              icon: accountIcon(selected.iconKey),
              color: Color(selected.colorValue),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SafeAccountDetailScreen(accountId: selected.id),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PeriodPill extends StatelessWidget {
  const _PeriodPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected
            ? theme.colorScheme.surfaceContainerHighest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 11),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BalanceTrend extends StatefulWidget {
  const _BalanceTrend({
    required this.state,
    required this.account,
    required this.from,
    required this.to,
    required this.period,
    required this.rangeLabel,
    required this.onShiftPeriod,
  });

  final AppState state;
  final Account? account;
  final DateTime from;
  final DateTime to;
  final _AnalyticsPeriod period;
  final String rangeLabel;
  final ValueChanged<int> onShiftPeriod;

  @override
  State<_BalanceTrend> createState() => _BalanceTrendState();
}

class _BalanceTrendState extends State<_BalanceTrend>
    with SingleTickerProviderStateMixin {
  int? _selectedSpotIndex;
  double? _swipeStartX;
  late final AnimationController _swipeHintController;
  late final Animation<double> _swipeHintAnimation;

  @override
  void initState() {
    super.initState();
    _swipeHintController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _swipeHintAnimation = CurvedAnimation(
      parent: _swipeHintController,
      curve: Curves.easeInOutSine,
    );
  }

  @override
  void dispose() {
    _swipeHintController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _BalanceTrend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from ||
        oldWidget.to != widget.to ||
        oldWidget.account?.id != widget.account?.id ||
        oldWidget.period != widget.period) {
      _selectedSpotIndex = null;
    }
  }

  double _deltaFor(FinanceTransaction item, Set<int> accountIds) {
    var delta = 0.0;
    if (accountIds.contains(item.accountId)) {
      delta += switch (item.type) {
        TransactionType.expense => -item.amount,
        TransactionType.income => item.amount,
        TransactionType.transfer => -item.amount,
      };
    }
    if (item.type == TransactionType.transfer &&
        item.toAccountId != null &&
        accountIds.contains(item.toAccountId)) {
      delta += item.amount;
    }
    return delta;
  }

  double _labelInterval(double maxX) {
    if (widget.period == _AnalyticsPeriod.today) return 1;
    if (widget.period == _AnalyticsPeriod.week) return 1;
    final targetLabels = widget.period == _AnalyticsPeriod.year ? 7 : 6;
    return (maxX / targetLabels)
        .ceilToDouble()
        .clamp(1.0, double.infinity)
        .toDouble();
  }

  String _axisLabel(DateTime date, int durationDays) {
    final from = widget.from;
    final sameMonth = date.month == from.month && date.year == from.year;
    final sameYear = date.year == from.year;

    return switch (widget.period) {
      _AnalyticsPeriod.today => DateFormat('HH', 'it_IT').format(date),
      _AnalyticsPeriod.week => sameMonth
          ? DateFormat('EEE dd', 'it_IT').format(date)
          : sameYear
          ? DateFormat('EEE dd MMM', 'it_IT').format(date)
          : DateFormat('EEE dd MMM yy', 'it_IT').format(date),
      _AnalyticsPeriod.month => sameMonth
          ? DateFormat('dd', 'it_IT').format(date)
          : sameYear
          ? DateFormat('dd MMM', 'it_IT').format(date)
          : DateFormat('dd MMM yy', 'it_IT').format(date),
      _AnalyticsPeriod.year => DateFormat('MMM', 'it_IT').format(date),
      _AnalyticsPeriod.custom =>
        durationDays <= 8
            ? sameMonth
                  ? DateFormat('EEE dd', 'it_IT').format(date)
                  : sameYear
                  ? DateFormat('EEE dd MMM', 'it_IT').format(date)
                  : DateFormat('EEE dd MMM yy', 'it_IT').format(date)
            : durationDays <= 70
            ? sameMonth
                  ? DateFormat('dd', 'it_IT').format(date)
                  : sameYear
                  ? DateFormat('dd MMM', 'it_IT').format(date)
                  : DateFormat('dd MMM yy', 'it_IT').format(date)
            : DateFormat('MMM yy', 'it_IT').format(date),
    };
  }

  String _axisValue(double value) {
    if (widget.state.hideBalance || (widget.account?.hideBalance ?? false)) {
      return '••';
    }
    return NumberFormat.compact(locale: 'it_IT').format(value);
  }

  double _niceStep(double raw) {
    if (!raw.isFinite || raw <= 0) return 1;
    final exponent = math
        .pow(10, (math.log(raw) / math.ln10).floor())
        .toDouble();
    final fraction = raw / exponent;
    final niceFraction = fraction <= 1
        ? 1.0
        : fraction <= 2
        ? 2.0
        : fraction <= 2.5
        ? 2.5
        : fraction <= 5
        ? 5.0
        : 10.0;
    return niceFraction * exponent;
  }

  (double, double, double) _yScale(List<FlSpot> spots) {
    var minValue = spots.first.y;
    var maxValue = spots.first.y;
    for (final spot in spots.skip(1)) {
      if (spot.y < minValue) minValue = spot.y;
      if (spot.y > maxValue) maxValue = spot.y;
    }

    final spread = (maxValue - minValue).abs();
    final rawStep = spread < .0001
        ? math.max(1.0, maxValue.abs() * .05).toDouble()
        : spread / 4;
    final step = _niceStep(rawStep);
    var minY = (minValue / step).floorToDouble() * step;
    var maxY = (maxValue / step).ceilToDouble() * step;

    if ((minY - minValue).abs() < .0001) minY -= step;
    if ((maxY - maxValue).abs() < .0001) maxY += step;
    if ((maxY - minY).abs() < step * 2) {
      minY -= step;
      maxY += step;
    }
    return (minY, maxY, step);
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final account = widget.account;
    final from = widget.from;
    final to = widget.to;
    final theme = Theme.of(context);
    final scopeAccounts = account == null
        ? state.accounts
              .where(
                (item) =>
                    !item.isSystem &&
                    !item.isArchived &&
                    item.includeInTotal,
              )
              .toList(growable: false)
        : [account];
    final accountIds = scopeAccounts.map((item) => item.id).toSet();

    final items = state.transactions.toList()
      ..sort((a, b) {
        final byDate = a.date.compareTo(b.date);
        return byDate != 0 ? byDate : a.id.compareTo(b.id);
      });

    var value = scopeAccounts.fold<double>(
      0,
      (sum, item) => sum + item.openingBalance,
    );
    for (final item in items) {
      if (!item.date.isBefore(from)) break;
      value += _deltaFor(item, accountIds);
    }
    final startValue = value;

    final periodItems = items
        .where((item) => !item.date.isBefore(from) && item.date.isBefore(to))
        .toList(growable: false);
    final durationDays = to.difference(from).inDays.clamp(1, 10000).toInt();
    final isToday = widget.period == _AnalyticsPeriod.today;
    final spots = <FlSpot>[];
    final spotDates = <DateTime>[];
    final movementHours = <int>{};

    if (isToday) {
      // A balance is continuous through the day: start from midnight, keep
      // the previous balance until a movement happens, jump at that exact
      // time, then keep the final value all the way to 24:00.
      spots.add(FlSpot(0, value));
      spotDates.add(from);
      for (final item in periodItems) {
        final delta = _deltaFor(item, accountIds);
        if (delta == 0) continue;
        final minutes = item.date.difference(from).inMinutes;
        final x = (minutes / 60).clamp(0.0, 24.0).toDouble();

        if (spots.last.x != x || spots.last.y != value) {
          spots.add(FlSpot(x, value));
          spotDates.add(item.date);
        }

        value += delta;
        spots.add(FlSpot(x, value));
        spotDates.add(item.date);
        movementHours.add(item.date.hour);
      }

      if (spots.last.x < 24) {
        spots.add(FlSpot(24, value));
        spotDates.add(to);
      }
    } else {
      var itemIndex = items.indexWhere((item) => !item.date.isBefore(from));
      if (itemIndex < 0) itemIndex = items.length;
      for (var day = 0; day < durationDays; day++) {
        final nextDay = from.add(Duration(days: day + 1));
        while (
            itemIndex < items.length &&
            items[itemIndex].date.isBefore(nextDay)) {
          value += _deltaFor(items[itemIndex], accountIds);
          itemIndex++;
        }
        spots.add(FlSpot(day.toDouble(), value));
        spotDates.add(from.add(Duration(days: day)));
      }
    }

    final finalValue = value;
    final chartMaxX = isToday
        ? 24.0
        : math.max(1.0, (durationDays - 1).toDouble()).toDouble();
    final xInterval = isToday ? 1.0 : _labelInterval(chartMaxX);
    final (chartMin, chartMax, yInterval) = _yScale(spots);
    final lineColor = account == null
        ? theme.colorScheme.onSurfaceVariant
        : Color(account.colorValue);
    final hideValues = state.hideBalance || (account?.hideBalance ?? false);

    final selectedSpotIndex =
        _selectedSpotIndex != null &&
            _selectedSpotIndex! >= 0 &&
            _selectedSpotIndex! < spots.length
        ? _selectedSpotIndex
        : null;
    final selectedDate = selectedSpotIndex == null
        ? null
        : spotDates[selectedSpotIndex];
    final selectedBalance = selectedSpotIndex == null
        ? null
        : spots[selectedSpotIndex].y;
    final selectedSpot = selectedSpotIndex == null
        ? null
        : spots[selectedSpotIndex];

    bool showTodayHour(double axisValue) {
      final hour = axisValue.round();
      if ((axisValue - hour).abs() > .01 || hour < 0 || hour > 24) {
        return false;
      }
      if (hour == 0 || hour == 6 || hour == 12 || hour == 18 || hour == 24) {
        return true;
      }
      return movementHours.contains(hour);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: _AnalyticsPeriodNavigator(
            label: widget.rangeLabel,
            animation: _swipeHintAnimation,
            onPrevious: () => widget.onShiftPeriod(-1),
            onNext: () => widget.onShiftPeriod(1),
          ),
        ),
        const SizedBox(height: 4),
        OverflowBox(
          alignment: Alignment.center,
          minWidth: MediaQuery.sizeOf(context).width - 4,
          maxWidth: MediaQuery.sizeOf(context).width - 4,
          child: SizedBox(
            height: 224,
            child: Semantics(
            label: account == null
                ? 'Andamento del patrimonio nel periodo selezionato'
                : 'Andamento del saldo di ${account.name} nel periodo selezionato',
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (event) => _swipeStartX = event.position.dx,
              onPointerCancel: (_) => _swipeStartX = null,
              onPointerUp: (event) {
                final startX = _swipeStartX;
                _swipeStartX = null;
                if (startX == null) return;
                final deltaX = event.position.dx - startX;
                if (deltaX.abs() < 48) return;
                widget.onShiftPeriod(deltaX < 0 ? 1 : -1);
              },
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: chartMaxX,
                  minY: chartMin,
                  maxY: chartMax,
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: yInterval,
                        reservedSize: 20,
                        minIncluded: true,
                        maxIncluded: true,
                        getTitlesWidget: (axisValue, meta) => Padding(
                          padding: EdgeInsets.zero,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              _axisValue(axisValue),
                              textAlign: TextAlign.right,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: xInterval,
                        reservedSize: 38,
                        minIncluded: true,
                        maxIncluded: true,
                        getTitlesWidget: (axisValue, meta) {
                          if (isToday) {
                            if (!showTodayHour(axisValue)) {
                              return const SizedBox.shrink();
                            }
                            final hour = axisValue.round();
                            final horizontalNudge = switch (hour) {
                              0 => -3.0,
                              1 => 3.0,
                              23 => -3.0,
                              24 => 3.0,
                              _ => 0.0,
                            };
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Transform.translate(
                                offset: Offset(horizontalNudge, 0),
                                child: SizedBox(
                                  width: 18,
                                  child: Text(
                                    hour == 24
                                        ? '24'
                                        : hour.toString().padLeft(2, '0'),
                                    maxLines: 1,
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 10.5,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }

                          final day = axisValue
                              .round()
                              .clamp(0, durationDays - 1)
                              .toInt();
                          final date = from.add(Duration(days: day));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => setState(
                                () => _selectedSpotIndex = day,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 3,
                                ),
                                child: Text(
                                  _axisLabel(date, durationDays),
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: selectedSpotIndex == day
                                        ? theme.colorScheme.onSurface
                                        : theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                    fontWeight: selectedSpotIndex == day
                                        ? FontWeight.w800
                                        : FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchCallback: (event, response) {
                      if (event is! FlTapUpEvent) return;
                      final touched = response?.lineBarSpots;
                      if (touched == null || touched.isEmpty) return;
                      setState(
                        () => _selectedSpotIndex =
                            touched.first.spotIndex,
                      );
                    },
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          theme.colorScheme.surfaceContainerHighest,
                      tooltipBorderRadius: BorderRadius.circular(10),
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (touchedSpots) => touchedSpots
                          .map((spot) {
                            final index = spot.spotIndex
                                .clamp(0, spotDates.length - 1)
                                .toInt();
                            final date = spotDates[index];
                            final dateLabel = isToday
                                ? DateFormat(
                                    'd MMM yyyy, HH:mm',
                                    'it_IT',
                                  ).format(date)
                                : DateFormat(
                                    'd MMM yyyy',
                                    'it_IT',
                                  ).format(date);
                            return LineTooltipItem(
                              '$dateLabel\n'
                              '${hideValues ? '••••' : moneyFor(state, spot.y)}',
                              theme.textTheme.bodyMedium!.copyWith(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w700,
                              ),
                            );
                          })
                          .toList(),
                    ),
                  ),
                  extraLinesData: selectedSpot == null
                      ? const ExtraLinesData()
                      : ExtraLinesData(
                          verticalLines: [
                            VerticalLine(
                              x: selectedSpot.x,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: .22,
                              ),
                              strokeWidth: 1,
                              dashArray: const [4, 4],
                            ),
                          ],
                        ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: false,
                      dotData: FlDotData(
                        show: spots.length == 1 || selectedSpot != null,
                        checkToShowDot: (spot, barData) =>
                            spots.length == 1 ||
                            (selectedSpot != null &&
                                (spot.x - selectedSpot.x).abs() < .0001 &&
                                (spot.y - selectedSpot.y).abs() < .0001),
                      ),
                      barWidth: 3,
                      color: lineColor,
                    ),
                  ],
                ),
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
              ),
              ),
            ),
          ),
        ),
        if (selectedDate != null && selectedBalance != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  isToday
                      ? 'Saldo alle ${DateFormat('HH:mm', 'it_IT').format(selectedDate)}'
                      : 'Saldo finale ${DateFormat('d MMM yyyy', 'it_IT').format(selectedDate)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                hideValues ? '••••' : moneyFor(state, selectedBalance),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Text(
                'Inizio ${hideValues ? '••••' : moneyFor(state, startValue)}',
                style: theme.textTheme.bodySmall,
              ),
            ),
            Text(
              'Fine ${hideValues ? '••••' : moneyFor(state, finalValue)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }
}

class _AnalyticsPeriodNavigator extends StatelessWidget {
  const _AnalyticsPeriodNavigator({
    required this.label,
    required this.animation,
    required this.onPrevious,
    required this.onNext,
  });

  final String label;
  final Animation<double> animation;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label:
          'Periodo $label. Usa le frecce o scorri il grafico per cambiare periodo.',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AnalyticsSwipeChevron(
            direction: -1,
            animation: animation,
            tooltip: 'Periodo precedente',
            onPressed: onPrevious,
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 110, maxWidth: 170),
            child: Text(
              label,
              maxLines: 1,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          _AnalyticsSwipeChevron(
            direction: 1,
            animation: animation,
            tooltip: 'Periodo successivo',
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsSwipeChevron extends StatelessWidget {
  const _AnalyticsSwipeChevron({
    required this.direction,
    required this.animation,
    required this.tooltip,
    required this.onPressed,
  });

  final int direction;
  final Animation<double> animation;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final travel = 2 + animation.value * 4;
        return Transform.translate(
          offset: Offset(direction * travel, 0),
          child: Opacity(
            opacity: .42 + animation.value * .48,
            child: IconButton(
              tooltip: tooltip,
              onPressed: onPressed,
              visualDensity: VisualDensity.compact,
              constraints: const BoxConstraints.tightFor(
                width: 36,
                height: 36,
              ),
              padding: EdgeInsets.zero,
              icon: Icon(
                direction < 0
                    ? Icons.chevron_left_rounded
                    : Icons.chevron_right_rounded,
                size: 24,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CategoryPeriodPage extends StatelessWidget {
  const _CategoryPeriodPage({
    required this.title,
    required this.accountId,
    required this.categoryId,
    required this.from,
    required this.to,
  });

  final String title;
  final int? accountId;
  final int categoryId;
  final DateTime from;
  final DateTime to;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = AccountContextService.transactionsFor(state, accountId).where(
      (item) {
        if (item.date.isBefore(from) || !item.date.isBefore(to)) return false;
        if (item.categoryId == categoryId) return true;
        return state
            .splitsFor(item.id)
            .any((split) => split.categoryId == categoryId);
      },
    ).toList()..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? const Center(child: Text('Nessun movimento'))
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) =>
                  TransactionListTile(item: items[index]),
            ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: Theme.of(context).textTheme.bodySmall),
      const SizedBox(height: 3),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: color),
        ),
      ),
    ],
  );
}

class _AnalyticsLine extends StatelessWidget {
  const _AnalyticsLine({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20),
      const SizedBox(width: 10),
      Expanded(child: Text(text)),
    ],
  );
}
