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

  void _handleRangeSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 80) return;
    _stepRange(velocity < 0 ? 1 : -1);
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
    final title = isExpense ? 'Spese per categoria' : 'Entrate per categoria';
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CategoryChartControls(
          selectedType: _type,
          rangeLabel: _rangeLabel,
          onTypeChanged: (value) {
            if (value == _type) return;
            setState(() {
              _type = value;
              _selectedIndex = -1;
            });
          },
          onPreviousRange: () => _stepRange(-1),
          onNextRange: () => _stepRange(1),
          onRangeSwipe: _handleRangeSwipe,
          onRangeTap: () {
            if (_range == _CategoryChartRange.custom) {
              _selectRange(_CategoryChartRange.custom);
            } else {
              _stepRange(1);
            }
          },
        ),
        const SizedBox(height: 20),
        SectionTitle(
          title,
          trailing: Text(
            state.hideBalance ? '••••' : moneyFor(state, total),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: accent,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        if (top.isEmpty || total <= 0) ...[
          const SizedBox(height: 8),
          Text(emptyLabel),
        ] else ...[
          const SizedBox(height: 8),
          Center(
            child: SizedBox.square(
              dimension: chartSize,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 850),
                    curve: Curves.easeInOutCubicEmphasized,
                    builder: (context, progress, child) {
                      return PieChart(
                        PieChartData(
                          startDegreeOffset: -90,
                          sectionsSpace: 4,
                          centerSpaceRadius: chartSize * .30,
                          borderData: FlBorderData(show: false),
                          pieTouchData: PieTouchData(
                            touchCallback: (event, response) {
                              if (event is! FlTapDownEvent ||
                                  response?.touchedSection == null) {
                                return;
                              }
                              final next =
                                  response!.touchedSection!.touchedSectionIndex;
                              setState(() {
                                _selectedIndex = _selectedIndex == next
                                    ? -1
                                    : next;
                              });
                            },
                          ),
                          sections: [
                            for (var index = 0; index < slices.length; index++)
                              PieChartSectionData(
                                color:
                                    _selectedIndex == -1 ||
                                        _selectedIndex == index
                                    ? slices[index].color
                                    : slices[index].color.withValues(
                                        alpha: .22,
                                      ),
                                value: slices[index].amount * progress,
                                title: '',
                                radius:
                                    chartSize *
                                    (_selectedIndex == index ? .165 : .145),
                                showTitle: false,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                  IgnorePointer(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      child: Column(
                        key: ValueKey(
                          '${_type.name}-${_range.name}-$_selectedIndex',
                        ),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            selected?.category == null
                                ? Icons.pie_chart_rounded
                                : categoryIcon(selected!.category!.iconKey),
                            size: 24,
                            color: selected?.color ?? accent,
                          ),
                          const SizedBox(height: 5),
                          ConstrainedBox(
                            constraints: BoxConstraints(
                              maxWidth: chartSize * .46,
                            ),
                            child: Text(
                              selected?.label ?? _rangeLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            selected == null
                                ? '${slices.length} categorie'
                                : '${(selected.amount / total * 100).round()}%',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: selected?.color ?? accent,
                                  fontWeight: FontWeight.w900,
                                ),
                          ),
                          if (selected != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              state.hideBalance
                                  ? '••••'
                                  : moneyFor(state, selected.amount),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurface,
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ],
                        ],
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
    );
  }
}

class _CategoryChartControls extends StatelessWidget {
  const _CategoryChartControls({
    required this.selectedType,
    required this.rangeLabel,
    required this.onTypeChanged,
    required this.onPreviousRange,
    required this.onNextRange,
    required this.onRangeSwipe,
    required this.onRangeTap,
  });

  final TransactionType selectedType;
  final String rangeLabel;
  final ValueChanged<TransactionType> onTypeChanged;
  final VoidCallback onPreviousRange;
  final VoidCallback onNextRange;
  final GestureDragEndCallback onRangeSwipe;
  final VoidCallback onRangeTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inactive = theme.colorScheme.onSurfaceVariant;
    final selectedColor = theme.colorScheme.onSurface;

    Widget typeAction({
      required TransactionType type,
      required String label,
      required Color color,
      required Alignment alignment,
    }) {
      final selected = selectedType == type;
      final resolvedColor = selected ? selectedColor : color;

      return Align(
        alignment: alignment,
        child: Semantics(
          button: true,
          selected: selected,
          label: label,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onTypeChanged(type),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: resolvedColor,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    width: 26,
                    height: 2,
                    decoration: BoxDecoration(
                      color: selected ? selectedColor : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: typeAction(
            type: TransactionType.expense,
            label: 'Spese',
            color: context.financeColors.negative,
            alignment: Alignment.centerLeft,
          ),
        ),
        Flexible(
          flex: 2,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragEnd: onRangeSwipe,
            onTap: onRangeTap,
            child: Semantics(
              button: true,
              label: 'Periodo: $rangeLabel',
              hint: 'Scorri a destra o sinistra per cambiare periodo',
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: 'Periodo precedente',
                      visualDensity: VisualDensity.compact,
                      onPressed: onPreviousRange,
                      icon: const Icon(Icons.chevron_left_rounded),
                    ),
                    Flexible(
                      child: Text(
                        rangeLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: inactive,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Periodo successivo',
                      visualDensity: VisualDensity.compact,
                      onPressed: onNextRange,
                      icon: const Icon(Icons.chevron_right_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: typeAction(
            type: TransactionType.income,
            label: 'Entrate',
            color: context.financeColors.positive,
            alignment: Alignment.centerRight,
          ),
        ),
      ],
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
