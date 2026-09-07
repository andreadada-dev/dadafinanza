import 'dart:convert';

import '../data/app_database.dart';
import 'transaction_metadata_suggestions.dart';

class TransactionMetadataPreferences {
  TransactionMetadataPreferences(this.database);

  static const favoriteNotesKey = 'quick_add_favorite_notes';
  static const favoriteTagsKey = 'quick_add_favorite_tags';

  final AppDatabase database;

  Future<Set<String>> favoriteNotes() => _load(favoriteNotesKey);

  Future<Set<String>> favoriteTags() => _load(favoriteTagsKey);

  Future<Set<String>> toggleFavoriteNote(String value) =>
      _toggle(favoriteNotesKey, value);

  Future<Set<String>> toggleFavoriteTag(String value) =>
      _toggle(favoriteTagsKey, value);

  Future<Set<String>> _load(String key) async {
    final raw = await database.getSetting(key);
    if (raw == null || raw.trim().isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded
          .whereType<String>()
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet();
    } on FormatException {
      return <String>{};
    }
  }

  Future<Set<String>> _toggle(String key, String rawValue) async {
    final value = key == favoriteTagsKey
        ? TransactionMetadataSuggestions.cleanTag(rawValue)
        : rawValue.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (value.isEmpty) return _load(key);

    final values = await _load(key);
    final normalized = TransactionMetadataSuggestions.normalizeLookup(value);
    final matching = values.where(
      (item) =>
          TransactionMetadataSuggestions.normalizeLookup(item) == normalized,
    );
    if (matching.isNotEmpty) {
      values.removeAll(matching.toList());
    } else {
      values.add(value);
    }
    final sorted = values.toList()
      ..sort((left, right) => left.toLowerCase().compareTo(right.toLowerCase()));
    await database.setSetting(key, jsonEncode(sorted));
    return sorted.toSet();
  }
}
