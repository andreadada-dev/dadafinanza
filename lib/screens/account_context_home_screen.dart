import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../core/money.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/account_context_service.dart';
import '../widgets/account_context_selector.dart';
import '../widgets/balyn_motion.dart';
import '../widgets/finance_charts.dart';
import '../widgets/finance_quick_action.dart';
import '../widgets/home_dashboard_widget.dart';
import '../widgets/ui_helpers.dart';
import 'account_context_analytics_screen.dart';
import 'account_management_screen.dart' show SafeAccountDetailScreen;
import 'account_screens.dart' show showAccountEditor;
import 'advances_screen.dart';
import 'personal_settings_screen.dart';
import 'planning_screens.dart';
import 'quick_add_page.dart';
import 'root_screen.dart' as advanced;
import 'settings_screen.dart' show DashboardCustomizerScreen;
import 'transaction_screens.dart';

class AccountContextHomeScreen extends StatelessWidget {
  const AccountContextHomeScreen({
    required this.accountId,
    required this.onAccountChanged,
    super.key,
  });

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

  static const _fixedSummaryTypes = <DashboardWidgetType>{
    DashboardWidgetType.totalBalance,
    DashboardWidgetType.monthlyIncome,
    DashboardWidgetType.monthlyExpense,
    DashboardWidgetType.safeToSpend,
  };

  final int? accountId;
  final ValueChanged<int?> onAccountChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selectedAccount = state.accountById(accountId);
    final effectiveAccountId =
        selectedAccount == null ||
            selectedAccount.isArchived ||
            selectedAccount.isSystem
        ? null
        : selectedAccount.id;
    final isTotal = effectiveAccountId == null;
    final balance = AccountContextService.balanceFor(state, effectiveAccountId);
    final income = AccountContextService.monthTotal(
      state,
      effectiveAccountId,
      TransactionType.income,
    );
    final expense = AccountContextService.monthTotal(
      state,
      effectiveAccountId,
      TransactionType.expense,
    );
    final recent = AccountContextService.transactionsFor(
      state,
      effectiveAccountId,
    )..sort((a, b) => b.date.compareTo(a.date));
    final upcoming = AccountContextService.recurringFor(
      state,
      effectiveAccountId,
    );
    final smartInsight = isTotal ? _smartInsight(state) : null;
    final dashboardWidgets = isTotal
        ? _visibleDashboardWidgets(state)
        : const <DashboardWidgetConfig>[];
    final secondaryDashboardWidgets = dashboardWidgets
        .where((config) => !_fixedSummaryTypes.contains(config.type))
        .toList(growable: false);

    final vignetteColor = Color.lerp(
      Theme.of(context).colorScheme.tertiary,
      Colors.black,
      .72,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0, -.18),
          radius: 1.12,
          colors: [
            Colors.transparent,
            vignetteColor.withValues(alpha: .018),
            vignetteColor.withValues(alpha: .075),
          ],
          stops: const [0, .62, 1],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            backgroundColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AccountContextSelector(
                  accountId: effectiveAccountId,
                  onChanged: onAccountChanged,
                ),
                Text(
                  DateFormat(
                    'MMMM yyyy',
                    AppI18n.intlLocale,
                  ).format(DateTime.now()),
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
                tooltip: AppI18n.tr('Dashboard avanzata'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const Scaffold(body: advanced.HomeScreen()),
                  ),
                ),
                icon: const Icon(Icons.dashboard_customize_outlined),
              ),
              IconButton(
                tooltip: AppI18n.tr('Impostazioni'),
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
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 130),
            sliver: SliverList.list(
              children: [
                if (state.userAccounts.isEmpty) ...[
                  _SetupBlock(
                    onAccount: () => showAccountEditor(context),
                    onMovement: () => _openQuick(
                      context,
                      TransactionType.expense,
                      effectiveAccountId,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                if (isTotal) ...[
                  BalynReveal(
                    key: const ValueKey('context-home-total-summary'),
                    child: _TotalOverviewSummary(
                      balance: balance,
                      income: income,
                      expense: expense,
                      available: state.safeToSpend,
                    ),
                  ),
                  const SizedBox(height: 20),
                ] else ...[
                  BalynReveal(
                    key: ValueKey(
                      'context-home-account-${selectedAccount.id}',
                    ),
                    child: _SelectedAccountSummary(
                      account: selectedAccount!,
                      balance: balance,
                      income: income,
                      expense: expense,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
                BalynReveal(
                  key: const ValueKey('context-home-quick-actions'),
                  delay: const Duration(milliseconds: 55),
                  child: _QuickActions(
                    onOpen: (type) =>
                        _openQuick(context, type, effectiveAccountId),
                  ),
                ),
                if (isTotal) ...[
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
                        title: const Text(
                          'Anticipi',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          state.hideBalance
                              ? '•••• da ricevere · •••• da restituire'
                              : '${moneyFor(state, Money.fromCents(state.advanceReceivableCents))} da ricevere · ${moneyFor(state, Money.fromCents(state.advancePayableCents))} da restituire',
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdvancesScreen(),
                          ),
                        ),
                      ),
                    if (smartInsight case final insight?)
                      _InsightRow(insight: insight),
                  ],
                  const SizedBox(height: 30),
                  if (secondaryDashboardWidgets.isEmpty)
                    EmptyState(
                      icon: Icons.dashboard_customize_outlined,
                      title: 'Nessuna sezione aggiuntiva',
                      subtitle:
                          'Il riepilogo principale resta fisso in alto. Riattiva qui le sezioni che vuoi vedere.',
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
                    ...secondaryDashboardWidgets.map(
                      (config) => Padding(
                        key: ValueKey('context-home-${config.type.name}'),
                        padding: EdgeInsets.only(
                          bottom: switch (config.size) {
                            DashboardWidgetSize.small => 20,
                            DashboardWidgetSize.medium => 28,
                            DashboardWidgetSize.large => 36,
                          },
                        ),
                        child: BalynReveal(
                          delay: Duration(
                            milliseconds:
                                90 + (config.orderIndex.clamp(0, 6) * 30),
                          ),
                          child: HomeDashboardWidget(config: config),
                        ),
                      ),
                    ),
                ] else ...[
                  const SizedBox(height: 28),
                  AccountCategoryCarousel(accountId: selectedAccount!.id),
                  const SizedBox(height: 28),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      accountIcon(selectedAccount.iconKey),
                      color: Color(selectedAccount.colorValue),
                    ),
                    title: const Text(
                      'Apri conto',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      'Modifica e gestisci ${selectedAccount.name}',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SafeAccountDetailScreen(
                          accountId: selectedAccount.id,
                        ),
                      ),
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      Icons.insights_rounded,
                      color: Color(selectedAccount.colorValue),
                    ),
                    title: const Text(
                      'Analytics del conto',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Entrate, spese e andamento del conto',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AccountContextAnalyticsScreen(
                          accountId: selectedAccount.id,
                          onAccountChanged: onAccountChanged,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  const SectionTitle('Ultimi movimenti'),
                  if (recent.isEmpty)
                    const EmptyState(
                      icon: Icons.receipt_long_outlined,
                      title: 'Nessun movimento',
                      subtitle:
                          'Non ci sono ancora movimenti per questo conto.',
                    )
                  else
                    ...recent
                        .take(5)
                        .map((item) => TransactionListTile(item: item)),
                  const SizedBox(height: 32),
                  SectionTitle(
                    'Prossime scadenze',
                    trailing: TextButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RecurringScreen(),
                        ),
                      ),
                      child: const Text('Apri'),
                    ),
                  ),
                  if (upcoming.isEmpty)
                    const Text('Nessuna scadenza prevista per questo conto')
                  else
                    ...upcoming
                        .take(3)
                        .map(
                          (item) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.repeat_rounded,
                              color: transactionColor(context, item.type),
                            ),
                            title: Text(item.name),
                            subtitle: Text(
                              DateFormat(
                                'EEE d MMM',
                                AppI18n.intlLocale,
                              ).format(item.nextDate),
                            ),
                            trailing: Text(
                              state.hideBalance
                                  ? '••••'
                                  : moneyFor(state, item.amount),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<DashboardWidgetConfig> _visibleDashboardWidgets(AppState state) {
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

  Future<void> _openQuick(
    BuildContext context,
    TransactionType type,
    int? selectedAccountId,
  ) async {
    final state = AppScope.of(context);
    int? account = selectedAccountId;
    if (account == null) {
      final key = switch (type) {
        TransactionType.expense => 'preferred_expense_account',
        TransactionType.income => 'preferred_income_account',
        TransactionType.transfer => 'preferred_transfer_source',
      };
      account = int.tryParse(await state.database.getSetting(key) ?? '');
    }
    var destination = type == TransactionType.transfer
        ? int.tryParse(
            await state.database.getSetting('preferred_transfer_destination') ??
                '',
          )
        : null;
    if (destination == account) destination = null;
    if (!context.mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickAddPage(
          initialTypeName: type.name,
          initialAccountId: account,
          initialToAccountId: destination,
        ),
      ),
    );
  }
}

class _TotalOverviewSummary extends StatelessWidget {
  const _TotalOverviewSummary({
    required this.balance,
    required this.income,
    required this.expense,
    required this.available,
  });

  final double balance;
  final double income;
  final double expense;
  final double available;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final snapshots = state.netWorthSnapshots;
    final visibleSnapshots = snapshots.length > 24
        ? snapshots.sublist(snapshots.length - 24)
        : snapshots;
    final trendValues = [
      for (final point in visibleSnapshots) (point['amount'] as num).toDouble(),
    ];
    return _OverviewSurface(
      accent: Theme.of(context).colorScheme.tertiary,
      eyebrow: const Text('PATRIMONIO'),
      value: state.hideBalance ? '••••••' : moneyFor(state, balance),
      trendValues: state.hideBalance ? const [] : trendValues,
      metrics: [
        _OverviewValue(
          label: 'Entrate',
          value: state.hideBalance ? '••••' : moneyFor(state, income),
          color: context.financeColors.positive,
          icon: Icons.south_west_rounded,
        ),
        _OverviewValue(
          label: 'Spese',
          value: state.hideBalance ? '••••' : moneyFor(state, expense),
          color: context.financeColors.negative,
          icon: Icons.north_east_rounded,
        ),
        _OverviewValue(
          label: 'Disponibile',
          value: state.hideBalance ? '••••' : moneyFor(state, available),
          color: Theme.of(context).colorScheme.tertiary,
          icon: Icons.account_balance_wallet_outlined,
        ),
      ],
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onOpen});

  final ValueChanged<TransactionType> onOpen;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: FinanceQuickAction(
          icon: Icons.arrow_upward_rounded,
          label: 'Spesa',
          color: context.financeColors.negative,
          onTap: () => onOpen(TransactionType.expense),
        ),
      ),
      Expanded(
        child: FinanceQuickAction(
          icon: Icons.arrow_downward_rounded,
          label: 'Entrata',
          color: context.financeColors.positive,
          onTap: () => onOpen(TransactionType.income),
        ),
      ),
      Expanded(
        child: FinanceQuickAction(
          icon: Icons.swap_horiz_rounded,
          label: 'Trasferisci',
          color: Theme.of(context).colorScheme.tertiary,
          onTap: () => onOpen(TransactionType.transfer),
        ),
      ),
    ],
  );
}

class _SelectedAccountSummary extends StatelessWidget {
  const _SelectedAccountSummary({
    required this.account,
    required this.balance,
    required this.income,
    required this.expense,
  });

  final Account account;
  final double balance;
  final double income;
  final double expense;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final hidden = state.hideBalance || account.hideBalance;
    final accent = Color(account.colorValue);
    return _OverviewSurface(
      accent: accent,
      eyebrow: Text(
        account.name.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      value: hidden ? '••••••' : moneyFor(state, balance),
      metrics: [
        _OverviewValue(
          label: 'Entrate',
          value: hidden ? '••••' : moneyFor(state, income),
          color: context.financeColors.positive,
          icon: Icons.south_west_rounded,
        ),
        _OverviewValue(
          label: 'Spese',
          value: hidden ? '••••' : moneyFor(state, expense),
          color: context.financeColors.negative,
          icon: Icons.north_east_rounded,
        ),
        _OverviewValue(
          label: 'Saldo',
          value: hidden ? '••••' : moneyFor(state, balance),
          color: accent,
          icon: accountIcon(account.iconKey),
        ),
      ],
    );
  }
}

class _OverviewSurface extends StatelessWidget {
  const _OverviewSurface({
    required this.accent,
    required this.eyebrow,
    required this.value,
    required this.metrics,
    this.trendValues = const [],
  });

  final Color accent;
  final Widget eyebrow;
  final String value;
  final List<_OverviewValue> metrics;
  final List<double> trendValues;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: .14),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: accent,
                  size: 21,
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('MMM', AppI18n.intlLocale).format(DateTime.now()),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          DefaultTextStyle(
            style: theme.textTheme.labelMedium!.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              letterSpacing: .35,
            ),
            child: eyebrow,
          ),
          const SizedBox(height: 3),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOutCubic,
            child: FittedBox(
              key: ValueKey(value),
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  letterSpacing: -1.3,
                ),
              ),
            ),
          ),
          if (trendValues.length >= 2) ...[
            const SizedBox(height: 10),
            FinanceSparkline(values: trendValues, color: accent, height: 58),
          ],
          const SizedBox(height: 15),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var index = 0; index < metrics.length; index++) ...[
                if (index > 0) const SizedBox(width: 10),
                Expanded(child: metrics[index]),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewValue extends StatelessWidget {
  const _OverviewValue({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 7),
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
            child: Text(
              value,
              style: theme.textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
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
      Text('Configura Balyn', style: Theme.of(context).textTheme.headlineSmall),
      const SizedBox(height: 8),
      const Text('Parti dal primo conto oppure registra subito un movimento.'),
      const SizedBox(height: 16),
      Wrap(
        spacing: 12,
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
