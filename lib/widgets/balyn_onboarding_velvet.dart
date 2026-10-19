import 'dart:ui' as ui;

import 'package:balyn/l10n/localized_material.dart';
import 'package:flutter/foundation.dart';

import 'balyn_shader_system.dart';

/// A single GPU surface for all onboarding pages. It combines deep-purple
/// velvet folds with very soft diagonal beams, using the existing app clock.
/// No separate ticker, external renderer, network dependency, or page reset.
class BalynOnboardingVelvet extends StatefulWidget {
  const BalynOnboardingVelvet({super.key});

  @override
  State<BalynOnboardingVelvet> createState() => _BalynOnboardingVelvetState();
}

class _BalynOnboardingVelvetState extends State<BalynOnboardingVelvet> {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final program = BalynShaderScope.maybeOf(context)?.onboardingVelvetProgram;
    if (!identical(program, _program)) {
      _program = program;
      _shader = program?.fragmentShader();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = BalynShaderScope.maybeOf(context);
    final reduced = MediaQuery.disableAnimationsOf(context);
    final animate = data?.motionEnabled == true && !reduced;
    final clock = animate
        ? data!.clock
        : const AlwaysStoppedAnimation<double>(0);

    return IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Visible immediately, also on devices without fragment shaders.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B0614),
                    Color(0xFF311342),
                    Color(0xFF180B29),
                  ],
                ),
              ),
            ),
            if (_shader != null)
              CustomPaint(
                key: const ValueKey('balyn-onboarding-velvet-shader'),
                isComplex: true,
                willChange: animate,
                painter: _VelvetPainter(shader: _shader!, clock: clock),
              ),
          ],
        ),
      ),
    );
  }
}

class _VelvetPainter extends CustomPainter {
  _VelvetPainter({required this.shader, required this.clock})
    : super(repaint: clock);

  final ui.FragmentShader shader;
  final ValueListenable<double> clock;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    shader
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, clock.value)
      // ~80% fabric lighting, ~20% subtle light beams.
      ..setFloat(3, 0.28);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_VelvetPainter oldDelegate) =>
      !identical(oldDelegate.shader, shader) ||
      !identical(oldDelegate.clock, clock);
}
