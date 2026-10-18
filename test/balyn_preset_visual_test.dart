import 'package:balyn/services/quick_preset_service.dart';
import 'package:balyn/widgets/balyn_preset_visual.dart';
import 'package:balyn/l10n/localized_material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Legacy presets use white initials without an icon key', () {
    final preset = QuickPreset.fromMap({
      'id': 1,
      'name': 'Spesa bar',
      'type': 'expense',
      'position': 0,
      'enabled': 1,
    });

    expect(preset.iconKey, isNull);
    expect(preset.colorValue, 0xFFFFFFFF);
  });

  test('Preset visual metadata can be read from persisted rows', () {
    final preset = QuickPreset.fromMap({
      'id': 2,
      'name': 'Viaggio',
      'type': 'expense',
      'position': 1,
      'enabled': 1,
      'icon_key': 'flight',
      'color_value': 0xFFAE94FF,
    });

    expect(preset.iconKey, 'flight');
    expect(preset.colorValue, 0xFFAE94FF);
    expect(presetIconData(preset.iconKey), isNotNull);
  });

  testWidgets('Empty radial slot stays visible and transparent', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: BalynPresetGlyph(
              name: '',
              iconKey: null,
              colorValue: 0xFFFFFFFF,
              empty: true,
            ),
          ),
        ),
      ),
    );

    expect(find.byType(BalynPresetGlyph), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });
}
