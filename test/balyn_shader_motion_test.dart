import 'package:balyn/widgets/balyn_shader_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Balyn shader clock keeps advancing when platform animations are disabled',
    (tester) async {
      const phaseKey = ValueKey('shader-phase');

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: BalynShaderScope(
              loadPrograms: false,
              child: BalynShaderMotionBuilder(
                builder: (context, phase, enabled) =>
                    Text('${enabled ? 'on' : 'off'}:${phase.toStringAsFixed(6)}', key: phaseKey),
              ),
            ),
          ),
        ),
      );

      final first = tester.widget<Text>(find.byKey(phaseKey)).data;
      await tester.pump(const Duration(seconds: 1));
      final second = tester.widget<Text>(find.byKey(phaseKey)).data;

      expect(first, isNotNull);
      expect(second, isNotNull);
      expect(first, startsWith('on:'));
      expect(second, startsWith('on:'));
      expect(second, isNot(first));
    },
  );

  testWidgets('chart shader toggle disables animated chart material', (
    tester,
  ) async {
    const stateKey = ValueKey('shader-enabled');

    await tester.pumpWidget(
      MaterialApp(
        home: BalynShaderScope(
          loadPrograms: false,
          chartEnabled: false,
          child: BalynShaderMotionBuilder(
            builder: (context, phase, enabled) => Text(
              '$enabled:${phase.toStringAsFixed(3)}',
              key: stateKey,
            ),
          ),
        ),
      ),
    );

    expect(tester.widget<Text>(find.byKey(stateKey)).data, 'false:0.000');
  });
}
