import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_cue_section_bar.dart';
import 'package:balyn/widgets/balyn_quick_action_launcher.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:pie_menu/pie_menu.dart';
import 'package:material_ui/material_ui.dart' as mui;

void main() {
  test('Home segments are in-place, directional, and account-aware', () {
    final home = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();
    final hero = File(
      'lib/widgets/balyn_revolut_home_hero.dart',
    ).readAsStringSync();
    final selector = File(
      'lib/widgets/balyn_cue_section_bar.dart',
    ).readAsStringSync();
    final shell = File('lib/screens/app_shell.dart').readAsStringSync();

    expect(home, contains('NestedScrollView('));
    expect(home, contains('body: PageView('));
    expect(home, contains('controller: _pageController'));
    expect(home, contains('onPageChanged: _onHomePageChanged'));
    expect(home, contains('onTabChanged: _selectHomePage'));
    expect(home, contains('AccountContextTransactionsScreen('));
    expect(home, contains('AccountContextAnalyticsScreen('));
    expect(home, contains('embedded: true'));
    expect(home, contains('onManageAccounts: () => Navigator.push('));
    expect(home, contains('onAccountChanged: onAccountChanged'));
    expect(home, isNot(contains('home-accounts-scroll')));
    expect(home, contains('sectionPage: _pageController.hasClients'));
    expect(hero, contains('BalynCueSectionBar('));
    expect(hero, contains('BalynCueThreeDotsAction('));
    expect(home, contains('onCustomizeHome: () => Navigator.push('));
    expect(selector, contains("'Panoramica'"));
    expect(selector, contains("'Movimenti'"));
    expect(selector, isNot(contains("'Conti'")));
    expect(selector, contains("'Analisi'"));
    expect(selector, contains('Cue.onToggle('));
    expect(selector, contains('left: unit * progress'));
    expect(selector, contains('width: unit * (1 + weight[i])'));
    expect(shell, contains('_homeDirection = next > _homeSection ? 1 : -1'));
    expect(shell, contains('onShowActivity: _showHomeActivity'));
    expect(shell, contains('_selectHomeSection(innerTab == 0 ? 1 : 2)'));
    expect(shell, contains('onSectionChanged: _selectHomeSection'));
  });

  test('Corner launcher replaces the old bottom bar', () {
    final shell = File('lib/screens/app_shell.dart').readAsStringSync();
    final launcher = File(
      'lib/widgets/balyn_quick_action_launcher.dart',
    ).readAsStringSync();
    expect(shell, contains('extendBody: true'));
    expect(shell, contains('body: Stack('));
    expect(shell, contains('BalynQuickActionLauncher('));
    expect(shell, isNot(contains('BalynGlassNavigation(')));
    expect(launcher, contains('return PieMenu('));
    expect(launcher, contains('BalynMorphingFab('));
    expect(launcher, contains('longPressDuration: holdDuration'));
    expect(launcher, contains('radius: 115'));
    expect(launcher, contains('latest.take(4).toList()'));
    expect(launcher, contains('PieAction('));
    expect(launcher, contains('Nuovo preset'));
    expect(launcher, contains('_WhiteChargePainter'));
    expect(shell, contains('return PieCanvas('));
    expect(shell, contains('onCreate: () => _open(TransactionType.transfer)'));
    expect(shell, contains('NotificationListener<ScrollNotification>'));
    expect(shell, contains('motion: _fabMotion'));
  });

  testWidgets('Cue selector dispatches three tabs', (tester) async {
    final changed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(
              width: 350,
              child: BalynCueSectionBar(
                selectedTab: 0,
                page: 0,
                onSelected: changed.add,
              ),
            ),
          ),
        ),
      ),
    );
    expect(find.byKey(const ValueKey('cue-home-sections')), findsOneWidget);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(ValueKey('home-segment-$i')));
      await tester.pump();
    }
    expect(changed, [0, 1, 2]);
  });

  testWidgets('FAB uses PieCanvas and a clockwise white charge', (
    tester,
  ) async {
    var transferCount = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: PieCanvas(
          child: Scaffold(
            body: Align(
              alignment: Alignment.bottomRight,
              child: BalynQuickActionLauncher(
                onCreate: () => transferCount++,
                onAdvances: () {},
                onPlanning: () {},
                onPresetSelected: (_) {},
                onAddPreset: () async {},
                loadPresets: () async => [],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(PieMenu), findsOneWidget);
    final pie = tester.widget<PieMenu>(find.byType(PieMenu));
    expect(pie.actions, hasLength(3));
    expect(
      find.byKey(const ValueKey('quick-fab-white-charge')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('quick-launcher')));
    await tester.pumpAndSettle();
    expect(transferCount, 1);
    final touch = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('quick-launcher'))),
    );
    await tester.pump(const Duration(milliseconds: 350));
    expect(tester.takeException(), isNull);
    await touch.up();
    await tester.pumpAndSettle();
  });

  testWidgets('PageView follows the finger and snaps between three sections', (
    tester,
  ) async {
    final controller = PageController();
    var selected = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 360,
            width: 320,
            child: PageView(
              key: const ValueKey('home-swipe-pages'),
              controller: controller,
              onPageChanged: (value) => selected = value,
              children: const [
                Center(child: Text('Panoramica')),
                Center(child: Text('Movimenti')),
                Center(child: Text('Analisi')),
              ],
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('home-swipe-pages'))),
    );
    await gesture.moveBy(const Offset(-110, 0));
    await tester.pump();
    expect(controller.page!, greaterThan(0));
    expect(controller.page!, lessThan(1));
    await gesture.moveBy(const Offset(-230, 0));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(selected, 1);

    await tester.drag(
      find.byKey(const ValueKey('home-swipe-pages')),
      const Offset(380, 0),
    );
    await tester.pumpAndSettle();
    expect(selected, 0);
    controller.dispose();
  });
}
