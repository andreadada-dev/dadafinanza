import 'dart:io';

import 'package:dadafinanza/app_state.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/main.dart';
import 'package:dadafinanza/models/advance_models.dart';
import 'package:dadafinanza/screens/advances_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('it_IT');
  });

  FinancePerson person(int id, String name) {
    final now = DateTime(2026, 9, 25);
    return FinancePerson(
      id: id,
      name: name,
      colorValue: 0xFF8E8E93,
      iconKey: 'person',
      archived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Advance advance({
    required int id,
    required int personId,
    required int cents,
    required DateTime createdAt,
    AdvanceDirection direction = AdvanceDirection.receivable,
    DateTime? reminderDate,
  }) => Advance(
    id: id,
    direction: direction,
    personId: personId,
    originalAmountCents: cents,
    reminderDate: reminderDate,
    createdAt: createdAt,
    updatedAt: createdAt,
  );

  Future<void> pumpScreen(
    WidgetTester tester,
    AppState state, {
    double width = 390,
    double textScale = 1,
    Widget home = const AdvancesScreen(showFab: false),
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      AppScope(
        notifier: state,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 850),
              textScaler: TextScaler.linear(textScale),
            ),
            child: home,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('main advances screen shows people in a searchable grid', (
    tester,
  ) async {
    final now = DateTime.now();
    final state = AppState(AppDatabase())
      ..people = [person(1, 'Dario'), person(2, 'Anna')]
      ..advances = [
        advance(
          id: 1,
          personId: 1,
          cents: 1000,
          createdAt: DateTime(2026, 9, 25),
          reminderDate: now.add(const Duration(days: 1)),
        ),
        advance(
          id: 2,
          personId: 1,
          cents: 500,
          createdAt: DateTime(2026, 9, 20),
        ),
        advance(
          id: 3,
          personId: 2,
          cents: 700,
          createdAt: DateTime(2026, 9, 19),
          direction: AdvanceDirection.payable,
        ),
      ];

    await pumpScreen(tester, state);

    expect(find.text('Persone'), findsOneWidget);
    expect(find.text('Cerca persona'), findsOneWidget);
    expect(find.byType(GridView), findsOneWidget);
    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.crossAxisCount, 3);
    expect(find.text('Dario'), findsOneWidget);
    expect(find.text('Anna'), findsOneWidget);
    expect(find.text('Notifica domani'), findsOneWidget);
    expect(find.text('Apri Storico'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Anna');
    await tester.pumpAndSettle();

    expect(
      find.descendant(of: find.byType(GridView), matching: find.text('Anna')),
      findsOneWidget,
    );
    expect(find.text('Dario'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('person detail shows dated timeline status and quick actions', (
    tester,
  ) async {
    final now = DateTime.now();
    final settledAt = DateTime(2026, 9, 20);
    final state = AppState(AppDatabase())
      ..people = [person(1, 'Dario')]
      ..advances = [
        advance(
          id: 1,
          personId: 1,
          cents: 1000,
          createdAt: DateTime(2026, 9, 25),
          reminderDate: now.add(const Duration(days: 1)),
        ),
        advance(id: 2, personId: 1, cents: 500, createdAt: settledAt),
      ]
      ..advanceSettlements = [
        AdvanceSettlement(
          id: 1,
          advanceId: 2,
          amountCents: 500,
          transactionId: 9,
          accountId: 1,
          date: settledAt,
          createdAt: settledAt,
        ),
      ];

    await pumpScreen(
      tester,
      state,
      home: const FinancePersonDetailScreen(personId: 1),
    );

    expect(find.text('Dario'), findsOneWidget);
    expect(find.text('Notifica domani'), findsOneWidget);
    expect(find.text('Movimenti'), findsOneWidget);
    expect(find.text('Nuovo anticipo'), findsOneWidget);
    expect(find.textContaining('25 set 2026 ·'), findsOneWidget);
    expect(find.text('Da saldare'), findsOneWidget);
    expect(find.text('Non recuperato'), findsOneWidget);
    expect(find.text('Mi hanno saldato'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('grouped person list remains scrollable on narrow screens', (
    tester,
  ) async {
    final people = List.generate(
      24,
      (index) => person(index + 1, 'Persona ${index + 1}'),
    );
    final advances = List.generate(
      24,
      (index) => advance(
        id: index + 1,
        personId: index + 1,
        cents: 1000 + index,
        createdAt: DateTime(2026, 9, 25),
      ),
    );
    final state = AppState(AppDatabase())
      ..people = people
      ..advances = advances;

    await pumpScreen(tester, state, width: 320, textScale: 1.3);

    final list = find.byType(ListView);
    expect(list, findsOneWidget);
    await tester.drag(list, const Offset(0, -900));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  test('people expose editable icon and color', () {
    final source = File('lib/screens/advances_screen.dart').readAsStringSync();
    final state = File('lib/app_state.dart').readAsStringSync();

    expect(source, contains('showFinancePersonEditor'));
    expect(source, contains('personIconOptions'));
    expect(source, contains("'Colore'"));
    expect(source, contains('personIcon(person.iconKey)'));
    expect(state, contains('updateFinancePerson'));
  });

  test('new advance flow accepts a preselected person', () {
    final source = File('lib/screens/advances_screen.dart').readAsStringSync();

    expect(source, contains('int? initialPersonId'));
    expect(
      source,
      contains('showAdvanceEditor(context, initialPersonId: person.id)'),
    );
  });
}
