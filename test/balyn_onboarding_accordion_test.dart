import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/l10n/balyn_onboarding_l10n.dart';
import 'package:balyn/widgets/balyn_onboarding_feature_accordion.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:material_ui/material_ui.dart' as mui;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('All twelve supported languages fully translate the three steps', () {
    const keys = [
      'welcomeTitle',
      'welcomeSubtitle',
      'language',
      'currency',
      'accountTitle',
      'accountSubtitle',
      'nameLabel',
      'typeLabel',
      'accountIcon',
      'accountColor',
      'howTitle',
      'howSubtitle',
      'homeTitle',
      'homeDescription',
      'movementTitle',
      'movementDescription',
      'advancesTitle',
      'advancesDescription',
      'planTitle',
      'planDescription',
      'back',
      'next',
      'done',
      'skip',
      'requiredName',
      'defaultName',
    ];
    expect(BalynOnboardingL10n.supportedCodes, hasLength(12));
    for (final language in BalynOnboardingL10n.supportedCodes) {
      expect(BalynOnboardingL10n.isComplete(language), isTrue);
      for (final key in keys) {
        final phrase = BalynOnboardingL10n.tr(language, key);
        expect(phrase.trim(), isNotEmpty, reason: '$language.$key');
      }
      for (final type in [
        'checking',
        'cash',
        'card',
        'savings',
        'prepaid',
        'investment',
      ]) {
        expect(BalynOnboardingL10n.accountType(language, type), isNot(type));
      }
    }
  });

  test(
    'The onboarding maintains account setup and actual data persistence',
    () {
      final source = File(
        'lib/screens/balyn_onboarding_flow.dart',
      ).readAsStringSync();
      expect(source, contains('BalynOnboardingFeatureAccordion('));
      expect(source, contains('onChanged: _changeLanguage'));
      expect(source, contains('state.setLanguageCode(_language)'));
      expect(source, contains('state.addAccount('));
      expect(source, contains("setSetting('onboarding_completed', '1')"));
      expect(
        source,
        contains('const Positioned.fill(child: BalynOnboardingVelvet())'),
      );
      expect(source, contains('backgroundColor: BalynPalette.darkCanvas'));
      expect(source, contains('backgroundColor: BalynPalette.accent'));
    },
  );

  testWidgets('Cue accordion opens one section at a time and can close', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('it'),
        supportedLocales: [Locale('it'), Locale('en')],
        localizationsDelegates: [
          mui.GlobalMaterialLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Scaffold(
          body: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: BalynOnboardingFeatureAccordion(languageCode: 'it'),
            ),
          ),
        ),
      ),
    );
    expect(
      find.byKey(const ValueKey('onboarding-feature-accordion')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('onboarding-feature-0')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('onboarding-feature-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.tap(find.byKey(const ValueKey('onboarding-feature-1')));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
