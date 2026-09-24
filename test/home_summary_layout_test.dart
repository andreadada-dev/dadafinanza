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
    expect(source, contains('DashboardWidgetType.monthlyIncome'));
    expect(source, contains('DashboardWidgetType.monthlyExpense'));
  });

  test('Personalizza Home keeps secondary widgets configurable', () {
    final source = File('lib/screens/settings_screen.dart').readAsStringSync();

    expect(source, contains("title: const Text('Personalizza Home')"));
    expect(source, contains('ReorderableListView.builder'));
    expect(source, contains('_fixedSummaryTypes.contains(item.type)'));
    expect(source, contains('await state.saveDashboard(normalized)'));
  });

  test('category chart is clearly exposed in Personalizza Home', () {
    final settings = File(
      'lib/screens/settings_screen.dart',
    ).readAsStringSync();
    final models = File('lib/models/models.dart').readAsStringSync();

    expect(
      models,
      contains("DashboardWidgetType.topCategories => 'Grafico categorie'"),
    );
    expect(
      settings,
      contains(
        'Torta Spese/Entrate con periodo scorrevole e intervallo personalizzato.',
      ),
    );
  });

  test('category carousel drags fluidly and commits data after release', () {
    final source = File(
      'lib/widgets/home_dashboard_widget.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('_CategoryChartControls')));
    expect(source, contains('PageView.builder'));
    expect(source, contains('NotificationListener<ScrollNotification>'));
    expect(source, contains('notification is ScrollEndNotification'));
    expect(source, contains('_commitCarouselPage()'));
    expect(source, contains('class _SwipeHintChevron'));
    expect(source, contains('repeat(reverse: true)'));
    expect(source, contains('class _DonutPeriodCenter'));
    expect(source, contains('totalLabel'));
  });

  test('dashboard seeding backfills missing widget types', () {
    final database = File('lib/data/app_database.dart').readAsStringSync();

    expect(database, contains("columns: ['type', 'order_index']"));
    expect(database, contains('existingTypes.contains(type.name)'));
    expect(database, contains('isFreshDashboard && defaultOrder >= 0'));
  });

  test('selected account Home starts with its category carousel', () {
    final home = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();
    final widget = File(
      'lib/widgets/home_dashboard_widget.dart',
    ).readAsStringSync();

    final accountCarousel = home.indexOf(
      'AccountCategoryCarousel(accountId: selectedAccount!.id)',
    );
    final quickActions = home.indexOf('_QuickActions(', accountCarousel + 1);

    expect(accountCarousel, greaterThanOrEqualTo(0));
    expect(quickActions, greaterThan(accountCarousel));
    expect(widget, contains('class AccountCategoryCarousel'));
    expect(widget, contains('widget.accountId'));
    expect(widget, contains('AccountContextService.periodTotal'));
  });

  test('selected account summary links to account analytics without repeating its name', () {
    final source = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'Analytics del conto'"));
    expect(source, contains("'Entrate, spese e andamento del conto'"));
    expect(source, contains('AccountContextAnalyticsScreen('));
    expect(source, contains('onTap: onOpenAnalytics'));
  });
}
