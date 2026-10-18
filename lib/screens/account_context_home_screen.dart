import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../core/money.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/account_context_service.dart';
import '../widgets/balyn_revolut_home_content.dart';
import '../widgets/balyn_revolut_home_hero.dart';
import '../widgets/balyn_recent_transactions_card.dart';
import '../widgets/balyn_motion.dart';
import '../widgets/balyn_editorial_components.dart';
import '../widgets/home_dashboard_widget.dart';
import '../widgets/ui_helpers.dart';
import 'account_context_analytics_screen.dart';
import 'balyn_activity_screen.dart';
import 'account_management_screen.dart'
    show AccountManagementScreen, SafeAccountDetailScreen;
import 'account_screens.dart' show showAccountEditor;
import 'advances_screen.dart';
import 'personal_settings_screen.dart';
import 'planning_screens.dart';
import 'quick_add_page.dart';
import 'root_screen.dart' as advanced;
import 'settings_screen.dart' show DashboardCustomizerScreen;

class AccountContextHomeScreen extends StatefulWidget
  const AccountContextHomeScreen({
    required this.accountId,
    required this.onAccountChanged,
    required this.selectedSection,
    required this.slideDirection,
    required this.activityInitialTab,
    required this.onSectionChanged,
    required this.onShowActivity,
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
  final int selectedSection;
  final int slideDirection;
  final int activityInitialTab;
  final ValueChanged<int> onSectionChanged;
  final ValueChanged<int> onShowActivity;

  @override
  State<AccountContextHomeScreen> createState() => _AccountContextHomeScreenState();
}

class _AccountContextHomeScreenState extends State<AccountContextHomeScreen> {
  late final PageController _pageController = PageController(
    initialPage: widget.selectedSection,
  );
  late int _requestedPage = widget.selectedSection;

  @override
  void didUpdateWidget(covariant AccountContextHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedSection != oldWidget.selectedSection &&
        _requestedPage != widget.selectedSection) {
      final next = widget.selectedSection;
      _requestedPage = next;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_pageController.hasClients) return;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 370),
          curve: Curves.easeOutCubic,
        );
      });
    }
  }

  void _selectHomePage(int next) {
    if (!_pageController.hasClients) {
      widget.onSectionChanged(next);
      return;
    }
    _requestedPage = next;
    _pageController.animateToPage(
      next,
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 390),
      curve: Curves.easeOutCubic,
    );
  }

  void _onHomePageChanged(int next) {
    _requestedPage = next;
    if (widget.selectedSection != next) widget.onSectionChanged(next);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accountId = widget.accountId;
    final onAccountChanged = widget.onAccountChanged;
    final selectedSection = widget.selectedSection;
    final activityInitialTab = widget.activityInitialTab;
    final onShowActivity = widget.onShowActivity;
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

    final hidden =
        state.hideBalance || (!isTotal && selectedAccount!.hideBalance);
    final dark = Theme.of(context).brightness == Brightness.dark;

    return ColoredBox(
      color: dark ? const Color(0xFF101018) : const Color(0xFFF7F8FA),
      child: NestedScrollView(
        key: const PageStorageKey('balyn-invest-home'),
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (context, _) => BalynRevolutHomeHero(
              title: isTotal ? 'Patrimonio totale' : selectedAccount!.name,
              balance: hidden ? '••••••' : moneyFor(state, balance),
              available: hidden
                  ? '••••'
                  : moneyFor(state, isTotal ? state.safeToSpend : balance),
              hideBalance: hidden,
              accounts: state.activeAccounts,
              currentAccountId: effectiveAccountId,
              onAccountChanged: onAccountChanged,
              selectedTab: selectedSection,
              sectionPage: _pageController.hasClients
                  ? (_pageController.page ?? selectedSection.toDouble())
                  : selectedSection.toDouble(),
              onTabChanged: _selectHomePage,
              onVisibility: () => state.setHideBalance(!state.hideBalance),
              onSearch: () => onShowActivity(0),
              onAnalytics: () => onShowActivity(1),
              onSettings: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PersonalSettingsScreen(),
                ),
              ),
              onExpense: () => _openQuick(
                context,
                TransactionType.expense,
                effectiveAccountId,
              ),
              onIncome: () => _openQuick(
                context,
                TransactionType.income,
                effectiveAccountId,
              ),
              onTransfer: () => _openQuick(
                context,
                TransactionType.transfer,
                effectiveAccountId,
              ),
              onMore: () => showModalBottomSheet<void>(
                context: context,
                useSafeArea: true,
                showDragHandle: true,
                builder: (sheetContext) => SafeArea(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ListTile(
                        leading: const Icon(
                          Icons.account_balance_wallet_outlined,
                        ),
                        title: const Text('Gestisci conti'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AccountManagementScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.handshake_outlined),
                        title: const Text('Anticipi'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdvancesScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.dashboard_customize_outlined),
                        title: const Text('Dashboard avanzata'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const Scaffold(body: advanced.HomeScreen()),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.tune_rounded),
                        title: const Text('Personalizza Home'),
                        onTap: () {
                          Navigator.pop(sheetContext);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DashboardCustomizerScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            ),
          ),

        ],
        body: PageView(
          key: const ValueKey('home-swipe-pages'),
          controller: _pageController,
          onPageChanged: _onHomePageChanged,
          physics: const PageScrollPhysics(),
          children: [
            _PersistentHomePage(
              child: CustomScrollView(
                key: const PageStorageKey('home-overview-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 9, 16, 130),
                    sliver: SliverList.list(
                      children: [

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              DateFormat(
                                'MMMM yyyy',
                                AppI18n.intlLocale,
                              ).format(DateTime.now()),
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // A compact real-data overview replaces the kit's fictional
                          // promotions, keeping its clear rounded white-strip rhythm.
                          BalynEditorialSurface(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const BalynEditorialIcon(
                                icon: Icons.calendar_month_outlined,
                                size: 42,
                              ),
                              title: const Text(
                                'Riepilogo del mese',
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              subtitle: Text(
                                hidden
                                    ? 'Entrate ••••  ·  Spese ••••'
                                    : 'Entrate ${moneyFor(state, income)}  ·  Spese ${moneyFor(state, expense)}',
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: const Icon(Icons.chevron_right_rounded),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AccountContextAnalyticsScreen(
                                    accountId: effectiveAccountId,
                                    onAccountChanged: onAccountChanged,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          BalynEditorialHeading(
                            title: 'Ultimi movimenti',
                            subtitle: 'Le operazioni più recenti',
                          ),
                          const SizedBox(height: 10),
                          BalynRecentTransactionsCard(
                            items: recent,
                            hideAmounts: hidden,
                            onSeeAll: () => onShowActivity(0),
                          ),
                          const SizedBox(height: 23),
                          BalynEditorialHeading(
                            title: 'In sintesi',
                            subtitle: 'Entrate, spese e disponibilità',
                          ),
                          const SizedBox(height: 10),
                          BalynRevolutHomeContent(
                            income: income,
                            expense: expense,
                            available: isTotal ? state.safeToSpend : balance,
                            hideValues: hidden,
                            showAccounts: true,
                            onSelectAccount: onAccountChanged,
                            onManageAccounts: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AccountManagementScreen(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          if (state.userAccounts.isEmpty) ...[
                            _SetupBlock(
                              onAccount: () => showAccountEditor(context),
                              onMovement: () => _openQuick(
                                context,
                                TransactionType.expense,
                                effectiveAccountId,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  subtitle: Text(
                                    state.hideBalance
                                        ? '•••• da ricevere · •••• da restituire'
                                        : '${moneyFor(state, Money.fromCents(state.advanceReceivableCents))} da ricevere · ${moneyFor(state, Money.fromCents(state.advancePayableCents))} da restituire',
                                  ),
                                  trailing: const Icon(
                                    Icons.chevron_right_rounded,
                                  ),
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
                                      builder: (_) =>
                                          const DashboardCustomizerScreen(),
                                    ),
                                  ),
                                  icon: const Icon(Icons.tune_rounded),
                                  label: const Text('Personalizza Home'),
                                ),
                              )
                            else
                              ...secondaryDashboardWidgets.map(
                                (config) => Padding(
                                  key: ValueKey(
                                    'context-home-${config.type.name}',
                                  ),
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
                                          90 +
                                          (config.orderIndex.clamp(0, 6) * 30),
                                    ),
                                    child: HomeDashboardWidget(config: config),
                                  ),
                                ),
                              ),
                          ] else ...[
                            const SizedBox(height: 28),
                            AccountCategoryCarousel(
                              accountId: selectedAccount!.id,
                            ),
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
                            const SizedBox(height: 24),
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
                              const Text(
                                'Nessuna scadenza prevista per questo conto',
                              )
                            else
                              ...upcoming
                                  .take(3)
                                  .map(
                                    (item) => ListTile(
                                      contentPadding: EdgeInsets.zero,
                                      leading: Icon(
                                        Icons.repeat_rounded,
                                        color: transactionColor(
                                          context,
                                          item.type,
                                        ),
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
            ),
            _PersistentHomePage(
              child: CustomScrollView(
                key: const PageStorageKey('home-accounts-scroll'),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 18, 16, 135),
                    sliver: SliverToBoxAdapter(
                      child: BalynRevolutHomeContent(
                        income: income,
                        expense: expense,
                        available: isTotal ? state.safeToSpend : balance,
                        hideValues: hidden,
                        showAccounts: false,
                        onSelectAccount: onAccountChanged,
                        onManageAccounts: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountManagementScreen(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _PersistentHomePage(
              child: BalynActivityScreen(
                accountId: effectiveAccountId,
                onAccountChanged: onAccountChanged,
                initialTab: activityInitialTab,
              ),
            ),
          ],
        ),
      ),
    );
  }

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
                      )
                    : selectedSection == 1
                    ? BalynRevolutHomeContent(
                        income: income,
                        expense: expense,
                        available: isTotal ? state.safeToSpend : balance,
                        hideValues: hidden,
                        showAccounts: false,
                        onSelectAccount: onAccountChanged,
                        onManageAccounts: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AccountManagementScreen(),
                          ),
                        ),
                      )
                    : SizedBox(
                        height: (MediaQuery.sizeOf(context).height * .78).clamp(
                          490.0,
                          820.0,
                        ),
                        child: BalynActivityScreen(
                          accountId: effectiveAccountId,
                          onAccountChanged: onAccountChanged,
                          initialTab: activityInitialTab,
                        ),
                      ),
              ),
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


class _PersistentHomePage extends StatefulWidget {
  const _PersistentHomePage({required this.child});
  final Widget child;

  @override
  State<_PersistentHomePage> createState() => _PersistentHomePageState();
}

class _PersistentHomePageState extends State<_PersistentHomePage>
    with AutomaticKeepAliveClientMixin<_PersistentHomePage> {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
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
