import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/models.dart';
import '../screens/transaction_screens.dart';
import '../theme/balyn_palette.dart';
import '../services/transaction_metadata_suggestions.dart';
import 'ui_helpers.dart';

/// An actual editable Home search. SearchAnchor takes the text typed in the
/// original header bar into a full-height live results view.
class BalynGlobalSearchBar extends StatefulWidget {
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
  State<BalynGlobalSearchBar> createState() => _BalynGlobalSearchBarState();
}

class _BalynGlobalSearchBarState extends State<BalynGlobalSearchBar> {
  final SearchController _controller = SearchController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final controller = _controller;

    void leaveSearch(VoidCallback action) {
      controller.closeView('');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) action();
      });
    }

    final destinations = <_SearchDestination>[
      _SearchDestination(
        'Movimenti',
        'Tutte le operazioni',
        Icons.receipt_long_outlined,
        widget.onMovements,
        ['movimenti', 'spese', 'entrate', 'trasferimenti', 'transazioni'],
      ),
      _SearchDestination(
        'Conti',
        'Gestisci i tuoi conti',
        Icons.account_balance_wallet_outlined,
        widget.onAccounts,
        ['conti', 'conto', 'portafoglio', 'saldo'],
      ),
      _SearchDestination(
        'Pianifica',
        'Budget, obiettivi e ricorrenze',
        Icons.event_note_outlined,
        widget.onPlanning,
        ['pianifica', 'pianificazione', 'budget', 'obiettivi', 'ricorrenze'],
      ),
      _SearchDestination(
        'Anticipi',
        'Persone e rimborsi',
        Icons.handshake_outlined,
        widget.onAdvances,
        ['anticipi', 'anticipo', 'rimborsi', 'debiti', 'crediti'],
      ),
      _SearchDestination(
        'Analisi',
        'Statistiche di entrate e spese',
        Icons.insights_outlined,
        widget.onAnalytics,
        ['analisi', 'statistiche', 'grafici'],
      ),
      _SearchDestination(
        'Impostazioni',
        'Personalizza Balyn',
        Icons.tune_rounded,
        widget.onSettings,
        ['impostazioni', 'settings', 'preferenze'],
      ),
    ];

    return SearchAnchor(
      searchController: controller,
      viewBackgroundColor: BalynPalette.canvas(Theme.of(context).brightness),
      viewElevation: 0,
      viewLeading: IconButton(
        tooltip: 'Chiudi ricerca',
        icon: const Icon(Icons.close_rounded),
        onPressed: () => controller.closeView(''),
      ),
      viewHintText: 'Cerca movimenti, importi, tag o sezioni',
      builder: (context, searchController) => SearchBar(
        key: const ValueKey('home-global-search'),
        controller: searchController,
        hintText: 'Cerca movimenti',
        leading: const Icon(
          Icons.search_rounded,
          color: Colors.white,
          size: 18,
        ),
        onTap: searchController.openView,
        onChanged: (_) => searchController.openView(),
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: WidgetStatePropertyAll(
          Colors.white.withValues(alpha: .28),
        ),
        textStyle: const WidgetStatePropertyAll(
          TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        hintStyle: const WidgetStatePropertyAll(
          TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 14),
        ),
        constraints: const BoxConstraints(minHeight: 40, maxHeight: 40),
        shape: const WidgetStatePropertyAll(StadiumBorder()),
      ),
      suggestionsBuilder: (context, searchController) {
        final query = searchController.text.trim();
        final key = TransactionMetadataSuggestions.normalizeLookup(query);
        final matchedDestinations = destinations
            .where(
              (destination) =>
                  query.isEmpty ||
                  destination.aliases.any(
                    (alias) => TransactionMetadataSuggestions.normalizeLookup(
                      alias,
                    ).contains(key),
                  ) ||
                  TransactionMetadataSuggestions.normalizeLookup(
                    destination.title,
                  ).contains(key),
            )
            .toList();

        final numeric = query
            .replaceAll(',', '.')
            .replaceAll(RegExp(r'[^0-9.]'), '');
        final transactions = [...state.transactions]
          ..sort((a, b) => b.date.compareTo(a.date));
        final matches = transactions
            .where((item) {
              if (query.isEmpty) return true;
              final category = state.categoryById(item.categoryId)?.name ?? '';
              final account = state.accountById(item.accountId)?.name ?? '';
              final destination =
                  state.accountById(item.toAccountId)?.name ?? '';
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
            })
            .take(query.isEmpty ? 5 : 30)
            .toList();


        return <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 15, 16, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  query.isEmpty ? 'Esplora' : 'Risultati della ricerca',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 20),
                _SearchHeading(
                  query.isEmpty ? 'Movimenti recenti' : 'Movimenti',
                  onSeeAll: query.isEmpty
                      ? () => leaveSearch(widget.onMovements)
                      : null,
                ),
                const SizedBox(height: 10),
                Material(
                  key: const ValueKey('search-recent-movements'),
                  color: BalynPalette.surface(Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(20),
                  clipBehavior: Clip.antiAlias,
                  child: matches.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.all(20),
                          child: Text('Nessun movimento trovato'),
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (var i = 0; i < matches.length; i++) ...[
                              if (i > 0)
                                Divider(
                                  height: 1,
                                  indent: 64,
                                  endIndent: 14,
                                  color: scheme.outlineVariant,
                                ),
                              _SearchMovementRow(
                                key: ValueKey('search-transaction-${matches[i].id}'),
                                item: matches[i],
                                onTap: () {
                                  final item = matches[i];
                                  leaveSearch(() => Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => TransactionDetailPage(
                                        transactionId: item.id,
                                      ),
                                    ),
                                  ));
                                },
                              ),
                            ],
                          ],
                        ),
                ),
                const SizedBox(height: 25),
                const _SearchHeading('Sezioni'),
                const SizedBox(height: 12),
                if (matchedDestinations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 15),
                    child: Text('Nessuna sezione corrispondente.'),
                  )
                else
                  GridView.builder(
                    key: const ValueKey('search-six-sections'),
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: matchedDestinations.length,
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.22,
                      mainAxisSpacing: 10,
                      crossAxisSpacing: 10,
                    ),
                    itemBuilder: (context, index) {
                      final destination = matchedDestinations[index];
                      return _SearchDestinationTile(
                        key: ValueKey('search-section-${destination.title}'),
                        destination: destination,
                        onTap: () => leaveSearch(destination.open),
                      );
                    },
                  ),
              ],
            ),
          ),
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


class _SearchMovementRow extends StatelessWidget {
  const _SearchMovementRow({required this.item, required this.onTap, super.key});
  final FinanceTransaction item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final accent = transactionColor(context, item.type);
    final category = state.categoryById(item.categoryId);
    final note = item.note?.trim() ?? '';
    final title = note.isNotEmpty ? note : category?.name ?? item.type.label;
    final value = moneyFor(state, item.amount);
    final signed = switch (item.type) {
      TransactionType.expense => '−$value',
      TransactionType.income => '+$value',
      TransactionType.transfer => value,
    };
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: .13),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                item.type == TransactionType.transfer
                    ? Icons.swap_horiz_rounded
                    : category == null
                        ? item.type == TransactionType.income
                            ? Icons.south_west_rounded
                            : Icons.north_east_rounded
                        : categoryIcon(category.iconKey),
                color: accent,
                size: 21,
              ),
            ),
            const SizedBox(width: 11),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      category?.name ?? item.type.label,
                      DateFormat('d MMM').format(item.date),
                      if (item.tags.isNotEmpty) item.tags.map((t) => '#$t').join(' '),
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              signed,
              style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchDestinationTile extends StatelessWidget {
  const _SearchDestinationTile({
    required this.destination,
    required this.onTap,
    super.key,
  });
  final _SearchDestination destination;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: BalynPalette.surface(Theme.of(context).brightness),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: BalynPalette.accent.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: SizedBox.square(
                  dimension: 37,
                  child: Icon(destination.icon, size: 20, color: BalynPalette.accent),
                ),
              ),
              const Spacer(),
              Text(
                destination.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                destination.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 10,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchHeading extends StatelessWidget {
  const _SearchHeading(this.title, {this.onSeeAll});
  final String title;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      if (onSeeAll != null)
        TextButton(
          onPressed: onSeeAll,
          child: const Text('Vedi tutti'),
        ),
    ],
  );
}
