import 'dart:io';

import 'package:dadafinanza/app_state.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/models/models.dart';
import 'package:dadafinanza/services/attachment_service.dart';
import 'package:dadafinanza/services/backup_service.dart';
import 'package:dadafinanza/services/data_integrity_service.dart';
import 'package:dadafinanza/services/finance_schema_service.dart';
import 'package:dadafinanza/services/widget_service.dart';
import 'package:dadafinanza/services/quick_preset_service.dart';
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
      'dadafinanza-integrity-db-',
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

  test('history rule application rolls back atomically', () async {
    final database = await openReadyDatabase();
    final source = await addAccount(database, 'Source', balance: 100);
    final destination = await addAccount(database, 'Destination', balance: 0);
    await database.addTransaction(
      type: TransactionType.expense,
      amount: 10,
      accountId: source,
      date: DateTime.utc(2026, 9, 23),
      note: 'first',
    );
    await database.addTransaction(
      type: TransactionType.transfer,
      amount: 20,
      accountId: source,
      toAccountId: destination,
      date: DateTime.utc(2026, 9, 24),
      note: 'second',
    );
    final items = await database.transactions();
    final expense = items.firstWhere((item) => item.note == 'first');
    final transfer = items.firstWhere((item) => item.note == 'second');
    final rule = AutomationRule(
      id: 0,
      name: 'Move source',
      enabled: true,
      accountId: destination,
      priority: 10,
    );

    await expectLater(
      database.applyRuleToHistory(rule, [expense, transfer]),
      throwsStateError,
    );

    final after = await database.transactions();
    expect(after.firstWhere((item) => item.note == 'first').accountId, source);
    expect(after.firstWhere((item) => item.note == 'second').accountId, source);
    final accounts = await database.accounts();
    expect(
      accounts.firstWhere((item) => item.id == source).balance,
      closeTo(70, 0.001),
    );
    expect(
      accounts.firstWhere((item) => item.id == destination).balance,
      closeTo(20, 0.001),
    );
  });

  test('category merge preserves split and preset references', () async {
    final database = await openReadyDatabase();
    final accountId = await addAccount(database, 'Main');
    final sourceId = await database.addCategory(
      name: 'Old',
      type: TransactionType.expense,
      iconKey: 'category',
      colorValue: 0xFF8E8E93,
    );
    final destinationId = await database.addCategory(
      name: 'New',
      type: TransactionType.expense,
      iconKey: 'category',
      colorValue: 0xFF8E8E93,
    );
    final transactionId = await database.addTransaction(
      type: TransactionType.expense,
      amount: 10,
      accountId: accountId,
      categoryId: sourceId,
      date: DateTime.utc(2026, 9, 24),
    );
    await database.replaceSplits(transactionId, [
      TransactionSplit(
        id: 0,
        transactionId: transactionId,
        amount: 10,
        categoryId: sourceId,
      ),
    ], 10);
    await QuickPresetService(database).save(
      name: 'Preset',
      type: TransactionType.expense,
      accountId: accountId,
      categoryId: sourceId,
    );
    final state = AppState(database, widgetService: _NoopWidgetService());
    await state.load();

    await DataIntegrityService.mergeCategories(
      state,
      source: state.categoryById(sourceId)!,
      destination: state.categoryById(destinationId)!,
    );

    expect((await database.splits()).single.categoryId, destinationId);
    expect(
      (await QuickPresetService(database).all()).single.categoryId,
      destinationId,
    );
    expect(state.categoryById(sourceId), isNull);
  });

  test('category delete refuses to discard split classification', () async {
    final database = await openReadyDatabase();
    final accountId = await addAccount(database, 'Main');
    final categoryId = await database.addCategory(
      name: 'Split category',
      type: TransactionType.expense,
      iconKey: 'category',
      colorValue: 0xFF8E8E93,
    );
    final transactionId = await database.addTransaction(
      type: TransactionType.expense,
      amount: 10,
      accountId: accountId,
      date: DateTime.utc(2026, 9, 24),
    );
    await database.replaceSplits(transactionId, [
      TransactionSplit(
        id: 0,
        transactionId: transactionId,
        amount: 10,
        categoryId: categoryId,
      ),
    ], 10);

    await expectLater(database.deleteCategory(categoryId), throwsStateError);
    expect(
      (await database.categories()).any((item) => item.id == categoryId),
      isTrue,
    );
  });

  test('empty account deletion clears preset references', () async {
    final database = await openReadyDatabase();
    final accountId = await addAccount(database, 'Disposable');
    await QuickPresetService(
      database,
    ).save(name: 'Preset', type: TransactionType.expense, accountId: accountId);
    final state = AppState(database, widgetService: _NoopWidgetService());
    await state.load();

    await DataIntegrityService.deleteEmptyAccount(
      state,
      state.accountById(accountId)!,
    );

    expect(state.accountById(accountId), isNull);
    expect((await QuickPresetService(database).all()).single.accountId, isNull);
  });

  test(
    'backup removes orphan attachments and keeps referenced receipt',
    () async {
      final database = await openReadyDatabase();
      final accountId = await addAccount(database, 'Main');
      await database.addTransaction(
        type: TransactionType.expense,
        amount: 5,
        accountId: accountId,
        date: DateTime.utc(2026, 9, 24),
        receiptPath: 'keep.jpg',
      );

      final supportRoot = await Directory.systemTemp.createTemp(
        'dada-attachments-test-',
      );
      final backupRoot = await Directory.systemTemp.createTemp(
        'dada-backup-test-',
      );
      addTearDown(() async {
        if (await supportRoot.exists()) {
          await supportRoot.delete(recursive: true);
        }
        if (await backupRoot.exists()) {
          await backupRoot.delete(recursive: true);
        }
      });

      final attachments = AttachmentService(rootDirectory: supportRoot);
      final dir = await attachments.directory();
      await File(p.join(dir.path, 'keep.jpg')).writeAsBytes([1, 2, 3]);
      await File(p.join(dir.path, 'orphan.jpg')).writeAsBytes([4, 5, 6]);

      final service = BackupService(
        database,
        attachments: attachments,
        temporaryDirectory: () async => backupRoot,
      );
      final backup = await service.create();
      final preview = await service.inspect(backup.path);

      expect(preview.attachments, 1);
      expect(await File(p.join(dir.path, 'keep.jpg')).exists(), isTrue);
      expect(await File(p.join(dir.path, 'orphan.jpg')).exists(), isFalse);
    },
  );

  test('deleting a movement removes its orphaned receipt file', () async {
    final database = await openReadyDatabase();
    final accountId = await addAccount(database, 'Main');
    await database.addTransaction(
      type: TransactionType.expense,
      amount: 7,
      accountId: accountId,
      date: DateTime.utc(2026, 9, 24),
      receiptPath: 'receipt.jpg',
    );

    final supportRoot = await Directory.systemTemp.createTemp(
      'dada-delete-receipt-test-',
    );
    addTearDown(() async {
      if (await supportRoot.exists()) {
        await supportRoot.delete(recursive: true);
      }
    });
    final attachments = AttachmentService(rootDirectory: supportRoot);
    final dir = await attachments.directory();
    final receipt = File(p.join(dir.path, 'receipt.jpg'));
    await receipt.writeAsBytes([1, 2, 3]);

    final state = AppState(
      database,
      widgetService: _NoopWidgetService(),
      attachmentService: attachments,
    );
    await state.load();
    await state.deleteTransaction(state.transactions.single);

    expect(await receipt.exists(), isFalse);
  });

  test('clear all user data clears managed attachments too', () async {
    final database = await openReadyDatabase();
    final supportRoot = await Directory.systemTemp.createTemp(
      'dada-clear-attachments-test-',
    );
    addTearDown(() async {
      if (await supportRoot.exists()) {
        await supportRoot.delete(recursive: true);
      }
    });
    final attachments = AttachmentService(rootDirectory: supportRoot);
    final dir = await attachments.directory();
    await File(p.join(dir.path, 'orphan.jpg')).writeAsBytes([1]);

    final state = AppState(database, widgetService: _NoopWidgetService(), attachmentService: attachments);
    await state.load();
    await state.clearAllUserData();

    expect(await attachments.all(), isEmpty);
  });
}
