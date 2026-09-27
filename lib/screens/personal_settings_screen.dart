import 'dart:async';

import 'package:dadafinanza/l10n/localized_material.dart';

import '../app_state.dart';
import '../l10n/app_i18n.dart';
import '../main.dart';
import '../models/models.dart';
import '../services/haptic_service.dart';
import '../widgets/ui_helpers.dart';
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
  const _BrandHeader();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ExcludeSemantics(
        child: _DadaFinanzaMark(
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      const SizedBox(height: 10),
      Text(
        'DadaFinanza',
        style: Theme.of(
          context,
        ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
    ],
  );
}

class _DadaFinanzaMark extends StatelessWidget {
  const _DadaFinanzaMark({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 88,
    child: CustomPaint(
      painter: _DadaFinanzaMarkPainter(color),
    ),
  );
}

class _DadaFinanzaMarkPainter extends CustomPainter {
  const _DadaFinanzaMarkPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.shortestSide / 512;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    canvas.save();
    canvas.scale(scale, scale);

    final back = Path()
      ..moveTo(401.22, 134.717)
      ..cubicTo(394.292, 134.621, 387.17, 134.622, 379.976, 134.623)
      ..lineTo(228.985, 134.623)
      ..cubicTo(208.562, 134.621, 188.715, 134.618, 172.288, 136.827)
      ..cubicTo(153.752, 139.319, 132.573, 145.391, 114.982, 162.982)
      ..cubicTo(97.3898, 180.574, 91.3183, 201.753, 88.8263, 220.289)
      ..cubicTo(86.6177, 236.716, 86.6196, 256.563, 86.6218, 276.988)
      ..lineTo(86.6218, 331.148)
      ..cubicTo(86.6211, 338.243, 86.6203, 345.268, 86.7123, 352.104)
      ..cubicTo(85.1447, 352.026, 83.6289, 351.934, 82.1663, 351.82)
      ..cubicTo(73.132, 351.123, 64.1279, 349.586, 55.3809, 345.418)
      ..cubicTo(40.3443, 338.253, 28.2279, 326.137, 21.0628, 311.1)
      ..cubicTo(16.8944, 302.352, 15.3576, 293.349, 14.6604, 284.316)
      ..cubicTo(13.9996, 275.749, 13.9998, 265.364, 14.0003, 253.329)
      ..lineTo(14.0001, 181.442)
      ..cubicTo(13.9988, 159.983, 13.9979, 141.494, 15.9886, 126.687)
      ..cubicTo(18.1219, 110.82, 22.9327, 95.6096, 35.2701, 83.2723)
      ..cubicTo(47.6072, 70.9352, 62.8173, 66.1244, 78.6849, 63.991)
      ..cubicTo(93.4911, 62.0003, 111.981, 62.0013, 133.439, 62.0025)
      ..lineTo(317.526, 62.0013)
      ..cubicTo(327.736, 61.9923, 336.532, 61.9846, 344.358, 63.7141)
      ..cubicTo(371.947, 69.8125, 393.495, 91.3597, 399.593, 118.949)
      ..cubicTo(400.665, 123.797, 401.069, 129.018, 401.22, 134.717)
      ..close();

    final frontOuter = Path()
      ..moveTo(110.826, 227.152)
      ..cubicTo(110.826, 189.552, 143.319, 159.071, 183.4, 159.071)
      ..lineTo(425.314, 159.071)
      ..cubicTo(465.396, 159.071, 497.888, 189.552, 497.888, 227.152)
      ..lineTo(497.888, 381.468)
      ..cubicTo(497.888, 419.069, 465.396, 449.549, 425.314, 449.549)
      ..lineTo(183.4, 449.549)
      ..cubicTo(143.319, 449.549, 110.826, 419.069, 110.826, 381.468)
      ..lineTo(110.826, 227.152)
      ..close();

    final slot = Path()
      ..moveTo(183.4, 213.536)
      ..cubicTo(175.384, 213.536, 168.885, 219.632, 168.885, 227.152)
      ..lineTo(168.885, 381.468)
      ..cubicTo(168.885, 388.988, 175.384, 395.085, 183.4, 395.085)
      ..cubicTo(191.417, 395.085, 197.915, 388.988, 197.915, 381.468)
      ..lineTo(197.915, 227.152)
      ..cubicTo(197.915, 219.632, 191.417, 213.536, 183.4, 213.536)
      ..close();

    final bug = Path()
      ..moveTo(290.429, 235.679)
      ..cubicTo(284.76, 230.361, 275.571, 230.361, 269.903, 235.679)
      ..cubicTo(264.234, 240.996, 264.234, 249.618, 269.903, 254.935)
      ..lineTo(293.043, 276.642)
      ..cubicTo(287.934, 284.752, 285.004, 294.209, 285.004, 304.31)
      ..cubicTo(285.004, 314.412, 287.934, 323.868, 293.043, 331.978)
      ..lineTo(269.903, 353.686)
      ..cubicTo(264.234, 359.004, 264.234, 367.624, 269.903, 372.941)
      ..cubicTo(275.571, 378.259, 284.76, 378.259, 290.429, 372.941)
      ..lineTo(313.569, 351.233)
      ..cubicTo(322.214, 356.026, 332.295, 358.775, 343.063, 358.775)
      ..cubicTo(353.832, 358.775, 363.913, 356.026, 372.558, 351.233)
      ..lineTo(395.698, 372.941)
      ..cubicTo(401.367, 378.259, 410.555, 378.259, 416.224, 372.941)
      ..cubicTo(421.893, 367.624, 421.893, 359.004, 416.224, 353.686)
      ..lineTo(393.084, 331.978)
      ..cubicTo(398.193, 323.868, 401.123, 314.412, 401.123, 304.31)
      ..cubicTo(401.123, 294.209, 398.193, 284.752, 393.084, 276.642)
      ..lineTo(416.224, 254.935)
      ..cubicTo(421.893, 249.618, 421.893, 240.996, 416.224, 235.679)
      ..cubicTo(410.555, 230.361, 401.367, 230.361, 395.698, 235.679)
      ..lineTo(372.558, 257.386)
      ..cubicTo(363.913, 252.595, 353.832, 249.846, 343.063, 249.846)
      ..cubicTo(332.295, 249.846, 322.214, 252.595, 313.569, 257.386)
      ..lineTo(290.429, 235.679)
      ..close();

    final holes = Path.combine(PathOperation.union, slot, bug);
    final front = Path.combine(PathOperation.difference, frontOuter, holes);

    canvas.drawPath(back, paint);
    canvas.drawPath(front, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _DadaFinanzaMarkPainter oldDelegate) =>
      oldDelegate.color != color;
}

class PersonalSettingsScreen extends StatelessWidget {
  const PersonalSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Impostazioni')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        children: [
          const _BrandHeader(),
          const SizedBox(height: 28),
          const SectionTitle('Aspetto'),
          _Link(
            icon: Icons.contrast_rounded,
            title: 'Tema',
            subtitle: switch (state.themePreference) {
              AppThemePreference.system => 'Sistema',
              AppThemePreference.light => 'Chiaro',
              AppThemePreference.dark => 'Scuro',
            },
            onTap: () => _pickTheme(context, state),
          ),
          _Link(
            icon: Icons.language_rounded,
            title: 'Lingua',
            subtitle: AppI18n.preferenceLabel(state.languageCode),
            onTap: () => _pickLanguage(context, state),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.visibility_off_outlined),
            title: const Text('Nascondi saldi nell’app'),
            subtitle: const Text(
              'Nasconde gli importi finanziari nelle viste principali.',
            ),
            value: state.hideBalance,
            onChanged: (value) => _setHideBalance(state, value),
          ),
          const SizedBox(height: 32),
          const SectionTitle('Generali'),
          _Link(
            icon: Icons.account_balance_wallet_outlined,
            title: 'Conti',
            subtitle: '${state.userAccounts.length} conti',
            onTap: () => _open(context, const AccountManagementScreen()),
          ),
          _Link(
            icon: Icons.currency_exchange_rounded,
            title: 'Valuta principale',
            subtitle: state.currency,
            onTap: () => _pickCurrency(context, state),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.pin_outlined),
            title: const Text('Mostra centesimi'),
            value: state.showCents,
            onChanged: (value) => _setBoolSetting(state, 'show_cents', value),
          ),
          _Link(
            icon: Icons.calendar_view_week_outlined,
            title: 'Primo giorno settimana',
            subtitle: state.weekStart == DateTime.sunday
                ? 'Domenica'
                : 'Lunedì',
            onTap: () => _pickWeekStart(context, state),
          ),
          _Link(
            icon: Icons.calendar_month_outlined,
            title: 'Inizio mese finanziario',
            subtitle: 'Giorno ${state.financialMonthStart}',
            onTap: () => _pickFinancialMonthStart(context, state),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.warning_amber_rounded),
            title: const Text('Conferma eliminazioni'),
            subtitle: const Text(
              'Richiede conferma prima di eliminare un movimento.',
            ),
            value: state.confirmDelete,
            onChanged: (value) =>
                _setBoolSetting(state, 'confirm_delete', value),
          ),
          const SizedBox(height: 32),
          const SectionTitle('Privacy locale'),
          _Link(
            icon: Icons.fingerprint_rounded,
            title: 'Blocco e schermata recenti',
            subtitle: 'Biometria o PIN · timeout · protezione screenshot',
            onTap: () => _open(context, const LocalPrivacyScreen()),
          ),
          _Link(
            icon: Icons.policy_outlined,
            title: 'Privacy e dati',
            subtitle: 'Dati locali, permessi, backup e servizi di sistema',
            onTap: () => _open(context, const PrivacyPolicyScreen()),
          ),
          _Link(
            icon: Icons.notifications_none_rounded,
            title: 'Notifiche locali',
            subtitle: 'Scadenze, anticipi, budget, obiettivi e cash-flow',
            onTap: () => _open(context, const NotificationSettingsScreen()),
          ),
          const SizedBox(height: 32),
          const SectionTitle('Inserimento'),
          _Link(
            icon: Icons.mic_none_rounded,
            title: 'Inserimento vocale',
            subtitle: 'Parser locale · on-device quando disponibile',
            onTap: () => _open(context, const VoiceSettingsScreen()),
          ),
          _Link(
            icon: Icons.bolt_outlined,
            title: 'Smart Suggestions',
            subtitle: state.smartSuggestionsEnabled
                ? '${state.learnedPatterns.length} pattern appresi'
                : 'Disattivate',
            onTap: () => _open(context, const SmartSuggestionsSettingsScreen()),
          ),
          _Link(
            icon: Icons.bookmark_add_outlined,
            title: 'Preset rapidi',
            subtitle: 'Caffè, benzina, spesa e azioni personalizzate',
            onTap: () => _open(context, const PresetManagementScreen()),
          ),
          const SizedBox(height: 32),
          const SectionTitle('Organizzazione'),
          _Link(
            icon: Icons.handshake_outlined,
            title: 'Anticipi',
            subtitle:
                '${state.advances.where((item) => item.closedKind == null && state.advanceRemainingCents(item.id) > 0).length} aperti · persone e storico',
            onTap: () => _open(context, const AdvancesScreen()),
          ),
          _Link(
            icon: Icons.category_outlined,
            title: 'Categorie',
            subtitle:
                '${state.categories.length} categorie · preferite e quick slot',
            onTap: () => _open(context, const CategoryManagementScreen()),
          ),
          _Link(
            icon: Icons.auto_fix_high_outlined,
            title: 'Regole automatiche',
            subtitle: '${state.rules.length} regole · priorità e test',
            onTap: () => _open(context, const RulesManagementScreen()),
          ),
          _Link(
            icon: Icons.dashboard_customize_outlined,
            title: 'Personalizza Home',
            subtitle: 'Mostra, nascondi, ridimensiona e riordina i widget',
            onTap: () => _open(context, const DashboardCustomizerScreen()),
          ),
          _Link(
            icon: Icons.widgets_outlined,
            title: 'Widget Android',
            subtitle:
                'Saldo, Quick Capture, importi rapidi e riepilogo configurabili',
            onTap: () => _open(context, const AndroidWidgetsScreen()),
          ),
          const SizedBox(height: 32),
          const SectionTitle('Dati'),
          _Link(
            icon: Icons.folder_zip_outlined,
            title: 'Backup, CSV e ripristino',
            subtitle: 'Backup completo con allegati · import portabile',
            onTap: () => _open(context, const DataManagementScreen()),
          ),
          const SizedBox(height: 32),
          const SectionTitle('Comportamento'),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.help_outline_rounded),
            title: const Text('Permetti “Non assegnato”'),
            subtitle: const Text(
              'Registra velocemente e assegna il conto in seguito.',
            ),
            value: state.allowUnassigned,
            onChanged: (value) =>
                _setBoolSetting(state, 'allow_unassigned', value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.swap_horiz_rounded),
            title: const Text('Trasferimenti nelle statistiche'),
            value: state.showTransfersInAnalytics,
            onChanged: (value) =>
                _setBoolSetting(state, 'show_transfers_analytics', value),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.vibration_rounded),
            title: const Text('Feedback aptico'),
            subtitle: const Text(
              'Vibrazione leggera su navigazione, azioni rapide e impostazioni.',
            ),
            value: state.haptics,
            onChanged: (value) => _setHaptics(state, value),
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

class _Link extends StatelessWidget {
  const _Link({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    contentPadding: EdgeInsets.zero,
    minVerticalPadding: 12,
    leading: Icon(icon),
    title: Text(title),
    subtitle: Text(subtitle),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}
