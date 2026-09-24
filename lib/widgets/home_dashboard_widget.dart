import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../screens/account_management_screen.dart';
import '../screens/account_screens.dart' show showAccountEditor;
import '../screens/canonical_shell.dart'
    show CanonicalDashboardWidget, CategoryDetailScreen;
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

class _TopCategoriesDonutState extends State<_TopCategoriesDonut> {
  var _selectedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final limit = switch (widget.config.size) {
      DashboardWidgetSize.small => 3,
      DashboardWidgetSize.medium => 4,
      DashboardWidgetSize.large => 5,
    };
    final top = state.topExpenseCategories(limit: limit);
    final totalExpense = state.monthTotal(TransactionType.expense).abs();

    if (top.isEmpty || totalExpense <= 0) {
      return const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle('Spese per categoria'),
          Text('Nessuna spesa da mostrare questo mese'),
        ],
      );
    }

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
    final other = totalExpense > shown ? totalExpense - shown : 0.0;
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
      DashboardWidgetSize.small => 158.0,
      DashboardWidgetSize.medium => 184.0,
      DashboardWidgetSize.large => 212.0,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(
          'Spese per categoria',
          trailing: Text(
            state.hideBalance ? '••••' : moneyFor(state, totalExpense),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: context.financeColors.negative,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(height: 4),
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
                        sectionsSpace: 3,
                        centerSpaceRadius: chartSize * .25,
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
                                  : slices[index].color.withValues(alpha: .22),
                              value: slices[index].amount * progress,
                              title: '',
                              radius: _selectedIndex == index ? 26 : 21,
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
                      key: ValueKey(_selectedIndex),
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          selected?.category == null
                              ? Icons.pie_chart_rounded
                              : categoryIcon(selected!.category!.iconKey),
                          size: 22,
                          color:
                              selected?.color ??
                              Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          selected?.label ?? 'Questo mese',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          selected == null
                              ? '${slices.length} categorie'
                              : '${(selected.amount / totalExpense * 100).round()}%',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color:
                                    selected?.color ??
                                    Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w900,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        for (final entry in top)
          _CategoryDonutRow(
            category: entry.key,
            amount: entry.value.abs(),
            total: totalExpense,
            state: state,
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
