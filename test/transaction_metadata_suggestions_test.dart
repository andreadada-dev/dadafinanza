import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/services/transaction_metadata_suggestions.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 9, 7, 12);

  test('note ranking uses exact, prefix, contains then frequency and recency', () {
    final index = TransactionMetadataSuggestions.buildIndex([
      _transaction(1, 'Monster', now.subtract(const Duration(days: 3))),
      _transaction(2, 'Monster', now.subtract(const Duration(days: 2))),
      _transaction(3, 'Spesa Monster Energy', now),
      _transaction(4, 'Monopoli', now.subtract(const Duration(days: 1))),
    ]);

    expect(index.noteSuggestions('Monster').first.value, 'Monster');
    expect(index.noteSuggestions('Mon').first.value, 'Monster');
    expect(
      index.noteSuggestions('ster').map((item) => item.value),
      containsAll(['Monster', 'Spesa Monster Energy']),
    );
  });

  test('lookup is case and accent insensitive', () {
    final index = TransactionMetadataSuggestions.buildIndex([
      _transaction(1, 'Università', now),
    ]);

    expect(index.noteSuggestions('universita').single.value, 'Università');
    expect(index.noteSuggestions('UNIVERSITÀ').single.value, 'Università');
  });

  test('favorites come before recent and frequent when query is empty', () {
    final index = TransactionMetadataSuggestions.buildIndex(
      [
        _transaction(1, 'Monster', now.subtract(const Duration(days: 30))),
        _transaction(2, 'LIDL', now),
        _transaction(3, 'LIDL', now.subtract(const Duration(days: 1))),
      ],
      favoriteNotes: const ['Monster'],
    );

    expect(index.noteSuggestions('').first.value, 'Monster');
  });

  test('tag catalog deduplicates case, hash and whitespace variants', () {
    final index = TransactionMetadataSuggestions.buildIndex([
      _transaction(1, null, now, tags: const ['Monster']),
      _transaction(2, null, now, tags: const ['monster']),
      _transaction(3, null, now, tags: const ['#MONSTER']),
      _transaction(4, null, now, tags: const [' Monster ']),
    ]);

    expect(index.tags, hasLength(1));
    expect(index.tags.single.usageCount, 4);
    expect(index.canonicalTag('#monster'), isNotNull);
  });

  test('tag search supports prefix and contains and excludes selected tags', () {
    final index = TransactionMetadataSuggestions.buildIndex([
      _transaction(1, null, now, tags: const ['Università', 'Vacanza']),
      _transaction(2, null, now, tags: const ['Roma2026']),
    ]);

    expect(index.tagSuggestions('Uni').first.value, 'Università');
    expect(index.tagSuggestions('2026').first.value, 'Roma2026');
    expect(
      index.tagSuggestions('', excluded: const ['universita']).map((e) => e.value),
      isNot(contains('Università')),
    );
  });
}

FinanceTransaction _transaction(
  int id,
  String? note,
  DateTime date, {
  List<String> tags = const [],
}) => FinanceTransaction(
  id: id,
  type: TransactionType.expense,
  amount: 1,
  accountId: 1,
  date: date,
  note: note,
  tags: tags,
  includeInAnalytics: true,
  createdAt: date,
  updatedAt: date,
);
