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

  test('selected account Home mirrors the main summary hierarchy', () {
    final home = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();
    final widget = File(
      'lib/widgets/home_dashboard_widget.dart',
    ).readAsStringSync();

    final summary = home.indexOf('_SelectedAccountSummary(');
    final quickActions = home.indexOf('_QuickActions(', summary + 1);
    final accountCarousel = home.indexOf(
      'AccountCategoryCarousel(accountId: selectedAccount!.id)',
      quickActions + 1,
    );
    final openAccount = home.indexOf("'Apri conto'", accountCarousel + 1);
    final analytics = home.indexOf("'Analytics del conto'", openAccount + 1);

    expect(summary, greaterThanOrEqualTo(0));
    expect(quickActions, greaterThan(summary));
    expect(accountCarousel, greaterThan(quickActions));
    expect(openAccount, greaterThan(accountCarousel));
    expect(analytics, greaterThan(openAccount));
    expect(widget, contains('class AccountCategoryCarousel'));
    expect(widget, contains('widget.accountId'));
    expect(widget, contains('AccountContextService.periodTotal'));
  });

  test('selected account exposes account settings before account analytics', () {
    final source = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();

    expect(source, contains("'Apri conto'"));
    expect(source, contains('accountIcon(selectedAccount.iconKey)'));
    expect(source, contains('SafeAccountDetailScreen('));
    expect(source, contains("'Analytics del conto'"));
    expect(source, contains("'Entrate, spese e andamento del conto'"));
    expect(source, contains('AccountContextAnalyticsScreen('));
  });

  test('account management is settings-first and trend lives in analytics', () {
    final account = File(
      'lib/screens/account_management_screen.dart',
    ).readAsStringSync();
    final analytics = File(
      'lib/screens/account_context_analytics_screen.dart',
    ).readAsStringSync();

    expect(account, contains("'Impostazioni conto'"));
    expect(account, contains("'Nome, icona e nota'"));
    expect(account, contains("'Colore'"));
    expect(account, contains('accountIconOptions'));
    expect(account, contains('SwitchListTile('));
    expect(account, isNot(contains("tooltip: 'Azioni conto'")));
    expect(account, isNot(contains('class _AccountTrend')));

    expect(analytics, contains("'Andamento saldo'"));
    expect(analytics, contains("'Andamento patrimonio'"));
    expect(analytics, contains('class _BalanceTrend'));
    expect(analytics, contains('LineChart('));
    expect(analytics, contains('LineTouchTooltipData('));
    expect(analytics, contains('surfaceContainerHighest'));
  });

  test('analytics periods all fit on screen and Custom stays Custom', () {
    final analytics = File(
      'lib/screens/account_context_analytics_screen.dart',
    ).readAsStringSync();

    expect(analytics, contains('class _PeriodPill'));
    expect(analytics, isNot(contains('SegmentedButton<_AnalyticsPeriod>')));
    expect(
      analytics,
      isNot(contains('scrollDirection: Axis.horizontal')),
    );
    expect(analytics, contains("_AnalyticsPeriod.today => 'Oggi'"));
    expect(analytics, contains("_AnalyticsPeriod.week => 'Settimana'"));
    expect(analytics, contains("_AnalyticsPeriod.month => 'Mese'"));
    expect(analytics, contains("_AnalyticsPeriod.year => 'Anno'"));
    expect(analytics, contains("_AnalyticsPeriod.custom => 'Custom'"));
    expect(analytics, contains('Expanded('));
    expect(analytics, contains('showDateRangePicker('));
    expect(analytics, contains('onTap: () => _selectPeriod(item)'));
  });

  test('analytics trend has date axis labels for total and account views', () {
    final analytics = File(
      'lib/screens/account_context_analytics_screen.dart',
    ).readAsStringSync();

    expect(analytics, contains('bottomTitles: AxisTitles('));
    expect(
      analytics,
      contains("_AnalyticsPeriod.week => sameMonth"),
    );
    expect(analytics, contains("DateFormat('EEE dd'"));
    expect(analytics, contains("_AnalyticsPeriod.year => DateFormat('MMM'"));
    expect(
      analytics,
      contains('account: effectiveAccountId == null ? null : selected'),
    );
    expect(analytics, contains('!item.isArchived'));
    expect(analytics, contains('item.includeInTotal'));
  });

  test('analytics chart supports hourly Today and clean selectable scales', () {
    final analytics = File(
      'lib/screens/account_context_analytics_screen.dart',
    ).readAsStringSync();

    expect(analytics, contains("import 'dart:math' as math;"));
    expect(analytics, contains('movementHours'));
    expect(analytics, contains('minutes / 60'));
    expect(analytics, contains('chartMaxX = isToday'));
    expect(analytics, contains('isCurved: false'));
    expect(analytics, contains('leftTitles: AxisTitles('));
    expect(analytics, contains('reservedSize: 44'));
    expect(analytics, contains('interval: yInterval'));
    expect(analytics, contains('minIncluded: true'));
    expect(analytics, contains('maxIncluded: true'));
    expect(analytics, contains('spots.length == 1 || selectedSpot != null'));
    expect(analytics, contains("'Saldo alle "));
    expect(analytics, contains("'Saldo finale "));
    expect(analytics, contains('touchCallback: (event, response)'));
    expect(analytics, contains('VerticalLine('));
    expect(analytics, contains('onPointerDown: (event)'));
    expect(analytics, contains('onPointerUp: (event)'));
    expect(analytics, contains('widget.onShiftPeriod(deltaX < 0 ? 1 : -1)'));
    expect(analytics, contains('periodOffset += delta'));
  });

  test('shared user palette offers many muted colors everywhere', () {
    final helpers = File('lib/widgets/ui_helpers.dart').readAsStringSync();
    final paletteStart = helpers.indexOf('const categoryPalette = <Color>[');
    final paletteEnd = helpers.indexOf('];', paletteStart);
    expect(paletteStart, greaterThanOrEqualTo(0));
    expect(paletteEnd, greaterThan(paletteStart));

    final paletteSource = helpers.substring(paletteStart, paletteEnd);
    final colorCount = RegExp(
      r'Color\(0xFF[0-9A-F]{6}\)',
    ).allMatches(paletteSource).length;
    expect(colorCount, greaterThanOrEqualTo(40));

    for (final path in const [
      'lib/screens/account_screens.dart',
      'lib/screens/account_management_screen.dart',
      'lib/screens/category_management_screen.dart',
      'lib/screens/advances_screen.dart',
      'lib/screens/planning_screens.dart',
    ]) {
      expect(
        File(path).readAsStringSync(),
        contains('categoryPalette'),
        reason: '$path deve usare la palette condivisa',
      );
    }
  });

  test('category donut always offers Today and renders an empty ring', () {
    final source = File(
      'lib/widgets/home_dashboard_widget.dart',
    ).readAsStringSync();

    expect(source, contains('var _range = _CategoryChartRange.today;'));
    expect(source, contains('static const _cycleRanges'));
    expect(source, contains('_CategoryChartRange.today,'));
    expect(source, contains('_CategoryChartRange.thisWeek,'));
    expect(source, contains('_CategoryChartRange.thisMonth,'));
    expect(source, contains('_CategoryChartRange.thisYear,'));
    expect(source, contains('onRangeTap: _cycleRange'));
    expect(source, contains('onRangeLongPress: _selectCustomRange'));
    expect(source, contains('_stepPeriod(-1)'));
    expect(source, contains('_stepPeriod(1)'));
    expect(source, isNot(contains('_hasTodayData')));
    expect(source, contains('emptyRingColor'));
    expect(source, contains('centerSpaceColor: Theme.of(context).scaffoldBackgroundColor'));
    expect(source, contains('value: 1'));
  });
}
