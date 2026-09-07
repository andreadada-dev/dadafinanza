import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('total Home keeps the original summary above quick actions', () {
    final source = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();

    final summary = source.indexOf('_TotalOverviewSummary(');
    final quickActions = source.indexOf('_QuickActions(', summary + 1);
    expect(summary, greaterThanOrEqualTo(0));
    expect(quickActions, greaterThan(summary));
    expect(source, contains("Text('PATRIMONIO'"));
    expect(source, contains("label: 'Entrate'"));
    expect(source, contains("label: 'Spese'"));
    expect(source, contains("label: 'Disponibile'"));
  });

  test('fixed summary metrics are not duplicated by personalized sections', () {
    final source = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();

    expect(source, contains('secondaryDashboardWidgets'));
    expect(source, contains('_fixedSummaryTypes.contains(config.type)'));
  });

  test('Personalizza Home keeps secondary widgets configurable', () {
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();

    expect(source, contains("title: const Text('Personalizza Home')"));
    expect(source, contains('ReorderableListView.builder'));
    expect(source, contains('_fixedSummaryTypes.contains(item.type)'));
    expect(source, contains('await state.saveDashboard(normalized)'));
  });
}
