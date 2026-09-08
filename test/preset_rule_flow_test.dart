import 'dart:io';

import 'package:dadafinanza/core/money.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/services/finance_schema_service.dart';
import 'package:dadafinanza/services/quick_preset_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;

void main() {
  late Directory databaseRoot;

  setUpAll(() async {
    ffi.sqfliteFfiInit();
    databaseFactory = ffi.databaseFactoryFfi;
    databaseRoot = await Directory.systemTemp.createTemp(
      'dadafinanza-preset-rule-db-',
    );
    await databaseFactory.setDatabasesPath(databaseRoot.path);
  });

  tearDownAll(() async {
    if (await databaseRoot.exists()) {
      await databaseRoot.delete(recursive: true);
    }
  });

  test('preset note and tags reach automation rules on save', () async {
    final root = await getDatabasesPath();
    await databaseFactory.deleteDatabase(p.join(root, 'dadafinanza.db'));

    final database = AppDatabase();
    await database.init();
    await FinanceSchemaService(database).ensure();
    addTearDown(() async {
      if (database.db.isOpen) await database.db.close();
    });

    final accountId = await database.addAccount(
      name: 'Revolut',
      balance: 20,
      colorValue: 0xFF8E8E93,
      iconKey: 'wallet',
      type: AccountType.bank,
      includeInTotal: true,
      includeInAnalytics: true,
      hideBalance: false,
    );

    await database.db.insert('automation_rules', {
      'name': 'Monster tag',
      'enabled': 1,
      'contains_text': 'Monster',
      'type': TransactionType.expense.dbValue,
      'min_amount': null,
      'max_amount': null,
      'min_amount_cents': null,
      'max_amount_cents': null,
      'category_id': null,
      'account_id': null,
      'add_tag': 'energy-drink',
      'include_in_analytics': null,
      'priority': 10,
    });

    final presets = QuickPresetService(database);
    await presets.save(
      name: 'Monster',
      type: TransactionType.expense,
      accountId: accountId,
      amount: 2.5,
      note: 'Monster',
      tags: const ['bevanda'],
    );

    final preset = (await presets.all()).single;
    final draft = preset.toTransactionDraft();

    expect(draft.note, 'Monster');
    expect(draft.tags, ['bevanda']);
    expect(draft.accountId, accountId);
    expect(draft.amountCents, 250);

    await database.addTransaction(
      type: draft.type,
      amount: Money.fromCents(draft.amountCents!),
      accountId: draft.accountId!,
      toAccountId: draft.toAccountId,
      categoryId: draft.categoryId,
      date: DateTime.utc(2026, 9, 8, 12),
      note: draft.note,
      tags: draft.tags,
    );

    final saved = (await database.transactions()).single;
    expect(saved.note, 'Monster');
    expect(saved.tags, containsAll(['bevanda', 'energy-drink']));
  });
}
