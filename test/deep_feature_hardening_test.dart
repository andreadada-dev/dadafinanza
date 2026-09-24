import 'dart:io';

import 'package:dadafinanza/app_state.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/services/finance_schema_service.dart';
import 'package:dadafinanza/services/widget_service.dart';
import 'package:dadafinanza/services/recurring_execution_service.dart';
import 'package:dadafinanza/services/rule_service.dart';
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
      'dadafinanza-hardening-db-',
    );
    await databaseFactory.setDatabasesPath(databaseRoot.path);
  });

  tearDownAll(() async {
    if (await databaseRoot.exists()) {
      await databaseRoot.delete(recursive: true);
    }
  });

  Future<void> resetDatabase() async {
    final root = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(root, 'dadafinanza.db'));
  }

  Future<AppDatabase> openReadyDatabase() async {
    await resetDatabase();
    final database = AppDatabase();
    await database.init();
    await FinanceSchemaService(database).ensure();
    addTearDown(() async {
      if (database.db.isOpen) await database.db.close();
    });
    return database;
  }

  Future<int> addAccount(
    AppDatabase database,
    String name, {
    double balance = 100,
  }) => database.addAccount(
    name: name,
    balance: balance,
    colorValue: 0xFF8E8E93,
    iconKey: 'wallet',
    type: AccountType.checking,
    includeInTotal: true,
    includeInAnalytics: true,
    hideBalance: false,
  );

  test('v6 migration preserves recurring destinations and integrity', () async {
    final original = await openReadyDatabase();
    final source = await addAccount(original, 'Source');
    final destination = await addAccount(original, 'Destination');
    await original.addRecurring(
      name: 'Transfer',
      amount: 15,
      type: TransactionType.transfer,
      accountId: source,
      toAccountId: destination,
      frequency: 'Mensile',
      nextDate: DateTime.utc(2026, 10, 1),
      autoCreate: true,
    );
    await original.addRule(
      const AutomationRule(
        id: 0,
        name: 'Priority',
        enabled: true,
        containsText: 'coffee',
        priority: 9,
      ),
    );

    final path = await original.databaseFilePath();
    await original.db.close();
    final legacy = await databaseFactory.openDatabase(path);
    await legacy.execute('PRAGMA user_version = 5');
    await legacy.close();

    final upgraded = AppDatabase();
    await upgraded.init();
    await FinanceSchemaService(upgraded).ensure();
    addTearDown(() async {
      if (upgraded.db.isOpen) await upgraded.db.close();
    });

    expect(AppDatabase.databaseVersion, 6);
    expect((await upgraded.recurring()).single.toAccountId, destination);
    expect((await upgraded.rules()).single.priority, 9);
    expect(await upgraded.db.rawQuery('PRAGMA foreign_key_check'), isEmpty);
  });

  test('highest-priority automation rule wins', () async {
    final database = await openReadyDatabase();
    final accountId = await addAccount(database, 'Main');
    final low = await database.addCategory(
      name: 'Low',
      type: TransactionType.expense,
      iconKey: 'category',
      colorValue: 0xFF8E8E93,
    );
    final high = await database.addCategory(
      name: 'High',
      type: TransactionType.expense,
      iconKey: 'category',
      colorValue: 0xFF8E8E93,
    );
    await database.addRule(
      AutomationRule(
        id: 0,
        name: 'Low',
        enabled: true,
        containsText: 'coffee',
        type: TransactionType.expense,
        categoryId: low,
        priority: 1,
      ),
    );
    await database.addRule(
      AutomationRule(
        id: 0,
        name: 'High',
        enabled: true,
        containsText: 'coffee',
        type: TransactionType.expense,
        categoryId: high,
        priority: 20,
      ),
    );
    await database.addTransaction(
      type: TransactionType.expense,
      amount: 3.5,
      accountId: accountId,
      date: DateTime.utc(2026, 9, 24),
      note: 'Coffee bar',
    );
    expect((await database.transactions()).single.categoryId, high);
  });

  test('rule validation rejects category without compatible type', () async {
    final database = await openReadyDatabase();
    final categoryId = await database.addCategory(
      name: 'Food',
      type: TransactionType.expense,
      iconKey: 'restaurant',
      colorValue: 0xFF8E8E93,
    );
    final state = AppState(database, widgetService: _NoopWidgetService());
    await state.load();
    expect(
      () => const RuleService().validate(
        state,
        AutomationRule(
          id: 0,
          name: 'Invalid',
          enabled: true,
          categoryId: categoryId,
        ),
      ),
      throwsStateError,
    );
  });

  test(
    'recurring transfer creates a real transfer and advances date',
    () async {
      final database = await openReadyDatabase();
      final source = await addAccount(database, 'Source', balance: 100);
      final destination = await addAccount(
        database,
        'Destination',
        balance: 50,
      );
      final due = DateTime.utc(2026, 9, 24, 12);
      await database.addRecurring(
        name: 'Savings transfer',
        amount: 12.34,
        type: TransactionType.transfer,
        accountId: source,
        toAccountId: destination,
        frequency: 'Mensile',
        nextDate: due,
        autoCreate: true,
      );

      final created = await const RecurringExecutionService().processDue(
        database,
        now: due.add(const Duration(minutes: 1)),
      );
      expect(created, 1);
      final movement = (await database.transactions()).single;
      expect(movement.type, TransactionType.transfer);
      expect(movement.accountId, source);
      expect(movement.toAccountId, destination);
      final accounts = await database.accounts();
      expect(
        accounts.firstWhere((item) => item.id == source).balance,
        closeTo(87.66, 0.001),
      );
      expect(
        accounts.firstWhere((item) => item.id == destination).balance,
        closeTo(62.34, 0.001),
      );
    },
  );

  test('automation rule lifecycle stays ordered and editable', () async {
    final database = await openReadyDatabase();
    final accountId = await addAccount(database, 'Main');
    final categoryId = await database.addCategory(
      name: 'Food',
      type: TransactionType.expense,
      iconKey: 'restaurant',
      colorValue: 0xFF8E8E93,
    );
    final state = AppState(database, widgetService: _NoopWidgetService());
    await state.load();
    const service = RuleService();

    await state.addRule(
      AutomationRule(
        id: 0,
        name: 'Coffee',
        enabled: true,
        containsText: 'coffee',
        type: TransactionType.expense,
        categoryId: categoryId,
        priority: 3,
      ),
    );
    await state.addRule(
      AutomationRule(
        id: 0,
        name: 'Generic expense',
        enabled: true,
        type: TransactionType.expense,
        priority: 1,
      ),
    );
    expect(state.rules.map((item) => item.priority), [3, 1]);

    final coffee = state.rules.firstWhere((item) => item.name == 'Coffee');
    await service.update(
      state,
      coffee.copyWith(name: 'Coffee disabled', enabled: false),
    );
    final disabled = state.rules.firstWhere((item) => item.id == coffee.id);
    expect(disabled.enabled, isFalse);
    expect(disabled.name, 'Coffee disabled');

    await service.duplicate(state, state.rules.last);
    expect(state.rules, hasLength(3));

    final reordered = [...state.rules.reversed];
    await service.reorder(state, reordered);
    expect(state.rules.first.id, reordered.first.id);

    await database.addTransaction(
      type: TransactionType.expense,
      amount: 4,
      accountId: accountId,
      date: DateTime.utc(2026, 9, 24),
      note: 'coffee',
    );
    await state.refreshCore();
    final enabledRule = state.rules.firstWhere((item) => item.enabled);
    expect(service.preview(state, enabledRule).count, greaterThanOrEqualTo(1));

    final beforeDelete = state.rules.length;
    await state.deleteRule(state.rules.last);
    expect(state.rules, hasLength(beforeDelete - 1));
  });
}
