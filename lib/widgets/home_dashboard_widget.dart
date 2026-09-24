import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/account_context_service.dart';
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

class AccountCategoryCarousel extends StatelessWidget {
  const AccountCategoryCarousel({
    required this.accountId,
    this.size = DashboardWidgetSize.medium,
    super.key,
  });

  final int accountId;
  final DashboardWidgetSize size;

  @override
  Widget build(BuildContext context) => _TopCategoriesDonut(
    key: ValueKey(accountId),
    config: DashboardWidgetConfig(
      type: DashboardWidgetType.topCategories,
      enabled: true,
      orderIndex: 0,
      size: size,
    ),
    accountId: accountId,
  );
}

class _TopCategoriesDonut extends StatefulWidget {
  const _TopCategoriesDonut({required this.config, this.accountId, super.key});

  final DashboardWidgetConfig config;
  final int? accountId;

  @override
  State<_TopCategoriesDonut> createState() => _TopCategoriesDonutState();
}

enum _CategoryChartRange { today, thisWeek, thisMonth, custom }

class _TopCategoriesDonutState extends State<_TopCategoriesDonut>
    with SingleTickerProviderStateMixin {
  static const _initialCarouselPage = 1000;

  late final PageController _typePageController;
  late final AnimationController _swipeHintController;
  late final Animation<double> _swipeHintAnimation;

  var _selectedIndex = -1;
  var _type = TransactionType.expense;
  var _range = _CategoryChartRange.thisMonth;
  var _carouselDragging = false;
  var _initialRangeResolved = false;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _typePageController = PageController(initialPage: _initialCarouselPage);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialRangeResolved) return;
    _initialRangeResolved = true;
    final state = AppScope.of(context);
    _range = _hasTodayData(state, TransactionType.expense)
        ? _CategoryChartRange.today
        : _CategoryChartRange.thisWeek;
  }

  @override
  void dispose() {
    _typePageController.dispose();
    _swipeHintController.dispose();
    super.dispose();
  }

  (DateTime, DateTime) _todayBounds() {
    final now = DateTime.now();
    return (
      DateTime(now.year, now.month, now.day),
      DateTime(now.year, now.month, now.day + 1),
    );
  }

  bool _hasTodayData(AppState state, TransactionType type) {
    final (from, to) = _todayBounds();
    return AccountContextService.periodTotal(
          state,
          widget.accountId,
          type,
          from,
          to,
        ).abs() >
        .005;
  }

  List<_CategoryChartRange> _availableRanges(
    AppState state,
    TransactionType type,
  ) => [
    if (_hasTodayData(state, type)) _CategoryChartRange.today,
    _CategoryChartRange.thisWeek,
    _CategoryChartRange.thisMonth,
    _CategoryChartRange.custom,
  ];

  (DateTime, DateTime) _bounds() {
    final now = DateTime.now();

    return switch (_range) {
      _CategoryChartRange.today => _todayBounds(),
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
      _CategoryChartRange.thisMonth => (
        DateTime(now.year, now.month),
        DateTime(now.year, now.month + 1),
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
    _CategoryChartRange.today => 'Oggi',
    _CategoryChartRange.thisWeek => 'Settimana',
    _CategoryChartRange.thisMonth => 'Mese',
    _CategoryChartRange.custom =>
      _customRange == null
          ? 'Custom'
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
    final state = AppScope.of(context);
    final ranges = _availableRanges(state, _type);
    final current = ranges.indexOf(_range);
    final safeCurrent = current < 0 ? 0 : current;
    final nextIndex = (safeCurrent + delta + ranges.length) % ranges.length;
    _selectRange(ranges[nextIndex]);
  }

  TransactionType _typeForPage(int page) =>
      page.isEven ? TransactionType.expense : TransactionType.income;

  void _setDragging(bool value) {
    if (_carouselDragging == value) return;
    setState(() {
      _carouselDragging = value;
      if (value) _selectedIndex = -1;
    });
  }

  void _commitCarouselPage() {
    if (!_typePageController.hasClients) return;
    final page = _typePageController.page?.round() ?? _initialCarouselPage;
    final nextType = _typeForPage(page);
    final state = AppScope.of(context);
    setState(() {
      _carouselDragging = false;
      if (nextType != _type) {
        _type = nextType;
        _selectedIndex = -1;
        if (_range == _CategoryChartRange.today &&
            !_hasTodayData(state, nextType)) {
          _range = _CategoryChartRange.thisWeek;
        }
      }
    });
  }

  List<MapEntry<Category, double>> _topCategories(
    AppState state,
    TransactionType type,
    int limit,
    DateTime from,
    DateTime to,
  ) {
    final totals = <int, double>{};

    final transactions = AccountContextService.analyticTransactionsFor(
      state,
      widget.accountId,
      from: from,
      to: to,
    );

    for (final transaction in transactions) {
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

  _CategoryCarouselData _dataFor(
    BuildContext context,
    AppState state,
    TransactionType type,
    int limit,
    DateTime from,
    DateTime to,
  ) {
    final top = _topCategories(state, type, limit, from, to);
    final total = AccountContextService.periodTotal(
      state,
      widget.accountId,
      type,
      from,
      to,
    ).abs();
    final isExpense = type == TransactionType.expense;
    final accent = isExpense
        ? context.financeColors.negative
        : context.financeColors.positive;

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

    return _CategoryCarouselData(
      top: top,
      total: total,
      slices: slices,
      accent: accent,
      icon: isExpense
          ? Icons.arrow_upward_rounded
          : Icons.arrow_downward_rounded,
      emptyLabel: isExpense
          ? 'Nessuna spesa da mostrare nel periodo'
          : 'Nessuna entrata da mostrare nel periodo',
    );
  }

  Widget _buildCarouselPage({
    required BuildContext context,
    required AppState state,
    required TransactionType type,
    required int limit,
    required DateTime from,
    required DateTime to,
    required double chartSize,
  }) {
    final data = _dataFor(context, state, type, limit, from, to);
    final interactive = !_carouselDragging && type == _type;
    final pageSelectedIndex = interactive ? _selectedIndex : -1;
    final selected =
        pageSelectedIndex >= 0 && pageSelectedIndex < data.slices.length
        ? data.slices[pageSelectedIndex]
        : null;

    return Center(
      child: SizedBox(
        width: double.infinity,
        height: chartSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            if (data.total > 0 && data.slices.isNotEmpty)
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
                        enabled: interactive,
                        touchCallback: (event, response) {
                          if (!interactive ||
                              event is! FlTapDownEvent ||
                              response?.touchedSection == null) {
                            return;
                          }
                          final next =
                              response!.touchedSection!.touchedSectionIndex;
                          setState(() {
                            _selectedIndex = _selectedIndex == next ? -1 : next;
                          });
                        },
                      ),
                      sections: [
                        for (var index = 0; index < data.slices.length; index++)
                          PieChartSectionData(
                            color:
                                pageSelectedIndex == -1 ||
                                    pageSelectedIndex == index
                                ? data.slices[index].color
                                : data.slices[index].color.withValues(
                                    alpha: .22,
                                  ),
                            value: data.slices[index].amount,
                            title: '',
                            radius:
                                chartSize *
                                (pageSelectedIndex == index ? .165 : .145),
                            showTitle: false,
                          ),
                      ],
                    ),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  ),
                ),
              ),
            Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOutCubic,
                child: selected == null
                    ? _DonutPeriodCenter(
                        key: ValueKey('${type.name}-${_range.name}-period'),
                        icon: data.icon,
                        accent: data.accent,
                        rangeLabel: _rangeLabel,
                        totalLabel: state.hideBalance
                            ? '••••'
                            : moneyFor(state, data.total),
                        onPreviousRange: () => _stepRange(-1),
                        onNextRange: () => _stepRange(1),
                      )
                    : _SelectedDonutCenter(
                        key: ValueKey(
                          '${type.name}-${_range.name}-$pageSelectedIndex',
                        ),
                        slice: selected,
                        percentage: data.total <= 0
                            ? 0
                            : selected.amount / data.total,
                        amountLabel: state.hideBalance
                            ? '••••'
                            : moneyFor(state, selected.amount),
                        onTap: () => setState(() => _selectedIndex = -1),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
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
    final activeData = _dataFor(context, state, _type, limit, from, to);
    if (_selectedIndex >= activeData.slices.length) _selectedIndex = -1;

    final chartSize = switch (widget.config.size) {
      DashboardWidgetSize.small => 210.0,
      DashboardWidgetSize.medium => 248.0,
      DashboardWidgetSize.large => 288.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: chartSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Semantics(
                label:
                    'Carosello categorie. Scorri a destra o sinistra per passare tra Spese ed Entrate.',
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollStartNotification &&
                        notification.dragDetails != null) {
                      _setDragging(true);
                    } else if (notification is ScrollEndNotification) {
                      _commitCarouselPage();
                    }
                    return false;
                  },
                  child: PageView.builder(
                    controller: _typePageController,
                    allowImplicitScrolling: true,
                    physics: const PageScrollPhysics(),
                    itemBuilder: (context, page) => _buildCarouselPage(
                      context: context,
                      state: state,
                      type: _typeForPage(page),
                      limit: limit,
                      from: from,
                      to: to,
                      chartSize: chartSize,
                    ),
                  ),
                ),
              ),
              IgnorePointer(
                child: AnimatedOpacity(
                  opacity: _carouselDragging ? 0 : 1,
                  duration: const Duration(milliseconds: 160),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _SwipeHintChevron(
                        direction: -1,
                        animation: _swipeHintAnimation,
                      ),
                      _SwipeHintChevron(
                        direction: 1,
                        animation: _swipeHintAnimation,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          child: activeData.top.isEmpty || activeData.total <= 0
              ? Center(
                  key: ValueKey('${_type.name}-empty-${_range.name}'),
                  child: Text(
                    activeData.emptyLabel,
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              : Column(
                  key: ValueKey('${_type.name}-list-${_range.name}'),
                  children: [
                    for (final entry in activeData.top)
                      _CategoryDonutRow(
                        category: entry.key,
                        amount: entry.value.abs(),
                        total: activeData.total,
                        state: state,
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _CategoryCarouselData {
  const _CategoryCarouselData({
    required this.top,
    required this.total,
    required this.slices,
    required this.accent,
    required this.icon,
    required this.emptyLabel,
  });

  final List<MapEntry<Category, double>> top;
  final double total;
  final List<_DonutSlice> slices;
  final Color accent;
  final IconData icon;
  final String emptyLabel;
}

class _SwipeHintChevron extends StatelessWidget {
  const _SwipeHintChevron({required this.direction, required this.animation});

  final int direction;
  final Animation<double> animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final travel = 4 + animation.value * 5;
        return Transform.translate(
          offset: Offset(direction * travel, 0),
          child: Opacity(
            opacity: .34 + animation.value * .46,
            child: Icon(
              direction < 0
                  ? Icons.chevron_left_rounded
                  : Icons.chevron_right_rounded,
              size: 30,
              color: theme.colorScheme.onSurface,
            ),
          ),
        );
      },
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
