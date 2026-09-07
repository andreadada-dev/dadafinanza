import '../models/models.dart';
import 'smart_finance_engine.dart';

class TransactionMetadataEntry {
  const TransactionMetadataEntry({
    required this.value,
    required this.normalized,
    required this.semanticKey,
    required this.usageCount,
    required this.lastUsed,
    required this.favorite,
  });

  final String value;
  final String normalized;
  final String semanticKey;
  final int usageCount;
  final DateTime lastUsed;
  final bool favorite;
}

class TransactionMetadataIndex {
  const TransactionMetadataIndex({required this.notes, required this.tags});

  final List<TransactionMetadataEntry> notes;
  final List<TransactionMetadataEntry> tags;

  List<TransactionMetadataEntry> noteSuggestions(
    String query, {
    int limit = 7,
  }) => _suggest(notes, query, limit: limit);

  List<TransactionMetadataEntry> tagSuggestions(
    String query, {
    int limit = 7,
    Iterable<String> excluded = const [],
  }) {
    final excludedKeys = excluded
        .map(TransactionMetadataSuggestions.normalizeLookup)
        .where((value) => value.isNotEmpty)
        .toSet();
    return _suggest(
      tags.where((item) => !excludedKeys.contains(item.normalized)).toList(),
      query,
      limit: limit,
    );
  }

  String? canonicalTag(String raw) {
    final key = TransactionMetadataSuggestions.normalizeLookup(raw);
    if (key.isEmpty) return null;
    for (final item in tags) {
      if (item.normalized == key) return item.value;
    }
    return null;
  }

  static List<TransactionMetadataEntry> _suggest(
    List<TransactionMetadataEntry> source,
    String query, {
    required int limit,
  }) {
    if (limit <= 0 || source.isEmpty) return const [];
    final normalizedQuery = TransactionMetadataSuggestions.normalizeLookup(
      query,
    );
    if (normalizedQuery.isEmpty) {
      return _defaultSuggestions(source, limit: limit);
    }

    final matches = <(TransactionMetadataEntry, int)>[];
    for (final item in source) {
      final rank = item.normalized == normalizedQuery
          ? 0
          : item.normalized.startsWith(normalizedQuery)
          ? 1
          : item.normalized.contains(normalizedQuery)
          ? 2
          : null;
      if (rank != null) matches.add((item, rank));
    }
    matches.sort((left, right) {
      final rank = left.$2.compareTo(right.$2);
      if (rank != 0) return rank;
      final favorite = _compareBoolDesc(left.$1.favorite, right.$1.favorite);
      if (favorite != 0) return favorite;
      final frequency = right.$1.usageCount.compareTo(left.$1.usageCount);
      if (frequency != 0) return frequency;
      final recent = right.$1.lastUsed.compareTo(left.$1.lastUsed);
      if (recent != 0) return recent;
      return left.$1.value.toLowerCase().compareTo(
        right.$1.value.toLowerCase(),
      );
    });
    return matches.take(limit).map((item) => item.$1).toList(growable: false);
  }

  static List<TransactionMetadataEntry> _defaultSuggestions(
    List<TransactionMetadataEntry> source, {
    required int limit,
  }) {
    final favorites = source.where((item) => item.favorite).toList()
      ..sort(_byRecentThenFrequency);
    final recent = [...source]..sort(_byRecentThenFrequency);
    final frequent = [...source]..sort(_byFrequencyThenRecent);
    final output = <TransactionMetadataEntry>[];
    final seen = <String>{};

    void append(Iterable<TransactionMetadataEntry> values) {
      for (final item in values) {
        if (output.length >= limit) return;
        if (seen.add(item.normalized)) output.add(item);
      }
    }

    append(favorites);
    append(recent);
    append(frequent);
    return output;
  }

  static int _byRecentThenFrequency(
    TransactionMetadataEntry left,
    TransactionMetadataEntry right,
  ) {
    final recent = right.lastUsed.compareTo(left.lastUsed);
    if (recent != 0) return recent;
    return right.usageCount.compareTo(left.usageCount);
  }

  static int _byFrequencyThenRecent(
    TransactionMetadataEntry left,
    TransactionMetadataEntry right,
  ) {
    final frequency = right.usageCount.compareTo(left.usageCount);
    if (frequency != 0) return frequency;
    return right.lastUsed.compareTo(left.lastUsed);
  }

  static int _compareBoolDesc(bool left, bool right) {
    if (left == right) return 0;
    return left ? -1 : 1;
  }
}

class TransactionMetadataSuggestions {
  const TransactionMetadataSuggestions._();

  static TransactionMetadataIndex buildIndex(
    Iterable<FinanceTransaction> transactions, {
    Iterable<String> favoriteNotes = const [],
    Iterable<String> favoriteTags = const [],
  }) {
    final noteFavorites = favoriteNotes
        .map(normalizeLookup)
        .where((value) => value.isNotEmpty)
        .toSet();
    final tagFavorites = favoriteTags
        .map(normalizeLookup)
        .where((value) => value.isNotEmpty)
        .toSet();
    final noteStats = <String, _MutableMetadataStats>{};
    final tagStats = <String, _MutableMetadataStats>{};

    for (final transaction in transactions) {
      final note = transaction.note?.trim();
      if (note != null && note.isNotEmpty) {
        _accumulate(noteStats, note, transaction.date);
      }
      for (final rawTag in transaction.tags) {
        final value = cleanTag(rawTag);
        if (value.isNotEmpty) _accumulate(tagStats, value, transaction.date);
      }
    }

    return TransactionMetadataIndex(
      notes: _freeze(noteStats, noteFavorites),
      tags: _freeze(tagStats, tagFavorites),
    );
  }

  static String cleanTag(String input) => input
      .trim()
      .replaceFirst(RegExp(r'^#+\s*'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  /// Lookup normalization intentionally keeps all meaningful words while
  /// following Smart Finance's lowercase/punctuation/spacing conventions.
  /// Smart Finance's semantic key is stored separately so learned signatures
  /// are not changed by this feature.
  static String normalizeLookup(String input) {
    final cleaned = cleanTag(input).toLowerCase();
    final withoutAccents = _stripAccents(cleaned);
    return withoutAccents
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String semanticKey(String input) =>
      SmartFinanceEngine.normalizeText(cleanTag(input));

  static void _accumulate(
    Map<String, _MutableMetadataStats> target,
    String raw,
    DateTime date,
  ) {
    final value = raw.trim().replaceAll(RegExp(r'\s+'), ' ');
    final normalized = normalizeLookup(value);
    if (normalized.isEmpty) return;
    final existing = target[normalized];
    if (existing == null) {
      target[normalized] = _MutableMetadataStats(
        value: value,
        normalized: normalized,
        semanticKey: semanticKey(value),
        usageCount: 1,
        lastUsed: date,
      );
      return;
    }
    existing.usageCount++;
    if (date.isAfter(existing.lastUsed)) {
      existing
        ..lastUsed = date
        ..value = value
        ..semanticKey = semanticKey(value);
    }
  }

  static List<TransactionMetadataEntry> _freeze(
    Map<String, _MutableMetadataStats> values,
    Set<String> favorites,
  ) => values.values
      .map(
        (item) => TransactionMetadataEntry(
          value: item.value,
          normalized: item.normalized,
          semanticKey: item.semanticKey,
          usageCount: item.usageCount,
          lastUsed: item.lastUsed,
          favorite: favorites.contains(item.normalized),
        ),
      )
      .toList(growable: false);

  static String _stripAccents(String value) {
    const from = 'àáâäãåèéêëìíîïòóôöõùúûüçñ';
    const to = 'aaaaaaeeeeiiiiooooouuuucn';
    var output = value;
    for (var index = 0; index < from.length; index++) {
      output = output.replaceAll(from[index], to[index]);
    }
    return output;
  }
}

class _MutableMetadataStats {
  _MutableMetadataStats({
    required this.value,
    required this.normalized,
    required this.semanticKey,
    required this.usageCount,
    required this.lastUsed,
  });

  String value;
  final String normalized;
  String semanticKey;
  int usageCount;
  DateTime lastUsed;
}
