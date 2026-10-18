import 'dart:math' as math;

import 'package:balyn/l10n/localized_material.dart';
import 'package:flutter/foundation.dart';
import 'package:mesh/mesh.dart';

import 'balyn_shader_system.dart';

/// The official O'Mesh "Basic Usage" 3x3 layout, with a barely perceptible
/// motion of the interior vertices. The boundary is fixed: no torn edges or
/// drifting gradients at the top of the Home screen.
///
/// The existing app-wide 72-second clock supplies the phase. This widget
/// neither allocates its own ticker nor rebuilds the hero's financial UI.
class BalynOMeshHeroBackground extends StatelessWidget {
  const BalynOMeshHeroBackground({
    required this.accent,
    required this.useBasicPalette,
    super.key,
  });

  final Color accent;
  final bool useBasicPalette;

  @override
  Widget build(BuildContext context) {
    final data = BalynShaderScope.maybeOf(context);
    final animate =
        data?.motionEnabled == true &&
        !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.of(context);
    final clock = animate
        ? data!.clock
        : const AlwaysStoppedAnimation<double>(0);

    return IgnorePointer(
      child: ClipRect(
        child: RepaintBoundary(
          child: AnimatedBuilder(
            animation: clock,
            builder: (context, _) {
              final mesh = OMeshRect(
                width: 3,
                height: 3,
                backgroundColor: accent,
                colorSpace: OMeshColorSpace.lab,
                vertices: balynHeroMeshVertices(clock.value),
                colors: balynHeroMeshColors(
                  accent,
                  useBasicPalette: useBasicPalette,
                ),
              );
              return Stack(
                fit: StackFit.expand,
                children: [
                  // The mesh package loads its shader asynchronously; this
                  // solid background avoids a blank first frame.
                  ColoredBox(color: accent),
                  OMeshGradient(
                    key: const ValueKey('hero-omesh-gradient'),
                    tessellation: 10,
                    mesh: mesh,
                  ),
                  // White balances and actions must remain legible even over
                  // the Basic Usage example's pale center vertex.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0x33000000),
                          Color(0x86000000),
                          Color(0x62000000),
                        ],
                        stops: [0, 0.50, 1],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Positions deliberately track O'Mesh's official Basic Usage example.
/// Only four interior/near-interior vertices travel; all movement is periodic
/// and joins seamlessly at the end of the shared 72-second clock.
@visibleForTesting
List<OVertex> balynHeroMeshVertices(double phase) {
  final t = phase * math.pi * 4.0; // two gentle 36-second cycles
  final x = math.sin(t);
  final y = math.cos(t);
  return [
    (-0.06, -0.08).v, (0.58 + .012 * x, -0.05).v, (1.36, 0.04).v, //
    (-0.02, 0.31).v, (0.44 + .036 * x, 0.63 + .027 * y).v,
    (1.11, 0.4 + .016 * y).v, //
    (-0.01, 1.01).v, (1.01 - .014 * x, 1.0).v, (1.02, 0.73).v, //
  ];
}

/// Preserve the original Basic Usage pink / cyan / cream composition when the
/// total balance is selected; recolor the same composition for specific
/// accounts using each account's stored accent color.
@visibleForTesting
List<Color> balynHeroMeshColors(Color accent, {required bool useBasicPalette}) {
  if (useBasicPalette) {
    return const [
      Color(0xFFA52B68), Color(0xFF4693A9), Color(0xFF4693A9), //
      Color(0xFFA52BA0), Color(0xFFE8DAD4), Color(0xFF4693A9), //
      Color(0xFF9715A9), Color(0xFF4693A9), Color(0xFF4693A9), //
    ];
  }
  final hsl = HSLColor.fromColor(accent);
  Color tone(double hueShift, double saturation, double lightness) {
    return HSLColor.fromAHSL(
      1,
      (hsl.hue + hueShift + 360) % 360,
      saturation,
      lightness,
    ).toColor();
  }

  final vibrant = tone(0, .69, .46);
  final dark = tone(-12, .73, .35);
  final cool = tone(-136, .40, .50);
  final pale = tone(-28, .21, .80);
  return [
    vibrant, cool, cool, //
    vibrant, pale, cool, //
    dark, cool, cool, //
  ];
}
