import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/models/models.dart';
import 'package:balyn/widgets/balyn_swipe_delete_tile.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all main transaction lists use the shared swipe delete gesture', () {
    final files = [
      'lib/screens/transaction_screens.dart',
      'lib/screens/account_context_transactions_screen.dart',
      'lib/widgets/balyn_recent_transactions_card.dart',
    ];
    for (final file in files) {
      final source = File(file).readAsStringSync();
      expect(source, contains('BalynSwipeDeleteTile('), reason: file);
    }
    final gesture = File(
      'lib/widgets/balyn_swipe_delete_tile.dart',
    ).readAsStringSync();
    expect(gesture, contains('confirmDestructiveAction('));
    expect(gesture, contains('isAdvanceProtectedTransaction('));
    expect(gesture, contains('await state.deleteTransaction(current)'));
  });

  testWidgets('idle row hides both actions; swipe reveals two compact icons', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 18);
    var edited = 0;
    final transaction = FinanceTransaction(
      id: 40,
      type: TransactionType.expense,
      amount: 12.50,
      accountId: 1,
      date: now,
      includeInAnalytics: true,
      createdAt: now,
      updatedAt: now,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: BalynSwipeDeleteTile(
                item: transaction,
                onEdit: () => edited++,
                child: const SizedBox(
                  key: ValueKey('row-content'),
                  height: 68,
                  child: Center(child: Text('Movimento')),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    final row = find.byKey(const ValueKey('row-content'));
    final delete = find.byKey(const ValueKey('swipe-delete-40'));
    final edit = find.byKey(const ValueKey('swipe-edit-40'));
    final initialWidth = tester.getSize(row).width;
    expect(delete, findsNothing);
    expect(edit, findsNothing);
    expect(initialWidth, closeTo(360, 1));

    await tester.drag(row, const Offset(-110, 0));
    await tester.pumpAndSettle();

    expect(delete, findsOneWidget);
    expect(edit, findsOneWidget);
    expect(tester.getSize(row).width, lessThan(initialWidth));
    expect(tester.getSize(edit).width, lessThanOrEqualTo(40));
    expect(tester.getSize(delete).width, lessThanOrEqualTo(40));

    await tester.tap(edit);
    await tester.pumpAndSettle();
    expect(edited, 1);
    expect(delete, findsNothing);
    expect(edit, findsNothing);
    expect(tester.getSize(row).width, closeTo(initialWidth, 1));

    await tester.drag(row, const Offset(-110, 0));
    await tester.pumpAndSettle();
    expect(delete, findsOneWidget);

    // Swiping back closes the rail without deleting the transaction.
    await tester.drag(row, const Offset(110, 0));
    await tester.pumpAndSettle();
    expect(delete, findsNothing);
    expect(edit, findsNothing);
    expect(tester.getSize(row).width, closeTo(initialWidth, 1));
    expect(tester.takeException(), isNull);
  });

  test('delete buttons are not part of the idle render tree', () {
    final source = File(
      'lib/widgets/balyn_swipe_delete_tile.dart',
    ).readAsStringSync();
    expect(source, contains('_reveal < .5'));
    expect(source, contains('Icons.edit_rounded'));
    expect(source, contains('Icons.delete_outline_rounded'));
    expect(source, contains('await confirmDestructiveAction('));
    expect(source, contains('OverflowBox('));
    expect(source, contains('Expanded(child: widget.child)'));
  });
}
