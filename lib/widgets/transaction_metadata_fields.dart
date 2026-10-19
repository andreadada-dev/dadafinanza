import 'dart:async';

import 'package:balyn/l10n/localized_material.dart';
import 'package:flutter/services.dart';

import '../data/app_database.dart';
import '../models/models.dart';
import '../services/transaction_metadata_preferences.dart';
import '../services/transaction_metadata_suggestions.dart';
import 'quick_suggestion_strip.dart';

enum TransactionMetadataSection { all, description, tags }

enum _MetadataFilter { all, recent, favorites }

class TransactionMetadataFields extends StatefulWidget {
  const TransactionMetadataFields({
    required this.noteController,
    required this.transactions,
    required this.tags,
    required this.database,
    required this.onTagsChanged,
    this.section = TransactionMetadataSection.all,
    super.key,
  });

  final TextEditingController noteController;
  final List<FinanceTransaction> transactions;
  final List<String> tags;
  final AppDatabase database;
  final ValueChanged<List<String>> onTagsChanged;
  final TransactionMetadataSection section;

  @override
  State<TransactionMetadataFields> createState() =>
      _TransactionMetadataFieldsState();
}

class _TransactionMetadataFieldsState extends State<TransactionMetadataFields> {
  final tagController = TextEditingController();
  late TransactionMetadataPreferences preferences;
  TransactionMetadataIndex index = const TransactionMetadataIndex(
    notes: [],
    tags: [],
  );
  Set<String> favoriteNotes = {};
  Set<String> favoriteTags = {};
  _MetadataFilter _noteFilter = _MetadataFilter.all;
  _MetadataFilter _tagFilter = _MetadataFilter.all;

  @override
  void initState() {
    super.initState();
    preferences = TransactionMetadataPreferences(widget.database);
    widget.noteController.addListener(_onTextChanged);
    tagController.addListener(_onTextChanged);
    _rebuildIndex();
    unawaited(_loadFavorites());
  }

  @override
  void didUpdateWidget(covariant TransactionMetadataFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.noteController != widget.noteController) {
      oldWidget.noteController.removeListener(_onTextChanged);
      widget.noteController.addListener(_onTextChanged);
    }
    if (!identical(oldWidget.transactions, widget.transactions) ||
        oldWidget.transactions.length != widget.transactions.length) {
      _rebuildIndex();
    }
  }

  @override
  void dispose() {
    widget.noteController.removeListener(_onTextChanged);
    tagController
      ..removeListener(_onTextChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadFavorites() async {
    final notes = await preferences.favoriteNotes();
    final tags = await preferences.favoriteTags();
    if (!mounted) return;
    setState(() {
      favoriteNotes = notes;
      favoriteTags = tags;
      _rebuildIndex();
    });
  }

  void _rebuildIndex() {
    index = TransactionMetadataSuggestions.buildIndex(
      widget.transactions,
      favoriteNotes: favoriteNotes,
      favoriteTags: favoriteTags,
    );
  }

  void _onTextChanged() {
    if (mounted) setState(() {});
  }

  List<TransactionMetadataEntry> _filtered(
    List<TransactionMetadataEntry> source,
    String text,
    _MetadataFilter filter, {
    bool tags = false,
  }) {
    if (filter == _MetadataFilter.all) {
      return tags
          ? index.tagSuggestions(text, excluded: widget.tags)
          : index.noteSuggestions(text);
    }
    final query = TransactionMetadataSuggestions.normalizeLookup(text);
    final excluded = widget.tags
        .map(TransactionMetadataSuggestions.normalizeLookup)
        .toSet();
    final matches =
        source.where((item) {
          if (tags && excluded.contains(item.normalized)) return false;
          if (filter == _MetadataFilter.favorites && !item.favorite)
            return false;
          return query.isEmpty || item.normalized.contains(query);
        }).toList()..sort((a, b) {
          final recent = b.lastUsed.compareTo(a.lastUsed);
          return recent != 0 ? recent : b.usageCount.compareTo(a.usageCount);
        });
    return matches.take(7).toList(growable: false);
  }

  List<TransactionMetadataEntry> get _noteSuggestions =>
      _filtered(index.notes, widget.noteController.text, _noteFilter);

  List<TransactionMetadataEntry> get _tagSuggestions =>
      _filtered(index.tags, tagController.text, _tagFilter, tags: true);

  Widget _suggestionSelector({
    required _MetadataFilter selected,
    required ValueChanged<_MetadataFilter> onChanged,
  }) => Padding(
    padding: const EdgeInsets.only(top: 8, bottom: 7),
    child: SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SegmentedButton<_MetadataFilter>(
        key: ValueKey(
          widget.section == TransactionMetadataSection.tags
              ? 'tag-suggestion-filter'
              : 'description-suggestion-filter',
        ),
        showSelectedIcon: false,
        style: const ButtonStyle(
          visualDensity: VisualDensity.compact,
          padding: WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          ),
        ),
        segments: const [
          ButtonSegment(value: _MetadataFilter.all, label: Text('Tutti')),
          ButtonSegment(value: _MetadataFilter.recent, label: Text('Recenti')),
          ButtonSegment(
            value: _MetadataFilter.favorites,
            label: Text('Preferiti'),
          ),
        ],
        selected: {selected},
        onSelectionChanged: (next) => onChanged(next.first),
      ),
    ),
  );

  void _completeNote(String value) {
    widget.noteController.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _completeFirstNoteSuggestion() {
    final values = _noteSuggestions;
    if (values.isEmpty) return;
    final current = TransactionMetadataSuggestions.normalizeLookup(
      widget.noteController.text,
    );
    if (current.isEmpty || values.first.normalized == current) return;
    _completeNote(values.first.value);
  }

  KeyEventResult _onNoteKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || event.logicalKey != LogicalKeyboardKey.tab) {
      return KeyEventResult.ignored;
    }
    final before = widget.noteController.text;
    _completeFirstNoteSuggestion();
    return before == widget.noteController.text
        ? KeyEventResult.ignored
        : KeyEventResult.handled;
  }

  Future<Set<String>> _toggleNoteFavorite(String value) async {
    final updated = await preferences.toggleFavoriteNote(value);
    if (mounted) {
      setState(() {
        favoriteNotes = updated;
        _rebuildIndex();
      });
    }
    return updated;
  }

  Future<Set<String>> _toggleTagFavorite(String value) async {
    final updated = await preferences.toggleFavoriteTag(value);
    if (mounted) {
      setState(() {
        favoriteTags = updated;
        _rebuildIndex();
      });
    }
    return updated;
  }

  Future<void> _showAllNotes() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MetadataPickerSheet(
        title: 'Descrizioni',
        searchHint: 'Cerca descrizione',
        entries: index.notes,
        favorites: favoriteNotes,
        tagMode: false,
        onToggleFavorite: _toggleNoteFavorite,
      ),
    );
    if (selected != null && mounted) _completeNote(selected);
  }

  Future<void> _showAllTags() async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _MetadataPickerSheet(
        title: 'Tag',
        searchHint: 'Cerca tag',
        entries: index.tags,
        favorites: favoriteTags,
        tagMode: true,
        excluded: widget.tags,
        onToggleFavorite: _toggleTagFavorite,
      ),
    );
    if (selected != null && mounted) _selectTag(selected);
  }

  bool _containsSelectedTag(String value) {
    final key = TransactionMetadataSuggestions.normalizeLookup(value);
    return widget.tags.any(
      (item) => TransactionMetadataSuggestions.normalizeLookup(item) == key,
    );
  }

  void _selectTag(String raw) {
    final cleaned = TransactionMetadataSuggestions.cleanTag(raw);
    if (cleaned.isEmpty) return;
    final canonical = index.canonicalTag(cleaned) ?? cleaned;
    if (_containsSelectedTag(canonical)) {
      tagController.clear();
      return;
    }
    widget.onTagsChanged([...widget.tags, canonical]);
    tagController.clear();
  }

  void _removeTag(String value) {
    final key = TransactionMetadataSuggestions.normalizeLookup(value);
    widget.onTagsChanged(
      widget.tags
          .where(
            (item) =>
                TransactionMetadataSuggestions.normalizeLookup(item) != key,
          )
          .toList(growable: false),
    );
  }

  void _submitTag(String raw) {
    final cleaned = TransactionMetadataSuggestions.cleanTag(raw);
    if (cleaned.isEmpty) return;
    final existing = index.canonicalTag(cleaned);
    if (existing != null) {
      _selectTag(existing);
      return;
    }
    final suggestions = _tagSuggestions;
    if (suggestions.isNotEmpty) {
      _selectTag(suggestions.first.value);
      return;
    }
    // Enter/Done is an explicit confirmation, equivalent to tapping “Crea”.
    _selectTag(cleaned);
  }

  @override
  Widget build(BuildContext context) {
    final noteSuggestions = _noteSuggestions;
    final tagSuggestions = _tagSuggestions;
    final cleanedTag = TransactionMetadataSuggestions.cleanTag(
      tagController.text,
    );
    final exactTag = cleanedTag.isEmpty ? null : index.canonicalTag(cleanedTag);
    final canCreateTag = cleanedTag.isNotEmpty && exactTag == null;

    final showDescription = widget.section != TransactionMetadataSection.tags;
    final showTags = widget.section != TransactionMetadataSection.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showDescription) ...[
          Text(
            'Descrizione',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (index.notes.isNotEmpty) ...[
            _suggestionSelector(
              selected: _noteFilter,
              onChanged: (filter) => setState(() => _noteFilter = filter),
            ),
            QuickSuggestionStrip(
              items: noteSuggestions
                  .map(
                    (item) => QuickSuggestionItem(
                      value: item.value,
                      label: item.value,
                      semanticsLabel:
                          '${item.value}${item.favorite ? ', preferita' : ''}',
                    ),
                  )
                  .toList(growable: false),
              onSelected: _completeNote,
              onShowAll: _showAllNotes,
            ),
            const SizedBox(height: 7),
          ] else
            const SizedBox(height: 10),
          Focus(
            onKeyEvent: _onNoteKey,
            child: TextField(
              controller: widget.noteController,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                labelText: AppI18n.tr('Descrizione opzionale'),
                hintText: AppI18n.tr('Es. LIDL, Spotify, stipendio…'),
                prefixIcon: const Icon(Icons.notes_rounded),
              ),
              onSubmitted: (_) => _completeFirstNoteSuggestion(),
            ),
          ),
        ],
        if (showDescription && showTags) const SizedBox(height: 22),
        if (showTags) ...[
          Text(
            'Tag',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            'Es. #Università o #Vacanza',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (widget.tags.isNotEmpty) ...[
            const SizedBox(height: 9),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: widget.tags
                  .map(
                    (value) => InputChip(
                      label: Text('#$value'),
                      onDeleted: () => _removeTag(value),
                      deleteButtonTooltipMessage: 'Rimuovi tag $value',
                    ),
                  )
                  .toList(growable: false),
            ),
          ],
          if (index.tags.isNotEmpty) ...[
            _suggestionSelector(
              selected: _tagFilter,
              onChanged: (filter) => setState(() => _tagFilter = filter),
            ),
            QuickSuggestionStrip(
              items: tagSuggestions
                  .map(
                    (item) => QuickSuggestionItem(
                      value: item.value,
                      label: '#${item.value}',
                      semanticsLabel:
                          'Tag ${item.value}${item.favorite ? ', preferito' : ''}',
                    ),
                  )
                  .toList(growable: false),
              onSelected: _selectTag,
              onShowAll: _showAllTags,
            ),
          ],
          const SizedBox(height: 9),
          TextField(
            controller: tagController,
            textInputAction: TextInputAction.done,
            decoration: InputDecoration(
              labelText: AppI18n.tr('Cerca o aggiungi tag'),
              hintText: AppI18n.tr('Es. Università'),
              prefixIcon: const Icon(Icons.tag_rounded),
            ),
            onSubmitted: _submitTag,
          ),
          if (canCreateTag)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _selectTag(cleanedTag),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text('Crea #$cleanedTag'),
              ),
            ),
        ],
      ],
    );
  }
}

class _MetadataPickerSheet extends StatefulWidget {
  const _MetadataPickerSheet({
    required this.title,
    required this.searchHint,
    required this.entries,
    required this.favorites,
    required this.tagMode,
    required this.onToggleFavorite,
    this.excluded = const [],
  });

  final String title;
  final String searchHint;
  final List<TransactionMetadataEntry> entries;
  final Set<String> favorites;
  final bool tagMode;
  final Future<Set<String>> Function(String value) onToggleFavorite;
  final List<String> excluded;

  @override
  State<_MetadataPickerSheet> createState() => _MetadataPickerSheetState();
}

class _MetadataPickerSheetState extends State<_MetadataPickerSheet> {
  final search = TextEditingController();
  late Set<String> favorites;
  bool changingFavorite = false;

  @override
  void initState() {
    super.initState();
    favorites = {...widget.favorites};
    search.addListener(_refresh);
  }

  @override
  void dispose() {
    search
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  bool _favorite(String value) {
    final key = TransactionMetadataSuggestions.normalizeLookup(value);
    return favorites.any(
      (item) => TransactionMetadataSuggestions.normalizeLookup(item) == key,
    );
  }

  bool _excluded(String value) {
    final key = TransactionMetadataSuggestions.normalizeLookup(value);
    return widget.excluded.any(
      (item) => TransactionMetadataSuggestions.normalizeLookup(item) == key,
    );
  }

  Future<void> _toggleFavorite(String value) async {
    if (changingFavorite) return;
    setState(() => changingFavorite = true);
    final updated = await widget.onToggleFavorite(value);
    if (!mounted) return;
    setState(() {
      favorites = updated;
      changingFavorite = false;
    });
  }

  List<TransactionMetadataEntry> _filtered() {
    final source = widget.entries
        .where((item) => !_excluded(item.value))
        .toList();
    if (search.text.trim().isEmpty) return source;
    final temp = widget.tagMode
        ? TransactionMetadataIndex(notes: const [], tags: source)
        : TransactionMetadataIndex(notes: source, tags: const []);
    return widget.tagMode
        ? temp.tagSuggestions(search.text, limit: 100)
        : temp.noteSuggestions(search.text, limit: 100);
  }

  List<_MetadataSection> _sections() {
    final filtered = _filtered();
    if (search.text.trim().isNotEmpty) {
      return [_MetadataSection('Risultati', filtered)];
    }
    final favorite = filtered.where((item) => _favorite(item.value)).toList()
      ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    final favoriteKeys = favorite.map((item) => item.normalized).toSet();
    final recent =
        filtered
            .where((item) => !favoriteKeys.contains(item.normalized))
            .toList()
          ..sort((a, b) => b.lastUsed.compareTo(a.lastUsed));
    final recentLimited = recent.take(10).toList();
    final used = {
      ...favoriteKeys,
      ...recentLimited.map((item) => item.normalized),
    };
    final frequent =
        filtered.where((item) => !used.contains(item.normalized)).toList()
          ..sort((a, b) {
            final count = b.usageCount.compareTo(a.usageCount);
            return count != 0 ? count : b.lastUsed.compareTo(a.lastUsed);
          });
    return [
      if (favorite.isNotEmpty) _MetadataSection('Preferiti', favorite),
      if (recentLimited.isNotEmpty) _MetadataSection('Recenti', recentLimited),
      if (frequent.isNotEmpty)
        _MetadataSection('Più usati', frequent.take(15).toList()),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final sections = _sections();
    return FractionallySizedBox(
      heightFactor: 0.82,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            TextField(
              controller: search,
              autofocus: false,
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Icons.search_rounded),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: sections.isEmpty
                  ? Center(
                      child: Text(
                        'Nessun elemento disponibile.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView(
                      children: [
                        for (final section in sections) ...[
                          Padding(
                            padding: const EdgeInsets.only(top: 8, bottom: 4),
                            child: Text(
                              section.title,
                              style: Theme.of(context).textTheme.labelLarge,
                            ),
                          ),
                          ...section.entries.map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text(
                                widget.tagMode ? '#${item.value}' : item.value,
                              ),
                              subtitle: Text(
                                item.usageCount == 1
                                    ? 'Usato 1 volta'
                                    : 'Usato ${item.usageCount} volte',
                              ),
                              onTap: () => Navigator.pop(context, item.value),
                              trailing: IconButton(
                                tooltip: _favorite(item.value)
                                    ? 'Rimuovi dai preferiti'
                                    : 'Aggiungi ai preferiti',
                                onPressed: changingFavorite
                                    ? null
                                    : () => _toggleFavorite(item.value),
                                icon: Icon(
                                  _favorite(item.value)
                                      ? Icons.star_rounded
                                      : Icons.star_border_rounded,
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
    );
  }
}

class _MetadataSection {
  const _MetadataSection(this.title, this.entries);

  final String title;
  final List<TransactionMetadataEntry> entries;
}
