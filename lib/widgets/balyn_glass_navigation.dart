import 'dart:ui';

import 'package:balyn/l10n/localized_material.dart';

/// A floating liquid-glass lens inspired by the Figma Dark Liquid Glass
/// component. It refracts the *live* page behind the bar; no static backdrop,
/// mock screenshots or additional packages are involved.
class BalynGlassNavigation extends StatelessWidget {
  const BalynGlassNavigation({
    required this.index,
    required this.onDestinationSelected,
    super.key,
  });

  final int index;
  final ValueChanged<int> onDestinationSelected;

  static const _items = <(String, IconData, IconData)>[
    ('Home', Icons.home_outlined, Icons.home_rounded),
    ('Attività', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    ('Anticipi', Icons.handshake_outlined, Icons.handshake_rounded),
    ('Pianifica', Icons.event_note_outlined, Icons.event_note_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    const shape = BorderRadius.all(Radius.circular(36));
    const redGlass = Color(0xFFAA4559);
    return RepaintBoundary(
      child: ClipRRect(
        borderRadius: shape,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
          child: CustomPaint(
            foregroundPainter: _LiquidRimPainter(dark: dark),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: shape,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: dark
                      ? [
                          const Color(0xFF17121B).withValues(alpha: .21),
                          const Color(0xFF7B3342).withValues(alpha: .16),
                          const Color(0xFF100D16).withValues(alpha: .26),
                        ]
                      : [
                          Colors.white.withValues(alpha: .24),
                          const Color(0xFFE9DDE6).withValues(alpha: .18),
                          Colors.white.withValues(alpha: .22),
                        ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: dark ? .22 : .08),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: SizedBox(
                height: 72,
                child: Row(
                  children: [
                    for (var i = 0; i < _items.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == index,
                          label: _items[i].$1,
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              key: ValueKey('glass-destination-$i'),
                              onTap: () => onDestinationSelected(i),
                              borderRadius: BorderRadius.circular(28),
                              child: AnimatedContainer(
                                duration: reducedMotion
                                    ? Duration.zero
                                    : const Duration(milliseconds: 270),
                                curve: Curves.easeOutCubic,
                                margin: const EdgeInsets.symmetric(
                                  horizontal: 3,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  gradient: i == index
                                      ? LinearGradient(
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                          colors: dark
                                              ? [
                                                  redGlass.withValues(
                                                    alpha: .35,
                                                  ),
                                                  const Color(0xFF60303B)
                                                      .withValues(alpha: .14),
                                                ]
                                              : [
                                                  Colors.white.withValues(
                                                    alpha: .44,
                                                  ),
                                                  redGlass.withValues(
                                                    alpha: .09,
                                                  ),
                                                ],
                                        )
                                      : null,
                                  border: i == index
                                      ? Border.all(
                                          width: .9,
                                          color: Colors.white.withValues(
                                            alpha: dark ? .30 : .62,
                                          ),
                                        )
                                      : null,
                                  borderRadius: BorderRadius.circular(29),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    AnimatedScale(
                                      duration: reducedMotion
                                          ? Duration.zero
                                          : const Duration(milliseconds: 230),
                                      scale: i == index ? 1.09 : 1.0,
                                      child: Icon(
                                        i == index
                                            ? _items[i].$3
                                            : _items[i].$2,
                                        size: 23,
                                        color: i == index
                                            ? (dark
                                                  ? Colors.white
                                                  : theme.colorScheme.onSurface)
                                            : (dark
                                                  ? Colors.white.withValues(
                                                      alpha: .77,
                                                    )
                                                  : theme
                                                        .colorScheme
                                                        .onSurfaceVariant),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        _items[i].$1,
                                        maxLines: 1,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: i == index
                                              ? FontWeight.w800
                                              : FontWeight.w500,
                                          color: i == index
                                              ? (dark
                                                    ? Colors.white
                                                    : theme
                                                          .colorScheme
                                                          .onSurface)
                                              : (dark
                                                    ? Colors.white.withValues(
                                                        alpha: .75,
                                                      )
                                                    : theme
                                                          .colorScheme
                                                          .onSurfaceVariant),
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
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The Figma control has a layered lens rim, including a bright top edge and
/// secondary inset highlights. Draw those as a responsive overlay above the
/// blurred live content rather than using the Figma demo's background PNG.
class _LiquidRimPainter extends CustomPainter {
  const _LiquidRimPainter({required this.dark});
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    final outer = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(36),
    );
    final borderRect = Offset.zero & size;
    canvas.drawRRect(
      outer,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: dark ? .72 : .9),
            Colors.white.withValues(alpha: .12),
            Colors.white.withValues(alpha: dark ? .29 : .49),
            Colors.white.withValues(alpha: .55),
          ],
          stops: const [0, .36, .72, 1],
        ).createShader(borderRect),
    );
    final inner = RRect.fromRectAndRadius(
      Rect.fromLTWH(3, 3, size.width - 6, size.height - 6),
      const Radius.circular(33),
    );
    canvas.drawRRect(
      inner,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: dark ? .20 : .31),
            Colors.white.withValues(alpha: .025),
            Colors.black.withValues(alpha: dark ? .27 : .08),
          ],
        ).createShader(borderRect),
    );
    final shine = Path()
      ..moveTo(22, 1.7)
      ..lineTo(size.width - 35, 1.7);
    canvas.drawPath(
      shine,
      Paint()
        ..color = Colors.white.withValues(alpha: dark ? .22 : .35)
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );
  }

  @override
  bool shouldRepaint(covariant _LiquidRimPainter oldDelegate) =>
      oldDelegate.dark != dark;
}
