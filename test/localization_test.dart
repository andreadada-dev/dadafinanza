import 'dart:io';

import 'package:dadafinanza/l10n/app_i18n.dart';
import 'package:dadafinanza/l10n/generated_translations.dart';
import 'package:dadafinanza/l10n/localized_material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' show Intl;

void main() {
  tearDown(() => AppI18n.use('it'));

  test('DadaFinanza exposes the supported language catalog', () {
    expect(AppI18n.languages.map((item) => item.code).toList(), const [
      'it',
      'en',
      'es',
      'fr',
      'de',
      'pt',
      'ru',
      'zh',
      'ja',
      'ko',
      'ar',
      'hi',
    ]);
    expect(AppI18n.supportedLocales, hasLength(12));
  });

  test('generated translations cover every non-Italian language', () {
    for (final language in AppI18n.languages.where(
      (item) => item.code != 'it',
    )) {
      final map = generatedTranslations[language.code];
      expect(
        map,
        isNotNull,
        reason: 'Missing generated map for ${language.code}',
      );
      expect(
        map!.length,
        greaterThan(100),
        reason: 'Translation coverage is too small for ${language.code}',
      );
    }

    expect(generatedTranslations['en']?['Impostazioni'], 'Settings');
    expect(generatedTranslations['en']?['Nuovo movimento'], 'New transaction');
    expect(generatedTranslations['es']?['Impostazioni'], isNot('Impostazioni'));
  });

  test('selected language updates Intl and translated runtime text', () {
    AppI18n.use('en');

    expect(AppI18n.currentCode, 'en');
    expect(AppI18n.intlLocale, 'en_US');
    expect(Intl.defaultLocale, 'en_US');
    expect(AppI18n.tr('Impostazioni'), 'Settings');
  });

  test(
    'system locale resolves to a supported language or English fallback',
    () {
      expect(
        AppI18n.resolvedCodeFor(
          AppI18n.systemCode,
          platformLocale: const Locale('fr', 'CA'),
        ),
        'fr',
      );
      expect(
        AppI18n.resolvedCodeFor(
          AppI18n.systemCode,
          platformLocale: const Locale('nl', 'NL'),
        ),
        'en',
      );
    },
  );

  test(
    'voice commands are normalized back to the canonical parser language',
    () {
      AppI18n.use('en');
      final canonical = AppI18n.voiceToItalian(
        'expense 12 today note lunch',
      ).toLowerCase();

      expect(canonical, contains('spesa'));
      expect(canonical, contains('oggi'));
      expect(canonical, contains('nota'));
    },
  );

  testWidgets('localized Text renders translated strings', (tester) async {
    AppI18n.use('en');

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: Text('Impostazioni'))),
    );

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Impostazioni'), findsNothing);
  });

  testWidgets('Arabic locale enables right-to-left Material layout', (
    tester,
  ) async {
    AppI18n.use('ar');
    TextDirection? direction;

    await tester.pumpWidget(
      MaterialApp(
        locale: AppI18n.locale,
        supportedLocales: AppI18n.supportedLocales,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: Builder(
          builder: (context) {
            direction = Directionality.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );

    expect(direction, TextDirection.rtl);
  });

  test('all Flutter UI sources are wired to localized Material and Intl', () {
    final files = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart'))
        .where((file) => !file.path.replaceAll('\\', '/').contains('/l10n/'));

    for (final file in files) {
      final source = file.readAsStringSync();
      expect(
        source,
        isNot(contains("import 'package:flutter/material.dart';")),
        reason: 'Direct Material import remains in ${file.path}',
      );
      expect(
        source,
        isNot(contains("'it_IT'")),
        reason: 'Hardcoded Italian Intl locale remains in ${file.path}',
      );
      expect(
        source,
        isNot(contains('"it_IT"')),
        reason: 'Hardcoded Italian Intl locale remains in ${file.path}',
      );
    }
  });

  test(
    'Android localized string resources exist for every translated locale',
    () {
      const folders = [
        'values-en',
        'values-es',
        'values-fr',
        'values-de',
        'values-pt-rBR',
        'values-ru',
        'values-zh-rCN',
        'values-ja',
        'values-ko',
        'values-ar',
        'values-hi',
      ];

      for (final folder in folders) {
        final file = File('android/app/src/main/res/$folder/strings.xml');
        expect(
          file.existsSync(),
          isTrue,
          reason: 'Missing $folder strings.xml',
        );
        final contents = file.readAsStringSync();
        expect(contents, contains('widget_config_title'));
        expect(contents, contains('widget_balance_total'));
      }
    },
  );
}
