import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/csv_service.dart';
import '../services/data_integrity_service.dart';
import '../widgets/ui_helpers.dart';
import 'account_screens.dart' show showAccountEditor;

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conti'),
        actions: [
          IconButton(
            tooltip: 'Nuovo conto',
            onPressed: () => showAccountEditor(context),
            icon: const Icon(Icons.add_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Text('PATRIMONIO', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            state.hideBalance ? '••••••' : moneyFor(state, state.totalBalance),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 28),
          if (state.activeAccounts.isEmpty)
            EmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Nessun conto',
              subtitle: 'Crea il primo conto per iniziare.',
              action: FilledButton.icon(
                onPressed: () => showAccountEditor(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Crea conto'),
              ),
            )
          else
            ...state.activeAccounts.map(
              (account) => _AccountTile(account: account),
            ),
          if (state.archivedAccounts.isNotEmpty) ...[
            const SizedBox(height: 32),
            SectionTitle(
              'Archiviati',
              trailing: Text('${state.archivedAccounts.length}'),
            ),
            ...state.archivedAccounts.map(
              (account) => _AccountTile(account: account),
            ),
          ],
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  const _AccountTile({required this.account});
  final Account account;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      minVerticalPadding: 12,
      leading: Icon(
        accountIcon(account.iconKey),
        color: Color(account.colorValue),
      ),
      title: Text(
        account.name,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        [
          account.accountType.label,
          if (account.isArchived) 'Archiviato',
          if (account.isLocked) 'Bloccato',
          if (!account.includeInTotal) 'Fuori patrimonio',
        ].join(' · '),
      ),
      trailing: Text(
        state.hideBalance || account.hideBalance
            ? '••••'
            : moneyFor(state, account.balance),
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SafeAccountDetailScreen(accountId: account.id),
        ),
      ),
    );
  }
}

class SafeAccountDetailScreen extends StatelessWidget {
  const SafeAccountDetailScreen({required this.accountId, super.key});
  final int accountId;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final account = state.accountById(accountId);
    if (account == null) {
      return const Scaffold(body: Center(child: Text('Conto non trovato')));
    }

    return Scaffold(
      appBar: AppBar(title: Text(account.name)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                accountIcon(account.iconKey),
                size: 34,
                color: Color(account.colorValue),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      account.name,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      account.accountType.label,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text('SALDO', style: Theme.of(context).textTheme.labelMedium),
          const SizedBox(height: 6),
          Text(
            state.hideBalance || account.hideBalance
                ? '••••••'
                : moneyFor(state, account.balance),
            style: Theme.of(context).textTheme.headlineLarge,
          ),
          const SizedBox(height: 6),
          Text(
            account.lastReconciledAt == null
                ? 'Mai riconciliato'
                : 'Ultimo controllo ${DateFormat('dd MMM yyyy', 'it_IT').format(account.lastReconciledAt!)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (account.note?.trim().isNotEmpty == true) ...[
            const SizedBox(height: 10),
            Text(account.note!, style: Theme.of(context).textTheme.bodyMedium),
          ],
          const SizedBox(height: 32),
          const SectionTitle('Impostazioni conto'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_outlined),
            title: const Text(
              'Nome, icona e nota',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Modifica nome, icona, colore e nota'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _editMetadata(context, state, account),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Includi nel patrimonio'),
            subtitle: const Text('Il saldo contribuisce al patrimonio totale'),
            value: account.includeInTotal,
            onChanged: (value) =>
                state.updateAccount(account.copyWith(includeInTotal: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Includi nelle statistiche'),
            subtitle: const Text('Usa i movimenti del conto nelle analytics'),
            value: account.includeInAnalytics,
            onChanged: (value) => state.updateAccount(
              account.copyWith(includeInAnalytics: value),
            ),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Nascondi saldo'),
            subtitle: const Text('Nasconde il saldo di questo conto'),
            value: account.hideBalance,
            onChanged: (value) =>
                state.updateAccount(account.copyWith(hideBalance: value)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Blocca conto'),
            subtitle: const Text('Impedisce nuovi movimenti sul conto'),
            value: account.isLocked,
            onChanged: (value) =>
                state.updateAccount(account.copyWith(isLocked: value)),
          ),
          const SizedBox(height: 28),
          const SectionTitle('Gestione'),
          if (!account.isArchived && !account.isLocked)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.balance_outlined),
              title: const Text('Riconcilia saldo'),
              subtitle: const Text('Allinea il saldo con quello reale'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _reconcile(context, state, account),
            ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.download_outlined),
            title: const Text('Esporta movimenti CSV'),
            subtitle: const Text('Esporta lo storico di questo conto'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => _export(context, state, account),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              account.isArchived
                  ? Icons.unarchive_outlined
                  : Icons.archive_outlined,
            ),
            title: Text(
              account.isArchived ? 'Ripristina conto' : 'Archivia conto',
            ),
            subtitle: Text(
              account.isArchived
                  ? 'Rende nuovamente disponibile il conto'
                  : 'Nasconde il conto mantenendo tutto lo storico',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              if (account.isArchived) {
                await state.updateAccount(account.copyWith(isArchived: false));
              } else {
                await DataIntegrityService.archiveAccount(state, account);
              }
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(
              Icons.delete_outline_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            title: Text(
              'Elimina se vuoto',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            subtitle: const Text(
              'Se contiene storico potrai archiviarlo invece di eliminarlo',
            ),
            trailing: Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.error,
            ),
            onTap: () => _delete(context, state, account),
          ),
        ],
      ),
    );
  }

  Future<void> _reconcile(
    BuildContext context,
    AppState state,
    Account account,
  ) async {
    final controller = TextEditingController(
      text: account.balance.toStringAsFixed(2),
    );
    final actual = await showModalBottomSheet<double>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          4,
          20,
          MediaQuery.viewInsetsOf(sheetContext).bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Riconcilia saldo',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Saldo DadaFinanza: ${moneyFor(state, account.balance)}'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: 'Saldo reale',
                suffixText: state.currency,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  final value = double.tryParse(
                    controller.text.replaceAll(',', '.'),
                  );
                  if (value != null) Navigator.pop(sheetContext, value);
                },
                child: const Text('Continua'),
              ),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    if (actual == null || !context.mounted) return;
    final difference = actual - account.balance;
    final confirmed =
        await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Conferma riconciliazione'),
            content: Text(
              'Saldo attuale: ${moneyFor(state, account.balance)}\nSaldo reale: ${moneyFor(state, actual)}\nDifferenza: ${moneyFor(state, difference, signed: true)}\n\nLa differenza sarà registrata come rettifica fuori dalle statistiche.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Annulla'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Riconcilia'),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    await DataIntegrityService.reconcileAccount(
      state,
      account: account,
      actualBalance: actual,
    );
  }

  Future<void> _delete(
    BuildContext context,
    AppState state,
    Account account,
  ) async {
    if (state.transactionCountForAccount(account.id) > 0 ||
        state.recurring.any(
          (item) =>
              item.accountId == account.id || item.toAccountId == account.id,
        )) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Il conto contiene storico'),
          content: const Text(
            'Per proteggere lo storico finanziario un conto con movimenti o ricorrenze non viene eliminato. Puoi archiviarlo e continuare a consultare i dati.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Chiudi'),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await DataIntegrityService.archiveAccount(state, account);
              },
              child: const Text('Archivia conto'),
            ),
          ],
        ),
      );
      return;
    }
    final confirmed = await confirmDestructiveAction(
      context,
      title: 'Eliminare “${account.name}”?',
      message: 'Il conto è vuoto e può essere eliminato in sicurezza.',
    );
    if (!confirmed) return;
    await DataIntegrityService.deleteEmptyAccount(state, account);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _export(
    BuildContext context,
    AppState state,
    Account account,
  ) async {
    final csv = const CsvService().export(state, accountId: account.id);
    final output = await FilePicker.saveFile(
      dialogTitle: 'Esporta ${account.name}',
      fileName:
          '${account.name.replaceAll(RegExp(r'[^A-Za-z0-9_-]+'), '-')}.csv',
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      bytes: Uint8List.fromList(utf8.encode(csv)),
    );
    if (context.mounted && output != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Movimenti del conto esportati.')),
      );
    }
  }

  Future<void> _editMetadata(
    BuildContext context,
    AppState state,
    Account account,
  ) async {
    final name = TextEditingController(text: account.name);
    final note = TextEditingController(text: account.note ?? '');
    var iconKey = account.iconKey;
    var color = Color(account.colorValue);

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
                  'Modifica conto',
                  style: Theme.of(sheetContext).textTheme.titleLarge,
                ),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(labelText: 'Nome'),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(accountIcon(iconKey), color: color),
                  title: const Text('Icona'),
                  subtitle: const Text('Scegli l’icona del conto'),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () async {
                    final picked = await showIconPicker(
                      sheetContext,
                      options: accountIconOptions,
                      selected: iconKey,
                    );
                    if (picked != null) {
                      setSheetState(() => iconKey = picked);
                    }
                  },
                ),
                const SizedBox(height: 8),
                Text(
                  'Colore',
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: categoryPalette
                      .map(
                        (item) => Semantics(
                          button: true,
                          selected: item == color,
                          label: 'Colore conto',
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () => setSheetState(() => color = item),
                            child: SizedBox.square(
                              dimension: 44,
                              child: Center(
                                child: Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: item,
                                    shape: BoxShape.circle,
                                  ),
                                  child: item == color
                                      ? const Icon(
                                          Icons.check_rounded,
                                          size: 17,
                                          color: Colors.white,
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
                TextField(
                  controller: note,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Nota opzionale',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () async {
                      if (name.text.trim().isEmpty) return;
                      await state.updateAccount(
                        account.copyWith(
                          name: name.text.trim(),
                          iconKey: iconKey,
                          colorValue: color.toARGB32(),
                          note: note.text.trim().isEmpty
                              ? null
                              : note.text.trim(),
                        ),
                      );
                      if (sheetContext.mounted) Navigator.pop(sheetContext);
                    },
                    child: const Text('Salva modifiche'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    name.dispose();
    note.dispose();
  }
}
