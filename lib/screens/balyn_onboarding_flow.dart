import 'dart:math' as math;
import 'package:balyn/l10n/localized_material.dart';
import 'package:introduction_screen/introduction_screen.dart';
import '../l10n/app_i18n.dart';
import '../main.dart';
import '../models/models.dart';

/// Three-page, first-install-only flow. Uses Balyn's real account and settings APIs.
class BalynOnboardingFlow extends StatefulWidget {
  const BalynOnboardingFlow({required this.onFinished, super.key});
  final VoidCallback onFinished;
  @override
  State<BalynOnboardingFlow> createState() => _BalynOnboardingFlowState();
}

class _BalynOnboardingFlowState extends State<BalynOnboardingFlow>
    with SingleTickerProviderStateMixin {
  final GlobalKey<IntroductionScreenState> _introKey = GlobalKey<IntroductionScreenState>();
  final TextEditingController _name = TextEditingController(
    text: 'Conto principale',
  );
  late final AnimationController _float = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);
  int _step = 0;
  bool _saving = false;
  bool _skipping = false;
  String _language = 'it';
  String _currency = 'EUR';
  AccountType _type = AccountType.checking;
  int _color = 0xFF6539E8;
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
    _name.dispose();
    _float.dispose();
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
            iconKey: _type == AccountType.cash ? 'cash' : 'wallet',
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

  Widget _tour(IconData icon, String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(bottom: 9),
    child: Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFFFBEE9), size: 27),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _page({
    required Widget illustration,
    required String title,
    required String subtitle,
    required Widget content,
  }) => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(23, 12, 23, 12),
    child: Column(
      children: [
        SizedBox(height: 174, child: Center(child: illustration)),
        const SizedBox(height: 10),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 27,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFE2D5FA), height: 1.45),
        ),
        const SizedBox(height: 24),
        content,
      ],
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
                    illustration: AnimatedBuilder(
                      animation: _float,
                      builder: (context, _) =>
                          _FloatingFinance(value: reduced ? 0 : _float.value),
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
                    illustration: const _CircleArt(
                      icon: Icons.account_balance_wallet_rounded,
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
                            onChanged: (v) => setState(
                              () => _type = v ?? AccountType.checking,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
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
                    illustration: const _CircleArt(
                      icon: Icons.auto_graph_rounded,
                    ),
                    title: _t('Ecco come funziona', 'How Balyn works'),
                    subtitle: _t(
                      'Quattro sezioni, tutte collegate tra loro.',
                      'Four connected sections, one clear view.',
                    ),
                    content: Column(
                      children: [
                        _tour(
                          Icons.home_rounded,
                          'Home',
                          _t('Patrimonio e conti', 'Balances and accounts'),
                        ),
                        _tour(
                          Icons.receipt_long_rounded,
                          _t('Attività', 'Activity'),
                          _t(
                            'Movimenti e analisi',
                            'Transactions and analytics',
                          ),
                        ),
                        _tour(
                          Icons.handshake_rounded,
                          _t('Anticipi', 'Advances'),
                          _t(
                            'Prestiti e rimborsi',
                            'Money owed and repayments',
                          ),
                        ),
                        _tour(
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
                  if (_step != page && mounted) setState(() => _step = page);
                },
                onDone: () => _complete(),
                next: Text(
                  _t('Avanti', 'Continue'),
                  key: const ValueKey('onboarding-next'),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                done: _saving
                    ? const SizedBox(
                        width: 22, height: 22,
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
                dotsDecorator: const DotsDecorator(
                  color: Color(0x66FFFFFF),
                  activeColor: Color(0xFFF0A8E5),
                  size: Size(8, 8),
                  activeSize: Size(24, 8),
                  spacing: EdgeInsets.symmetric(horizontal: 4),
                  activeShape: StadiumBorder(),
                ),
                controlsPadding: const EdgeInsets.symmetric(
                  horizontal: 21, vertical: 11,
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
  const _CircleArt({required this.icon});
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    height: 150,
    width: 150,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: const RadialGradient(
        colors: [Color(0xFFD5A1FF), Color(0xFF6731B8), Color(0xFF24104D)],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFFAD76DB).withValues(alpha: .36),
          blurRadius: 28,
          spreadRadius: 8,
        ),
      ],
    ),
    child: Icon(icon, size: 74, color: Colors.white),
  );
}

class _FloatingFinance extends StatelessWidget {
  const _FloatingFinance({required this.value});
  final double value;
  @override
  Widget build(BuildContext context) => Transform.translate(
    offset: Offset(0, -10 * math.sin(value * math.pi)),
    child: SizedBox(
      width: 260,
      height: 165,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const _CircleArt(icon: Icons.auto_graph_rounded),
          const Positioned(
            left: 12,
            top: 12,
            child: _Bubble(icon: Icons.euro_rounded, color: Color(0xFF42D8AA)),
          ),
          const Positioned(
            right: 15,
            top: 5,
            child: _Bubble(
              icon: Icons.show_chart_rounded,
              color: Color(0xFFEBA3DF),
            ),
          ),
          const Positioned(
            right: 15,
            bottom: 4,
            child: _Bubble(
              icon: Icons.account_balance_wallet_rounded,
              color: Color(0xFFFFCA75),
            ),
          ),
        ],
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.icon, required this.color});
  final IconData icon;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
    width: 46,
    height: 46,
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: [
        BoxShadow(color: color.withValues(alpha: .45), blurRadius: 14),
      ],
    ),
    child: Icon(icon, color: const Color(0xFF27134A)),
  );
}
