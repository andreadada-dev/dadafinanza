import 'dart:io';

import 'package:dadafinanza/app_state.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/services/csv_service.dart';
import 'package:dadafinanza/services/finance_schema_service.dart';
import 'package:dadafinanza/services/widget_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

class _NoopWidgetService extends WidgetService {
  @override
  Future<void> sync({
    required double balance,
    required List<Category> expenseCategories,
  }) async {}
}

void main() {
  late Directory databaseRoot;

  setUpAll(() async {
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
    databaseRoot = await Directory.systemTemp.createTemp(
      'dadafinanza-settings-db-',
    );
    await databaseFactory.setDatabasesPath(databaseRoot.path);
  });

  tearDownAll(() async {
    if (await databaseRoot.exists()) {
      await databaseRoot.delete(recursive: true);
    }
  });

  Future<AppDatabase> openReadyDatabase() async {
    final root = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(root, 'dadafinanza.db'));
    final database = AppDatabase();
    await database.init();
    await FinanceSchemaService(database).ensure();
    addTearDown(() async {
      if (database.db.isOpen) await database.db.close();
    });
    return database;
  }

  test('settings values persist through AppState reload', () async {
    final database = await openReadyDatabase();
    final state = AppState(database, widgetService: _NoopWidgetService());
    await state.load();

    await state.setSetting('currency', 'USD');
    await state.setSetting('show_cents', '0');
    await state.setSetting('week_start', DateTime.sunday.toString());
    await state.setSetting('financial_month_start', '15');
    await state.setSetting('confirm_delete', '0');

    final reloaded = AppState(database, widgetService: _NoopWidgetService());
    await reloaded.load();
    expect(reloaded.currency, 'USD');
    expect(reloaded.showCents, isFalse);
    expect(reloaded.weekStart, DateTime.sunday);
    expect(reloaded.financialMonthStart, 15);
    expect(reloaded.confirmDelete, isFalse);
  });

  test('CSV preserves multiline notes and structured tags', () {
    final now = DateTime.utc(2026, 9, 24, 12);
    final state = AppState(AppDatabase())
      ..accounts = [
        Account(
          id: 1,
          name: 'Main',
          balance: 100,
          colorValue: 0xFF8E8E93,
          iconKey: 'wallet',
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
      ]
      ..transactions = [
        FinanceTransaction(
          id: 1,
          type: TransactionType.expense,
          amount: 8.4,
          accountId: 1,
          date: now,
          note: 'Prima riga\nSeconda, "citata"',
          tags: const ['a|b', 'unicode-è'],
          includeInAnalytics: true,
          createdAt: now,
          updatedAt: now,
        ),
      ];

    const service = CsvService();
    final csv = service.export(state);
    final preview = service.preview(state, csv);

    expect(csv, contains('tags_json'));
    expect(csv, contains('Prima riga\nSeconda, ""citata""'));
    expect(preview.invalidRows, 0);
    expect(preview.rows, hasLength(1));
    expect(preview.rows.single.note, 'Prima riga\nSeconda, "citata"');
    expect(preview.rows.single.tags, const ['a|b', 'unicode-è']);
  });

  test('canonical settings and contextual donut periods stay wired', () {
    final settings = File(
      'lib/screens/personal_settings_screen.dart',
    ).readAsStringSync();
    final legacySettings = File(
      'lib/screens/settings_screen.dart',
    ).readAsStringSync();
    final root = File('lib/screens/root_screen.dart').readAsStringSync();
    final polished = File('lib/screens/polished_shell.dart').readAsStringSync();
    final donut = File(
      'lib/widgets/home_dashboard_widget.dart',
    ).readAsStringSync();

    for (final label in const [
      'Valuta principale',
      'Mostra centesimi',
      'Primo giorno settimana',
      'Inizio mese finanziario',
      'Conferma eliminazioni',
      'Conti',
    ]) {
      expect(settings, contains(label));
    }
    expect(root, contains('PersonalSettingsScreen()'));
    expect(polished, contains('PersonalSettingsScreen()'));
    expect(legacySettings, isNot(contains('class SettingsScreen')));

    expect(
      donut,
      contains(
        'enum _CategoryChartRange { today, thisWeek, thisMonth, custom }',
      ),
    );
    expect(donut, contains("_CategoryChartRange.today => 'Oggi'"));
    expect(donut, contains("_CategoryChartRange.thisWeek => 'Settimana'"));
    expect(donut, contains("_CategoryChartRange.thisMonth => 'Mese'"));
    expect(donut, contains("_CategoryChartRange.custom"));
    expect(donut, contains('_hasTodayData'));
    expect(donut, contains('widget.accountId'));
  });

  test('CSV import remains compatible with the previous header', () {
    final now = DateTime.utc(2026, 9, 24, 12);
    final state = AppState(AppDatabase())
      ..accounts = [
        Account(
          id: 1,
          name: 'Main',
          balance: 100,
          colorValue: 0xFF8E8E93,
          iconKey: 'wallet',
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

    const oldCsv =
        'type,amount,date,account,to_account,category,description,tags,include_in_analytics,stable_key\n'
        'expense,4.20,2026-09-24T12:00:00.000Z,Main,,,Coffee,work|break,1,legacy-key\n';

    const service = CsvService();
    final preview = service.preview(state, oldCsv);

    expect(preview.invalidRows, 0);
    expect(preview.rows, hasLength(1));
    expect(preview.rows.single.tags, const ['work', 'break']);
    expect(preview.rows.single.note, 'Coffee');
  });
}
