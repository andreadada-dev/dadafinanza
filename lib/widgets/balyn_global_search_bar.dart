import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/models.dart';
import '../screens/transaction_screens.dart';
import '../services/transaction_metadata_suggestions.dart';
import 'ui_helpers.dart';

/// An actual editable Home search. SearchAnchor takes the text typed in the
/// original header bar into a full-height live results view.
class BalynGlobalSearchBar extends StatelessWidget {
  const BalynGlobalSearchBar({
    required this.onMovements,
    required this.onAnalytics,
    required this.onAccounts,
    required this.onPlanning,
    required this.onAdvances,
    required this.onSettings,
    super.key,
  });

  final VoidCallback onMovements;
  final VoidCallback onAnalytics;
  final VoidCallback onAccounts;
  final VoidCallback onPlanning;
  final VoidCallback onAdvances;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final controller = SearchController();

    void leaveSearch(VoidCallback action) {
      controller.closeView('');
      WidgetsBinding.instance.addPostFrameCallback((_) => action());
    }

    final destinations = <_SearchDestination>[
      _SearchDestination(
        'Movimenti',
        'Tutte le operazioni',
        Icons.receipt_long_outlined,
        onMovements,
        ['movimenti', 'spese', 'entrate', 'trasferimenti', 'transazioni'],
      ),
      _SearchDestination(
        'Conti',
        'Gestisci i tuoi conti',
        Icons.account_balance_wallet_outlined,
        onAccounts,
        ['conti', 'conto', 'portafoglio', 'saldo'],
      ),
      _SearchDestination(
        'Pianifica',
        'Budget, obiettivi e ricorrenze',
        Icons.event_note_outlined,
        onPlanning,
        ['pianifica', 'pianificazione', 'budget', 'obiettivi', 'ricorrenze'],
      ),
      _SearchDestination(
        'Anticipi',
        'Persone e rimborsi',
        Icons.handshake_outlined,
        onAdvances,
        ['anticipi', 'anticipo', 'rimborsi', 'debiti', 'crediti'],
      ),
      _SearchDestination(
        'Analisi',
        'Statistiche di entrate e spese',
        Icons.insights_outlined,
        onAnalytics,
        ['analisi', 'statistiche', 'grafici'],
      ),
      _SearchDestination(
        'Impostazioni',
        'Personalizza Balyn',
        Icons.tune_rounded,
        onSettings,
        ['impostazioni', 'settings', 'preferenze'],
      ),
    ];

    return SearchAnchor(
      searchController: controller,
      viewBackgroundColor: scheme.surface,
      viewHintText: 'Cerca movimenti, importi, tag o sezioni',
      builder: (context, searchController) => SearchBar(
        key: const ValueKey('home-global-search'),
        controller: searchController,
        hintText: 'Cerca movimenti',
        leading: const Icon(Icons.search_rounded, color: Colors.white, size: 18),
        onTap: searchController.openView,
        onChanged: (_) => searchController.openView(),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: .28),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        hintStyle: const WidgetStatePropertyAll(
          TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14),
        ),
        constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
        shape: const WidgetStatePropertyAll(
          StadiumBorder(),
        ),
      ),
      suggestionsBuilder: (context, searchController) {
        final query = searchController.text.trim();
        final key = TransactionMetadataSuggestions.normalizeLookup(query);
        final matchedDestinations = destinations.where(
          (destination) =>
              query.isEmpty ||
              destination.aliases.any(
                (alias) => TransactionMetadataSuggestions.normalizeLookup(alias).contains(key),
              ) ||
              TransactionMetadataSuggestions.normalizeLookup(destination.title).contains(key),
        ).toList();

        final numeric = query
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'[^0-9.]'), '');
        final transactions = [...state.transactions]
          ..sort((a, b) => b.date.compareTo(a.date));
        final matches = transactions.where((item) {
          if (query.isEmpty) return true;
          final category = state.categoryById(item.categoryId)?.name ?? '';
          final account = state.accountById(item.accountId)?.name ?? '';
          final destination = state.accountById(item.toAccountId)?.name ?? '';
          final searchable = [
            item.note ?? '',
            ...item.tags,
            category,
            account,
            destination,
            item.type.label,
          ].map(TransactionMetadataSuggestions.normalizeLookup).join(' ');
          if (searchable.contains(key)) return true;
          final formatted = moneyFor(state, item.amount).toLowerCase();
          if (formatted.contains(query.toLowerCase())) return true;
          return numeric.isNotEmpty &&
              (item.amount.toStringAsFixed(2).contains(numeric) ||
                  item.amount.toString().contains(numeric));
        }).take(query.isEmpty ? 6 : 30).toList();

        return <Widget>[
          if (matchedDestinations.isNotEmpty) ...[
            const _SearchHeading('Sezioni'),
            for (final destination in matchedDestinations)
              ListTile(
                key: ValueKey('search-section-${destination.title}'),
                leading: Icon(destination.icon, color: scheme.primary),
                title: Text(destination.title),
                subtitle: Text(destination.subtitle),
                trailing: const Icon(Icons.arrow_outward_rounded, size: 19),
                onTap: () => leaveSearch(destination.open),
              ),
          ],
          _SearchHeading(query.isEmpty ? 'Movimenti recenti' : 'Movimenti'),
          if (matches.isEmpty)
            const ListTile(
              leading: Icon(Icons.search_off_rounded),
              title: Text('Nessun movimento trovato'),
              subtitle: Text('Prova con un tag, una descrizione o un importo.'),
            ),
          for (final item in matches)
            ListTile(
              key: ValueKey('search-transaction-${item.id}'),
              leading: CircleAvatar(
                backgroundColor: scheme.primary.withValues(alpha: .10),
                child: Icon(
                  item.type == TransactionType.income
                      ? Icons.arrow_downward_rounded
                      : item.type == TransactionType.expense
                          ? Icons.arrow_upward_rounded
                          : Icons.swap_horiz_rounded,
                  color: scheme.primary,
                ),
              ),
              title: Text(
                (item.note?.trim().isNotEmpty ?? false)
                    ? item.note!.trim()
                    : state.categoryById(item.categoryId)?.name ?? item.type.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                [
                  DateFormat('dd MMM yyyy').format(item.date),
                  state.accountById(item.accountId)?.name ?? '',
                  if (item.tags.isNotEmpty) item.tags.map((tag) => '#$tag').join(' '),
                ].where((value) => value.isNotEmpty).join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                moneyFor(state, item.amount, signed: true),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              onTap: () => leaveSearch(
                () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => TransactionDetailPage(transactionId: item.id),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 24),
        ];
      },
    );
  }
}

class _SearchDestination {
  const _SearchDestination(
    this.title,
    this.subtitle,
    this.icon,
    this.open,
    this.aliases,
  );
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback open;
  final List<String> aliases;
}

class _SearchHeading extends StatelessWidget {
  const _SearchHeading(this.title);
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
    child: Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
