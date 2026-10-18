import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_glass_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home segments are in-place, directional, and account-aware', () {
    final home = File(
      'lib/screens/account_context_home_screen.dart',
    ).readAsStringSync();
    final hero = File(
      'lib/widgets/balyn_revolut_home_hero.dart',
    ).readAsStringSync();
    final shell = File('lib/screens/app_shell.dart').readAsStringSync();

    expect(home, contains('NestedScrollView('));
    expect(home, contains('body: PageView('));
    expect(home, contains('controller: _pageController'));
    expect(home, contains('onPageChanged: _onHomePageChanged'));
    expect(home, contains('onTabChanged: _selectHomePage'));
    expect(home, contains('BalynActivityScreen('));
    expect(home, contains('sectionPage: _pageController.hasClients'));
    expect(hero, contains("label: 'Panoramica'"));
    expect(hero, contains("label: 'Conti'"));
    expect(hero, contains("label: 'Attività'"));
    expect(hero, contains('left: segmentWidth * sectionPage.clamp(0.0, 2.0)'));
    expect(shell, contains('_homeDirection = next > _homeSection ? 1 : -1'));
    expect(shell, contains('onShowActivity: _showHomeActivity'));
    expect(shell, contains('onSectionChanged: _selectHomeSection'));
  });

  test(
    'Glass navigation overlays page content instead of reserving bottom bar',
    () {
      final shell = File('lib/screens/app_shell.dart').readAsStringSync();
      final nav = File(
        'lib/widgets/balyn_glass_navigation.dart',
      ).readAsStringSync();
      expect(shell, contains('extendBody: true'));
      expect(shell, contains('body: Stack('));
      expect(shell, contains('BalynGlassNavigation('));
      expect(shell, isNot(contains('bottomNavigationBar: NavigationBar(')));
      expect(nav, contains('BackdropFilter('));
      expect(nav, contains('ImageFilter.blur('));
      expect(nav, contains('_LiquidRimPainter'));
      expect(nav, contains('Color(0xFFAA4559)'));
      expect(nav, contains('Colors.white.withValues(alpha: dark ? .72 : .9)'));
    },
  );

  testWidgets('Floating glass destinations dispatch all four taps', (
    tester,
  ) async {
    final selections = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 360,
              child: BalynGlassNavigation(
                index: 0,
                onDestinationSelected: selections.add,
              ),
            ),
          ),
        ),
      ),
    );

    for (var i = 0; i < 4; i++) {
      await tester.tap(find.byKey(ValueKey('glass-destination-$i')));
      await tester.pump();
    }
    expect(selections, [0, 1, 2, 3]);
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
                Center(child: Text('Conti')),
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
