import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/models/models.dart';
import 'package:balyn/theme/app_theme.dart';
import 'package:balyn/widgets/ui_helpers.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final source = File(
    'lib/widgets/balyn_transaction_detail_content.dart',
  ).readAsStringSync();

  test('Detail uses whitespace rather than horizontal separators', () {
    expect(source, isNot(contains('Divider(')));
    expect(source, isNot(contains('UnderlineInputBorder(')));
    expect(source, isNot(contains('Border(bottom:')));
    expect(source, contains('child: Column(children: children)'));
    expect(source, contains('enabledBorder: InputBorder.none'));
    expect(source, contains('focusedBorder: InputBorder.none'));
  });

  test('Account/category/type use semantic or persisted colors', () {
    expect(source, contains('valueColor: transactionColor(context, _type)'));
    expect(source, contains('Color(account.colorValue)'));
    expect(source, contains('Color(target.colorValue)'));
    expect(source, contains('Color(category.colorValue)'));
    expect(source, contains('BalynShaderInk('));
  });

  test('Amount is larger and edit icon follows the measured value', () {
    expect(source, contains('fontSize: 35'));
    expect(source, contains('valueListenable: _amount'));
    expect(source, contains('TextPainter('));
    expect(source, contains('width: fieldWidth'));
    expect(source, contains("ValueKey('detail-amount-pencil')"));
    expect(source, isNot(contains('border: Border(\n                            bottom:')));
  });

  testWidgets('Semantic transaction colors distinguish income and expense', (
    tester,
  ) async {
    late Color expense;
    late Color income;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        home: Builder(
          builder: (context) {
            expense = transactionColor(context, TransactionType.expense);
            income = transactionColor(context, TransactionType.income);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(expense, const Color(0xFFFF7373));
    expect(income, const Color(0xFF38E0A8));
  });
}
