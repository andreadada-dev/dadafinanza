import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_cue_three_dots_action.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Onboarding steps one and three display the official Balyn mark', () {
    final source = File('lib/screens/balyn_onboarding_flow.dart')
        .readAsStringSync();
    expect(
      RegExp(r'illustration: const _BalynBrandArt\\(')
          .allMatches(source)
          .length,
      2,
    );
    expect(source, contains('assets/branding/balyn_logo_only.png'));
    expect(source, contains("key: const ValueKey('onboarding-balyn-logo')"));
    expect(source, contains("key: const ValueKey('onboarding-balyn-wordmark')"));
    expect(source, contains("'Balyn'"));
    expect(source, contains('illustration: _CircleArt('));
    expect(source, isNot(contains('icon: Icons.auto_graph_rounded')));
    expect(
      source,
      isNot(contains('Icons.dashboard_customize_outlined')),
    );
  });

  testWidgets('Home More opens below its original right-hand trigger', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    var opened = '';
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topRight,
            child: Padding(
              padding: const EdgeInsets.only(top: 90, right: 52),
              child: BalynCueThreeDotsAction(
                onManageAccounts: () => opened = 'accounts',
                onPlanning: () => opened = 'planning',
                onAdvances: () => opened = 'advances',
              ),
            ),
          ),
        ),
      ),
    );
    final trigger = find.byKey(const ValueKey('home-more-cue-trigger'));
    final right = tester.getTopRight(trigger).dx;
    final bottom = tester.getBottomRight(trigger).dy;
    await tester.tap(trigger);
    await tester.pumpAndSettle();

    final firstItem = find.byType(PopupMenuItem<String>).first;
    expect(firstItem, findsOneWidget);
    expect(find.text('Conti'), findsOneWidget);
    expect(find.text('Pianifica'), findsOneWidget);
    expect(find.text('Anticipi'), findsOneWidget);
    final menuRight = tester.getTopRight(firstItem).dx;
    final menuTop = tester.getTopLeft(firstItem).dy;
    expect((menuRight - right).abs(), lessThan(16));
    expect(menuTop, greaterThan(bottom));
    expect(trigger, findsOneWidget);

    await tester.tap(find.text('Pianifica'));
    await tester.pumpAndSettle();
    expect(opened, 'planning');
  });
}
