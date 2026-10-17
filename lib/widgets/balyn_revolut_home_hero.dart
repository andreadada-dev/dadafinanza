import 'package:balyn/l10n/localized_material.dart';

/// Revolut Invest-inspired, full-width Home header. All amounts and callbacks
/// are supplied by the finance state; this is not a screenshot or mock data.
class BalynRevolutHomeHero extends StatelessWidget {
  const BalynRevolutHomeHero({
    required this.title,
    required this.balance,
    required this.available,
    required this.hideBalance,
    required this.selectedTab,
    required this.onTabChanged,
    required this.onSearch,
    required this.onAnalytics,
    required this.onSettings,
    required this.onVisibility,
    required this.onExpense,
    required this.onIncome,
    required this.onTransfer,
    required this.onMore,
    super.key,
  });

  final String title;
  final String balance;
  final String available;
  final bool hideBalance;
  final int selectedTab;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onSearch;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;
  final VoidCallback onVisibility;
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onTransfer;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height;
    final height = (availableHeight * .53).clamp(340.0, 440.0).toDouble();
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;

    return SizedBox(
      height: height + 23,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: height,
            child: const CustomPaint(painter: _VioletWavesPainter()),
          ),
          Positioned.fill(
            bottom: 23,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Tooltip(
                        message: 'Impostazioni Balyn',
                        child: Material(
                          color: Colors.white.withValues(alpha: .18),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onSettings,
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Text(
                                  'B',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Material(
                          color: Colors.white.withValues(alpha: .28),
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: onSearch,
                            borderRadius: BorderRadius.circular(24),
                            child: const SizedBox(
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cerca movimenti',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _RoundHeaderAction(
                        icon: Icons.bar_chart_rounded,
                        tooltip: 'Analisi',
                        onTap: onAnalytics,
                      ),
                      const SizedBox(width: 6),
                      _RoundHeaderAction(
                        icon: Icons.tune_rounded,
                        tooltip: 'Impostazioni',
                        onTap: onSettings,
                      ),
                    ],
                  ),
                  const Spacer(flex: 4),
                  Text(
                    title.toUpperCase(),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: .88),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: .45,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            balance,
                            maxLines: 1,
                            key: const ValueKey('balyn-revolut-balance'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 39,
                              height: 1.05,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.7,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        tooltip: hideBalance
                            ? 'Mostra saldi'
                            : 'Nascondi saldi',
                        onPressed: onVisibility,
                        color: Colors.white.withValues(alpha: .85),
                        iconSize: 18,
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                        icon: Icon(
                          hideBalance
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Disponibile  $available',
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: .85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Spacer(flex: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HeroAction(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Spesa',
                        onTap: onExpense,
                      ),
                      _HeroAction(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Entrata',
                        onTap: onIncome,
                      ),
                      _HeroAction(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Trasferisci',
                        onTap: onTransfer,
                      ),
                      _HeroAction(
                        icon: Icons.more_horiz_rounded,
                        label: 'Altro',
                        onTap: onMore,
                      ),
                    ],
                  ),
                  SizedBox(height: largeText ? 28 : 19),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 1,
            left: 16,
            right: 16,
            child: Semantics(
              label: 'Sezione Home',
              child: Container(
                height: 46,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8E9EF),
                  borderRadius: BorderRadius.circular(27),
                ),
                child: Row(
                  children: [
                    _TabPill(
                      label: 'Panoramica',
                      active: selectedTab == 0,
                      onTap: () => onTabChanged(0),
                    ),
                    _TabPill(
                      label: 'Conti',
                      active: selectedTab == 1,
                      onTap: () => onTabChanged(1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoundHeaderAction extends StatelessWidget {
  const _RoundHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .27),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 39,
            height: 39,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .26),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 9),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.active,
    required this.onTap,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Material(
      color: active ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: SizedBox(
          height: 38,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFF22222B)
                    : const Color(0xFF747682),
                fontSize: 12,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _VioletWavesPainter extends CustomPainter {
  const _VioletWavesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF6119FC),
            Color(0xFF8217F7),
            Color(0xFF440DF7),
            Color(0xFF3610DF),
          ],
          stops: [0, .36, .74, 1],
        ).createShader(rect),
    );

    final bloom = Rect.fromCenter(
      center: Offset(size.width * .86, size.height * .43),
      width: size.width * .98,
      height: size.height * .85,
    );
    canvas.drawOval(
      bloom,
      Paint()
        ..shader = const RadialGradient(
          colors: [Color(0x669F7CFF), Color(0x187E5DFD), Color(0x008B5CFF)],
          stops: [0, .65, 1],
        ).createShader(bloom),
    );
    final ribbon = Path()
      ..moveTo(-size.width * .24, size.height * .98)
      ..cubicTo(
        size.width * .33,
        size.height * .93,
        size.width * .83,
        size.height * .64,
        size.width * .98,
        size.height * .29,
      );
    final glow = Paint()
      ..color = const Color(0x889A8AFF)
      ..strokeWidth = 28
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 24);
    canvas.drawPath(ribbon, glow);
    canvas.drawPath(
      ribbon,
      Paint()
        ..shader = const LinearGradient(
          colors: [
            Color(0x003B22F3),
            Color(0x707FBFFF),
            Color(0xB49EABFF),
            Color(0x007B55FF),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    final lower = Path()
      ..moveTo(size.width * .25, size.height * 1.08)
      ..cubicTo(
        size.width * .60,
        size.height * .86,
        size.width * 1.11,
        size.height * .89,
        size.width * 1.22,
        size.height * .56,
      );
    canvas.drawPath(
      lower,
      Paint()
        ..color = const Color(0x8858A4FF)
        ..strokeWidth = 22
        ..style = PaintingStyle.stroke
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 22),
    );
  }

  @override
  bool shouldRepaint(covariant _VioletWavesPainter oldDelegate) => false;
}
