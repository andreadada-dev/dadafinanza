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
  static final Map<String, List<MapEntry<String, String>>>
  _reverseVoiceEntries = {};

  static const Map<String, Map<String, String>> _voiceAliases = {
    'en': {
      'expense': 'spesa',
      'income': 'entrata',
      'transfer': 'trasferimento',
      'today': 'oggi',
      'yesterday': 'ieri',
      'tomorrow': 'domani',
      'note': 'nota',
      'description': 'nota',
      'tag': 'tag',
      'category': 'categoria',
      'account': 'conto',
      'advance': 'anticipo',
      'iou': 'anticipo',
    },
    'es': {
      'gasto': 'spesa',
      'ingreso': 'entrata',
      'transferencia': 'trasferimento',
      'hoy': 'oggi',
      'ayer': 'ieri',
      'mañana': 'domani',
      'nota': 'nota',
      'etiqueta': 'tag',
      'categoría': 'categoria',
      'cuenta': 'conto',
      'anticipo': 'anticipo',
    },
    'fr': {
      'dépense': 'spesa',
      'revenu': 'entrata',
      'virement': 'trasferimento',
      'transfert': 'trasferimento',
      'aujourd’hui': 'oggi',
      "aujourd'hui": 'oggi',
      'hier': 'ieri',
      'demain': 'domani',
      'note': 'nota',
      'étiquette': 'tag',
      'catégorie': 'categoria',
      'compte': 'conto',
      'avance': 'anticipo',
    },
    'de': {
      'ausgabe': 'spesa',
      'einnahme': 'entrata',
      'überweisung': 'trasferimento',
      'heute': 'oggi',
      'gestern': 'ieri',
      'morgen': 'domani',
      'notiz': 'nota',
      'tag': 'tag',
      'kategorie': 'categoria',
      'konto': 'conto',
      'vorschuss': 'anticipo',
    },
    'pt': {
      'despesa': 'spesa',
      'receita': 'entrata',
      'rendimento': 'entrata',
      'transferência': 'trasferimento',
      'hoje': 'oggi',
      'ontem': 'ieri',
      'amanhã': 'domani',
      'nota': 'nota',
      'etiqueta': 'tag',
      'categoria': 'categoria',
      'conta': 'conto',
      'adiantamento': 'anticipo',
    },
    'ru': {
      'расход': 'spesa',
      'доход': 'entrata',
      'перевод': 'trasferimento',
      'сегодня': 'oggi',
      'вчера': 'ieri',
      'завтра': 'domani',
      'заметка': 'nota',
      'тег': 'tag',
      'категория': 'categoria',
      'счёт': 'conto',
      'счет': 'conto',
      'аванс': 'anticipo',
    },
    'zh': {
      '支出': 'spesa',
      '收入': 'entrata',
      '转账': 'trasferimento',
      '今天': 'oggi',
      '昨天': 'ieri',
      '明天': 'domani',
      '备注': 'nota',
      '标签': 'tag',
      '类别': 'categoria',
      '账户': 'conto',
      '垫付': 'anticipo',
    },
    'ja': {
      '支出': 'spesa',
      '収入': 'entrata',
      '振替': 'trasferimento',
      '送金': 'trasferimento',
      '今日': 'oggi',
      '昨日': 'ieri',
      '明日': 'domani',
      'メモ': 'nota',
      'タグ': 'tag',
      'カテゴリ': 'categoria',
      '口座': 'conto',
      '立替': 'anticipo',
    },
    'ko': {
      '지출': 'spesa',
      '수입': 'entrata',
      '이체': 'trasferimento',
      '오늘': 'oggi',
      '어제': 'ieri',
      '내일': 'domani',
      '메모': 'nota',
      '태그': 'tag',
      '카테고리': 'categoria',
      '계좌': 'conto',
      '대납': 'anticipo',
    },
    'ar': {
      'مصروف': 'spesa',
      'دخل': 'entrata',
      'تحويل': 'trasferimento',
      'اليوم': 'oggi',
      'أمس': 'ieri',
      'غداً': 'domani',
      'غدا': 'domani',
      'ملاحظة': 'nota',
      'وسم': 'tag',
      'فئة': 'categoria',
      'حساب': 'conto',
      'سلفة': 'anticipo',
    },
    'hi': {
      'खर्च': 'spesa',
      'आय': 'entrata',
      'ट्रांसफर': 'trasferimento',
      'हस्तांतरण': 'trasferimento',
      'आज': 'oggi',
      'नोट': 'nota',
      'टैग': 'tag',
      'श्रेणी': 'categoria',
      'खाता': 'conto',
      'अग्रिम': 'anticipo',
    },
  };

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

  static String resolvedCodeFor(String preference, {Locale? platformLocale}) {
    if (preference != systemCode) {
      return languages.any((item) => item.code == preference)
          ? preference
          : 'it';
    }

    final device = platformLocale ?? PlatformDispatcher.instance.locale;
    final languageCode = device.languageCode.toLowerCase();
    if (languages.any((item) => item.code == languageCode)) {
      return languageCode;
    }
    return 'en';
  }

  static void use(String preference, {Locale? platformLocale}) {
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
      _reverseVoiceEntries.clear();
    }
  }

  static String preferenceLabel(String preference) {
    if (preference == systemCode) {
      return '${tr('Sistema')} · ${currentLanguage.nativeName}';
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
      final keys = _orderedPhraseKeys.putIfAbsent(_resolvedCode, () {
        final values = phrases.keys
            .where((key) => key.trim().length >= 3)
            .toList(growable: false);
        values.sort((left, right) => right.length.compareTo(left.length));
        return values;
      });
      for (final key in keys) {
        if (translated.contains(key)) {
          translated = translated.replaceAll(key, phrases[key]!);
        }
      }
    }

    _runtimeCache[cacheKey] = translated;
    return translated;
  }

  static String voiceToItalian(String source) {
    if (source.isEmpty || _resolvedCode == 'it') return source;

    var canonical = source;
    final reverse = _reverseVoiceEntries.putIfAbsent(_resolvedCode, () {
      final values = <MapEntry<String, String>>[];
      final exact = generatedTranslations[_resolvedCode] ?? const {};
      final phrases = generatedPhraseTranslations[_resolvedCode] ?? const {};
      for (final entry in [...exact.entries, ...phrases.entries]) {
        final translated = entry.value.trim();
        if (translated.length < 2 || entry.key.trim().length < 2) continue;
        values.add(MapEntry(translated, entry.key));
      }
      values.sort((left, right) => right.key.length.compareTo(left.key.length));
      return values;
    });

    for (final entry in reverse) {
      canonical = canonical.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false, unicode: true),
        entry.value,
      );
    }

    final aliases = _voiceAliases[_resolvedCode] ?? const {};
    final orderedAliases = aliases.entries.toList()
      ..sort((left, right) => right.key.length.compareTo(left.key.length));
    for (final entry in orderedAliases) {
      canonical = canonical.replaceAll(
        RegExp(RegExp.escape(entry.key), caseSensitive: false, unicode: true),
        entry.value,
      );
    }
    return canonical;
  }
}
