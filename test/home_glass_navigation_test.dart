import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_cue_section_bar.dart';
import 'package:balyn/widgets/balyn_quick_action_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

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
    expect(home, contains("title: 'Gestisci conti'"));
    expect(home, contains('onAccountChanged: onAccountChanged'));
    expect(home, isNot(contains('home-accounts-scroll')));
    expect(home, contains('sectionPage: _pageController.hasClients'));
    expect(hero, contains('BalynCueSectionBar('));
    expect(selector, contains("'Panoramica'"));
    expect(selector, contains("'Movimenti'"));
    expect(selector, isNot(contains("'Conti'")));
    expect(selector, contains("'Attività'"));
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
    expect(launcher, contains('SizeTransition('));
    expect(launcher, contains('FadeTransition('));
    expect(launcher, contains('SlideTransition('));
    expect(launcher, contains("label: 'Movimento'"));
    expect(launcher, contains('Color(0xFF8157F7)'));
    expect(launcher, contains('onLongPress: widget.onLongPress'));
    expect(launcher, contains("id: 'create'"));
    expect(launcher, contains("id: 'advances'"));
    expect(launcher, contains("id: 'planning'"));
    expect(launcher, contains("id: 'home'"));
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

  testWidgets('Launcher reveals working actions and closes', (tester) async {
    var expanded = false;
    final actions = <String>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Align(
              alignment: Alignment.bottomRight,
              child: BalynQuickActionLauncher(
                expanded: expanded,
                showHome: true,
                onToggle: () => setState(() => expanded = !expanded),
                onCreate: () => actions.add('create'),
                onAdvances: () => actions.add('advances'),
                onPlanning: () => actions.add('planning'),
                onHome: () => actions.add('home'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('quick-launcher')));
    await tester.pumpAndSettle();
    expect(expanded, isTrue);
    for (final item in ['create', 'advances', 'planning', 'home']) {
      await tester.tap(find.byKey(ValueKey('quick-nav-$item')));
      await tester.pump();
    }
    expect(actions, ['create', 'advances', 'planning', 'home']);
    await tester.tap(find.byKey(const ValueKey('quick-launcher')));
    await tester.pumpAndSettle();
    expect(expanded, isFalse);
    expect(tester.takeException(), isNull);
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
                Center(child: Text('Attività')),
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
