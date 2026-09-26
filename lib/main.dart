import 'dart:async';

import 'package:dadafinanza/l10n/localized_material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:home_widget/home_widget.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app_state.dart';
import 'data/app_database.dart';
import 'l10n/app_i18n.dart';
import 'models/models.dart';
import 'screens/app_shell.dart';
import 'screens/quick_add_page.dart';
import 'services/finance_schema_service.dart';
import 'services/notification_service.dart';
import 'services/quick_capture_deep_link_service.dart';
import 'services/recurring_execution_service.dart';
import 'services/security_service.dart';
import 'theme/app_theme.dart';
import 'widgets/app_lock_gate.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  final database = AppDatabase();
  await database.init();
  await FinanceSchemaService(database).ensure();
  await const RecurringExecutionService().processDue(database);
  final state = AppState(database);
  await state.load();
  runApp(DadaFinanzaApp(state: state));
}

class DadaFinanzaApp extends StatefulWidget {
  const DadaFinanzaApp({required this.state, super.key});
  final AppState state;

  @override
  State<DadaFinanzaApp> createState() => _DadaFinanzaAppState();
}

class _DadaFinanzaAppState extends State<DadaFinanzaApp>
    with WidgetsBindingObserver {
  final security = SecurityService();
  final notificationService = NotificationService();
  final deepLinks = QuickCaptureDeepLinkService();
  StreamSubscription<Uri?>? _widgetSubscription;
  Timer? _notificationDebounce;
  bool? _lastWidgetPrivacy;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _widgetSubscription = HomeWidget.widgetClicked.listen(
      (uri) => unawaited(_handleWidgetUri(uri)),
    );
    widget.state.addListener(_handleStateChanged);
    _handleStateChanged();
    WidgetsBinding.instance.addPostFrameCallback(
      (_) async =>
          _handleWidgetUri(await HomeWidget.initiallyLaunchedFromHomeWidget()),
    );
  }

  void _handleStateChanged() {
    _syncWidgetPrivacy();
    _notificationDebounce?.cancel();
    _notificationDebounce = Timer(
      const Duration(milliseconds: 350),
      () => unawaited(notificationService.sync(widget.state)),
    );
  }

  Future<void> _handleWidgetUri(Uri? uri) async {
    if (uri == null) return;
    final draft = await deepLinks.fromUri(widget.state, uri);
    if (draft == null) return;
    navigatorKey.currentState?.push(
      MaterialPageRoute(builder: (_) => QuickAddPage(initialDraft: draft)),
    );
  }

  void _syncWidgetPrivacy() {
    final hidden = widget.state.hideBalance;
    if (_lastWidgetPrivacy == hidden) return;
    _lastWidgetPrivacy = hidden;
    unawaited(_writeWidgetPrivacy(hidden));
  }

  Future<void> _writeWidgetPrivacy(bool hidden) async {
    await HomeWidget.saveWidgetData<bool>('hide_balance', hidden);
    await Future.wait([
      HomeWidget.updateWidget(
        androidName: 'DadaFinanceWidgetProvider',
        qualifiedAndroidName: 'com.dadafinanza.app.DadaFinanceWidgetProvider',
      ),
      HomeWidget.updateWidget(
        androidName: 'DadaBalanceWidgetProvider',
        qualifiedAndroidName: 'com.dadafinanza.app.DadaBalanceWidgetProvider',
      ),
      HomeWidget.updateWidget(
        androidName: 'DadaQuickAddWidgetProvider',
        qualifiedAndroidName: 'com.dadafinanza.app.DadaQuickAddWidgetProvider',
      ),
      HomeWidget.updateWidget(
        androidName: 'DadaQuickAmountsWidgetProvider',
        qualifiedAndroidName:
            'com.dadafinanza.app.DadaQuickAmountsWidgetProvider',
      ),
    ]);
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    if (widget.state.languageCode != AppI18n.systemCode) return;
    AppI18n.use(
      widget.state.languageCode,
      platformLocale: locales?.first,
    );
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.state.removeListener(_handleStateChanged);
    _notificationDebounce?.cancel();
    _widgetSubscription?.cancel();
    super.dispose();
  }

  ThemeMode get _themeMode => switch (widget.state.themePreference) {
    AppThemePreference.system => ThemeMode.system,
    AppThemePreference.light => ThemeMode.light,
    AppThemePreference.dark => ThemeMode.dark,
  };

  @override
  Widget build(BuildContext context) {
    AppI18n.use(widget.state.languageCode);
    return AppScope(
      notifier: widget.state,
      child: AnimatedBuilder(
        animation: widget.state,
        builder: (context, _) {
          AppI18n.use(widget.state.languageCode);
          return MaterialApp(
            title: 'DadaFinanza',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: _themeMode,
            locale: AppI18n.locale,
            supportedLocales: AppI18n.supportedLocales,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: AppLockGate(security: security, child: const DadaAppShell()),
          );
        },
      ),
    );
  }
}

class AppScope extends InheritedNotifier<AppState> {
  const AppScope({required super.notifier, required super.child, super.key});

  static AppState of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'AppScope not found');
    return scope!.notifier!;
  }
}
