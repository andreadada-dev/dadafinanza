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

enum _AnalyticsPeriod { week, month, year, custom }

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
  DateTimeRange? custom;

  String _periodLabel(_AnalyticsPeriod item) {
    if (item != _AnalyticsPeriod.custom || custom == null) {
      return switch (item) {
        _AnalyticsPeriod.week => 'Settimana',
        _AnalyticsPeriod.month => 'Mese',
        _AnalyticsPeriod.year => 'Anno',
        _AnalyticsPeriod.custom => 'Custom',
      };
    }
    final formatter = DateFormat('d/M/yyyy');
    return '${formatter.format(custom!.start)} ~ ${formatter.format(custom!.end)}';
  }

  Future<void> _selectPeriod(_AnalyticsPeriod next) async {
    if (next != _AnalyticsPeriod.custom) {
      if (next != period) setState(() => period = next);
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
      });
    }
  }

  (DateTime, DateTime) _bounds(AppState state) {
    final now = DateTime.now();
    switch (period) {
      case _AnalyticsPeriod.week:
        final startWeekday = state.weekStart.clamp(1, 7);
        final offset = (now.weekday - startWeekday) % 7;
        final start = DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: offset));
        return (start, start.add(const Duration(days: 7)));
      case _AnalyticsPeriod.month:
        final day = state.financialMonthStart.clamp(1, 28);
        var start = DateTime(now.year, now.month, day);
        if (now.isBefore(start)) start = DateTime(now.year, now.month - 1, day);
        return (start, DateTime(start.year, start.month + 1, day));
      case _AnalyticsPeriod.year:
        return (DateTime(now.year), DateTime(now.year + 1));
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final item in _AnalyticsPeriod.values) ...[
                  _PeriodPill(
                    label: _periodLabel(item),
                    selected: period == item,
                    onTap: () => _selectPeriod(item),
                  ),
                  if (item != _AnalyticsPeriod.values.last)
                    const SizedBox(width: 10),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${DateFormat('d MMM', 'it_IT').format(from)} – '
            '${DateFormat('d MMM', 'it_IT').format(to.subtract(const Duration(days: 1)))}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                  const SizedBox(width: 7),
                ],
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ],
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
  });

  final AppState state;
  final Account? account;
  final DateTime from;
  final DateTime to;
  final _AnalyticsPeriod period;

  @override
  State<_BalanceTrend> createState() => _BalanceTrendState();
}

class _BalanceTrendState extends State<_BalanceTrend> {
  int? _selectedDay;

  @override
  void didUpdateWidget(covariant _BalanceTrend oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.from != widget.from ||
        oldWidget.to != widget.to ||
        oldWidget.account?.id != widget.account?.id) {
      _selectedDay = null;
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
    if (widget.period == _AnalyticsPeriod.week) return 1;
    final targetLabels = widget.period == _AnalyticsPeriod.year ? 7 : 6;
    return (maxX / targetLabels)
        .ceilToDouble()
        .clamp(1.0, double.infinity)
        .toDouble();
  }

  String _axisLabel(DateTime date, int durationDays) {
    return switch (widget.period) {
      _AnalyticsPeriod.week => DateFormat('EEE', 'it_IT').format(date),
      _AnalyticsPeriod.month => DateFormat('d MMM', 'it_IT').format(date),
      _AnalyticsPeriod.year => DateFormat('MMM', 'it_IT').format(date),
      _AnalyticsPeriod.custom =>
        durationDays <= 8
            ? DateFormat('EEE d', 'it_IT').format(date)
            : durationDays <= 70
            ? DateFormat('d MMM', 'it_IT').format(date)
            : DateFormat('MMM yy', 'it_IT').format(date),
    };
  }

  String _axisValue(double value) {
    if (widget.state.hideBalance || (widget.account?.hideBalance ?? false)) {
      return '••';
    }
    return NumberFormat.compact(locale: 'it_IT').format(value);
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
    final durationDays = to.difference(from).inDays.clamp(1, 10000).toInt();
    final endOfDayBalances = <double>[];
    var itemIndex = items.indexWhere((item) => !item.date.isBefore(from));
    if (itemIndex < 0) itemIndex = items.length;

    for (var day = 0; day < durationDays; day++) {
      final nextDay = from.add(Duration(days: day + 1));
      while (itemIndex < items.length && items[itemIndex].date.isBefore(nextDay)) {
        value += _deltaFor(items[itemIndex], accountIds);
        itemIndex++;
      }
      endOfDayBalances.add(value);
    }

    final spots = <FlSpot>[
      for (var day = 0; day < endOfDayBalances.length; day++)
        FlSpot(day.toDouble(), endOfDayBalances[day]),
    ];
    if (spots.length == 1) {
      spots.add(FlSpot(1, spots.first.y));
    }

    final maxX = spots.last.x;
    var minValue = spots.first.y;
    var maxValue = spots.first.y;
    for (final spot in spots.skip(1)) {
      if (spot.y < minValue) minValue = spot.y;
      if (spot.y > maxValue) maxValue = spot.y;
    }

    final spread = (maxValue - minValue).abs();
    final basePadding = spread < .01
        ? (maxValue.abs() * .06 + 1)
        : spread * .08;
    final chartMin = minValue - basePadding;
    final chartMax = maxValue + basePadding;
    final yInterval = ((chartMax - chartMin) / 4)
        .clamp(.01, double.infinity)
        .toDouble();
    final xInterval = _labelInterval(maxX);
    final lineColor = account == null
        ? theme.colorScheme.onSurfaceVariant
        : Color(account.colorValue);
    final hideValues = state.hideBalance || (account?.hideBalance ?? false);

    final selectedDay = _selectedDay == null
        ? null
        : _selectedDay!.clamp(0, endOfDayBalances.length - 1).toInt();
    final selectedDate = selectedDay == null
        ? null
        : from.add(Duration(days: selectedDay));
    final selectedBalance = selectedDay == null
        ? null
        : endOfDayBalances[selectedDay];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: Semantics(
            label: account == null
                ? 'Andamento del patrimonio nel periodo selezionato'
                : 'Andamento del saldo di ${account.name} nel periodo selezionato',
            child: LineChart(
              LineChartData(
                minX: 0,
                maxX: maxX,
                minY: chartMin,
                maxY: chartMax,
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 56,
                      minIncluded: true,
                      maxIncluded: true,
                      getTitlesWidget: (axisValue, meta) => Padding(
                        padding: const EdgeInsets.only(right: 8),
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
                      maxIncluded: endOfDayBalances.length > 1,
                      getTitlesWidget: (axisValue, meta) {
                        final day = axisValue
                            .round()
                            .clamp(0, endOfDayBalances.length - 1)
                            .toInt();
                        final date = from.add(Duration(days: day));
                        final selected = selectedDay == day;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => setState(() => _selectedDay = day),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                                vertical: 3,
                              ),
                              child: Text(
                                _axisLabel(date, durationDays),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: selected
                                      ? theme.colorScheme.onSurface
                                      : theme.colorScheme.onSurfaceVariant,
                                  fontWeight: selected
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
                    final day = touched.first.x
                        .round()
                        .clamp(0, endOfDayBalances.length - 1)
                        .toInt();
                    setState(() => _selectedDay = day);
                  },
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) =>
                        theme.colorScheme.surfaceContainerHighest,
                    tooltipBorderRadius: BorderRadius.circular(10),
                    fitInsideHorizontally: true,
                    fitInsideVertically: true,
                    getTooltipItems: (touchedSpots) => touchedSpots
                        .map((spot) {
                          final day = spot.x
                              .round()
                              .clamp(0, endOfDayBalances.length - 1)
                              .toInt();
                          final date = from.add(Duration(days: day));
                          return LineTooltipItem(
                            '${DateFormat('d MMM yyyy', 'it_IT').format(date)}\n'
                            '${hideValues ? '••••' : moneyFor(state, endOfDayBalances[day])}',
                            theme.textTheme.bodyMedium!.copyWith(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                            ),
                          );
                        })
                        .toList(),
                  ),
                ),
                extraLinesData: selectedDay == null
                    ? const ExtraLinesData()
                    : ExtraLinesData(
                        verticalLines: [
                          VerticalLine(
                            x: selectedDay.toDouble(),
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
                      show: selectedDay != null,
                      checkToShowDot: (spot, barData) =>
                          selectedDay != null &&
                          spot.x.round() == selectedDay,
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
        if (selectedDate != null && selectedBalance != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.event_outlined, size: 18),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  'Saldo finale ${DateFormat('d MMM yyyy', 'it_IT').format(selectedDate)}',
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
              'Fine ${hideValues ? '••••' : moneyFor(state, value)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ],
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
