import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/models/quick_capture_models.dart';
import 'package:dadafinanza/services/voice_transaction_parser.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const parser = VoiceTransactionParser();
  final now = DateTime(2026, 9, 7, 12);
  final accounts = [_account(1, 'Revolut')];
  final categories = [
    const Category(
      id: 1,
      name: 'Bar',
      iconKey: 'food',
      colorValue: 0xff000000,
      type: TransactionType.expense,
      quickOrder: null,
    ),
  ];

  VoiceParseResult parse(String value, {List<String> knownTags = const []}) =>
      parser.parse(
        value,
        accounts: accounts,
        categories: categories,
        knownTags: knownTags,
        now: now,
      );

  test('explicit note commands protect note content from amount parsing', () {
    for (final phrase in [
      'nota Monster',
      'descrizione Monster',
      'segna Monster',
      'scrivi nella nota Monster',
    ]) {
      final result = parse(phrase);
      expect(result.draft.note, 'Monster', reason: phrase);
      expect(result.draft.amountCents, isNull, reason: phrase);
    }
  });

  test('segna 1:46 keeps the whole value in the note', () {
    final result = parse('segna 1:46');
    expect(result.draft.note, '1:46');
    expect(result.draft.amountCents, isNull);
    expect(
      result.issues.any((issue) => issue.type == VoiceIssueType.missingAmount),
      isTrue,
    );
  });

  test('nota 1:46 is not interpreted as two amounts', () {
    final result = parse('nota 1:46');
    expect(result.draft.note, '1:46');
    expect(
      result.issues.any((issue) => issue.type == VoiceIssueType.ambiguousAmount),
      isFalse,
    );
  });

  test('explicit note is separated from transaction amount', () {
    final result = parse('spesa 1,46 euro nota Monster');
    expect(result.draft.amountCents, 146);
    expect(result.draft.note, 'Monster');
  });

  test('explicit tag commands populate draft tags', () {
    for (final phrase in [
      'aggiungi tag Monster',
      'aggiungi il tag Monster',
      'tag Monster',
      'metti tag Monster',
    ]) {
      final result = parse(phrase);
      expect(result.draft.tags, ['Monster'], reason: phrase);
    }
  });

  test('multiple tags are parsed and deduplicated logically', () {
    final result = parse(
      'tag vacanza e università e VACANZA',
      knownTags: const ['Vacanza', 'Università'],
    );
    expect(result.draft.tags, ['Vacanza', 'Università']);
  });

  test('known tag keeps its canonical casing', () {
    final result = parse('tag università', knownTags: const ['Università']);
    expect(result.draft.tags, ['Università']);
  });

  test('amount note and tag can coexist in one phrase', () {
    final result = parse(
      'Ho speso 3 euro nota Monster tag università',
      knownTags: const ['Università'],
    );
    expect(result.draft.type, TransactionType.expense);
    expect(result.draft.amountCents, 300);
    expect(result.draft.note, 'Monster');
    expect(result.draft.tags, ['Università']);
  });

  test('merchant note remains available before explicit tag', () {
    final result = parse(
      'Ho speso 5 euro al bar tag università',
      knownTags: const ['Università'],
    );
    expect(result.draft.amountCents, 500);
    expect(result.draft.note?.toLowerCase(), 'bar');
    expect(result.draft.tags, ['Università']);
  });

  test('structured sentence with note and tag preserves transaction fields', () {
    final result = parse(
      'Segna una spesa di 12 euro nota pranzo tag lavoro',
      knownTags: const ['Lavoro'],
    );
    expect(result.draft.amountCents, 1200);
    expect(result.draft.type, TransactionType.expense);
    expect(result.draft.note, 'pranzo');
    expect(result.draft.tags, ['Lavoro']);
  });
}

Account _account(int id, String name) => Account(
  id: id,
  name: name,
  balance: 0,
  colorValue: 0xff000000,
  iconKey: 'wallet',
  accountType: AccountType.checking,
  includeInTotal: true,
  includeInAnalytics: true,
  isLocked: false,
  isArchived: false,
  hideBalance: false,
  isSystem: false,
  createdAt: DateTime(2026),
  updatedAt: DateTime(2026),
);
