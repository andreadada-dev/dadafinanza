import 'dart:async';

import 'package:balyn/l10n/localized_material.dart';

import '../app_state.dart';
import '../l10n/app_i18n.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/haptic_service.dart';
import '../widgets/balyn_settings_components.dart';
import 'account_management_screen.dart';
import 'android_widgets_screen.dart';
import 'advances_screen.dart';
import 'category_management_screen.dart';
import 'data_management_screen.dart';
import 'local_privacy_screen.dart';
import 'notification_settings_screen.dart';
import 'preset_management_screen.dart';
import 'privacy_policy_screen.dart';
import 'rules_management_screen.dart';
import 'settings_screen.dart'
    show DashboardCustomizerScreen, SmartSuggestionsSettingsScreen;
import 'voice_settings_screen.dart';

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.accountCount, required this.currency});

  final int accountCount;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Material(
      color: dark ? const Color(0xFF252633) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 19),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: .09),
                borderRadius: BorderRadius.circular(18),
              ),
              child: ExcludeSemantics(
                child: Image.asset(
                  'assets/branding/balyn_logo_only.png',
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  isAntiAlias: true,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.account_balance_wallet_rounded,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Balyn',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w900,
                      letterSpacing: -.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Le tue preferenze finanziarie',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    '$accountCount conti · $currency',
                    style: theme.textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PersonalSettingsScreen extends StatelessWidget {
  const PersonalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF111218) : const Color(0xFFF5F6F9),
      appBar: AppBar(
        title: const Text('Impostazioni'),
        backgroundColor: Colors.transparent,
        centerTitle: false,
        scrolledUnderElevation: 0,
      ),
      body: ListView(
        key: const PageStorageKey('balyn-settings-scroll'),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
        children: [
          _BrandHeader(
            accountCount: state.userAccounts.length,
            currency: state.currency,
          ),
          const SizedBox(height: 26),
          BalynSettingsGroup(
            title: 'Aspetto',
            accent: const Color(0xFF4365F5),
            children: [
              BalynSettingsTile(
                icon: Icons.contrast_rounded,
                title: 'Tema',
                subtitle: switch (state.themePreference) {
                  AppThemePreference.system => 'Sistema',
                  AppThemePreference.light => 'Chiaro',
                  AppThemePreference.dark => 'Scuro',
                },
                onTap: () => _pickTheme(context, state),
              ),
              BalynSettingsTile(
                icon: Icons.language_rounded,
                title: 'Lingua',
                subtitle: AppI18n.preferenceLabel(state.languageCode),
                onTap: () => _pickLanguage(context, state),
              ),
              BalynSettingsTile(
                icon: Icons.auto_awesome_rounded,
                title: 'Gradient animati',
                subtitle: 'Icone · Torte · Testo · Barre · Sfondo',
                onTap: () =>
                    _open(context, const ShaderAppearanceSettingsScreen()),
              ),
              BalynSettingsSwitch(
                icon: Icons.visibility_off_outlined,
                title: const Text('Nascondi saldi nell’app'),
                subtitle: const Text(
                  'Nasconde gli importi finanziari nelle viste principali.',
                ),
                value: state.hideBalance,
                onChanged: (value) => _setHideBalance(state, value),
              ),
            ],
          ),
          BalynSettingsGroup(
            title: 'Generali',
            accent: const Color(0xFF684BEC),
            children: [
              BalynSettingsTile(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Conti',
                subtitle: '${state.userAccounts.length} conti',
                onTap: () => _open(context, const AccountManagementScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.currency_exchange_rounded,
                title: 'Valuta principale',
                subtitle: state.currency,
                onTap: () => _pickCurrency(context, state),
              ),
              BalynSettingsSwitch(
                icon: Icons.pin_outlined,
                title: const Text('Mostra centesimi'),
                value: state.showCents,
                onChanged: (value) =>
                    _setBoolSetting(state, 'show_cents', value),
              ),
              BalynSettingsTile(
                icon: Icons.calendar_view_week_outlined,
                title: 'Primo giorno settimana',
                subtitle: state.weekStart == DateTime.sunday
                    ? 'Domenica'
                    : 'Lunedì',
                onTap: () => _pickWeekStart(context, state),
              ),
              BalynSettingsTile(
                icon: Icons.calendar_month_outlined,
                title: 'Inizio mese finanziario',
                subtitle: 'Giorno ${state.financialMonthStart}',
                onTap: () => _pickFinancialMonthStart(context, state),
              ),
              BalynSettingsSwitch(
                icon: Icons.warning_amber_rounded,
                title: const Text('Conferma eliminazioni'),
                subtitle: const Text(
                  'Richiede conferma prima di eliminare un movimento.',
                ),
                value: state.confirmDelete,
                onChanged: (value) =>
                    _setBoolSetting(state, 'confirm_delete', value),
              ),
            ],
          ),
          BalynSettingsGroup(
            title: 'Privacy locale',
            accent: const Color(0xFF298B83),
            children: [
              BalynSettingsTile(
                icon: Icons.fingerprint_rounded,
                title: 'Blocco e schermata recenti',
                subtitle: 'Biometria o PIN · timeout · protezione screenshot',
                onTap: () => _open(context, const LocalPrivacyScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.policy_outlined,
                title: 'Privacy e dati',
                subtitle: 'Dati locali, permessi, backup e servizi di sistema',
                onTap: () => _open(context, const PrivacyPolicyScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.notifications_none_rounded,
                title: 'Notifiche locali',
                subtitle: 'Scadenze, anticipi, budget, obiettivi e cash-flow',
                onTap: () => _open(context, const NotificationSettingsScreen()),
              ),
            ],
          ),
          BalynSettingsGroup(
            title: 'Inserimento',
            accent: const Color(0xFF8651B2),
            children: [
              BalynSettingsTile(
                icon: Icons.mic_none_rounded,
                title: 'Inserimento vocale',
                subtitle: 'Parser locale · on-device quando disponibile',
                onTap: () => _open(context, const VoiceSettingsScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.bolt_outlined,
                title: 'Smart Suggestions',
                subtitle: state.smartSuggestionsEnabled
                    ? '${state.learnedPatterns.length} pattern appresi'
                    : 'Disattivate',
                onTap: () =>
                    _open(context, const SmartSuggestionsSettingsScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.bookmark_add_outlined,
                title: 'Preset rapidi',
                subtitle: 'Caffè, benzina, spesa e azioni personalizzate',
                onTap: () => _open(context, const PresetManagementScreen()),
              ),
            ],
          ),
          BalynSettingsGroup(
            title: 'Organizzazione',
            accent: const Color(0xFFCB7737),
            children: [
              BalynSettingsTile(
                icon: Icons.handshake_outlined,
                title: 'Anticipi',
                subtitle:
                    '${state.advances.where((item) => item.closedKind == null && state.advanceRemainingCents(item.id) > 0).length} aperti · persone e storico',
                onTap: () => _open(context, const AdvancesScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.category_outlined,
                title: 'Categorie',
                subtitle:
                    '${state.categories.length} categorie · preferite e quick slot',
                onTap: () => _open(context, const CategoryManagementScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.auto_fix_high_outlined,
                title: 'Regole automatiche',
                subtitle: '${state.rules.length} regole · priorità e test',
                onTap: () => _open(context, const RulesManagementScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.dashboard_customize_outlined,
                title: 'Personalizza Home',
                subtitle: 'Mostra, nascondi, ridimensiona e riordina i widget',
                onTap: () => _open(context, const DashboardCustomizerScreen()),
              ),
              BalynSettingsTile(
                icon: Icons.widgets_outlined,
                title: 'Widget Android',
                subtitle: 'Saldo, Quick Capture, importi rapidi e riepilogo configurabili',
                onTap: () => _open(context, const AndroidWidgetsScreen()),
              ),
            ],
          ),
          BalynSettingsGroup(
            title: 'Dati',
            accent: const Color(0xFF4C749C),
            children: [
              BalynSettingsTile(
                icon: Icons.folder_zip_outlined,
                title: 'Backup, CSV e ripristino',
                subtitle: 'Backup completo con allegati · import portabile',
                onTap: () => _open(context, const DataManagementScreen()),
              ),
            ],
          ),
          BalynSettingsGroup(
            title: 'Comportamento',
            accent: const Color(0xFF7664BE),
            children: [
              BalynSettingsSwitch(
                icon: Icons.help_outline_rounded,
                title: const Text('Permetti “Non assegnato”'),
                subtitle: const Text(
                  'Registra velocemente e assegna il conto in seguito.',
                ),
                value: state.allowUnassigned,
                onChanged: (value) =>
                    _setBoolSetting(state, 'allow_unassigned', value),
              ),
              BalynSettingsSwitch(
                icon: Icons.swap_horiz_rounded,
                title: const Text('Trasferimenti nelle statistiche'),
                value: state.showTransfersInAnalytics,
                onChanged: (value) =>
                    _setBoolSetting(state, 'show_transfers_analytics', value),
              ),
              BalynSettingsSwitch(
                icon: Icons.vibration_rounded,
                title: const Text('Feedback aptico'),
                subtitle: const Text(
                  'Vibrazione leggera su navigazione, azioni rapide e impostazioni.',
                ),
                value: state.haptics,
                onChanged: (value) => _setHaptics(state, value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _open(BuildContext context, Widget page) {
    final state = AppScope.of(context);
    unawaited(HapticService.light(enabled: state.haptics));
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  Future<void> _setHideBalance(AppState state, bool value) async {
    await HapticService.light(enabled: state.haptics);
    await state.setHideBalance(value);
  }

  Future<void> _setBoolSetting(AppState state, String key, bool value) async {
    await HapticService.light(enabled: state.haptics);
    await state.setSetting(key, value ? '1' : '0');
  }

  Future<void> _setHaptics(AppState state, bool value) async {
    // Give one final confirmation when disabling, and immediate proof when
    // enabling, before persisting the new preference.
    await HapticService.medium(enabled: state.haptics || value);
    await state.setSetting('haptics', value ? '1' : '0');
  }

  Future<void> _pickLanguage(BuildContext context, AppState state) async {
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(sheetContext).height * .78,
          ),
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              Text(
                'Lingua',
                style: Theme.of(sheetContext).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  state.languageCode == AppI18n.systemCode
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                ),
                title: const Text('Sistema'),
                subtitle: Text(
                  'Segue la lingua del dispositivo · ${AppI18n.currentLanguage.nativeName}',
                ),
                onTap: () => Navigator.pop(sheetContext, AppI18n.systemCode),
              ),
              const Divider(height: 1),
              ...AppI18n.languages.map(
                (language) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    state.languageCode == language.code
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                  ),
                  title: Text(language.nativeName),
                  subtitle: language.code == 'en'
                      ? null
                      : Text(language.englishName),
                  onTap: () => Navigator.pop(sheetContext, language.code),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (selected != null && selected != state.languageCode) {
      await HapticService.light(enabled: state.haptics);
      await state.setLanguageCode(selected);
    }
  }

  Future<void> _pickCurrency(BuildContext context, AppState state) async {
    const currencies = ['EUR', 'USD', 'GBP', 'CHF'];
    final selected = await showModalBottomSheet<String>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: currencies
              .map(
                (value) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    value == state.currency
                        ? Icons.check_circle_rounded
                        : Icons.circle_outlined,
                  ),
                  title: Text(value),
                  onTap: () => Navigator.pop(sheetContext, value),
                ),
              )
              .toList(),
        ),
      ),
    );
    if (selected != null) {
      await HapticService.light(enabled: state.haptics);
      await state.setSetting('currency', selected);
    }
  }

  Future<void> _pickWeekStart(BuildContext context, AppState state) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final entry in const [
              (DateTime.monday, 'Lunedì'),
              (DateTime.sunday, 'Domenica'),
            ])
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  entry.$1 == state.weekStart
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                ),
                title: Text(entry.$2),
                onTap: () => Navigator.pop(sheetContext, entry.$1),
              ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await HapticService.light(enabled: state.haptics);
      await state.setSetting('week_start', selected.toString());
    }
  }

  Future<void> _pickFinancialMonthStart(
    BuildContext context,
    AppState state,
  ) async {
    final selected = await showModalBottomSheet<int>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Inizio mese finanziario',
              style: Theme.of(sheetContext).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 260,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (var day = 1; day <= 28; day++)
                      ChoiceChip(
                        label: Text('$day'),
                        selected: state.financialMonthStart == day,
                        onSelected: (_) => Navigator.pop(sheetContext, day),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await HapticService.light(enabled: state.haptics);
      await state.setSetting('financial_month_start', selected.toString());
    }
  }

  Future<void> _pickTheme(BuildContext context, AppState state) async {
    final selected = await showModalBottomSheet<AppThemePreference>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tema', style: Theme.of(sheetContext).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...AppThemePreference.values.map(
              (value) => ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 10,
                leading: Icon(
                  value == state.themePreference
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                ),
                title: Text(switch (value) {
                  AppThemePreference.system => 'Sistema',
                  AppThemePreference.light => 'Chiaro',
                  AppThemePreference.dark => 'Scuro',
                }),
                onTap: () => Navigator.pop(sheetContext, value),
              ),
            ),
          ],
        ),
      ),
    );
    if (selected != null) {
      await HapticService.light(enabled: state.haptics);
      await state.setThemePreference(selected);
    }
  }
}

class ShaderAppearanceSettingsScreen extends StatelessWidget {
  const ShaderAppearanceSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Gradient animati')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 20),
            child: Text(
              'Scegli dove usare il materiale shader animato. Disattivando una voce, quell’elemento torna al suo colore piatto originale.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          BalynSettingsGroup(
            title: 'Elementi animati',
            accent: const Color(0xFF8651B2),
            children: [
              BalynSettingsSwitch(
                icon: Icons.interests_outlined,
                title: const Text('Icone'),
                subtitle: const Text('Icone colorate e azioni rapide'),
                value: state.shaderIcons,
                onChanged: (value) =>
                    _setShaderSetting(state, 'shader_icons', value),
              ),
              BalynSettingsSwitch(
                icon: Icons.donut_large_rounded,
                title: const Text('Torte'),
                subtitle: const Text('Donut e grafici colorati'),
                value: state.shaderCharts,
                onChanged: (value) =>
                    _setShaderSetting(state, 'shader_charts', value),
              ),
              BalynSettingsSwitch(
                icon: Icons.text_fields_rounded,
                title: const Text('Testo'),
                subtitle: const Text('Importi e testi semanticamente colorati'),
                value: state.shaderText,
                onChanged: (value) =>
                    _setShaderSetting(state, 'shader_text', value),
              ),
              BalynSettingsSwitch(
                icon: Icons.linear_scale_rounded,
                title: const Text('Barre'),
                subtitle: const Text('Progress bar e indicatori lineari'),
                value: state.shaderBars,
                onChanged: (value) =>
                    _setShaderSetting(state, 'shader_bars', value),
              ),
              BalynSettingsSwitch(
                icon: Icons.wallpaper_rounded,
                title: const Text('Sfondo'),
                subtitle: const Text(
                  'Onde liquide lente sul nero o sul bianco',
                ),
                value: state.shaderBackground,
                onChanged: (value) =>
                    _setShaderSetting(state, 'shader_background', value),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _setShaderSetting(AppState state, String key, bool value) async {
    await HapticService.light(enabled: state.haptics);
    await state.setSetting(key, value ? '1' : '0');
  }
}
