import 'dart:ui';

import 'package:intl/intl.dart';

import 'generated_translations.dart';

class AppLanguage {
  const AppLanguage({
    required this.code,
    required this.locale,
    required this.intlLocale,
    required this.speechLocaleId,
    required this.nativeName,
    required this.englishName,
  });

  final String code;
  final Locale locale;
  final String intlLocale;
  final String speechLocaleId;
  final String nativeName;
  final String englishName;
}

class AppI18n {
  AppI18n._();

  static const systemCode = 'system';

  static const languages = <AppLanguage>[
    AppLanguage(
      code: 'it',
      locale: Locale('it', 'IT'),
      intlLocale: 'it_IT',
      speechLocaleId: 'it_IT',
      nativeName: 'Italiano',
      englishName: 'Italian',
    ),
    AppLanguage(
      code: 'en',
      locale: Locale('en', 'US'),
      intlLocale: 'en_US',
      speechLocaleId: 'en_US',
      nativeName: 'English',
      englishName: 'English',
    ),
    AppLanguage(
      code: 'es',
      locale: Locale('es', 'ES'),
      intlLocale: 'es_ES',
      speechLocaleId: 'es_ES',
      nativeName: 'Español',
      englishName: 'Spanish',
    ),
    AppLanguage(
      code: 'fr',
      locale: Locale('fr', 'FR'),
      intlLocale: 'fr_FR',
      speechLocaleId: 'fr_FR',
      nativeName: 'Français',
      englishName: 'French',
    ),
    AppLanguage(
      code: 'de',
      locale: Locale('de', 'DE'),
      intlLocale: 'de_DE',
      speechLocaleId: 'de_DE',
      nativeName: 'Deutsch',
      englishName: 'German',
    ),
    AppLanguage(
      code: 'pt',
      locale: Locale('pt', 'BR'),
      intlLocale: 'pt_BR',
      speechLocaleId: 'pt_BR',
      nativeName: 'Português (Brasil)',
      englishName: 'Portuguese (Brazil)',
    ),
    AppLanguage(
      code: 'ru',
      locale: Locale('ru', 'RU'),
      intlLocale: 'ru_RU',
      speechLocaleId: 'ru_RU',
      nativeName: 'Русский',
      englishName: 'Russian',
    ),
    AppLanguage(
      code: 'zh',
      locale: Locale('zh', 'CN'),
      intlLocale: 'zh_CN',
      speechLocaleId: 'zh_CN',
      nativeName: '简体中文',
      englishName: 'Simplified Chinese',
    ),
    AppLanguage(
      code: 'ja',
      locale: Locale('ja', 'JP'),
      intlLocale: 'ja_JP',
      speechLocaleId: 'ja_JP',
      nativeName: '日本語',
      englishName: 'Japanese',
    ),
    AppLanguage(
      code: 'ko',
      locale: Locale('ko', 'KR'),
      intlLocale: 'ko_KR',
      speechLocaleId: 'ko_KR',
      nativeName: '한국어',
      englishName: 'Korean',
    ),
    AppLanguage(
      code: 'ar',
      locale: Locale('ar'),
      intlLocale: 'ar',
      speechLocaleId: 'ar_SA',
      nativeName: 'العربية',
      englishName: 'Arabic',
    ),
    AppLanguage(
      code: 'hi',
      locale: Locale('hi', 'IN'),
      intlLocale: 'hi_IN',
      speechLocaleId: 'hi_IN',
      nativeName: 'हिन्दी',
      englishName: 'Hindi',
    ),
  ];

  static String _preference = 'it';
  static String _resolvedCode = 'it';
  static final Map<String, String> _runtimeCache = {};
  static final Map<String, List<String>> _orderedPhraseKeys = {};

  static String get preference => _preference;
  static String get currentCode => _resolvedCode;

  static AppLanguage get currentLanguage => languages.firstWhere(
    (item) => item.code == _resolvedCode,
    orElse: () => languages.first,
  );

  static Locale get locale => currentLanguage.locale;
  static String get intlLocale => currentLanguage.intlLocale;
  static String get speechLocaleId => currentLanguage.speechLocaleId;

  static List<Locale> get supportedLocales =>
      languages.map((item) => item.locale).toList(growable: false);

  static bool isSupportedPreference(String value) =>
      value == systemCode || languages.any((item) => item.code == value);

  static AppLanguage languageForCode(String code) => languages.firstWhere(
    (item) => item.code == code,
    orElse: () => languages.first,
  );

  static String resolvedCodeFor(
    String preference, {
    Locale? platformLocale,
  }) {
    if (preference != systemCode) {
      return languages.any((item) => item.code == preference)
          ? preference
          : 'it';
    }

    final device =
        platformLocale ?? PlatformDispatcher.instance.locale;
    final languageCode = device.languageCode.toLowerCase();
    if (languages.any((item) => item.code == languageCode)) {
      return languageCode;
    }
    return 'en';
  }

  static void use(
    String preference, {
    Locale? platformLocale,
  }) {
    final safePreference = isSupportedPreference(preference)
        ? preference
        : 'it';
    final next = resolvedCodeFor(
      safePreference,
      platformLocale: platformLocale,
    );
    final changed = next != _resolvedCode || safePreference != _preference;
    _preference = safePreference;
    _resolvedCode = next;
    Intl.defaultLocale = intlLocale;
    if (changed) {
      _runtimeCache.clear();
    }
  }

  static String preferenceLabel(String preference) {
    if (preference == systemCode) {
      return 'Sistema · ${currentLanguage.nativeName}';
    }
    return languageForCode(preference).nativeName;
  }

  static String tr(String source) => translateRuntime(source);

  static String translateRuntime(String source) {
    if (source.isEmpty || _resolvedCode == 'it') return source;
    final cacheKey = '$_resolvedCode\u0000$source';
    final cached = _runtimeCache[cacheKey];
    if (cached != null) return cached;

    final exact = generatedTranslations[_resolvedCode];
    final exactMatch = exact?[source];
    if (exactMatch != null && exactMatch.isNotEmpty) {
      _runtimeCache[cacheKey] = exactMatch;
      return exactMatch;
    }

    var translated = source;
    final phrases = generatedPhraseTranslations[_resolvedCode];
    if (phrases != null && phrases.isNotEmpty) {
      final keys = _orderedPhraseKeys.putIfAbsent(
        _resolvedCode,
        () {
          final values = phrases.keys
              .where((key) => key.trim().length >= 3)
              .toList(growable: false);
          values.sort((left, right) => right.length.compareTo(left.length));
          return values;
        },
      );
      for (final key in keys) {
        if (translated.contains(key)) {
          translated = translated.replaceAll(key, phrases[key]!);
        }
      }
    }

    _runtimeCache[cacheKey] = translated;
    return translated;
  }
}
