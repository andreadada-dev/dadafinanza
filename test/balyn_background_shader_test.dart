import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';

/// Renders the real compiled fragment program; a passing Dart source check
/// alone cannot prove that a near-black shader is visible on screen.
Future<Uint8List> _renderBackground({
  required double phase,
  required bool dark,
}) async {
  const width = 160;
  const height = 240;
  final program = await ui.FragmentProgram.fromAsset(
    'shaders/balyn_background.frag',
  );
  final shader = program.fragmentShader()
    ..setFloat(0, width.toDouble())
    ..setFloat(1, height.toDouble())
    ..setFloat(2, phase)
    ..setFloat(3, dark ? 1 : 0);

  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  canvas.drawRect(
    ui.Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    ui.Paint()..shader = shader,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  image.dispose();
  picture.dispose();
  return bytes!.buffer.asUint8List();
}

void main() {
  testWidgets('liquid background has visible contrast and moves in both themes', (
    tester,
  ) async {
    for (final dark in [true, false]) {
      final initial = await _renderBackground(phase: 0, dark: dark);
      final moved = await _renderBackground(phase: .25, dark: dark);

      // Blue/violet must stand away from black and lavender away from white.
      final visiblePixels = <int>[];
      var movingPixels = 0;
      for (var index = 0; index < initial.length; index += 4) {
        final blue = initial[index + 2];
        if (dark ? blue >= 24 : blue <= 247 && initial[index] <= 245) {
          visiblePixels.add(index);
        }
        final delta =
            (initial[index] - moved[index]).abs() +
            (initial[index + 1] - moved[index + 1]).abs() +
            (initial[index + 2] - moved[index + 2]).abs();
        if (delta >= 8) movingPixels++;
      }
      // At least 5% of the surface must be visibly tinted, and the movement
      // must change at least 5% of its pixels rather than remaining static.
      expect(visiblePixels.length, greaterThan(initial.length ~/ 4 ~/ 20));
      expect(movingPixels, greaterThan(initial.length ~/ 4 ~/ 20));
    }
  });
}
