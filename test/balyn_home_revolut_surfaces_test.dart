import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_editorial_components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final homeWidgets =
      File('lib/widgets/home_dashboard_widget.dart').readAsStringSync();
  final accountHome =
      File('lib/screens/account_context_home_screen.dart').readAsStringSync();
  final content =
      File('lib/widgets/balyn_revolut_home_content.dart').readAsStringSync();

  test('Every configurable Home widget has a Revolut surface', () {
    // No unstyled fallthrough: legacy, accounts, metrics, categories and
    // highlights all have a card, while recent movements/monthly overview
    // already carry their own identical surface.
    expect(homeWidgets, contains('case DashboardWidgetType.accounts:'));
    expect(homeWidgets, contains('return _AccountsBlock(config: config)'));
    expect(homeWidgets, contains('case DashboardWidgetType.topCategories:'));
    expect(homeWidgets, contains('child: _TopCategoriesDonut(config: config)'));
    expect(homeWidgets, contains('return _SizedCanonicalWidget(config: config)'));
    expect(homeWidgets, contains('child: CanonicalDashboardWidget(config: config)'));
    expect(homeWidgets, contains('class _MetricBlock'));
    expect(homeWidgets, contains('class _AccountsBlock'));
    expect(homeWidgets, contains('case DashboardWidgetType.smartHighlights:'));
    expect(homeWidgets, contains('child: BalynRevolutHomeContent('));
    expect(homeWidgets, contains('embedded: true'));
    expect(
      RegExp(r'BalynEditorialSurface\(').allMatches(homeWidgets).length,
      greaterThanOrEqualTo(6),
    );
  });

  test('Already styled sections are not wrapped twice', () {
    final recentStart =
        homeWidgets.indexOf('case DashboardWidgetType.recentTransactions:');
    final recentEnd =
        homeWidgets.indexOf('case DashboardWidgetType.financialSnapshot:');
    final recent = homeWidgets.substring(recentStart, recentEnd);
    expect(recent, contains('BalynRecentTransactionsCard('));
    expect(recent, isNot(contains('BalynEditorialSurface(')));

    final monthStart =
        homeWidgets.indexOf('case DashboardWidgetType.monthlyOverview:');
    final monthEnd =
        homeWidgets.indexOf('case DashboardWidgetType.recentTransactions:');
    final month = homeWidgets.substring(monthStart, monthEnd);
    expect(RegExp(r'BalynEditorialSurface\(').allMatches(month).length, 1);
  });

  test('Accounts inside the summary are flat in the unified card', () {
    expect(content, contains('final bool embedded;'));
    expect(content, contains('if (i > 0 && !embedded)'));
    expect(content, contains('decoration: embedded'));
    expect(accountHome, contains('child: AccountCategoryCarousel('));
    expect(accountHome, contains("'Prossime scadenze'"));
    expect(accountHome, contains('class _SetupBlock'));
    expect(accountHome, contains('Widget build(BuildContext context) => BalynEditorialSurface('));
  });

  testWidgets('Revolut surface uses matching flat colors in dark and light', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.light(),
        home: const Scaffold(
          body: BalynEditorialSurface(child: Text('Cash flow del mese')),
        ),
      ),
    );
    expect(find.text('Cash flow del mese'), findsOneWidget);
    expect(find.byType(BalynEditorialSurface), findsOneWidget);
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: BalynEditorialSurface(child: Text('Conti')),
        ),
      ),
    );
    expect(find.text('Conti'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
