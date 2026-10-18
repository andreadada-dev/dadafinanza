import 'package:balyn/l10n/localized_material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../l10n/app_i18n.dart';
import '../l10n/balyn_onboarding_l10n.dart';
import '../theme/balyn_palette.dart';
import '../widgets/balyn_onboarding_feature_accordion.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/balyn_onboarding_velvet.dart';

/// Three-page, first-install-only flow. Uses Balyn's real account and settings APIs.
class BalynOnboardingFlow extends StatefulWidget {
  const BalynOnboardingFlow({required this.onFinished, super.key});
  final VoidCallback onFinished;
  @override
  State<BalynOnboardingFlow> createState() => _BalynOnboardingFlowState();
}

class _BalynOnboardingFlowState extends State<BalynOnboardingFlow> {
  final GlobalKey<IntroductionScreenState> _introKey =
      GlobalKey<IntroductionScreenState>();
  final TextEditingController _name = TextEditingController(
    text: 'Conto principale',
  );
  int _step = 0;
  bool _saving = false;
  bool _skipping = false;
  String _language = 'it';
  String _currency = 'EUR';
  AccountType _type = AccountType.checking;
  int _color = 0xFF7955EB;
  String _iconKey = 'wallet';
  static const colors = <int>[
    0xFF7955EB,
    0xFF3573ED,
    0xFF1F9D8A,
    0xFFEF853B,
    0xFFD55686,
  ];

  String _t(String it, String en) {
    const keys = <String, String>{
      "Inserisci il nome del conto": "requiredName",
      "Le tue finanze, più semplici": "welcomeTitle",
      "Tutti i tuoi conti, movimenti e obiettivi in un solo posto. I dati restano sul dispositivo.": "welcomeSubtitle",
      "Lingua": "language",
      "Valuta": "currency",
      "Crea il tuo primo conto": "accountTitle",
      "Il saldo parte da zero e puoi cambiarlo in seguito.": "accountSubtitle",
      "Nome conto": "nameLabel",
      "Tipo": "typeLabel",
      "Icona del conto": "accountIcon",
      "Colore del conto": "accountColor",
      "Ecco come funziona": "howTitle",
      "Quattro sezioni, tutte collegate tra loro.": "howSubtitle",
      "Salta": "skip",
      "Avanti": "next",
      "Inizia": "done",
      "Indietro": "back",
    };
    final key = keys[it];
    return key == null
        ? (_language == 'it' ? it : en)
        : BalynOnboardingL10n.tr(_language, key);
  }

  void _changeLanguage(String? code) {
    if (code == null || code == _language) return;
    final oldName = BalynOnboardingL10n.tr(_language, 'defaultName');
    if (_name.text == oldName || _name.text == 'Conto principale') {
      _name.text = BalynOnboardingL10n.tr(code, 'defaultName');
    }
    setState(() => _language = code);
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _complete({bool skip = false}) async {
    if (_saving) return;
    if (!skip && _name.text.trim().isEmpty) {
      _introKey.currentState?.animateScroll(1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('Inserisci il nome del conto', 'Enter your account name'),
          ),
        ),
      );
      return;
    }
    setState(() => _saving = true);
    final state = AppScope.of(context);
    try {
      if (!skip) {
        await state.setLanguageCode(_language);
        await state.setSetting('currency', _currency);
        if (state.userAccounts.isEmpty) {
          await state.addAccount(
            name: _name.text.trim(),
            type: _type,
            colorValue: _color,
            iconKey: _iconKey,
          );
        }
      }
      await state.setSetting('onboarding_completed', '1');
      if (mounted) widget.onFinished();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _skipping = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _tile(IconData icon, String label, Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: BalynPalette.darkSurface,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Row(
      children: [
        Icon(icon, color: Colors.white),
        const SizedBox(width: 11),
        Text(label, style: const TextStyle(color: Colors.white)),
        const Spacer(),
        Flexible(child: child),
      ],
    ),
  );

  Widget _page({
    required Widget illustration,
    required String title,
    required String subtitle,
    required Widget content,
    bool compact = false,
  }) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 25),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: compact ? 82 : 120, child: Center(child: illustration)),
            const SizedBox(height: 13),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 27,
                height: 1.18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: BalynPalette.darkMuted,
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            content,
          ],
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    const options = ['EUR', 'USD', 'GBP', 'CHF'];
    return Scaffold(
      backgroundColor: BalynPalette.darkCanvas,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          const Positioned.fill(child: BalynOnboardingVelvet()),
          const Positioned.fill(
            child: ColoredBox(color: Color(0xC5101018)),
          ),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 13),
                  child: Row(
                    children: [
                      const Text(
                        'Balyn',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${_step + 1}/3',
                        style: const TextStyle(color: BalynPalette.darkMuted),
                      ),
                      const SizedBox(width: 17),
                      if (!_saving)
                        InkWell(
                          key: const ValueKey('onboarding-skip'),
                          onTap: () => setState(() => _skipping = true),
                          child: SizedBox(
                            width: 62,
                            height: 54,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                TweenAnimationBuilder<double>(
                                  tween: Tween<double>(
                                    begin: 0,
                                    end: _skipping ? 1 : 0,
                                  ),
                                  duration: reduced
                                      ? Duration.zero
                                      : const Duration(milliseconds: 880),
                                  curve: Curves.easeInOutCubic,
                                  onEnd: () {
                                    if (_skipping && mounted)
                                      _complete(skip: true);
                                  },
                                  builder: (_, value, __) => SizedBox.square(
                                    dimension: 48,
                                    child: CircularProgressIndicator(
                                      value: value,
                                      strokeWidth: 3,
                                      backgroundColor: BalynPalette.darkSurfaceHigh,
                                      valueColor: const AlwaysStoppedAnimation(
                                        BalynPalette.accentTextDark,
                                      ),
                                    ),
                                  ),
                                ),
                                Text(
                                  _t('Salta', 'Skip'),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Expanded(
                  child: IntroductionScreen(
                    key: _introKey,
                    rawPages: [
                      _page(
                        illustration: const _CircleArt(
                          icon: Icons.auto_graph_rounded,
                        ),
                        title: _t(
                          'Le tue finanze, più semplici',
                          'Your finances, simplified',
                        ),
                        subtitle: _t(
                          'Tutti i tuoi conti, movimenti e obiettivi in un solo posto. '
                              'I dati restano sul dispositivo.',
                          'Your accounts, activity and goals in one place. '
                              'Your data stays on your device.',
                        ),
                        content: Column(
                          children: [
                            _tile(
                              Icons.language_rounded,
                              _t('Lingua', 'Language'),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _language,
                                dropdownColor: BalynPalette.darkSurfaceHigh,
                                style: const TextStyle(color: BalynPalette.darkText),
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (final l in AppI18n.languages)
                                    DropdownMenuItem(
                                      value: l.code,
                                      child: Text(l.nativeName),
                                    ),
                                ],
                                onChanged: _changeLanguage,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _tile(
                              Icons.currency_exchange_rounded,
                              _t('Valuta', 'Currency'),
                              DropdownButton<String>(
                                isExpanded: true,
                                value: _currency,
                                dropdownColor: BalynPalette.darkSurfaceHigh,
                                style: const TextStyle(color: Colors.white),
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (final v in options)
                                    DropdownMenuItem(value: v, child: Text(v)),
                                ],
                                onChanged: (v) =>
                                    setState(() => _currency = v ?? 'EUR'),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _page(
                        illustration: _CircleArt(
                          icon: accountIcon(_iconKey),
                          color: Color(_color),
                        ),
                        title: _t(
                          'Crea il tuo primo conto',
                          'Create your first account',
                        ),
                        subtitle: _t(
                          'Il saldo parte da zero e puoi cambiarlo in seguito.',
                          'Your balance starts at zero and can be updated later.',
                        ),
                        content: Column(
                          children: [
                            TextField(
                              controller: _name,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: _t('Nome conto', 'Account name'),
                                labelStyle: const TextStyle(
                                  color: BalynPalette.darkMuted,
                                ),
                                filled: true,
                                fillColor: BalynPalette.darkSurface,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(17),
                                  borderSide: BorderSide.none,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _tile(
                              Icons.account_balance_outlined,
                              _t('Tipo', 'Type'),
                              DropdownButton<AccountType>(
                                isExpanded: true,
                                value: _type,
                                dropdownColor: BalynPalette.darkSurfaceHigh,
                                style: const TextStyle(color: Colors.white),
                                underline: const SizedBox.shrink(),
                                items: [
                                  for (final v in [
                                    AccountType.checking,
                                    AccountType.cash,
                                    AccountType.card,
                                    AccountType.savings,
                                    AccountType.prepaid,
                                    AccountType.investment,
                                  ])
                                    DropdownMenuItem(
                                      value: v,
                                      child: Text(BalynOnboardingL10n.accountType(_language, v.name)),
                                    ),
                                ],
                                onChanged: (v) => setState(() {
                                  _type = v ?? AccountType.checking;
                                  _iconKey = switch (_type) {
                                    AccountType.cash => 'cash',
                                    AccountType.checking => 'bank',
                                    AccountType.savings => 'savings',
                                    AccountType.card ||
                                    AccountType.prepaid => 'card',
                                    AccountType.investment => 'investment',
                                    AccountType.other => 'wallet',
                                  };
                                }),
                              ),
                            ),
                            const SizedBox(height: 18),
                            Text(
                              _t('Icona del conto', 'Account icon'),
                              textAlign: TextAlign.center,
                              style: const TextStyle(color: BalynPalette.darkMuted),
                            ),
                            const SizedBox(height: 9),
                            Wrap(
                              alignment: WrapAlignment.center,
                              spacing: 9,
                              runSpacing: 9,
                              children: [
                                for (final key in const [
                                  'wallet',
                                  'bank',
                                  'card',
                                  'cash',
                                  'savings',
                                  'investment',
                                ])
                                  InkWell(
                                    key: ValueKey('intro-icon-$key'),
                                    borderRadius: BorderRadius.circular(15),
                                    onTap: () => setState(() => _iconKey = key),
                                    child: Container(
                                      width: 47,
                                      height: 45,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: _iconKey == key
                                            ? Color(
                                                _color,
                                              ).withValues(alpha: .26)
                                            : Colors.white.withValues(
                                                alpha: .07,
                                              ),
                                        borderRadius: BorderRadius.circular(15),
                                        border: Border.all(
                                          color: _iconKey == key
                                              ? Color(_color)
                                              : BalynPalette.darkSurface,
                                        ),
                                      ),
                                      child: Icon(
                                        accountIcon(key),
                                        color: Colors.white,
                                        size: 23,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _t('Colore del conto', 'Account color'),
                              style: const TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 9),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                for (final c in colors)
                                  InkWell(
                                    onTap: () => setState(() => _color = c),
                                    child: Container(
                                      width: 43,
                                      height: 43,
                                      decoration: BoxDecoration(
                                        color: Color(c),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: _color == c ? 3 : 0,
                                        ),
                                      ),
                                      child: _color == c
                                          ? const Icon(
                                              Icons.check_rounded,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      _page(
                        illustration: const Icon(
                          Icons.dashboard_customize_outlined,
                          size: 45,
                          color: BalynPalette.accentTextDark,
                        ),
                        title: _t('Ecco come funziona', 'How Balyn works'),
                        subtitle: _t(
                          'Quattro sezioni, tutte collegate tra loro.',
                          'Four connected sections, one clear view.',
                        ),
                        compact: true,
                        content: BalynOnboardingFeatureAccordion(
                          languageCode: _language,
                        ),
                      ),
                    ],
                    animationDuration: 460,
                    curve: Curves.easeOutCubic,
                    globalBackgroundColor: Colors.transparent,
                    freeze: _saving || _skipping,
                    scrollPhysics: const BouncingScrollPhysics(),
                    showNextButton: true,
                    showBackButton: true,
                    showDoneButton: true,
                    showSkipButton: false,
                    isProgressTap: false,
                    onChange: (page) {
                      if (_step != page && mounted) {
                        setState(() => _step = page);

                      }
                    },
                    onDone: () => _complete(),
                    next: Text(
                      _t('Avanti', 'Continue'),
                      key: const ValueKey('onboarding-next'),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    done: _saving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _t('Inizia', 'Get started'),
                            key: const ValueKey('onboarding-done'),
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                    back: Text(
                      _t('Indietro', 'Back'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    backStyle: TextButton.styleFrom(
                      foregroundColor: Colors.white70,
                      minimumSize: const Size(65, 48),
                    ),
                    nextStyle: TextButton.styleFrom(
                      backgroundColor: BalynPalette.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(106, 51),
                      shape: const StadiumBorder(),
                    ),
                    doneStyle: TextButton.styleFrom(
                      backgroundColor: BalynPalette.accent,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(116, 51),
                      shape: const StadiumBorder(),
                    ),
                    // The thin worm stretches between dots on every page change.
                    customProgress: AnimatedSmoothIndicator(
                      activeIndex: _step,
                      count: 3,
                      effect: const WormEffect(
                        type: WormType.thin,
                        dotWidth: 9,
                        dotHeight: 9,
                        spacing: 10,
                        radius: 8,
                        dotColor: BalynPalette.darkSurfaceHigh,
                        activeDotColor: BalynPalette.accentTextDark,
                      ),
                    ),
                    controlsPadding: const EdgeInsets.symmetric(
                      horizontal: 21,
                      vertical: 11,
                    ),
                    controlsMargin: const EdgeInsets.only(bottom: 12),
                    hideBottomOnKeyboard: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleArt extends StatelessWidget {
  const _CircleArt({required this.icon, this.color = BalynPalette.accentTextDark});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const ValueKey('introduction-account-preview'),
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOut,
    alignment: Alignment.center,
    width: 102,
    height: 102,
    decoration: BoxDecoration(
      color: BalynPalette.darkSurface,
      borderRadius: BorderRadius.circular(26),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(icon, key: ValueKey(icon), size: 53, color: color),
    ),
  );
}

