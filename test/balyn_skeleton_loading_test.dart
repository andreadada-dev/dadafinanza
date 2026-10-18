import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_data_skeleton.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:skeletonizer/skeletonizer.dart';

void main() {
  testWidgets('Cold start shows a proper shimmer without finance sample data', (
    tester,
  ) async {
    await tester.pumpWidget(const BalynBootstrapLoadingApp());
    expect(find.byKey(const ValueKey('balyn-data-skeleton')), findsOneWidget);
    expect(
      find.byWidgetPredicate((widget) => widget is Skeletonizer),
      findsWidgets,
    );
    expect(find.byWidgetPredicate((widget) => widget is Bone), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Different sections have loading placeholders', (tester) async {
    for (var section = 0; section < 4; section++) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BalynDataSkeletonView(section: section)),
        ),
      );
      expect(find.byKey(const ValueKey('balyn-data-skeleton')), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  test('Skeletons are only shown during real async initialization', () {
    final main = File('lib/main.dart').readAsStringSync();
    final shell = File('lib/screens/app_shell.dart').readAsStringSync();
    expect(
      main.indexOf('runApp(const BalynBootstrapLoadingApp())'),
      lessThan(main.indexOf('await database.init()')),
    );
    expect(shell, contains('if (state.loading)'));
    expect(shell, contains('BalynDataSkeletonView(section: index)'));
  });

  test(
    'Onboarding third page explains all sections with the Cue accordion',
    () {
      final onboarding = File(
        'lib/screens/balyn_onboarding_flow.dart',
      ).readAsStringSync();
      final accordion = File(
        'lib/widgets/balyn_onboarding_feature_accordion.dart',
      ).readAsStringSync();
      expect(onboarding, contains('BalynOnboardingFeatureAccordion('));
      expect(onboarding, contains('MediaQuery.disableAnimationsOf(context)'));
      expect(accordion, contains('Cue.onToggle('));
      expect(accordion, contains('Spring.smooth()'));
      expect(accordion, contains("'homeTitle'"));
      expect(accordion, contains("'movementTitle'"));
      expect(accordion, contains("'advancesTitle'"));
      expect(accordion, contains("'planTitle'"));
    },
  );
}
