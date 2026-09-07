import 'package:dadafinanza/app_state.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/main.dart';
import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/screens/quick_add_page.dart';
import 'package:dadafinanza/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

class _SmokeDatabase extends AppDatabase {
  final settings = <String, String>{};

  @override
  Future<String?> getSetting(String key) async => settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    settings[key] = value;
  }
}

Finder _noteField() => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.labelText == 'Descrizione opzionale',
);

Finder _tagField() => find.byWidgetPredicate(
  (widget) =>
      widget is TextField &&
      widget.decoration?.labelText == 'Cerca o aggiungi tag',
);

void main() {
  for (final size in const [
    Size(320, 700),
    Size(360, 800),
    Size(390, 844),
    Size(430, 932),
  ]) {
    testWidgets('Quick Add metadata has no overflow at ${size.width}dp', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await _pumpQuickAdd(tester, dark: false);
      await _revealTagMetadata(tester);

      expect(find.text('TAG'), findsOneWidget);
      expect(find.text('#Università'), findsWidgets);
      expect(_tagField(), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Quick Add metadata supports dark mode and large text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpQuickAdd(tester, dark: true, textScale: 1.6);
    await _revealTagMetadata(tester);

    expect(find.text('TAG'), findsOneWidget);
    expect(_tagField(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Quick Add metadata bottom sheet closes cleanly', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpQuickAdd(tester, dark: true);
    await _revealNoteMetadata(tester);

    final showAll = find.text('Mostra tutte').first;
    await tester.ensureVisible(showAll);
    await tester.pumpAndSettle();
    await tester.tap(showAll);
    await tester.pumpAndSettle();

    expect(find.text('Descrizioni'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byTooltip('Chiudi'));
    await tester.pumpAndSettle();
    expect(find.text('Descrizioni'), findsNothing);
    expect(find.text('Nuovo movimento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpQuickAdd(
  WidgetTester tester, {
  required bool dark,
  double textScale = 1,
}) async {
  await initializeDateFormatting('it_IT');
  final state = _state();
  await tester.pumpWidget(
    AppScope(
      notifier: state,
      child: MediaQuery(
        data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
        child: MaterialApp(
          theme: dark ? AppTheme.dark() : AppTheme.light(),
          home: const QuickAddPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _revealNoteMetadata(WidgetTester tester) async {
  await tester.scrollUntilVisible(
    _noteField(),
    300,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

Future<void> _revealTagMetadata(WidgetTester tester) async {
  await _revealNoteMetadata(tester);
  await tester.scrollUntilVisible(
    _tagField(),
    220,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

AppState _state() {
  final database = _SmokeDatabase();
  final state = AppState(database)..loading = false;
  final now = DateTime(2026, 9, 7, 12);
  state.accounts = [
    Account(
      id: 1,
      name: 'Revolut',
      balance: 100,
      colorValue: 0xFF607DFF,
      iconKey: 'bank',
      accountType: AccountType.checking,
      includeInTotal: true,
      includeInAnalytics: true,
      isLocked: false,
      isArchived: false,
      hideBalance: false,
      isSystem: false,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  state.categories = const [
    Category(
      id: 1,
      name: 'Alimentari',
      iconKey: 'groceries',
      colorValue: 0xFF888888,
      type: TransactionType.expense,
      quickOrder: 0,
    ),
  ];
  state.transactions = [
    FinanceTransaction(
      id: 1,
      type: TransactionType.expense,
      amount: 3,
      accountId: 1,
      categoryId: 1,
      date: now,
      note: 'Monster',
      tags: const ['Università'],
      includeInAnalytics: true,
      createdAt: now,
      updatedAt: now,
    ),
  ];
  return state;
}
