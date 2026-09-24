import 'package:dadafinanza/app_state.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/main.dart';
import 'package:dadafinanza/models/advance_models.dart';
import 'package:dadafinanza/screens/advances_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  FinancePerson person(int id) {
    final now = DateTime(2026, 9, 25);
    return FinancePerson(
      id: id,
      name: 'Persona $id',
      colorValue: 0xFF8E8E93,
      iconKey: 'person',
      archived: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  Future<void> pumpPicker(
    WidgetTester tester, {
    required double width,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final state = AppState(AppDatabase())
      ..people = List.generate(30, (index) => person(index + 1));

    await tester.pumpWidget(
      AppScope(
        notifier: state,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 800),
              textScaler: TextScaler.linear(textScale),
            ),
            child: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () =>
                        showFinancePersonPicker(context, allowCreate: true),
                    child: const Text('Apri persone'),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Apri persone'));
    await tester.pumpAndSettle();
  }

  testWidgets('person picker uses three columns on compact widths', (
    tester,
  ) async {
    await pumpPicker(tester, width: 360);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 3);
    expect(find.text('Cerca persona'), findsOneWidget);
    expect(find.text('Nuova'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('person picker uses four columns on wider phones', (
    tester,
  ) async {
    await pumpPicker(tester, width: 430);

    final grid = tester.widget<GridView>(find.byType(GridView));
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;

    expect(delegate.crossAxisCount, 4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('person picker filters people while typing', (tester) async {
    await pumpPicker(tester, width: 390);

    await tester.enterText(find.byType(TextField), 'Persona 27');
    await tester.pumpAndSettle();

    expect(find.text('Persona 27'), findsOneWidget);
    expect(find.text('Persona 1'), findsNothing);
    expect(find.text('Nuova'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('person picker remains scrollable without overflow', (
    tester,
  ) async {
    await pumpPicker(tester, width: 320, textScale: 1.3);

    expect(find.byType(GridView), findsOneWidget);
    await tester.drag(find.byType(GridView), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
