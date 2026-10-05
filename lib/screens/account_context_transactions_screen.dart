import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/account_context_service.dart';
import '../widgets/account_context_selector.dart';
import '../widgets/balyn_motion.dart';
import '../widgets/ui_helpers.dart';
import 'quick_add_page.dart';
import 'transaction_screens.dart';

enum _MovementView { timeline, categories }

enum _MovementSort { newest, oldest, amountDesc, amountAsc }

class AccountContextTransactionsScreen extends StatefulWidget {
  const AccountContextTransactionsScreen({
    required this.accountId,
    required this.onAccountChanged,
    super.key,
  });

  final int? accountId;
  final ValueChanged<int?> onAccountChanged;

  @override
  State<AccountContextTransactionsScreen> createState() =>
      _AccountContextTransactionsScreenState();
}

class _AccountContextTransactionsScreenState
    extends State<AccountContextTransactionsScreen> {
  final search = TextEditingController();
  String query = '';
  TransactionType? type;
  int? categoryId;
  DateTime? from;
  DateTime? to;
  _MovementView view = _MovementView.timeline;
  _MovementSort sort = _MovementSort.newest;

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<FinanceTransaction> _items(AppState state) {
    final lowered = query.trim().toLowerCase();
    final items = AccountContextService.transactionsFor(state, widget.accountId)
        .where((item) {
          if (type != null && item.type != type) return false;
          if (categoryId != null) {
            final direct = item.categoryId == categoryId;
            final split = state
                .splitsFor(item.id)
                .any((part) => part.categoryId == categoryId);
            if (!direct && !split) return false;
          }
          if (from != null && item.date.isBefore(from!)) return false;
          if (to != null) {
            final inclusiveEnd = DateTime(
              to!.year,
              to!.month,
              to!.day,
              23,
              59,
              59,
            );
            if (item.date.isAfter(inclusiveEnd)) return false;
          }
          if (lowered.isNotEmpty) {
            final account = state.accountById(item.accountId);
            final destination = state.accountById(item.toAccountId);
            final category = state.categoryById(item.categoryId);
            final text = [
              item.note ?? '',
              account?.name ?? '',
              destination?.name ?? '',
              category?.name ?? '',
              ...item.tags,
            ].join(' ').toLowerCase();
            if (!text.contains(lowered)) return false;
          }
          return true;
        })
        .toList();

    switch (sort) {
      case _MovementSort.newest:
        items.sort((a, b) => b.date.compareTo(a.date));
      case _MovementSort.oldest:
        items.sort((a, b) => a.date.compareTo(b.date));
      case _MovementSort.amountDesc:
        items.sort((a, b) => b.amount.compareTo(a.amount));
      case _MovementSort.amountAsc:
        items.sort((a, b) => a.amount.compareTo(b.amount));
    }
    return items;
  }

  bool get hasFilters =>
      type != null ||
      categoryId != null ||
      from != null ||
      to != null ||
      sort != _MovementSort.newest;

  int get activeFilterCount => [
    type != null,
    categoryId != null,
    from != null || to != null,
    sort != _MovementSort.newest,
  ].where((active) => active).length;

  void _clearFilters() {
    setState(() {
      type = null;
      categoryId = null;
      from = null;
      to = null;
      sort = _MovementSort.newest;
    });
  }

  void _setQuickType(AppState state, TransactionType? value) {
    setState(() {
      type = value;
      if (value == TransactionType.transfer) {
        categoryId = null;
      } else if (value != null && categoryId != null) {
        final compatible = state
            .categoriesFor(value)
            .any((item) => item.id == categoryId);
        if (!compatible) categoryId = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items = _items(state);
    final groups = AccountContextService.groupByCategory(state, items);
    final totals = _MovementTotals.from(state, items);

    return Scaffold(
      appBar: AppBar(
        title: AccountContextSelector(
          accountId: widget.accountId,
          onChanged: widget.onAccountChanged,
        ),
      ),
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            sliver: SliverList.list(
              children: [
                BalynReveal(
                  child: _MovementHeader(
                    count: items.length,
                    totals: totals,
                    hideValues: state.hideBalance,
                  ),
                ),
                const SizedBox(height: 22),
                _MovementSearch(
                  controller: search,
                  query: query,
                  activeFilterCount: activeFilterCount,
                  onChanged: (value) => setState(() => query = value),
                  onClear: () {
                    search.clear();
                    setState(() => query = '');
                  },
                  onFilters: () => _showFilters(context, state),
                ),
                const SizedBox(height: 14),
                _TypeFilters(
                  selected: type,
                  onChanged: (value) => _setQuickType(state, value),
                ),
                if (hasFilters) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _clearFilters,
                      icon: const Icon(
                        Icons.filter_alt_off_outlined,
                        size: 18,
                      ),
                      label: Text(
                        activeFilterCount == 1
                            ? 'Azzera filtro'
                            : 'Azzera filtri',
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                _MovementViewSwitch(
                  value: view,
                  onChanged: (next) => setState(() => view = next),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
          if (items.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.receipt_long_outlined,
                title: state.transactions.isEmpty
                    ? 'Nessun movimento'
                    : 'Nessun risultato',
                subtitle: state.transactions.isEmpty
                    ? 'Aggiungi una spesa o un’entrata.'
                    : 'Prova a modificare ricerca o filtri.',
                action: FilledButton.icon(
                  onPressed: () =>
                      _openNew(context, TransactionType.expense),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nuovo movimento'),
                ),
              ),
            )
          else if (view == _MovementView.timeline)
            _buildTimelineSliver(state, items)
          else
            _buildCategoriesSliver(state, groups),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
    );
  }

  Widget _buildTimelineSliver(
    AppState state,
    List<FinanceTransaction> items,
  ) {
    if (sort == _MovementSort.amountDesc ||
        sort == _MovementSort.amountAsc) {
      return SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        sliver: SliverList.builder(
          itemCount: items.length,
          itemBuilder: (context, index) => _MovementTile(item: items[index]),
        ),
      );
    }

    final days = _groupByDay(items);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.builder(
        itemCount: days.length,
        itemBuilder: (context, index) {
          final day = days[index];
          return Padding(
            padding: EdgeInsets.only(bottom: index == days.length - 1 ? 0 : 24),
            child: _MovementDaySection(
              day: day,
              hideValues: state.hideBalance,
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoriesSliver(
    AppState state,
    List<AccountCategoryGroup> groups,
  ) {
    final sections = <_CategoryGroupSection>[
      _CategoryGroupSection(
        title: 'Spese per categoria',
        type: TransactionType.expense,
        groups: groups
            .where((item) => item.type == TransactionType.expense)
            .toList(growable: false),
      ),
      _CategoryGroupSection(
        title: 'Entrate per categoria',
        type: TransactionType.income,
        groups: groups
            .where((item) => item.type == TransactionType.income)
            .toList(growable: false),
      ),
      _CategoryGroupSection(
        title: 'Trasferimenti',
        type: TransactionType.transfer,
        groups: groups
            .where((item) => item.type == TransactionType.transfer)
            .toList(growable: false),
      ),
    ].where((section) => section.groups.isNotEmpty).toList(growable: false);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverList.builder(
        itemCount: sections.length,
        itemBuilder: (context, index) {
          final section = sections[index];
          return Padding(
            padding: EdgeInsets.only(
              bottom: index == sections.length - 1 ? 0 : 30,
            ),
            child: _CategorySection(
              section: section,
              state: state,
              onOpen: (group) => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => _GroupedMovementsPage(
                    title: group.title,
                    ids: group.transactionIds,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  List<_MovementDay> _groupByDay(List<FinanceTransaction> items) {
    final byDay = <DateTime, List<FinanceTransaction>>{};
    for (final item in items) {
      final day = DateTime(item.date.year, item.date.month, item.date.day);
      byDay.putIfAbsent(day, () => <FinanceTransaction>[]).add(item);
    }

    final days = byDay.entries
        .map((entry) => _MovementDay(day: entry.key, items: entry.value))
        .toList();
    days.sort(
      (a, b) => sort == _MovementSort.oldest
          ? a.day.compareTo(b.day)
          : b.day.compareTo(a.day),
    );
    return days;
  }

  Future<void> _openNew(BuildContext context, TransactionType type) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuickAddPage(
          initialTypeName: type.name,
          initialAccountId: widget.accountId,
        ),
      ),
    );
  }

  Future<void> _showFilters(BuildContext context, AppState state) async {
    var draftType = type;
    var draftCategory = categoryId;
    var draftFrom = from;
    var draftTo = to;
    var draftSort = sort;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final availableCategories =
              draftType == null || draftType == TransactionType.transfer
              ? state.categories
              : state.categoriesFor(draftType!);
          if (draftCategory != null &&
              !availableCategories.any((item) => item.id == draftCategory)) {
            draftCategory = null;
          }
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: .18),
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Filtra movimenti',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 18),
                  DropdownButtonFormField<TransactionType?>(
                    initialValue: draftType,
                    decoration: InputDecoration(labelText: AppI18n.tr('Tipo')),
                    items: [
                      const DropdownMenuItem<TransactionType?>(
                        value: null,
                        child: Text('Tutti'),
                      ),
                      ...TransactionType.values.map(
                        (item) => DropdownMenuItem<TransactionType?>(
                          value: item,
                          child: Text(item.label),
                        ),
                      ),
                    ],
                    onChanged: (value) => setSheetState(() {
                      draftType = value;
                      draftCategory = null;
                    }),
                  ),
                  DropdownButtonFormField<int?>(
                    key: ValueKey(
                      'movement-category-$draftType-$draftCategory',
                    ),
                    initialValue: draftCategory,
                    decoration: InputDecoration(
                      labelText: AppI18n.tr('Categoria'),
                    ),
                    items: [
                      const DropdownMenuItem<int?>(
                        value: null,
                        child: Text('Tutte le categorie'),
                      ),
                      ...availableCategories.map(
                        (item) => DropdownMenuItem<int?>(
                          value: item.id,
                          child: Text(item.name),
                        ),
                      ),
                    ],
                    onChanged: (value) => draftCategory = value,
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.date_range_outlined),
                    title: const Text('Dal'),
                    trailing: Text(
                      draftFrom == null
                          ? 'Qualsiasi'
                          : DateFormat('dd/MM/yyyy').format(draftFrom!),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: draftFrom ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setSheetState(() => draftFrom = picked);
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_available_outlined),
                    title: const Text('Al'),
                    trailing: Text(
                      draftTo == null
                          ? 'Qualsiasi'
                          : DateFormat('dd/MM/yyyy').format(draftTo!),
                    ),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        firstDate: draftFrom ?? DateTime(2000),
                        lastDate: DateTime(2100),
                        initialDate: draftTo ?? DateTime.now(),
                      );
                      if (picked != null) {
                        setSheetState(() => draftTo = picked);
                      }
                    },
                  ),
                  DropdownButtonFormField<_MovementSort>(
                    initialValue: draftSort,
                    decoration: InputDecoration(
                      labelText: AppI18n.tr('Ordina'),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: _MovementSort.newest,
                        child: Text('Più recenti'),
                      ),
                      DropdownMenuItem(
                        value: _MovementSort.oldest,
                        child: Text('Più vecchi'),
                      ),
                      DropdownMenuItem(
                        value: _MovementSort.amountDesc,
                        child: Text('Importo decrescente'),
                      ),
                      DropdownMenuItem(
                        value: _MovementSort.amountAsc,
                        child: Text('Importo crescente'),
                      ),
                    ],
                    onChanged: (value) => draftSort = value ?? draftSort,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () {
                            _clearFilters();
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Azzera'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            setState(() {
                              type = draftType;
                              categoryId = draftCategory;
                              from = draftFrom;
                              to = draftTo;
                              sort = draftSort;
                            });
                            Navigator.pop(sheetContext);
                          },
                          child: const Text('Applica'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MovementTotals {
  const _MovementTotals({
    required this.income,
    required this.expense,
  });

  factory _MovementTotals.from(
    AppState state,
    Iterable<FinanceTransaction> items,
  ) {
    var income = 0.0;
    var expense = 0.0;
    for (final item in items) {
      if (item.type == TransactionType.income) {
        income += item.amount;
      } else if (item.type == TransactionType.expense) {
        expense += state.effectiveExpense(item);
      }
    }
    return _MovementTotals(income: income, expense: expense);
  }

  final double income;
  final double expense;

  double get net => income - expense;
}

class _MovementHeader extends StatelessWidget {
  const _MovementHeader({
    required this.count,
    required this.totals,
    required this.hideValues,
  });

  final int count;
  final _MovementTotals totals;
  final bool hideValues;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final netColor = totals.net > 0
        ? context.financeColors.positive
        : totals.net < 0
        ? context.financeColors.negative
        : theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Movimenti',
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          '$count ${count == 1 ? 'movimento' : 'movimenti'} nel risultato',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: 22),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _MovementMetric(
                label: 'Entrate',
                value: hideValues ? '••••' : moneyFor(state, totals.income),
                color: context.financeColors.positive,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MovementMetric(
                label: 'Spese',
                value: hideValues ? '••••' : moneyFor(state, totals.expense),
                color: context.financeColors.negative,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MovementMetric(
                label: 'Netto',
                value: hideValues ? '••••' : moneyFor(state, totals.net),
                color: netColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _MovementMetric extends StatelessWidget {
  const _MovementMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

class _MovementSearch extends StatelessWidget {
  const _MovementSearch({
    required this.controller,
    required this.query,
    required this.activeFilterCount,
    required this.onChanged,
    required this.onClear,
    required this.onFilters,
  });

  final TextEditingController controller;
  final String query;
  final int activeFilterCount;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  final VoidCallback onFilters;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: AppI18n.tr('Cerca movimenti'),
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: AppI18n.tr('Cancella ricerca'),
                      onPressed: onClear,
                      icon: const Icon(Icons.close_rounded),
                    ),
              filled: true,
              fillColor: theme.colorScheme.surfaceContainer.withValues(
                alpha: .64,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(
                  color: theme.colorScheme.tertiary.withValues(alpha: .55),
                  width: 1.2,
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 10),
        Semantics(
          button: true,
          label: activeFilterCount == 0
              ? 'Filtri'
              : '$activeFilterCount filtri attivi',
          child: InkWell(
            onTap: onFilters,
            borderRadius: BorderRadius.circular(18),
            child: Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: activeFilterCount > 0
                    ? theme.colorScheme.tertiary.withValues(alpha: .14)
                    : theme.colorScheme.surfaceContainer.withValues(alpha: .64),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Badge(
                isLabelVisible: activeFilterCount > 0,
                label: Text('$activeFilterCount'),
                child: Icon(
                  Icons.tune_rounded,
                  color: activeFilterCount > 0
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _TypeFilters extends StatelessWidget {
  const _TypeFilters({
    required this.selected,
    required this.onChanged,
  });

  final TransactionType? selected;
  final ValueChanged<TransactionType?> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          _TypeChip(
            label: 'Tutti',
            selected: selected == null,
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () => onChanged(null),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Spese',
            selected: selected == TransactionType.expense,
            color: context.financeColors.negative,
            onTap: () => onChanged(TransactionType.expense),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Entrate',
            selected: selected == TransactionType.income,
            color: context.financeColors.positive,
            onTap: () => onChanged(TransactionType.income),
          ),
          const SizedBox(width: 8),
          _TypeChip(
            label: 'Trasferimenti',
            selected: selected == TransactionType.transfer,
            color: Theme.of(context).colorScheme.tertiary,
            onTap: () => onChanged(TransactionType.transfer),
          ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      selected: selected,
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(
                    alpha: theme.brightness == Brightness.dark ? .18 : .11,
                  )
                : theme.colorScheme.surfaceContainer.withValues(alpha: .48),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              color: selected ? color : theme.colorScheme.onSurfaceVariant,
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}

class _MovementViewSwitch extends StatelessWidget {
  const _MovementViewSwitch({
    required this.value,
    required this.onChanged,
  });

  final _MovementView value;
  final ValueChanged<_MovementView> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget item(String label, _MovementView itemValue) {
      final selected = value == itemValue;
      return Expanded(
        child: Semantics(
          selected: selected,
          button: true,
          child: InkWell(
            onTap: () => onChanged(itemValue),
            borderRadius: BorderRadius.circular(14),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.tertiary.withValues(alpha: .12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: Text(
                label,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: selected
                      ? theme.colorScheme.tertiary
                      : theme.colorScheme.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: .5),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          item('Cronologia', _MovementView.timeline),
          item('Categorie', _MovementView.categories),
        ],
      ),
    );
  }
}

class _MovementDay {
  const _MovementDay({
    required this.day,
    required this.items,
  });

  final DateTime day;
  final List<FinanceTransaction> items;
}

class _MovementDaySection extends StatelessWidget {
  const _MovementDaySection({
    required this.day,
    required this.hideValues,
  });

  final _MovementDay day;
  final bool hideValues;

  String _label() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final delta = today.difference(day.day).inDays;
    if (delta == 0) return 'Oggi';
    if (delta == 1) return 'Ieri';
    final raw = DateFormat(
      day.day.year == now.year ? 'EEEE d MMMM' : 'd MMMM yyyy',
      AppI18n.intlLocale,
    ).format(day.day);
    return raw.isEmpty ? raw : '${raw[0].toUpperCase()}${raw.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    var income = 0.0;
    var expense = 0.0;
    for (final item in day.items) {
      if (item.type == TransactionType.income) {
        income += item.amount;
      } else if (item.type == TransactionType.expense) {
        expense += state.effectiveExpense(item);
      }
    }
    final net = income - expense;
    final netColor = net > 0
        ? context.financeColors.positive
        : net < 0
        ? context.financeColors.negative
        : Theme.of(context).colorScheme.onSurfaceVariant;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                _label(),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              hideValues
                  ? '••••'
                  : '${net >= 0 ? '+' : '−'}${moneyFor(state, net.abs())}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: netColor,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        for (final item in day.items) _MovementTile(item: item),
      ],
    );
  }
}

class _MovementTile extends StatelessWidget {
  const _MovementTile({required this.item});

  final FinanceTransaction item;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final category = state.categoryById(item.categoryId);
    final account = state.accountById(item.accountId);
    final destination = state.accountById(item.toAccountId);
    final color = category == null
        ? transactionColor(context, item.type)
        : Color(category.colorValue);
    final categoryName = item.type == TransactionType.transfer
        ? 'Trasferimento'
        : category?.name ?? 'Senza categoria';
    final note = item.note?.trim();
    final title = note?.isNotEmpty == true ? note! : categoryName;
    final accountLabel = item.type == TransactionType.transfer
        ? '${account?.name ?? 'Conto'} → ${destination?.name ?? 'Conto'}'
        : account?.isSystem == true
        ? 'Non assegnato'
        : account?.name ?? 'Conto';
    final detailParts = <String>[
      if (title != categoryName) categoryName,
      accountLabel,
      DateFormat('HH:mm', AppI18n.intlLocale).format(item.date),
    ];
    final amount = item.type == TransactionType.expense
        ? '-${moneyFor(state, item.amount)}'
        : item.type == TransactionType.income
        ? '+${moneyFor(state, item.amount)}'
        : moneyFor(state, item.amount);

    return Semantics(
      button: true,
      label: '$title, $amount',
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailPage(transactionId: item.id),
          ),
        ),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 46,
                height: 46,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.type == TransactionType.transfer
                      ? Icons.swap_horiz_rounded
                      : category == null
                      ? Icons.receipt_long_rounded
                      : categoryIcon(category.iconKey),
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detailParts.join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                    if (item.tags.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        item.tags.take(2).map((tag) => '#$tag').join('  '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                state.hideBalance ? '••••' : amount,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: transactionColor(context, item.type),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryGroupSection {
  const _CategoryGroupSection({
    required this.title,
    required this.type,
    required this.groups,
  });

  final String title;
  final TransactionType type;
  final List<AccountCategoryGroup> groups;
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.section,
    required this.state,
    required this.onOpen,
  });

  final _CategoryGroupSection section;
  final AppState state;
  final ValueChanged<AccountCategoryGroup> onOpen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        for (final group in section.groups)
          _CategoryRankRow(
            group: group,
            state: state,
            onTap: () => onOpen(group),
          ),
      ],
    );
  }
}

class _CategoryRankRow extends StatelessWidget {
  const _CategoryRankRow({
    required this.group,
    required this.state,
    required this.onTap,
  });

  final AccountCategoryGroup group;
  final AppState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final category = state.categoryById(group.categoryId);
    final color = category == null
        ? transactionColor(context, group.type)
        : Color(category.colorValue);
    final icon = group.type == TransactionType.transfer
        ? Icons.swap_horiz_rounded
        : category == null
        ? Icons.receipt_long_outlined
        : categoryIcon(category.iconKey);
    final amount = group.type == TransactionType.expense
        ? '-${moneyFor(state, group.total)}'
        : group.type == TransactionType.income
        ? '+${moneyFor(state, group.total)}'
        : moneyFor(state, group.total);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: color.withValues(alpha: .12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          group.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        state.hideBalance ? '••••' : amount,
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(99),
                          child: LinearProgressIndicator(
                            value: (group.percentage / 100).clamp(0.0, 1.0),
                            minHeight: 4,
                            backgroundColor: theme.colorScheme.onSurface
                                .withValues(alpha: .07),
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '${group.percentage.toStringAsFixed(0)}%',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${group.count} ${group.count == 1 ? 'movimento' : 'movimenti'}',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupedMovementsPage extends StatelessWidget {
  const _GroupedMovementsPage({
    required this.title,
    required this.ids,
  });

  final String title;
  final Set<int> ids;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final items =
        state.transactions.where((item) => ids.contains(item.id)).toList()
          ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: items.isEmpty
          ? const Center(child: Text('Nessun movimento'))
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
              itemCount: items.length,
              itemBuilder: (context, index) => _MovementTile(item: items[index]),
            ),
    );
  }
}
