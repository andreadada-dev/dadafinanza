import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../screens/account_management_screen.dart';
import '../screens/account_screens.dart' show showAccountEditor;
import '../screens/canonical_shell.dart' show CanonicalDashboardWidget;
import '../screens/category_management_screen.dart' show CategoryDetailScreen;
import 'ui_helpers.dart';

/// Renders a dashboard configuration on the canonical Home.
///
/// Core metrics are rendered by the Ivy-style overview in DadaHomeScreen.
/// Remaining widgets preserve "Personalizza Home" visibility, ordering and size.
class HomeDashboardWidget extends StatelessWidget {
  const HomeDashboardWidget({required this.config, super.key});

  final DashboardWidgetConfig config;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final type = config.type;

    switch (type) {
      case DashboardWidgetType.totalBalance:
        return _MetricBlock(
          config: config,
          title: 'PATRIMONIO',
          value: state.hideBalance
              ? '••••••'
              : moneyFor(state, state.totalBalance),
          detail: 'Patrimonio incluso nel totale',
          icon: Icons.account_balance_wallet_outlined,
        );
      case DashboardWidgetType.monthlyIncome:
        return _MetricBlock(
          config: config,
          title: type.label,
          value: state.hideBalance
              ? '••••'
              : moneyFor(state, state.monthTotal(TransactionType.income)),
          icon: Icons.arrow_downward_rounded,
          valueColor: context.financeColors.positive,
        );
      case DashboardWidgetType.monthlyExpense:
        return _MetricBlock(
          config: config,
          title: type.label,
          value: state.hideBalance
              ? '••••'
              : moneyFor(state, state.monthTotal(TransactionType.expense)),
          icon: Icons.arrow_upward_rounded,
          valueColor: context.financeColors.negative,
        );
      case DashboardWidgetType.safeToSpend:
        return _MetricBlock(
          config: config,
          title: type.label,
          value: state.hideBalance
              ? '••••'
              : moneyFor(state, state.safeToSpend),
          detail: 'Stima fino a fine mese',
          icon: Icons.safety_check_outlined,
        );
      case DashboardWidgetType.accounts:
        return _AccountsBlock(config: config);
      case DashboardWidgetType.topCategories:
        return _TopCategoriesDonut(config: config);
      default:
        return _SizedCanonicalWidget(config: config);
    }
  }
}

class _SizedCanonicalWidget extends StatelessWidget {
  const _SizedCanonicalWidget({required this.config});

  final DashboardWidgetConfig config;

  @override
  Widget build(BuildContext context) {
    final padding = switch (config.size) {
      DashboardWidgetSize.small => 0.0,
      DashboardWidgetSize.medium => 4.0,
      DashboardWidgetSize.large => 10.0,
    };
    return Padding(
      padding: EdgeInsets.symmetric(vertical: padding),
      child: CanonicalDashboardWidget(config: config),
    );
  }
}

class _MetricBlock extends StatelessWidget {
  const _MetricBlock({
    required this.config,
    required this.title,
    required this.value,
    this.detail,
    this.icon,
    this.valueColor,
  });

  final DashboardWidgetConfig config;
  final String title;
  final String value;
  final String? detail;
  final IconData? icon;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final style = switch (config.size) {
      DashboardWidgetSize.small => Theme.of(context).textTheme.titleLarge,
      DashboardWidgetSize.medium => Theme.of(context).textTheme.headlineSmall,
      DashboardWidgetSize.large => Theme.of(context).textTheme.displaySmall,
    };
    final showDetail = config.size != DashboardWidgetSize.small;
    final showIcon = icon != null && config.size == DashboardWidgetSize.large;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.labelMedium),
        if (showIcon) ...[const SizedBox(height: 8), Icon(icon, size: 24)],
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: style?.copyWith(
              color: valueColor,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (showDetail && detail != null) ...[
          const SizedBox(height: 4),
          Text(detail!, style: Theme.of(context).textTheme.bodySmall),
        ],
      ],
    );
  }
}

class _AccountsBlock extends StatelessWidget {
  const _AccountsBlock({required this.config});

  final DashboardWidgetConfig config;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final limit = switch (config.size) {
      DashboardWidgetSize.small => 2,
      DashboardWidgetSize.medium => 4,
      DashboardWidgetSize.large => 6,
    };
    final accounts = state.activeAccounts.take(limit).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Conti',
          trailing: TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const AccountManagementScreen(),
              ),
            ),
            child: const Text('Tutti'),
          ),
        ),
        if (accounts.isEmpty)
          EmptyState(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Nessun conto',
            subtitle:
                'Aggiungi il conto che usi davvero oppure continua con movimenti Non assegnati.',
            action: TextButton.icon(
              onPressed: () => showAccountEditor(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Crea conto'),
            ),
          )
        else
          ...accounts.map(
            (account) => ListTile(
              contentPadding: EdgeInsets.zero,
              minVerticalPadding: 10,
              leading: Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Color(account.colorValue).withValues(alpha: .11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  accountIcon(account.iconKey),
                  size: 21,
                  color: Color(account.colorValue),
                ),
              ),
              title: Text(
                account.name,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: config.size == DashboardWidgetSize.small
                  ? null
                  : Text(account.accountType.label),
              trailing: Text(
                state.hideBalance || account.hideBalance
                    ? '••••'
                    : moneyFor(state, account.balance),
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      SafeAccountDetailScreen(accountId: account.id),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TopCategoriesDonut extends StatefulWidget {
  const _TopCategoriesDonut({required this.config});

  final DashboardWidgetConfig config;

  @override
  State<_TopCategoriesDonut> createState() => _TopCategoriesDonutState();
}

enum _CategoryChartRange { thisMonth, thisWeek, last7Days, last30Days, custom }

class _TopCategoriesDonutState extends State<_TopCategoriesDonut> {
  static const _rangeOrder = <_CategoryChartRange>[
    _CategoryChartRange.thisMonth,
    _CategoryChartRange.thisWeek,
    _CategoryChartRange.last7Days,
    _CategoryChartRange.last30Days,
    _CategoryChartRange.custom,
  ];

  var _selectedIndex = -1;
  var _type = TransactionType.expense;
  var _typeDirection = 1;
  var _range = _CategoryChartRange.thisMonth;
  DateTimeRange? _customRange;

  (DateTime, DateTime) _bounds() {
    final now = DateTime.now();
    final todayEnd = DateTime(now.year, now.month, now.day + 1);

    return switch (_range) {
      _CategoryChartRange.thisMonth => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
      ),
      _CategoryChartRange.thisWeek => (
        DateTime(
          now.year,
          now.month,
          now.day,
        ).subtract(Duration(days: now.weekday - 1)),
        DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1))
            .add(const Duration(days: 7)),
      ),
      _CategoryChartRange.last7Days => (
        todayEnd.subtract(const Duration(days: 7)),
        todayEnd,
      ),
      _CategoryChartRange.last30Days => (
        todayEnd.subtract(const Duration(days: 30)),
        todayEnd,
      ),
      _CategoryChartRange.custom =>
        _customRange == null
            ? (DateTime(now.year, now.month), DateTime(now.year, now.month + 1))
            : (
                DateTime(
                  _customRange!.start.year,
                  _customRange!.start.month,
                  _customRange!.start.day,
                ),
                DateTime(
                  _customRange!.end.year,
                  _customRange!.end.month,
                  _customRange!.end.day + 1,
                ),
              ),
    };
  }

  String get _rangeLabel => switch (_range) {
    _CategoryChartRange.thisMonth => 'Questo mese',
    _CategoryChartRange.thisWeek => 'Questa settimana',
    _CategoryChartRange.last7Days => 'Ultimi 7 giorni',
    _CategoryChartRange.last30Days => 'Ultimi 30 giorni',
    _CategoryChartRange.custom =>
      _customRange == null
          ? 'Personalizzato'
          : '${_customRange!.start.day}/${_customRange!.start.month} – '
                '${_customRange!.end.day}/${_customRange!.end.month}',
  };

  Future<void> _selectRange(_CategoryChartRange next) async {
    if (next == _CategoryChartRange.custom) {
      final now = DateTime.now();
      final picked = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2000),
        lastDate: now.add(const Duration(days: 3650)),
        initialDateRange:
            _customRange ??
            DateTimeRange(start: DateTime(now.year, now.month), end: now),
      );
      if (!mounted || picked == null) return;
      setState(() {
        _customRange = picked;
        _range = next;
        _selectedIndex = -1;
      });
      return;
    }

    if (next == _range) return;
    setState(() {
      _range = next;
      _selectedIndex = -1;
    });
  }

  void _stepRange(int delta) {
    final current = _rangeOrder.indexOf(_range);
    final nextIndex =
        (current + delta + _rangeOrder.length) % _rangeOrder.length;
    _selectRange(_rangeOrder[nextIndex]);
  }

  void _stepType(int direction) {
    final next = _type == TransactionType.expense
        ? TransactionType.income
        : TransactionType.expense;
    setState(() {
      _type = next;
      _selectedIndex = -1;
      _typeDirection = direction == 0 ? 1 : direction;
    });
  }

  void _handleTypeSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 120) return;
    _stepType(velocity < 0 ? 1 : -1);
  }

  List<MapEntry<Category, double>> _topCategories(
    AppState state,
    TransactionType type,
    int limit,
    DateTime from,
    DateTime to,
  ) {
    final totals = <int, double>{};

    for (final transaction in state.analyticTransactions(from: from, to: to)) {
      if (transaction.type != type) continue;
      if (type == TransactionType.income &&
          transaction.refundOfTransactionId != null) {
        continue;
      }

      if (type == TransactionType.expense) {
        final itemSplits = state.splitsFor(transaction.id);
        if (itemSplits.isNotEmpty) {
          for (final split in itemSplits) {
            totals[split.categoryId] =
                (totals[split.categoryId] ?? 0) +
                state.analyticsAmountForSplit(transaction.id, split);
          }
        } else if (transaction.categoryId != null) {
          totals[transaction.categoryId!] =
              (totals[transaction.categoryId!] ?? 0) +
              state.effectiveExpense(transaction);
        }
      } else if (transaction.categoryId != null) {
        totals[transaction.categoryId!] =
            (totals[transaction.categoryId!] ?? 0) + transaction.amount;
      }
    }

    final items =
        state
            .categoriesFor(type)
            .map((category) => MapEntry(category, totals[category.id] ?? 0))
            .where((entry) => entry.value > 0)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return items.take(limit).toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final limit = switch (widget.config.size) {
      DashboardWidgetSize.small => 3,
      DashboardWidgetSize.medium => 4,
      DashboardWidgetSize.large => 5,
    };
    final (from, to) = _bounds();
    final top = _topCategories(state, _type, limit, from, to);
    final total = state.periodTotal(_type, from, to).abs();
    final isExpense = _type == TransactionType.expense;
    final accent = isExpense
        ? context.financeColors.negative
        : context.financeColors.positive;
    final emptyLabel = isExpense
        ? 'Nessuna spesa da mostrare nel periodo'
        : 'Nessuna entrata da mostrare nel periodo';

    final slices = <_DonutSlice>[
      for (final entry in top)
        _DonutSlice(
          category: entry.key,
          label: entry.key.name,
          amount: entry.value.abs(),
          color: Color(entry.key.colorValue),
        ),
    ];
    final shown = slices.fold<double>(0, (sum, item) => sum + item.amount);
    final other = total > shown ? total - shown : 0.0;
    if (other > 0.005) {
      slices.add(
        _DonutSlice(
          category: null,
          label: 'Altro',
          amount: other,
          color: Theme.of(
            context,
          ).colorScheme.onSurfaceVariant.withValues(alpha: .38),
        ),
      );
    }

    if (_selectedIndex >= slices.length) _selectedIndex = -1;
    final selected = _selectedIndex >= 0 ? slices[_selectedIndex] : null;
    final chartSize = switch (widget.config.size) {
      DashboardWidgetSize.small => 210.0,
      DashboardWidgetSize.medium => 248.0,
      DashboardWidgetSize.large => 288.0,
    };

    final otherTypeLabel = isExpense ? 'Entrate' : 'Spese';
    final typeIcon = isExpense
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onHorizontalDragEnd: _handleTypeSwipe,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 240),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: Offset(.07 * _typeDirection, 0),
            end: Offset.zero,
          ).animate(animation);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(position: slide, child: child),
          );
        },
        child: Column(
          key: ValueKey(_type),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (top.isEmpty || total <= 0) ...[
              SizedBox(
                height: chartSize * .72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _CarouselTypeArrow(
                        icon: Icons.chevron_left_rounded,
                        tooltip: 'Mostra $otherTypeLabel',
                        onPressed: () => _stepType(-1),
                      ),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: _CarouselTypeArrow(
                        icon: Icons.chevron_right_rounded,
                        tooltip: 'Mostra $otherTypeLabel',
                        onPressed: () => _stepType(1),
                      ),
                    ),
                    _EmptyDonutCenter(
                      icon: typeIcon,
                      accent: accent,
                      rangeLabel: _rangeLabel,
                      totalLabel: state.hideBalance
                          ? '••••'
                          : moneyFor(state, total),
                      onPreviousRange: () => _stepRange(-1),
                      onNextRange: () => _stepRange(1),
                    ),
                  ],
                ),
              ),
              Center(
                child: Text(
                  emptyLabel,
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ] else ...[
              Center(
                child: SizedBox(
                  height: chartSize,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: SizedBox.square(
                          dimension: chartSize,
                          child: PieChart(
                            PieChartData(
                              startDegreeOffset: -90,
                              sectionsSpace: 4,
                              centerSpaceRadius: chartSize * .32,
                              borderData: FlBorderData(show: false),
                              pieTouchData: PieTouchData(
                                touchCallback: (event, response) {
                                  if (event is! FlTapDownEvent ||
                                      response?.touchedSection == null) {
                                    return;
                                  }
                                  final next = response!
                                      .touchedSection!
                                      .touchedSectionIndex;
                                  setState(() {
                                    _selectedIndex = _selectedIndex == next
                                        ? -1
                                        : next;
                                  });
                                },
                              ),
                              sections: [
                                for (
                                  var index = 0;
                                  index < slices.length;
                                  index++
                                )
                                  PieChartSectionData(
                                    color:
                                        _selectedIndex == -1 ||
                                            _selectedIndex == index
                                        ? slices[index].color
                                        : slices[index].color.withValues(
                                            alpha: .22,
                                          ),
                                    value: slices[index].amount,
                                    title: '',
                                    radius:
                                        chartSize *
                                        (_selectedIndex == index ? .165 : .145),
                                    showTitle: false,
                                  ),
                              ],
                            ),
                            duration: const Duration(milliseconds: 420),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _CarouselTypeArrow(
                          icon: Icons.chevron_left_rounded,
                          tooltip: 'Mostra $otherTypeLabel',
                          onPressed: () => _stepType(-1),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: _CarouselTypeArrow(
                          icon: Icons.chevron_right_rounded,
                          tooltip: 'Mostra $otherTypeLabel',
                          onPressed: () => _stepType(1),
                        ),
                      ),
                      Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 220),
                          switchInCurve: Curves.easeOutCubic,
                          child: selected == null
                              ? _DonutPeriodCenter(
                                  key: ValueKey(
                                    '${_type.name}-${_range.name}-period',
                                  ),
                                  icon: typeIcon,
                                  accent: accent,
                                  rangeLabel: _rangeLabel,
                                  totalLabel: state.hideBalance
                                      ? '••••'
                                      : moneyFor(state, total),
                                  onPreviousRange: () => _stepRange(-1),
                                  onNextRange: () => _stepRange(1),
                                )
                              : _SelectedDonutCenter(
                                  key: ValueKey(
                                    '${_type.name}-${_range.name}-$_selectedIndex',
                                  ),
                                  slice: selected,
                                  percentage: total <= 0
                                      ? 0
                                      : selected.amount / total,
                                  amountLabel: state.hideBalance
                                      ? '••••'
                                      : moneyFor(state, selected.amount),
                                  onTap: () =>
                                      setState(() => _selectedIndex = -1),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              for (final entry in top)
                _CategoryDonutRow(
                  category: entry.key,
                  amount: entry.value.abs(),
                  total: total,
                  state: state,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CarouselTypeArrow extends StatelessWidget {
  const _CarouselTypeArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: theme.colorScheme.surfaceContainer.withValues(
          alpha: .72,
        ),
        foregroundColor: theme.colorScheme.onSurface,
      ),
      icon: Icon(icon, size: 26),
    );
  }
}

class _DonutPeriodCenter extends StatelessWidget {
  const _DonutPeriodCenter({
    required this.icon,
    required this.accent,
    required this.rangeLabel,
    required this.totalLabel,
    required this.onPreviousRange,
    required this.onNextRange,
    super.key,
  });

  final IconData icon;
  final Color accent;
  final String rangeLabel;
  final String totalLabel;
  final VoidCallback onPreviousRange;
  final VoidCallback onNextRange;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      label: 'Periodo $rangeLabel, totale $totalLabel',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 26, color: accent),
          const SizedBox(height: 6),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _DonutRangeArrow(
                icon: Icons.chevron_left_rounded,
                tooltip: 'Periodo precedente',
                onPressed: onPreviousRange,
              ),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 96),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    rangeLabel,
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              _DonutRangeArrow(
                icon: Icons.chevron_right_rounded,
                tooltip: 'Periodo successivo',
                onPressed: onNextRange,
              ),
            ],
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              totalLabel,
              style: theme.textTheme.titleMedium?.copyWith(
                color: accent,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyDonutCenter extends StatelessWidget {
  const _EmptyDonutCenter({
    required this.icon,
    required this.accent,
    required this.rangeLabel,
    required this.totalLabel,
    required this.onPreviousRange,
    required this.onNextRange,
  });

  final IconData icon;
  final Color accent;
  final String rangeLabel;
  final String totalLabel;
  final VoidCallback onPreviousRange;
  final VoidCallback onNextRange;

  @override
  Widget build(BuildContext context) => _DonutPeriodCenter(
    icon: icon,
    accent: accent,
    rangeLabel: rangeLabel,
    totalLabel: totalLabel,
    onPreviousRange: onPreviousRange,
    onNextRange: onNextRange,
  );
}

class _DonutRangeArrow extends StatelessWidget {
  const _DonutRangeArrow({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: tooltip,
    onPressed: onPressed,
    visualDensity: VisualDensity.compact,
    constraints: const BoxConstraints.tightFor(width: 36, height: 36),
    padding: EdgeInsets.zero,
    icon: Icon(icon, size: 21),
  );
}

class _SelectedDonutCenter extends StatelessWidget {
  const _SelectedDonutCenter({
    required this.slice,
    required this.percentage,
    required this.amountLabel,
    required this.onTap,
    super.key,
  });

  final _DonutSlice slice;
  final double percentage;
  final String amountLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      label:
          '${slice.label}, ${(percentage * 100).round()}%, $amountLabel. Tocca per tornare al periodo.',
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                slice.category == null
                    ? Icons.pie_chart_rounded
                    : categoryIcon(slice.category!.iconKey),
                size: 24,
                color: slice.color,
              ),
              const SizedBox(height: 4),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Text(
                  slice.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${(percentage * 100).round()}%',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: slice.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                amountLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryDonutRow extends StatelessWidget {
  const _CategoryDonutRow({
    required this.category,
    required this.amount,
    required this.total,
    required this.state,
  });

  final Category category;
  final double amount;
  final double total;
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final color = Color(category.colorValue);
    final percent = total <= 0 ? 0 : amount / total;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CategoryDetailScreen(categoryId: category.id),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .11),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                categoryIcon(category.iconKey),
                color: color,
                size: 19,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 5),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: percent.clamp(0, 1).toDouble(),
                      minHeight: 4,
                      color: color,
                      backgroundColor: color.withValues(alpha: .10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  state.hideBalance ? '••••' : moneyFor(state, amount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DonutSlice {
  const _DonutSlice({
    required this.category,
    required this.label,
    required this.amount,
    required this.color,
  });

  final Category? category;
  final String label;
  final double amount;
  final Color color;
}
