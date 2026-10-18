import 'package:balyn/l10n/localized_material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/quick_preset_service.dart';
import '../widgets/full_page_empty_state.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/balyn_preset_visual.dart';

class PresetManagementScreen extends StatefulWidget {
  const PresetManagementScreen({this.startCreating = false, super.key});
  final bool startCreating;

  @override
  State<PresetManagementScreen> createState() => _PresetManagementScreenState();
}

class _PresetManagementScreenState extends State<PresetManagementScreen> {
  List<QuickPreset>? items;
  bool _requestedInitialLoad = false;

  Future<void> _load() async {
    final state = AppScope.of(context);
    final value = await QuickPresetService(state.database).all();
    if (mounted) setState(() => items = value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_requestedInitialLoad) return;
    _requestedInitialLoad = true;
    _load();
    if (widget.startCreating) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await _edit(context, AppScope.of(context));
        if (mounted) await _load();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final presets = items;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preset rapidi'),
        actions: [
          IconButton(
            tooltip: AppI18n.tr('Nuovo preset'),
            onPressed: () async {
              await _edit(context, state);
              await _load();
            },
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: presets == null
          ? const Center(child: CircularProgressIndicator())
          : presets.isEmpty
          ? FullPageEmptyState(
              icon: Icons.bookmark_add_outlined,
              title: 'Nessun preset',
              subtitle:
                  'Crea scorciatoie per i movimenti che inserisci spesso.',
              action: FilledButton.icon(
                onPressed: () async {
                  await _edit(context, state);
                  await _load();
                },
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crea preset'),
              ),
            )
          : ReorderableListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
              itemCount: presets.length,
              onReorderItem: (oldIndex, newIndex) async {
                if (newIndex > oldIndex) newIndex--;
                final moved = presets.removeAt(oldIndex);
                presets.insert(newIndex, moved);
                setState(() {});
                await QuickPresetService(state.database).reorder(presets);
              },
              itemBuilder: (context, index) {
                final preset = presets[index];
                return ListTile(
                  key: ValueKey(preset.id),
                  contentPadding: EdgeInsets.zero,
                  minVerticalPadding: 12,
                  leading: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.drag_handle_rounded),
                      const SizedBox(width: 9),
                      BalynPresetGlyph(
                        name: preset.name,
                        iconKey: preset.iconKey,
                        colorValue: preset.colorValue,
                      ),
                    ],
                  ),
                  title: Text(
                    preset.name,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_summary(state, preset)),
                  trailing: PopupMenuButton<String>(
                    tooltip: AppI18n.tr('Azioni preset'),
                    onSelected: (value) async {
                      if (value == 'edit') {
                        await _edit(context, state, existing: preset);
                      } else if (value == 'delete') {
                        final confirmed = await confirmDestructiveAction(
                          context,
                          title: 'Eliminare “${preset.name}”?',
                          message: 'Il preset verrà rimosso. I movimenti già registrati non cambieranno.',
                        );
                        if (confirmed) {
                          await QuickPresetService(state.database)
                              .delete(preset.id);
                        }
                      }
                      if (mounted) await _load();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text('Modifica'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text(
                          'Elimina',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                  onTap: () async {
                    await _edit(context, state, existing: preset);
                    if (mounted) await _load();
                  },
                );
              },
            ),
    );
  }

  String _summary(AppState state, QuickPreset item) {
    final account = state.accountById(item.accountId)?.name;
    final destination = state.accountById(item.toAccountId)?.name;
    final category = state.categoryById(item.categoryId)?.name;
    return [
      item.type.label,
      if (category != null) category,
      if (account != null) account,
      if (destination != null) '→ $destination',
      if (item.amount != null) moneyFor(state, item.amount!),
    ].join(' · ');
  }

  Future<void> _edit(
    BuildContext context,
    AppState state, {
    QuickPreset? existing,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final amount = TextEditingController(
      text: existing?.amount == null
          ? ''
          : existing!.amount!.toStringAsFixed(2),
    );
    final note = TextEditingController(text: existing?.note ?? '');
    var type = existing?.type ?? TransactionType.expense;
    String? iconKey = existing?.iconKey;
    Color iconColor = Color(existing?.colorValue ?? 0xFFFFFFFF);
    int? accountId = existing?.accountId;
    int? toAccountId = existing?.toAccountId;
    int? categoryId = existing?.categoryId;
    final service = QuickPresetService(state.database);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            4,
            20,
            MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Nuovo preset' : 'Modifica preset',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                TextField(
                  controller: name,
                  autofocus: existing == null,
                  decoration: InputDecoration(labelText: AppI18n.tr('Nome')),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: BalynPresetGlyph(
                    name: name.text.isEmpty ? 'P' : name.text,
                    iconKey: iconKey,
                    colorValue: iconColor.toARGB32(),
                  ),
                  title: const Text('Icona del preset'),
                  subtitle: Text(
                    iconKey == null
                        ? 'Iniziale del nome (predefinita)'
                        : 'Icona personalizzata',
                  ),
                  trailing: const Icon(Icons.edit_outlined, size: 18),
                  onTap: () async {
                    final selected = await showIconPicker(
                      sheetContext,
                      options: presetIconOptions,
                      selected: iconKey ?? '',
                    );
                    if (selected != null) {
                      setSheetState(() => iconKey = selected);
                    }
                  },
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setSheetState(() => iconKey = null),
                    child: const Text('Usa iniziale'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Colore icona',
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: <Color>[Colors.white, ...categoryPalette]
                      .map(
                        (candidate) => Semantics(
                          button: true,
                          selected: candidate == iconColor,
                          label: 'Colore preset',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                setSheetState(() => iconColor = candidate),
                            child: SizedBox.square(
                              dimension: 42,
                              child: Center(
                                child: Container(
                                  height: 28,
                                  width: 28,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: candidate,
                                    border: Border.all(
                                      color: Theme.of(sheetContext)
                                          .colorScheme
                                          .outlineVariant,
                                    ),
                                  ),
                                  child: candidate == iconColor
                                      ? Icon(
                                          Icons.check_rounded,
                                          size: 17,
                                          color: candidate == Colors.white
                                              ? Colors.black
                                              : Colors.white,
                                        )
                                      : null,
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<TransactionType>(
                  initialValue: type,
                  decoration: InputDecoration(labelText: AppI18n.tr('Tipo')),
                  items: TransactionType.values
                      .map(
                        (item) => DropdownMenuItem(
                          value: item,
                          child: Text(item.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setSheetState(() {
                      type = value;
                      categoryId = null;
                      if (type != TransactionType.transfer) toAccountId = null;
                    });
                  },
                ),
                DropdownButtonFormField<int?>(
                  initialValue: accountId,
                  decoration: InputDecoration(
                    labelText: AppI18n.tr('Conto preferito'),
                  ),
                  items: [
                    const DropdownMenuItem<int?>(
                      value: null,
                      child: Text('Usa ultimo conto'),
                    ),
                    ...state.activeAccounts
                        .where((item) => !item.isLocked)
                        .map(
                          (item) => DropdownMenuItem<int?>(
                            value: item.id,
                            child: Text(item.name),
                          ),
                        ),
                  ],
                  onChanged: (value) => setSheetState(() {
                    accountId = value;
                    if (toAccountId == accountId) toAccountId = null;
                  }),
                ),
                if (type == TransactionType.transfer)
                  DropdownButtonFormField<int?>(
                    initialValue: toAccountId,
                    decoration: InputDecoration(
                      labelText: AppI18n.tr('Destinazione'),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Scegli nel Quick Add'),
                      ),
                      ...state.activeAccounts
                          .where(
                            (item) => !item.isLocked && item.id != accountId,
                          )
                          .map(
                            (item) => DropdownMenuItem<int?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                    ],
                    onChanged: (value) => toAccountId = value,
                  )
                else
                  DropdownButtonFormField<int?>(
                    initialValue: categoryId,
                    decoration: InputDecoration(
                      labelText: AppI18n.tr('Categoria'),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Scegli nel Quick Add'),
                      ),
                      ...state
                          .categoriesFor(type)
                          .map(
                            (item) => DropdownMenuItem<int?>(
                              value: item.id,
                              child: Text(item.name),
                            ),
                          ),
                    ],
                    onChanged: (value) => categoryId = value,
                  ),
                TextField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: InputDecoration(
                    labelText: AppI18n.tr('Importo opzionale'),
                    suffixText: state.currency,
                  ),
                ),
                TextField(
                  controller: note,
                  decoration: InputDecoration(
                    labelText: AppI18n.tr('Nota opzionale'),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      final parsed = amount.text.trim().isEmpty
                          ? null
                          : double.tryParse(amount.text.replaceAll(',', '.'));
                      if (name.text.trim().isEmpty ||
                          (amount.text.trim().isNotEmpty &&
                              (parsed == null || parsed <= 0)) ||
                          (type == TransactionType.transfer &&
                              accountId != null &&
                              accountId == toAccountId)) {
                        return;
                      }
                      await service.save(
                        id: existing?.id,
                        name: name.text.trim(),
                        type: type,
                        accountId: accountId,
                        toAccountId: toAccountId,
                        categoryId: categoryId,
                        amount: parsed,
                        note: note.text.trim(),
                        tags: existing?.tags ?? const [],
                        iconKey: iconKey,
                        colorValue: iconColor.toARGB32(),
                        position: existing?.position,
                        enabled: existing?.enabled ?? true,
                      );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text('Salva preset'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
    amount.dispose();
    note.dispose();
  }
}
