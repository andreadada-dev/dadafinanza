import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_glass_navigation.dart';
import 'package:balyn/widgets/balyn_home_section_transition.dart';
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

    expect(home, contains('BalynHomeSectionTransition('));
    expect(home, contains('selectedSection == 0'));
    expect(home, contains('selectedSection == 1'));
    expect(home, contains('BalynActivityScreen('));
    expect(home, contains('onTabChanged: onSectionChanged'));
    expect(hero, contains("label: 'Panoramica'"));
    expect(hero, contains("label: 'Conti'"));
    expect(hero, contains("label: 'Attività'"));
    expect(hero, contains('AnimatedPositioned('));
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

  testWidgets('Home content slides in either direction without routes', (
    tester,
  ) async {
    var selected = 0;
    var direction = 1;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return SizedBox(
                width: 340,
                child: BalynHomeSectionTransition(
                  index: selected,
                  direction: direction,
                  child: Text('Sezione $selected'),
                ),
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Sezione 0'), findsOneWidget);
    update(() {
      direction = 1;
      selected = 2;
    });
    await tester.pump();
    expect(find.text('Sezione 2'), findsOneWidget);
    await tester.pumpAndSettle();

    update(() {
      direction = -1;
      selected = 1;
    });
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Sezione 1'), findsOneWidget);
    expect(find.text('Sezione 2'), findsNothing);
  });
}
