import 'dart:io';

import 'package:balyn/models/models.dart';
import 'package:balyn/widgets/balyn_home_widget_catalog.dart';
import 'package:flutter_test/flutter_test.dart';

DashboardWidgetConfig widget(
  DashboardWidgetType type, {
  bool enabled = true,
  int order = 0,
}) => DashboardWidgetConfig(
  type: type,
  enabled: enabled,
  orderIndex: order,
  size: DashboardWidgetSize.medium,
);

void main() {
  test('New redesigned sections are configurable with one unique ID each', () {
    final layout = BalynHomeWidgetCatalog.normalize(const []);
    final types = layout.map((item) => item.type).toList();
    expect(types.toSet().length, types.length);
    expect(types.toSet(), containsAll(DashboardWidgetType.values));
    expect(
      types,
      containsAll(BalynHomeWidgetCatalog.featured),
    );
    for (final type in BalynHomeWidgetCatalog.featured) {
      expect(layout.firstWhere((item) => item.type == type).enabled, isTrue);
    }
  });

  test('Legacy layout retains previous order while adding new sections', () {
    final result = BalynHomeWidgetCatalog.normalize([
      widget(DashboardWidgetType.accounts, order: 1),
      widget(DashboardWidgetType.goals, order: 0),
      widget(DashboardWidgetType.accounts, order: 2),
    ]);
    expect(
      result.where((item) => item.type == DashboardWidgetType.accounts),
      hasLength(1),
    );
    final goalsIndex = result.indexWhere(
      (item) => item.type == DashboardWidgetType.goals,
    );
    final accountsIndex = result.indexWhere(
      (item) => item.type == DashboardWidgetType.accounts,
    );
    expect(goalsIndex, lessThan(accountsIndex));
    expect(result.map((item) => item.orderIndex),
        orderedEquals(List.generate(result.length, (i) => i)));
  });

  test('Explicitly hidden widget remains hidden through normalization', () {
    final result = BalynHomeWidgetCatalog.normalize([
      widget(DashboardWidgetType.monthlyOverview, enabled: false),
    ]);
    expect(
      result.firstWhere(
        (item) => item.type == DashboardWidgetType.monthlyOverview,
      ).enabled,
      isFalse,
    );
  });

  test('Accounts never appear twice inside the summary and standalone', () {
    expect(
      BalynHomeWidgetCatalog.showAccountsInsideSnapshot([
        widget(DashboardWidgetType.financialSnapshot),
        widget(DashboardWidgetType.accounts),
      ]),
      isFalse,
    );
    expect(
      BalynHomeWidgetCatalog.showAccountsInsideSnapshot([
        widget(DashboardWidgetType.financialSnapshot),
        widget(DashboardWidgetType.accounts, enabled: false),
      ]),
      isTrue,
    );
  });

  test('Settings offer drag handle, add, previews and persistence', () {
    final settings = File('lib/screens/settings_screen.dart').readAsStringSync();
    final home = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();
    final widgetSource =
        File('lib/widgets/home_dashboard_widget.dart').readAsStringSync();
    expect(settings, contains('ReorderableListView.builder('));
    expect(settings, contains('ReorderableDragStartListener('));
    expect(settings, contains('oldIndex < newIndex'));
    expect(settings, contains('AnimatedSize('));
    expect(settings, contains('HomeDashboardWidget('));
    expect(settings, contains('Ignored'), isFalse);
    expect(settings, contains('IgnorePointer('));
    expect(settings, contains("ValueKey('add-home-widget')"));
    expect(settings, contains('state.saveDashboard(normalized)'));
    expect(home, contains('BalynHomeWidgetCatalog.normalize('));
    expect(home, contains('HomeDashboardWidget('));
    expect(widgetSource, contains('BalynRecentTransactionsCard('));
    expect(widgetSource, contains('BalynRevolutHomeContent('));
  });
}
