import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/balyn_shader_system.dart';
import '../widgets/balyn_transaction_detail_content.dart';
import '../widgets/balyn_swipe_delete_tile.dart';
import '../widgets/ui_helpers.dart';
import 'quick_add_page.dart';

class TransactionListTile extends StatelessWidget {
  const TransactionListTile({
    required this.item,
    this.selected = false,
    this.onLongPress,
    super.key,
  });
  final FinanceTransaction item;
  final bool selected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final category = state.categoryById(item.categoryId);
    final account = state.accountById(item.accountId);
    final unassigned = account?.isSystem == true;
    final theme = Theme.of(context);
    final iconSeed = category == null
        ? (item.type == TransactionType.transfer
              ? theme.colorScheme.tertiary
              : transactionColor(context, item.type))
        : Color(category.colorValue);
    final amountSeed = item.type == TransactionType.transfer
        ? theme.colorScheme.tertiary
        : transactionColor(context, item.type);
    return BalynSwipeDeleteTile(
      item: item,
      child: ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 10,
      selected: selected,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.onSurface.withValues(
          alpha: theme.brightness == Brightness.dark ? .07 : .045,
        ),
        child: BalynShaderIcon(
          category == null
              ? (item.type == TransactionType.transfer
                    ? Icons.swap_horiz_rounded
                    : Icons.receipt_long_rounded)
              : categoryIcon(category.iconKey),
          seed: iconSeed,
        ),
      ),
      title: Text(
        item.type == TransactionType.transfer
            ? 'Trasferimento'
            : (category?.name ?? 'Senza categoria'),
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        '${unassigned ? 'Non assegnato' : account?.name ?? 'Conto'} · ${DateFormat('dd MMM, HH:mm', AppI18n.intlLocale).format(item.date)}${item.note?.isNotEmpty == true ? ' · ${item.note}' : ''}',
      ),
      trailing: BalynShaderText(
        item.type == TransactionType.expense
            ? '-${moneyFor(state, item.amount)}'
            : item.type == TransactionType.income
            ? '+${moneyFor(state, item.amount)}'
            : moneyFor(state, item.amount),
        seed: amountSeed,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      onLongPress: onLongPress,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TransactionDetailPage(transactionId: item.id),
        ),
      ),
    ),
    );
  }
}

class TransactionDetailPage extends StatelessWidget {
  const TransactionDetailPage({required this.transactionId, super.key});
  final int transactionId;

  Future<void> _delete(
    BuildContext context,
    FinanceTransaction item,
    AppState state,
  ) async {
    final confirmed =
        !state.confirmDelete ||
        await confirmDestructiveAction(
          context,
          title: 'Eliminare il movimento?',
          message: 'Il saldo del conto verrà ricalcolato automaticamente.',
        );
    if (!confirmed) return;
    await state.deleteTransaction(item);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _editSimple(
    BuildContext context,
    FinanceTransaction item,
    AppState state, {
    TransactionType? type,
    int? categoryId,
    int? accountId,
    bool? includeInAnalytics,
  }) async {
    final next = item.copyWith(
      type: type ?? item.type,
      categoryId: categoryId ?? item.categoryId,
      accountId: accountId ?? item.accountId,
      includeInAnalytics: includeInAnalytics ?? item.includeInAnalytics,
      updatedAt: DateTime.now(),
    );
    try {
      await state.updateTransaction(item, next);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Bad state: ', ''))),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final item = state.transactionById(transactionId);
    if (item == null)
      return const Scaffold(body: Center(child: Text('Movimento non trovato')));
    final category = state.categoryById(item.categoryId);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: 'Chiudi',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const SizedBox.shrink(),
        actions: [
          PopupMenuButton<String>(
            tooltip: AppI18n.tr('Azioni movimento'),
            onSelected: (value) async {
              if (value == 'edit')
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuickAddPage(editing: item),
                  ),
                );
              if (value == 'duplicate') {
                await state.duplicateTransaction(item);
                if (context.mounted)
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Movimento duplicato.')),
                  );
              }
              if (value == 'toggle_analytics')
                await _editSimple(
                  context,
                  item,
                  state,
                  includeInAnalytics: !item.includeInAnalytics,
                );
              if (value == 'expense')
                await _editSimple(
                  context,
                  item,
                  state,
                  type: TransactionType.expense,
                );
              if (value == 'income')
                await _editSimple(
                  context,
                  item,
                  state,
                  type: TransactionType.income,
                );
              if (value == 'split' && context.mounted)
                await showSplitEditor(context, item);
              if (value == 'refund' && context.mounted)
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuickAddPage(
                      initialTypeName: 'income',
                      refundOfTransactionId: item.id,
                    ),
                  ),
                );
              if (value == 'recurring' && context.mounted) {
                final account = state.accountById(item.accountId);
                final destination = state.accountById(item.toAccountId);
                final invalidSource =
                    account == null ||
                    account.isLocked ||
                    account.isArchived ||
                    account.isSystem;
                final invalidDestination =
                    item.type == TransactionType.transfer &&
                    (destination == null ||
                        destination.isLocked ||
                        destination.isArchived ||
                        destination.isSystem ||
                        destination.id == item.accountId);
                if (invalidSource || invalidDestination) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        item.type == TransactionType.transfer
                            ? 'Il trasferimento richiede due conti attivi diversi prima di creare una ricorrenza.'
                            : 'Assegna il movimento a un conto attivo prima di creare una ricorrenza.',
                      ),
                    ),
                  );
                } else {
                  await state.addRecurring(
                    name: category?.name ?? item.note ?? 'Movimento ricorrente',
                    amount: item.amount,
                    type: item.type,
                    accountId: item.accountId,
                    toAccountId: item.type == TransactionType.transfer
                        ? item.toAccountId
                        : null,
                    categoryId: item.type == TransactionType.transfer
                        ? null
                        : item.categoryId,
                    frequency: 'Mensile',
                    nextDate: DateTime(
                      item.date.year,
                      item.date.month + 1,
                      item.date.day,
                    ),
                    note: item.note,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Ricorrenza mensile creata. Puoi modificarla in Pianifica.',
                        ),
                      ),
                    );
                  }
                }
              }
              if (value == 'delete' && context.mounted)
                await _delete(context, item, state);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'edit', child: Text('Modifica')),
              const PopupMenuItem(value: 'duplicate', child: Text('Duplica')),
              if (item.type != TransactionType.expense)
                const PopupMenuItem(
                  value: 'expense',
                  child: Text('Trasforma in spesa'),
                ),
              if (item.type != TransactionType.income)
                const PopupMenuItem(
                  value: 'income',
                  child: Text('Trasforma in entrata'),
                ),
              if (item.type != TransactionType.transfer)
                const PopupMenuItem(
                  value: 'split',
                  child: Text('Dividi movimento'),
                ),
              if (item.type == TransactionType.expense)
                const PopupMenuItem(
                  value: 'refund',
                  child: Text('Registra rimborso'),
                ),
              if (item.type != TransactionType.transfer)
                const PopupMenuItem(
                  value: 'recurring',
                  child: Text('Rendi ricorrente'),
                ),
              PopupMenuItem(
                value: 'toggle_analytics',
                child: Text(
                  item.includeInAnalytics
                      ? 'Escludi dalle statistiche'
                      : 'Includi nelle statistiche',
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Elimina',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
      body: BalynTransactionDetailContent(
        item: item,
        onEdit: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => QuickAddPage(editing: item)),
        ),
        onDelete: () async {
          if (state.isAdvanceProtectedTransaction(item)) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gestisci il movimento da Anticipi.'),
              ),
            );
            return;
          }
          await _delete(context, item, state);
        },
        onDuplicate: () async {
          try {
            await state.duplicateTransaction(item);
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Movimento duplicato.')),
              );
            }
          } catch (error) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(error.toString())));
            }
          }
        },
        onAnalyticsChanged: (included) =>
            _editSimple(context, item, state, includeInAnalytics: included),
      ),
    );
  }
}

Future<void> showSplitEditor(
  BuildContext context,
  FinanceTransaction item,
) async {
  final state = AppScope.of(context);
  final expenseCategories = state.categoriesFor(TransactionType.expense);
  if (expenseCategories.length < 2) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Servono almeno due categorie di spesa per dividere il movimento.',
        ),
      ),
    );
    return;
  }
  final existing = state.splitsFor(item.id);
  final rows = <_SplitDraft>[];
  if (existing.isEmpty) {
    rows.add(
      _SplitDraft(
        categoryId: expenseCategories.first.id,
        controller: TextEditingController(),
      ),
    );
    rows.add(
      _SplitDraft(
        categoryId: expenseCategories[1].id,
        controller: TextEditingController(),
      ),
    );
  } else {
    for (final split in existing)
      rows.add(
        _SplitDraft(
          categoryId: split.categoryId,
          controller: TextEditingController(
            text: split.amount.toStringAsFixed(2),
          ),
        ),
      );
  }
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => StatefulBuilder(
      builder: (context, setSheetState) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(context).bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Dividi ${moneyFor(state, item.amount)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              ...List.generate(rows.length, (index) {
                final row = rows[index];
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        initialValue: row.categoryId,
                        decoration: InputDecoration(
                          labelText: AppI18n.tr('Categoria'),
                        ),
                        items: expenseCategories
                            .map(
                              (c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) =>
                            row.categoryId = value ?? row.categoryId,
                      ),
                    ),
                    const SizedBox(width: 12),
                    SizedBox(
                      width: 110,
                      child: TextField(
                        controller: row.controller,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: InputDecoration(
                          labelText: AppI18n.tr('Importo'),
                          suffixText: state.currency,
                        ),
                      ),
                    ),
                    if (rows.length > 2)
                      IconButton(
                        tooltip: AppI18n.tr('Rimuovi'),
                        onPressed: () => setSheetState(() {
                          rows[index].controller.dispose();
                          rows.removeAt(index);
                        }),
                        icon: const Icon(Icons.remove_circle_outline_rounded),
                      ),
                  ],
                );
              }),
              TextButton.icon(
                onPressed: () => setSheetState(
                  () => rows.add(
                    _SplitDraft(
                      categoryId: expenseCategories.first.id,
                      controller: TextEditingController(),
                    ),
                  ),
                ),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Aggiungi parte'),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    final values = <TransactionSplit>[];
                    for (final row in rows) {
                      final value = double.tryParse(
                        row.controller.text.replaceAll(',', '.'),
                      );
                      if (value == null || value <= 0) return;
                      values.add(
                        TransactionSplit(
                          id: 0,
                          transactionId: item.id,
                          amount: value,
                          categoryId: row.categoryId,
                        ),
                      );
                    }
                    try {
                      await state.replaceSplits(item.id, values, item.amount);
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      if (context.mounted)
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              e.toString().replaceFirst('Bad state: ', ''),
                            ),
                          ),
                        );
                    }
                  },
                  child: const Text('Salva divisione'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  for (final row in rows) row.controller.dispose();
}

class _SplitDraft {
  _SplitDraft({required this.categoryId, required this.controller});
  int categoryId;
  final TextEditingController controller;
}
