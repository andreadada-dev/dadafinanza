import 'package:balyn/l10n/localized_material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../models/smart_models.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/home_dashboard_widget.dart';
import '../widgets/balyn_home_widget_catalog.dart';
import '../widgets/balyn_omesh_hero_background.dart';

class _SettingsLink extends StatelessWidget {
  const _SettingsLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 12,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class SmartSuggestionsSettingsScreen extends StatelessWidget {
  const SmartSuggestionsSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Suggestions')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'Il sistema riconosce abitudini con statistiche locali e regole spiegabili. Non usa IA né cloud.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.bolt_rounded),
            title: const Text('Suggerimenti automatici'),
            subtitle: const Text(
              'Mostra “Completa” solo quando la confidenza è sufficiente.',
            ),
            value: state.smartSuggestionsEnabled,
            onChanged: (value) => state.setSetting(
              'smart_suggestions_enabled',
              value ? '1' : '0',
            ),
          ),
          const SizedBox(height: 16),
          const SectionTitle('Segnali'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Usa descrizione'),
            subtitle: const Text('È il segnale principale del modello locale.'),
            value: state.smartUseDescription,
            onChanged: state.smartSuggestionsEnabled
                ? (value) => state.setSetting(
                    'smart_use_description',
                    value ? '1' : '0',
                  )
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Usa importo'),
            subtitle: const Text(
              'Rafforza pattern con fasce di importo simili.',
            ),
            value: state.smartUseAmount,
            onChanged: state.smartSuggestionsEnabled
                ? (value) =>
                      state.setSetting('smart_use_amount', value ? '1' : '0')
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Usa giorno e orario'),
            subtitle: const Text(
              'Segnali deboli: rafforzano una previsione, non la creano da soli.',
            ),
            value: state.smartUseTime,
            onChanged: state.smartSuggestionsEnabled
                ? (value) =>
                      state.setSetting('smart_use_time', value ? '1' : '0')
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Rileva ricorrenze'),
            subtitle: const Text(
              'Propone di configurare pattern settimanali, mensili o annuali.',
            ),
            value: state.smartDetectRecurring,
            onChanged: state.smartSuggestionsEnabled
                ? (value) => state.setSetting(
                    'smart_detect_recurring',
                    value ? '1' : '0',
                  )
                : null,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Suggerimenti obiettivi'),
            subtitle: const Text(
              'Calcola un ritmo realistico usando il tuo cash-flow storico.',
            ),
            value: state.smartGoalSuggestions,
            onChanged: state.smartSuggestionsEnabled
                ? (value) => state.setSetting(
                    'smart_goal_suggestions',
                    value ? '1' : '0',
                  )
                : null,
          ),
          const SizedBox(height: 24),
          _SettingsLink(
            icon: Icons.tune_rounded,
            title: 'Sensibilità',
            subtitle: _sensitivityLabel(state.smartSensitivity),
            onTap: () => _pickSensitivity(context, state),
          ),
          _SettingsLink(
            icon: Icons.manage_search_rounded,
            title: 'Gestisci apprendimento',
            subtitle:
                '${state.learnedPatterns.length} pattern · ${state.detectedRecurringPatterns.length} ricorrenze rilevate',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LearningManagementScreen(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _sensitivityLabel(SmartSensitivity value) => switch (value) {
  SmartSensitivity.conservative => 'Conservativa',
  SmartSensitivity.balanced => 'Bilanciata',
  SmartSensitivity.proactive => 'Proattiva',
};

Future<void> _pickSensitivity(BuildContext context, AppState state) async {
  final result = await showModalBottomSheet<SmartSensitivity>(
    context: context,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sensibilità', style: Theme.of(context).textTheme.titleLarge),
          ...SmartSensitivity.values.map(
            (item) => RadioListTile<SmartSensitivity>(
              contentPadding: EdgeInsets.zero,
              value: item,
              groupValue: state.smartSensitivity,
              title: Text(_sensitivityLabel(item)),
              subtitle: Text(switch (item) {
                SmartSensitivity.conservative =>
                  'Richiede più esempi e una confidenza più alta.',
                SmartSensitivity.balanced =>
                  'Equilibrio tra utilità e prudenza. Consigliata.',
                SmartSensitivity.proactive =>
                  'Mostra prima i pattern, mantenendo sempre la conferma.',
              }),
              onChanged: (value) => Navigator.pop(context, value),
            ),
          ),
        ],
      ),
    ),
  );
  if (result != null) {
    await state.setSetting('smart_sensitivity', result.name);
  }
}

class LearningManagementScreen extends StatelessWidget {
  const LearningManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Apprendimento'),
        actions: [
          PopupMenuButton<String>(
            tooltip: AppI18n.tr('Azioni apprendimento'),
            onSelected: (value) async {
              if (value == 'clear') {
                final confirmed = await confirmDestructiveAction(
                  context,
                  title: 'Cancellare l’apprendimento?',
                  message:
                      'Pattern, feedback e soppressioni verranno eliminati. I movimenti resteranno invariati e il sistema potrà imparare di nuovo.',
                  confirmLabel: 'Cancella apprendimento',
                );
                if (confirmed) await state.clearLearning();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'clear',
                child: Text(
                  'Cancella apprendimento',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text(
            'I pattern sono ricavati dai tuoi movimenti. Puoi disattivarli, convertirli in regole esplicite o eliminarli senza modificare lo storico.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          if (state.learnedPatterns.isEmpty)
            const EmptyState(
              icon: Icons.school_outlined,
              title: 'Nessun pattern ancora',
              subtitle:
                  'Dopo alcuni movimenti coerenti compariranno qui le abitudini riconosciute.',
            )
          else
            ...state.learnedPatterns.map((pattern) {
              final category = state.categoryById(pattern.categoryId);
              final account = state.accountById(pattern.accountId);
              return Column(
                children: [
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(
                      pattern.enabled
                          ? Icons.auto_awesome_rounded
                          : Icons.visibility_off_outlined,
                    ),
                    title: Text(
                      pattern.normalizedText,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        '${pattern.sampleCount} esempi',
                        if (category != null) category.name,
                        if (account != null && !account.isSystem) account.name,
                        if (pattern.acceptedCount > 0)
                          '${pattern.acceptedCount} accettati',
                        if (pattern.rejectedCount > 0)
                          '${pattern.rejectedCount} rifiutati',
                      ].join(' · '),
                    ),
                    trailing: PopupMenuButton<String>(
                      tooltip: AppI18n.tr('Azioni pattern'),
                      onSelected: (value) async {
                        if (value == 'toggle') {
                          await state.setPatternEnabled(
                            pattern,
                            !pattern.enabled,
                          );
                        } else if (value == 'rule') {
                          await state.convertPatternToRule(pattern);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Regola manuale creata.'),
                              ),
                            );
                          }
                        } else if (value == 'delete') {
                          await state.deleteLearnedPattern(pattern);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'toggle',
                          child: Text(pattern.enabled ? 'Disattiva' : 'Attiva'),
                        ),
                        const PopupMenuItem(
                          value: 'rule',
                          child: Text('Converti in regola'),
                        ),
                        PopupMenuItem(
                          value: 'delete',
                          child: Text(
                            'Elimina pattern',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                ],
              );
            }),
        ],
      ),
    );
  }
}

class DashboardCustomizerScreen extends StatefulWidget {
  const DashboardCustomizerScreen({super.key});

  @override
  State<DashboardCustomizerScreen> createState() =>
      _DashboardCustomizerScreenState();
}

class _DashboardCustomizerScreenState extends State<DashboardCustomizerScreen> {
  List<DashboardWidgetConfig>? items;
  final Set<DashboardWidgetType> _expanded = {};
  Future<void> _pendingSave = Future<void>.value();

  void _load(AppState state) {
    items ??= BalynHomeWidgetCatalog.normalize(state.dashboardWidgets)
        .where((item) => !BalynHomeWidgetCatalog.fixed.contains(item.type))
        .toList(growable: true);
  }

  Future<void> _save(AppState state) async {
    final fixed = BalynHomeWidgetCatalog.normalize(state.dashboardWidgets)
        .where((item) => BalynHomeWidgetCatalog.fixed.contains(item.type))
        .toList();
    final snapshot = <DashboardWidgetConfig>[...fixed, ...items!];
    final normalized = [
      for (var index = 0; index < snapshot.length; index++)
        DashboardWidgetConfig(
          type: snapshot[index].type,
          enabled:
              BalynHomeWidgetCatalog.fixed.contains(snapshot[index].type) ||
              snapshot[index].enabled,
          orderIndex: index,
          size: snapshot[index].size,
        ),
    ];
    // A quick drag followed by a switch cannot let an older async database
    // write overwrite the user's latest layout.
    _pendingSave = _pendingSave.then((_) => state.saveDashboard(normalized));
    await _pendingSave;
  }

  void _update(
    AppState state,
    DashboardWidgetType type, {
    bool? enabled,
    DashboardWidgetSize? size,
  }) {
    final index = items!.indexWhere((item) => item.type == type);
    if (index < 0) return;
    final old = items![index];
    setState(() {
      items![index] = DashboardWidgetConfig(
        type: type,
        enabled: enabled ?? old.enabled,
        orderIndex: old.orderIndex,
        size: size ?? old.size,
      );
    });
    _save(state);
  }

  void _reorder(AppState state, int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) newIndex -= 1;
      final item = items!.removeAt(oldIndex);
      items!.insert(newIndex, item);
    });
    _save(state);
  }

  Future<void> _addElement(AppState state) async {
    final choices = items!.where((item) => !item.enabled).toList();
    if (choices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tutti i widget sono già attivi')),
      );
      return;
    }
    final type = await showModalBottomSheet<DashboardWidgetType>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .68,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 4, 20, 16),
                child: Text(
                  'Aggiungi alla Home',
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 19),
                ),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final item in choices)
                      ListTile(
                        leading: Icon(_homeWidgetIcon(item.type)),
                        title: Text(item.type.label),
                        trailing: const Icon(Icons.add_rounded),
                        onTap: () => Navigator.pop(sheetContext, item.type),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (!mounted || type == null) return;
    // An existing disabled entry is re-enabled; never insert the same type
    // twice into the persisted list.
    _update(state, type, enabled: true);
  }

  Widget _preview(
    BuildContext context,
    DashboardWidgetConfig config, {
    bool hero = false,
  }) {
    final state = AppScope.of(context);
    final realWidget = hero
        ? SizedBox(
            height: 145,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const BalynOMeshHeroBackground(
                  accent: Color(0xFF6221E9),
                  useBasicPalette: true,
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'PATRIMONIO TOTALE',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        state.hideBalance
                            ? '••••••'
                            : moneyFor(state, state.totalBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          )
        : HomeDashboardWidget(
            key: ValueKey('home-widget-preview-${config.type.name}'),
            config: config,
            showAccountsInsideSummary:
                BalynHomeWidgetCatalog.showAccountsInsideSnapshot(
                  BalynHomeWidgetCatalog.normalize(state.dashboardWidgets),
                ),
          );
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 13),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: Padding(
            padding: const EdgeInsets.all(12),
            // Real data and actual Home components, but never allow edits,
            // navigation, or accidental swipe-to-delete in preview mode.
            child: IgnorePointer(
              child: TickerMode(
                enabled: false,
                child: MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: realWidget,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _fixedTile(DashboardWidgetConfig config) {
    final expanded = _expanded.contains(config.type);
    return Card(
      key: ValueKey('fixed-${config.type.name}'),
      child: Column(
        children: [
          ListTile(
            title: Text(
              config.type == DashboardWidgetType.totalBalance
                  ? 'Hero · Patrimonio totale'
                  : config.type.label,
            ),
            subtitle: const Text('Sempre visibile nella Hero'),
            leading: const Icon(Icons.lock_outline_rounded),
            trailing: IconButton(
              key: ValueKey('expand-fixed-${config.type.name}'),
              tooltip: expanded ? 'Chiudi anteprima' : 'Apri anteprima',
              icon: Icon(
                expanded
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
              ),
              onPressed: () => setState(() {
                if (expanded) {
                  _expanded.remove(config.type);
                } else {
                  _expanded.add(config.type);
                }
              }),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.topCenter,
            child: expanded
                ? _preview(
                    context,
                    config,
                    hero: config.type == DashboardWidgetType.totalBalance,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _reorderableTile(
    AppState state,
    DashboardWidgetConfig item,
    int index,
  ) {
    final expanded = _expanded.contains(item.type);
    return Card(
      key: ValueKey('config-${item.type.name}'),
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        children: [
          Row(
            children: [
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(13, 15, 8, 15),
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Icon(_homeWidgetIcon(item.type), size: 19),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  item.type.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                key: ValueKey('expand-${item.type.name}'),
                tooltip: expanded ? 'Chiudi anteprima' : 'Apri anteprima',
                onPressed: () => setState(() {
                  if (expanded) {
                    _expanded.remove(item.type);
                  } else {
                    _expanded.add(item.type);
                  }
                }),
                icon: Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                ),
              ),
              Switch(
                key: ValueKey('enabled-${item.type.name}'),
                value: item.enabled,
                onChanged: (enabled) =>
                    _update(state, item.type, enabled: enabled),
              ),
              const SizedBox(width: 8),
            ],
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(48, 0, 14, 7),
            child: Row(
              children: [
                Text(
                  'Dimensione',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 8),
                DropdownButton<DashboardWidgetSize>(
                  key: ValueKey('size-${item.type.name}'),
                  value: item.size,
                  isDense: true,
                  underline: const SizedBox.shrink(),
                  items: DashboardWidgetSize.values
                      .map(
                        (size) => DropdownMenuItem(
                          value: size,
                          child: Text(_sizeLabel(size)),
                        ),
                      )
                      .toList(),
                  onChanged: (size) {
                    if (size != null) _update(state, item.type, size: size);
                  },
                ),
                const Spacer(),
                if (!item.enabled)
                  Text(
                    'Nascosto',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          if (item.type == DashboardWidgetType.topCategories)
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 7),
              child: Text(
                'Torta Spese/Entrate con periodo scorrevole e intervallo personalizzato.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          if (item.type == DashboardWidgetType.accounts &&
              items!.any(
                (entry) =>
                    entry.type == DashboardWidgetType.financialSnapshot &&
                    entry.enabled,
              ))
            const Padding(
              padding: EdgeInsets.fromLTRB(15, 0, 15, 7),
              child: Text(
                'La lista conti di In sintesi viene nascosta per evitare doppioni.',
                style: TextStyle(fontSize: 11),
              ),
            ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            alignment: Alignment.topCenter,
            child: expanded ? _preview(context, item) : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _load(state);
    final configs = BalynHomeWidgetCatalog.normalize(state.dashboardWidgets);
    final fixed = configs.where(
      (item) => BalynHomeWidgetCatalog.fixed.contains(item.type),
    );
    final duplicates =
        state.dashboardWidgets.length -
        state.dashboardWidgets.map((item) => item.type).toSet().length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizza Home'),
        actions: [
          TextButton(
            onPressed: () async {
              await _pendingSave;
              await state.resetDashboard();
              if (mounted) {
                setState(() {
                  items = null;
                  _expanded.clear();
                });
              }
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const ValueKey('add-home-widget'),
        onPressed: () => _addElement(state),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Aggiungi'),
      ),
      body: ReorderableListView.builder(
        buildDefaultDragHandles: false,
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 90),
        header: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 2, 4, 10),
              child: Text(
                'Trascina gli elementi dalla maniglia a sinistra per '
                'cambiare il loro ordine. Tocca la freccia V per '
                'vedere il widget reale con i tuoi dati.',
              ),
            ),
            if (duplicates > 0)
              Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  '${duplicates} duplicati nei dati salvati: '
                  'verranno unificati al prossimo salvataggio.',
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                'Elementi fissi',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 6),
            for (final item in fixed) _fixedTile(item),
            const SizedBox(height: 19),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5),
              child: Text(
                'Sezioni riordinabili',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 5),
          ],
        ),
        itemCount: items!.length,
        onReorder: (oldIndex, newIndex) => _reorder(state, oldIndex, newIndex),
        itemBuilder: (context, index) =>
            _reorderableTile(state, items![index], index),
      ),
    );
  }
}

IconData _homeWidgetIcon(DashboardWidgetType type) => switch (type) {
  DashboardWidgetType.monthlyOverview => Icons.calendar_month_outlined,
  DashboardWidgetType.recentTransactions => Icons.receipt_long_outlined,
  DashboardWidgetType.financialSnapshot =>
    Icons.account_balance_wallet_outlined,
  DashboardWidgetType.smartHighlights => Icons.auto_awesome_outlined,
  DashboardWidgetType.topCategories => Icons.donut_large_outlined,
  DashboardWidgetType.accounts => Icons.account_balance_outlined,
  DashboardWidgetType.goals => Icons.flag_outlined,
  DashboardWidgetType.netWorthTrend => Icons.show_chart_rounded,
  DashboardWidgetType.monthlyBudget ||
  DashboardWidgetType.closestBudget => Icons.pie_chart_outline_rounded,
  DashboardWidgetType.financeCalendar ||
  DashboardWidgetType.upcomingRecurring => Icons.event_note_outlined,
  _ => Icons.widgets_outlined,
};

String _sizeLabel(DashboardWidgetSize size) => switch (size) {
  DashboardWidgetSize.small => 'Compatto',
  DashboardWidgetSize.medium => 'Medio',
  DashboardWidgetSize.large => 'Grande',
};
