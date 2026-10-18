import 'package:balyn/l10n/localized_material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import '../l10n/app_i18n.dart';
import '../main.dart';
import '../models/models.dart';
import '../widgets/ui_helpers.dart';

/// Three-page, first-install-only flow. Uses Balyn's real account and settings APIs.
class BalynOnboardingFlow extends StatefulWidget {
  const BalynOnboardingFlow({required this.onFinished, super.key});
  final VoidCallback onFinished;
  @override
  State<BalynOnboardingFlow> createState() => _BalynOnboardingFlowState();
}

class _BalynOnboardingFlowState extends State<BalynOnboardingFlow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tourController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 920),
  );

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
  int _color = 0xFF6539E8;
  String _iconKey = 'wallet';
  static const colors = <int>[
    0xFF6539E8,
    0xFF3573ED,
    0xFF1F9D8A,
    0xFFEF853B,
    0xFFD55686,
  ];

  String _t(String it, String en) => _language == 'it' ? it : en;

  @override
  void dispose() {
    _tourController.dispose();
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  Widget _tile(IconData icon, String label, Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .13),
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

  Widget _tour(int index, IconData icon, String title, String subtitle) {
    const accent = [
      Color(0xFFFFC2ED),
      Color(0xFFAACDFF),
      Color(0xFFB3F5D9),
      Color(0xFFFFD8A3),
    ];
    final color = accent[index];
    final begin = index * .14;
    final end = (begin + .57).clamp(0.0, 1.0);
    return AnimatedBuilder(
      animation: _tourController,
      builder: (context, child) {
        final progress = Curves.easeOutCubic.transform(
          ((_tourController.value - begin) / (end - begin)).clamp(0.0, 1.0),
        );
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, 25 * (1 - progress)),
            child: Transform.scale(scale: .965 + .035 * progress, child: child),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Semantics(
          label: '$title. $subtitle',
          child: Container(
            key: ValueKey('onboarding-tour-$index'),
            padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .095),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: .15)),
            ),
            child: Row(
              children: [
                Container(
                  height: 47,
                  width: 47,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(icon, color: color, size: 25),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Color(0xFFE0D9ED),
                          fontSize: 12,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: color.withValues(alpha: .7),
                  size: 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _page({
    required Widget illustration,
    required String title,
    required String subtitle,
    required Widget content,
  }) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
    child: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 132, child: Center(child: illustration)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
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
                color: Color(0xFFCEC9D8),
                height: 1.45,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 28),
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
      backgroundColor: const Color(0xFF211248),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
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
                    style: const TextStyle(color: Colors.white70),
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
                                if (_skipping && mounted) _complete(skip: true);
                              },
                              builder: (_, value, __) => SizedBox.square(
                                dimension: 48,
                                child: CircularProgressIndicator(
                                  value: value,
                                  strokeWidth: 3,
                                  backgroundColor: Colors.white24,
                                  valueColor: const AlwaysStoppedAnimation(
                                    Color(0xFFFFD5EE),
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
                            dropdownColor: const Color(0xFF392566),
                            style: const TextStyle(color: Colors.white),
                            underline: const SizedBox.shrink(),
                            items: [
                              for (final l in AppI18n.languages)
                                DropdownMenuItem(
                                  value: l.code,
                                  child: Text(l.nativeName),
                                ),
                            ],
                            onChanged: (v) =>
                                setState(() => _language = v ?? 'it'),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _tile(
                          Icons.currency_exchange_rounded,
                          _t('Valuta', 'Currency'),
                          DropdownButton<String>(
                            isExpanded: true,
                            value: _currency,
                            dropdownColor: const Color(0xFF392566),
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
                            labelStyle: const TextStyle(color: Colors.white70),
                            filled: true,
                            fillColor: Colors.white12,
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
                            dropdownColor: const Color(0xFF392566),
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
                                  child: Text(v.label),
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
                          style: const TextStyle(color: Colors.white70),
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
                                        ? Color(_color).withValues(alpha: .26)
                                        : Colors.white.withValues(alpha: .07),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: _iconKey == key
                                          ? Color(_color)
                                          : Colors.white12,
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
                    illustration: _TourOrbitIllustration(
                      progress: _tourController,
                    ),
                    title: _t('Ecco come funziona', 'How Balyn works'),
                    subtitle: _t(
                      'Quattro sezioni, tutte collegate tra loro.',
                      'Four connected sections, one clear view.',
                    ),
                    content: Column(
                      children: [
                        _tour(
                          0,
                          Icons.home_rounded,
                          'Home',
                          _t('Patrimonio e conti', 'Balances and accounts'),
                        ),
                        _tour(
                          1,
                          Icons.receipt_long_rounded,
                          _t(
                            'Movimenti e Analisi',
                            'Transactions and Analytics',
                          ),
                          _t(
                            'Entrate, spese e statistiche',
                            'Income, expenses and insights',
                          ),
                        ),
                        _tour(
                          2,
                          Icons.handshake_rounded,
                          _t('Anticipi', 'Advances'),
                          _t(
                            'Prestiti e rimborsi',
                            'Money owed and repayments',
                          ),
                        ),
                        _tour(
                          3,
                          Icons.event_note_rounded,
                          _t('Pianifica', 'Plan'),
                          _t(
                            'Budget, obiettivi e scadenze',
                            'Budgets, goals and schedules',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                animationDuration: 460,
                curve: Curves.easeOutCubic,
                globalBackgroundColor: const Color(0xFF211248),
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
                    if (page == 2) {
                      if (reduced) {
                        _tourController.value = 1;
                      } else {
                        _tourController.forward(from: 0);
                      }
                    } else {
                      _tourController.reset();
                    }
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
                  backgroundColor: const Color(0xFFEBA2DA),
                  foregroundColor: const Color(0xFF28144C),
                  minimumSize: const Size(106, 51),
                  shape: const StadiumBorder(),
                ),
                doneStyle: TextButton.styleFrom(
                  backgroundColor: const Color(0xFFEBA2DA),
                  foregroundColor: const Color(0xFF28144C),
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
                    dotColor: Color(0x66FFFFFF),
                    activeDotColor: Color(0xFFF0A8E5),
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
    );
  }
}

class _CircleArt extends StatelessWidget {
  const _CircleArt({required this.icon, this.color = const Color(0xFF9D8ABF)});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => AnimatedContainer(
    key: const ValueKey('introduction-account-preview'),
    duration: const Duration(milliseconds: 220),
    curve: Curves.easeInOut,
    alignment: Alignment.center,
    width: 116,
    height: 116,
    decoration: BoxDecoration(
      color: color.withValues(alpha: .14),
      borderRadius: BorderRadius.circular(31),
    ),
    child: AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Icon(icon, key: ValueKey(icon), size: 65, color: color),
    ),
  );
}

/// On the last page the four product sections assemble around the Balyn core.
class _TourOrbitIllustration extends StatelessWidget {
  const _TourOrbitIllustration({required this.progress});

  final Animation<double> progress;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: progress,
    builder: (context, _) {
      final factor = Curves.easeOutCubic.transform(progress.value);
      final symbols = [
        (Icons.home_rounded, const Color(0xFFFFC2ED), const Offset(-58, -25)),
        (
          Icons.receipt_long_rounded,
          const Color(0xFFAACDFF),
          const Offset(58, -25),
        ),
        (
          Icons.handshake_rounded,
          const Color(0xFFB3F5D9),
          const Offset(-58, 30),
        ),
        (
          Icons.event_note_rounded,
          const Color(0xFFFFD8A3),
          const Offset(58, 30),
        ),
      ];
      return SizedBox(
        height: 124,
        width: 230,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 65,
              height: 65,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22),
                color: const Color(0xFF9B74FF).withValues(alpha: .28),
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.auto_graph_rounded,
                color: Colors.white,
                size: 34,
              ),
            ),
            for (final item in symbols)
              Transform.translate(
                offset: item.$3 * factor,
                child: Opacity(
                  opacity: factor,
                  child: Container(
                    height: 35,
                    width: 35,
                    decoration: BoxDecoration(
                      color: item.$2.withValues(alpha: .17),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: item.$2.withValues(alpha: .47)),
                    ),
                    child: Icon(item.$1, color: item.$2, size: 20),
                  ),
                ),
              ),
          ],
        ),
      );
    },
  );
}
