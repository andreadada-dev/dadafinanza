import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/widgets/transaction_metadata_fields.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeMetadataDatabase extends AppDatabase {
  final settings = <String, String>{};

  @override
  Future<String?> getSetting(String key) async => settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }
}

void main() {
  final now = DateTime(2026, 9, 7, 12);

  testWidgets('Enter completes the first note suggestion without saving', (
    tester,
  ) async {
    final note = TextEditingController();
    addTearDown(note.dispose);
    await _pumpFields(
      tester,
      note: note,
      transactions: [
        _transaction(1, note: 'Monster', date: now),
        _transaction(
          2,
          note: 'Spesa Monster Energy',
          date: now.subtract(const Duration(days: 1)),
        ),
      ],
    );

    final field = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Descrizione opzionale',
    );
    await tester.enterText(field, 'Mon');
    await tester.pump();
    expect(find.text('Monster'), findsWidgets);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(note.text, 'Monster');
  });

  testWidgets('existing tag is selected instead of creating a duplicate', (
    tester,
  ) async {
    final note = TextEditingController();
    addTearDown(note.dispose);
    var selected = <String>[];
    await _pumpFields(
      tester,
      note: note,
      transactions: [
        _transaction(1, date: now, tags: const ['Università']),
      ],
      onTagsChanged: (values) => selected = values,
    );

    final tagField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Cerca o aggiungi tag',
    );
    await tester.enterText(tagField, 'universita');
    await tester.pump();
    expect(find.text('#Università'), findsWidgets);

    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(selected, ['Università']);
  });

  testWidgets('new tag requires explicit create action while typing', (
    tester,
  ) async {
    final note = TextEditingController();
    addTearDown(note.dispose);
    var selected = <String>[];
    await _pumpFields(
      tester,
      note: note,
      transactions: const [],
      onTagsChanged: (values) => selected = values,
    );

    final tagField = find.byWidgetPredicate(
      (widget) =>
          widget is TextField &&
          widget.decoration?.labelText == 'Cerca o aggiungi tag',
    );
    await tester.enterText(tagField, 'Roma2026');
    await tester.pump();

    expect(selected, isEmpty);
    expect(find.text('Crea #Roma2026'), findsOneWidget);
    await tester.tap(find.text('Crea #Roma2026'));
    await tester.pump();
    expect(selected, ['Roma2026']);
  });

  testWidgets('favorite note is persisted through local settings', (
    tester,
  ) async {
    final note = TextEditingController();
    addTearDown(note.dispose);
    final database = FakeMetadataDatabase();
    await _pumpFields(
      tester,
      note: note,
      database: database,
      transactions: [_transaction(1, note: 'Monster', date: now)],
    );

    await tester.tap(find.text('Mostra tutte').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Aggiungi ai preferiti').first);
    await tester.pumpAndSettle();

    expect(database.settings['quick_add_favorite_notes'], contains('Monster'));
  });
}

Future<void> _pumpFields(
  WidgetTester tester, {
  required TextEditingController note,
  required List<FinanceTransaction> transactions,
  FakeMetadataDatabase? database,
  ValueChanged<List<String>>? onTagsChanged,
}) async {
  final db = database ?? FakeMetadataDatabase();
  var tags = <String>[];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatefulBuilder(
          builder: (context, setState) => ListView(
            padding: const EdgeInsets.all(20),
            children: [
              TransactionMetadataFields(
                noteController: note,
                transactions: transactions,
                tags: tags,
                database: db,
                onTagsChanged: (values) {
                  onTagsChanged?.call(values);
                  setState(() => tags = values);
                },
              ),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

FinanceTransaction _transaction(
  int id, {
  String? note,
  required DateTime date,
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
