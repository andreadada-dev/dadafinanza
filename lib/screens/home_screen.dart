import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../core/money.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/dada_motion.dart';
import '../widgets/finance_quick_action.dart';
import '../widgets/home_dashboard_widget.dart';
import '../widgets/ui_helpers.dart';
import 'account_screens.dart' show showAccountEditor;
import 'advances_screen.dart';
import 'personal_settings_screen.dart';
import 'planning_screens.dart';
import 'quick_add_page.dart';
import 'root_screen.dart' as advanced;
import 'settings_screen.dart' show DashboardCustomizerScreen;

/// Canonical Home.
///
/// The financial overview is intentionally kept above the primary actions,
/// while visibility of each metric still follows "Personalizza Home".
class DadaHomeScreen extends StatelessWidget {
  const DadaHomeScreen({super.key});

  static const _fallbackTypes = <DashboardWidgetType>[
    DashboardWidgetType.totalBalance,
    DashboardWidgetType.monthlyCashFlow,
    DashboardWidgetType.safeToSpend,
    DashboardWidgetType.accounts,
    DashboardWidgetType.monthlyBudget,
    DashboardWidgetType.recentTransactions,
    DashboardWidgetType.upcomingRecurring,
    DashboardWidgetType.goals,
    DashboardWidgetType.topCategories,
    DashboardWidgetType.endMonthForecast,
    DashboardWidgetType.unassignedTransactions,
  ];

  static const _overviewTypes = <DashboardWidgetType>{
    DashboardWidgetType.totalBalance,
    DashboardWidgetType.monthlyIncome,
    DashboardWidgetType.monthlyExpense,
    DashboardWidgetType.safeToSpend,
  };

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final smartInsight = _smartInsight(state);
    final visible = _visibleWidgets(state);
    final overview = visible
        .where((config) => _overviewTypes.contains(config.type))
        .toList(growable: false);
    final widgets = visible
        .where((config) => !_overviewTypes.contains(config.type))
        .toList(growable: false);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          floating: true,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('DadaFinanza'),
              Text(
                DateFormat('MMMM yyyy', 'it_IT').format(DateTime.now()),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          actions: [
            IconButton(
              tooltip: state.hideBalance ? 'Mostra saldi' : 'Nascondi saldi',
              onPressed: () => state.setHideBalance(!state.hideBalance),
              icon: Icon(
                state.hideBalance
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
              ),
            ),
            IconButton(
              tooltip: 'Dashboard avanzata',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const Scaffold(body: advanced.HomeScreen()),
                ),
              ),
              icon: const Icon(Icons.dashboard_customize_outlined),
            ),
            IconButton(
              tooltip: 'Impostazioni',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalSettingsScreen(),
                ),
              ),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 130),
          sliver: SliverList.list(
            children: [
              if (state.userAccounts.isEmpty) ...[
                _SetupBlock(
                  onAccount: () => showAccountEditor(context),
                  onMovement: () =>
                      _openQuick(context, TransactionType.expense),
                ),
                const SizedBox(height: 24),
              ],
              if (overview.isNotEmpty) ...[
                DadaReveal(
                  key: const ValueKey('home-overview'),
                  child: _IvyFinanceOverview(
                    state: state,
                    configs: overview,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DadaReveal(
                key: const ValueKey('home-quick-actions'),
                delay: const Duration(milliseconds: 55),
                child: Row(
                  children: [
                    Expanded(
                      child: FinanceQuickAction(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Spesa',
                        color: context.financeColors.negative,
                        onTap: () =>
                            _openQuick(context, TransactionType.expense),
                      ),
                    ),
                    Expanded(
                      child: FinanceQuickAction(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Entrata',
                        color: context.financeColors.positive,
                        onTap: () =>
                            _openQuick(context, TransactionType.income),
                      ),
                    ),
                    Expanded(
                      child: FinanceQuickAction(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Trasferisci',
                        onTap: () =>
                            _openQuick(context, TransactionType.transfer),
                      ),
                    ),
                  ],
                ),
              ),
              if (state.advanceReceivableCents > 0 ||
                  state.advancePayableCents > 0 ||
                  smartInsight != null) ...[
                const SizedBox(height: 28),
                const SectionTitle('Per te'),
                if (state.advanceReceivableCents > 0 ||
                    state.advancePayableCents > 0)
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.handshake_outlined),
                    title: const Text('Anticipi'),
                    subtitle: Text(
                      state.hideBalance
                          ? '•••• da ricevere · •••• da restituire'
                          : '${moneyFor(state, Money.fromCents(state.advanceReceivableCents))} da ricevere · '
                                '${moneyFor(state, Money.fromCents(state.advancePayableCents))} da restituire',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdvancesScreen()),
                    ),
                  ),
                if (smartInsight case final insight?)
                  _InsightRow(insight: insight),
              ],
              const SizedBox(height: 30),
              if (widgets.isEmpty)
                EmptyState(
                  icon: Icons.dashboard_customize_outlined,
                  title: 'Home essenziale',
                  subtitle:
                      'Le metriche principali restano in alto. Riattiva altri widget dalla personalizzazione Home.',
                  action: TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardCustomizerScreen(),
                      ),
                    ),
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Personalizza Home'),
                  ),
                )
              else
                for (var index = 0; index < widgets.length; index++)
                  Padding(
                    key: ValueKey('home-${widgets[index].type.name}'),
                    padding: EdgeInsets.only(
                      bottom: switch (widgets[index].size) {
                        DashboardWidgetSize.small => 20,
                        DashboardWidgetSize.medium => 28,
                        DashboardWidgetSize.large => 36,
                      },
                    ),
                    child: DadaReveal(
                      delay: Duration(
                        milliseconds: 90 + (index.clamp(0, 6) * 35),
                      ),
                      child: HomeDashboardWidget(config: widgets[index]),
                    ),
                  ),
            ],
          ),
        ),
      ],
    );
  }

  List<DashboardWidgetConfig> _visibleWidgets(AppState state) {
    if (state.dashboardWidgets.isEmpty) {
      return [
        for (var i = 0; i < _fallbackTypes.length; i++)
          DashboardWidgetConfig(
            type: _fallbackTypes[i],
            enabled: true,
            orderIndex: i,
            size: DashboardWidgetSize.medium,
          ),
      ];
    }
    final items = state.dashboardWidgets
        .where((item) => item.enabled)
        .toList(growable: false);
    return [...items]..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  _HomeInsight? _smartInsight(AppState state) {
    if (!state.smartSuggestionsEnabled) return null;

    if (state.smartGoalSuggestions) {
      for (final goal in state.goals.where(
        (item) => !item.archived && !item.completed,
      )) {
        final plan = state.goalPlan(goal);
        if (plan.status.name == 'slightlyBehind' ||
            plan.status.name == 'unrealistic') {
          return _HomeInsight(
            icon: Icons.flag_outlined,
            title: goal.name,
            detail: plan.realisticWeekly > 0
                ? '${moneyFor(state, plan.realisticWeekly)}/settimana è il ritmo realistico stimato.'
                : 'Il cash-flow attuale non lascia ancora un margine stabile.',
            open: (context) => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const GoalsScreen()),
            ),
          );
        }
      }
    }

    if (state.detectedRecurringPatterns.isNotEmpty) {
      final pattern = state.detectedRecurringPatterns.first;
      return _HomeInsight(
        icon: Icons.event_repeat_rounded,
        title: 'Possibile ricorrenza',
        detail: '${pattern.normalizedText} · ${pattern.frequency}',
        open: (context) => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const RecurringScreen()),
        ),
      );
    }
    return null;
  }

  Future<void> _openQuick(BuildContext context, TransactionType type) async {
    final state = AppScope.of(context);
    final key = switch (type) {
      TransactionType.expense => 'preferred_expense_account',
      TransactionType.income => 'preferred_income_account',
      TransactionType.transfer => 'preferred_transfer_source',
    };
    final accountId = int.tryParse(await state.database.getSetting(key) ?? '');
    final destination = type == TransactionType.transfer
        ? int.tryParse(
            await state.database.getSetting('preferred_transfer_destination') ??
                '',
          )
        : null;
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickAddPage(
          initialTypeName: type.name,
          initialAccountId: accountId,
          initialToAccountId: destination,
        ),
      ),
    );
  }
}

class _IvyFinanceOverview extends StatelessWidget {
  const _IvyFinanceOverview({
    required this.state,
    required this.configs,
  });

  final AppState state;
  final List<DashboardWidgetConfig> configs;

  bool _shows(DashboardWidgetType type) =>
      configs.any((config) => config.type == type);

  DashboardWidgetConfig? _configFor(DashboardWidgetType type) {
    for (final config in configs) {
      if (config.type == type) return config;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showBalance = _shows(DashboardWidgetType.totalBalance);
    final metrics = <Widget>[];

    if (_shows(DashboardWidgetType.monthlyIncome)) {
      metrics.add(
        _OverviewMetric(
          label: 'Entrate',
          value: state.hideBalance
              ? '••••'
              : moneyFor(state, state.monthTotal(TransactionType.income)),
          icon: Icons.south_west_rounded,
          color: context.financeColors.positive,
        ),
      );
    }
    if (_shows(DashboardWidgetType.monthlyExpense)) {
      metrics.add(
        _OverviewMetric(
          label: 'Spese',
          value: state.hideBalance
              ? '••••'
              : moneyFor(state, state.monthTotal(TransactionType.expense)),
          icon: Icons.north_east_rounded,
          color: context.financeColors.negative,
        ),
      );
    }
    if (_shows(DashboardWidgetType.safeToSpend)) {
      metrics.add(
        _OverviewMetric(
          label: 'Disponibile',
          value: state.hideBalance ? '••••' : moneyFor(state, state.safeToSpend),
          icon: Icons.account_balance_wallet_rounded,
          color: scheme.primary,
        ),
      );
    }

    final balanceSize = switch (
      _configFor(DashboardWidgetType.totalBalance)?.size
    ) {
      DashboardWidgetSize.small => theme.textTheme.headlineMedium,
      DashboardWidgetSize.large => theme.textTheme.displaySmall,
      _ => theme.textTheme.headlineLarge,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: scheme.primary,
                  size: 21,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  DateFormat('MMM', 'it_IT').format(DateTime.now()),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          if (showBalance) ...[
            const SizedBox(height: 18),
            Text(
              'Saldo totale',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: ScaleTransition(
                  scale: Tween<double>(
                    begin: .97,
                    end: 1,
                  ).animate(animation),
                  child: child,
                ),
              ),
              child: Text(
                state.hideBalance
                    ? '••••••'
                    : moneyFor(state, state.totalBalance),
                key: ValueKey(state.hideBalance),
                style: balanceSize?.copyWith(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.4,
                ),
              ),
            ),
          ],
          if (metrics.isNotEmpty) ...[
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var index = 0; index < metrics.length; index++) ...[
                  if (index > 0) const SizedBox(width: 8),
                  Expanded(child: metrics[index]),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _OverviewMetric extends StatelessWidget {
  const _OverviewMetric({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      constraints: const BoxConstraints(minHeight: 78),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(
          alpha: theme.brightness == Brightness.dark ? .13 : .08,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 8),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: Text(
                value,
                key: ValueKey(value),
                style: theme.textTheme.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SetupBlock extends StatelessWidget {
  const _SetupBlock({required this.onAccount, required this.onMovement});

  final VoidCallback onAccount;
  final VoidCallback onMovement;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'Configura DadaFinanza',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      Text(
        'Parti dal primo conto oppure registra subito un movimento e assegnalo in seguito.',
        style: Theme.of(context).textTheme.bodyLarge,
      ),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
        runSpacing: 8,
        children: [
          FilledButton.icon(
            onPressed: onAccount,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Crea primo conto'),
          ),
          TextButton.icon(
            onPressed: onMovement,
            icon: const Icon(Icons.receipt_long_outlined),
            label: const Text('Registra movimento'),
          ),
        ],
      ),
    ],
  );
}

class _HomeInsight {
  const _HomeInsight({
    required this.icon,
    required this.title,
    required this.detail,
    required this.open,
  });

  final IconData icon;
  final String title;
  final String detail;
  final void Function(BuildContext context) open;
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.insight});

  final _HomeInsight insight;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 10,
    leading: Icon(insight.icon),
    title: Text(
      insight.title,
      style: const TextStyle(fontWeight: FontWeight.w700),
    ),
    subtitle: Text(insight.detail),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: () => insight.open(context),
  );
}
