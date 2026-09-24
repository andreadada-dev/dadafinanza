import 'package:flutter/material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../models/smart_models.dart';
import '../widgets/ui_helpers.dart';

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
            tooltip: 'Azioni apprendimento',
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
                      tooltip: 'Azioni pattern',
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
  static const _fixedSummaryTypes = <DashboardWidgetType>{
    DashboardWidgetType.totalBalance,
    DashboardWidgetType.monthlyIncome,
    DashboardWidgetType.monthlyExpense,
    DashboardWidgetType.safeToSpend,
  };

  List<DashboardWidgetConfig>? items;

  void _load(AppState state) {
    items ??=
        state.dashboardWidgets
            .where((item) => !_fixedSummaryTypes.contains(item.type))
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
  }

  Future<void> _save(AppState state) async {
    final fixed =
        state.dashboardWidgets
            .where((item) => _fixedSummaryTypes.contains(item.type))
            .toList()
          ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final normalizedItems = <DashboardWidgetConfig>[];
    for (var index = 0; index < items!.length; index++) {
      final item = items![index];
      normalizedItems.add(
        DashboardWidgetConfig(
          type: item.type,
          enabled: item.enabled,
          orderIndex: fixed.length + index,
          size: item.size,
        ),
      );
    }
    items = normalizedItems;
    final normalized = <DashboardWidgetConfig>[
      for (var index = 0; index < fixed.length; index++)
        DashboardWidgetConfig(
          type: fixed[index].type,
          enabled: true,
          orderIndex: index,
          size: fixed[index].size,
        ),
      ...normalizedItems,
    ];
    await state.saveDashboard(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    _load(state);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Personalizza Home'),
        actions: [
          TextButton(
            onPressed: () async {
              await state.resetDashboard();
              if (mounted) setState(() => items = null);
            },
            child: const Text('Ripristina'),
          ),
        ],
      ),
      body: ReorderableListView.builder(
        header: const Padding(
          padding: EdgeInsets.fromLTRB(8, 8, 8, 20),
          child: Text(
            'Patrimonio, Entrate, Spese e Disponibile restano fissi in alto, sopra le azioni rapide. Qui puoi mostrare, nascondere, ridimensionare e riordinare le sezioni successive.',
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 80),
        itemCount: items!.length,
        onReorderItem: (oldIndex, newIndex) async {
          setState(() {
            final item = items!.removeAt(oldIndex);
            items!.insert(newIndex, item);
          });
          await _save(state);
        },
        itemBuilder: (context, index) {
          final item = items![index];
          return ListTile(
            key: ValueKey(item.type),
            leading: const Icon(Icons.drag_handle_rounded),
            title: Text(item.type.label),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (item.type == DashboardWidgetType.topCategories) ...[
                  const SizedBox(height: 3),
                  const Text(
                    'Torta Spese/Entrate con periodo scorrevole e intervallo personalizzato.',
                  ),
                  const SizedBox(height: 6),
                ],
                DropdownButton<DashboardWidgetSize>(
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
                  onChanged: (size) async {
                    if (size == null) return;
                    setState(
                      () => items![index] = DashboardWidgetConfig(
                        type: item.type,
                        enabled: item.enabled,
                        orderIndex: item.orderIndex,
                        size: size,
                      ),
                    );
                    await _save(state);
                  },
                ),
              ],
            ),
            trailing: Switch(
              value: item.enabled,
              onChanged: (enabled) async {
                setState(
                  () => items![index] = DashboardWidgetConfig(
                    type: item.type,
                    enabled: enabled,
                    orderIndex: item.orderIndex,
                    size: item.size,
                  ),
                );
                await _save(state);
              },
            ),
          );
        },
      ),
    );
  }
}

String _sizeLabel(DashboardWidgetSize size) => switch (size) {
  DashboardWidgetSize.small => 'Compatto',
  DashboardWidgetSize.medium => 'Medio',
  DashboardWidgetSize.large => 'Grande',
};
