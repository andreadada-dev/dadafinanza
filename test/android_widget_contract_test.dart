import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Android manifest publishes all Balyn widget variants', () {
    final manifest = File('android/app/src/main/AndroidManifest.xml')
        .readAsStringSync();
    expect(manifest, contains('.BalynFinanceWidgetProvider'));
    expect(manifest, contains('.BalynBalanceWidgetProvider'));
    expect(manifest, contains('.BalynQuickAddWidgetProvider'));
    expect(manifest, contains('@xml/balyn_finance_widget_info'));
    expect(manifest, contains('@xml/balyn_balance_widget_info'));
    expect(manifest, contains('@xml/balyn_quick_add_widget_info'));
  });

  test('Android widgets declare distinct target home-screen sizes', () {
    final balance = File(
      'android/app/src/main/res/xml/balyn_balance_widget_info.xml',
    ).readAsStringSync();
    final quick = File(
      'android/app/src/main/res/xml/balyn_quick_add_widget_info.xml',
    ).readAsStringSync();
    final summary = File(
      'android/app/src/main/res/xml/balyn_finance_widget_info.xml',
    ).readAsStringSync();

    expect(balance, contains('android:targetCellWidth="2"'));
    expect(balance, contains('android:targetCellHeight="1"'));
    expect(quick, contains('android:targetCellWidth="2"'));
    expect(quick, contains('android:targetCellHeight="2"'));
    expect(summary, contains('android:targetCellWidth="4"'));
    expect(summary, contains('android:targetCellHeight="2"'));
  });

  test('Android widgets use the configured app currency', () {
    final provider = File(
      'android/app/src/main/kotlin/com/andreadada/balyn/BalynFinanceWidgetProvider.kt',
    ).readAsStringSync();
    final widgetService = File('lib/services/widget_service.dart')
        .readAsStringSync();
    final balanceLayout = File(
      'android/app/src/main/res/layout/balyn_balance_widget.xml',
    ).readAsStringSync();
    final summaryLayout = File(
      'android/app/src/main/res/layout/balyn_finance_widget.xml',
    ).readAsStringSync();

    expect(widgetService, contains("'currency', currency"));
    expect(provider, contains('getString("currency", "EUR")'));
    expect(provider, contains('fun moneyLabel'));
    expect(balanceLayout, isNot(contains('0,00 €')));
    expect(summaryLayout, isNot(contains('0,00 €')));
  });
}
