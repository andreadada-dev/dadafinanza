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

  testWidgets('swiping left reveals but does not automatically delete', (
    tester,
  ) async {
    final now = DateTime(2026, 10, 18);
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
    final xBefore = tester.getTopLeft(row).dx;
    await tester.drag(row, const Offset(-110, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(row).dx, lessThan(xBefore));
    expect(find.byKey(const ValueKey('swipe-delete-40')), findsOneWidget);
    await tester.drag(row, const Offset(110, 0));
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(row).dx, closeTo(xBefore, 1.0));
  });
}
