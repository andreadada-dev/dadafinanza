import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_balance_analytics_charts.dart';
import 'package:balyn/widgets/home_dashboard_widget.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Income and expense share account palette instead of purple constants',
    () {
      const accountViolet = Color(0xFF7134D6);
      const accountOrange = Color(0xFFFF7C30);
      final violetIncome = balynAnalyticsIncomeColor(accountViolet);
      final violetExpense = balynAnalyticsExpenseColor(accountViolet);
      final orangeIncome = balynAnalyticsIncomeColor(accountOrange);
      final orangeExpense = balynAnalyticsExpenseColor(accountOrange);

      expect(violetIncome, isNot(violetExpense));
      expect(violetIncome, isNot(orangeIncome));
      expect(violetExpense, isNot(orangeExpense));
      expect(balynAnalyticsIncomeColor(null), const Color(0xFFD0A7F7));
      expect(balynAnalyticsExpenseColor(null), const Color(0xFF7522ED));
    },
  );

  testWidgets('Bar chart accepts the selected account color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BalynStatisticBars(
            points: [],
            hidden: false,
            accountColor: Color(0xFF7134D6),
          ),
        ),
      ),
    );
    expect(find.byType(BalynStatisticBars), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('One global analytics period controls trend bars and Home donut', () {
    final analytics = File(
      'lib/screens/account_context_analytics_screen.dart',
    ).readAsStringSync();
    final homeDonut = File(
      'lib/widgets/home_dashboard_widget.dart',
    ).readAsStringSync();

    final globalNavigator = analytics.indexOf(
      'child: _AnalyticsPeriodNavigator(',
    );
    final line = analytics.indexOf('child: _BalanceTrend(');
    final bars = analytics.indexOf('BalynStatisticBars(');
    final pie = analytics.indexOf('child: AccountCategoryCarousel(');

    expect(globalNavigator, greaterThan(0));
    expect(line, greaterThan(globalNavigator));
    expect(bars, greaterThan(line));
    expect(pie, greaterThan(bars));
    expect(analytics, contains('onPrevious: () => _shiftPeriod(-1)'));
    expect(analytics, contains('onNext: () => _shiftPeriod(1)'));
    expect(analytics, contains('periodLabel: _visibleRangeLabel(from, to)'));
    expect(analytics, contains('accountColor: effectiveAccountId == null'));
    expect(analytics, isNot(contains('BalynBalanceDonut(')));
    expect(homeDonut, contains('final DateTime? from;'));
    expect(homeDonut, contains('final DateTime? to;'));
    expect(homeDonut, contains('showPeriodControls: widget.from == null'));
    expect(homeDonut, contains('hideAmounts: hideAmounts'));
  });
}
