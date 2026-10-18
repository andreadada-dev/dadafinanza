import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_onboarding_velvet.dart';
import 'package:flutter_test/flutter_test.dart';

Future<Uint8List> _renderVelvet(double phase) async {
  const width = 160;
  const height = 240;
  final program = await ui.FragmentProgram.fromAsset(
    'shaders/balyn_onboarding_velvet.frag',
  );
  final shader = program.fragmentShader()
    ..setFloat(0, width.toDouble())
    ..setFloat(1, height.toDouble())
    ..setFloat(2, phase)
    ..setFloat(3, 0.28);

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
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'Velvet shader paints purple folds and visibly moves over time',
    () async {
      final initial = await _renderVelvet(0.0);
      final moved = await _renderVelvet(0.25);
      var purplePixels = 0;
      var movingPixels = 0;
      for (var index = 0; index < initial.length; index += 4) {
        final red = initial[index];
        final blue = initial[index + 2];
        if (blue > red + 6 && red > 12) purplePixels++;
        final difference =
            (initial[index] - moved[index]).abs() +
            (initial[index + 1] - moved[index + 1]).abs() +
            (initial[index + 2] - moved[index + 2]).abs();
        if (difference >= 6) movingPixels++;
      }

      expect(purplePixels, greaterThan(initial.length ~/ 4 ~/ 5));
      expect(movingPixels, greaterThan(initial.length ~/ 4 ~/ 50));
    },
  );

  test('Shader animation is a seamless loop on the global 72s clock', () async {
    final first = await _renderVelvet(0.0);
    final afterOneCycle = await _renderVelvet(1.0);
    expect(afterOneCycle, orderedEquals(first));
  });

  testWidgets('Onboarding keeps a visible fallback without ShaderScope', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: BalynOnboardingVelvet())),
    );
    expect(find.byType(BalynOnboardingVelvet), findsOneWidget);
    expect(find.byType(DecoratedBox), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test(
    'Shader stays behind onboarding navigation and respects reduced motion',
    () {
      final source = File(
        'lib/screens/balyn_onboarding_flow.dart',
      ).readAsStringSync();
      final velvet = File(
        'lib/widgets/balyn_onboarding_velvet.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('BalynOnboardingVelvet()')));
      expect(source, contains('ColoredBox(color: BalynPalette.darkCanvas)'));
      expect(source, contains('globalBackgroundColor: Colors.transparent'));
      expect(source, contains('IntroductionScreen('));
      expect(source, contains("setSetting('onboarding_completed', '1')"));
      expect(velvet, contains('data?.motionEnabled == true && !reduced'));
      expect(velvet, contains('const AlwaysStoppedAnimation<double>(0)'));
      expect(velvet, contains('super(repaint: clock)'));
    },
  );
}
