import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/theme/app_theme.dart';
import 'package:balyn/theme/balyn_palette.dart';
import 'package:balyn/widgets/balyn_editorial_components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Dark app uses the new Home as single color source', () {
    final theme = AppTheme.dark();
    expect(theme.colorScheme.surface, BalynPalette.darkCanvas);
    expect(theme.colorScheme.surfaceContainer, BalynPalette.darkSurface);
    expect(theme.colorScheme.primary, BalynPalette.accentTextDark);
    expect(theme.colorScheme.primaryContainer, BalynPalette.accent);
    expect(theme.cardTheme.color, BalynPalette.darkSurface);
    expect(theme.floatingActionButtonTheme.backgroundColor, BalynPalette.accent);
    expect(theme.dialogTheme.backgroundColor, BalynPalette.darkSurface);
    expect(theme.bottomSheetTheme.backgroundColor, BalynPalette.darkSurface);
    expect(theme.inputDecorationTheme.fillColor, BalynPalette.darkSurface);
    expect(theme.inputDecorationTheme.filled, isTrue);
    expect(theme.scaffoldBackgroundColor, Colors.transparent);
  });

  test('Light mode shares the same purple family and rounded surfaces', () {
    final theme = AppTheme.light();
    expect(theme.colorScheme.surface, BalynPalette.lightCanvas);
    expect(theme.colorScheme.surfaceContainer, BalynPalette.lightSurface);
    expect(theme.colorScheme.primary, BalynPalette.accentLight);
    expect(theme.cardTheme.color, BalynPalette.lightSurface);
    expect(theme.floatingActionButtonTheme.backgroundColor, BalynPalette.accent);
    expect(theme.inputDecorationTheme.fillColor, BalynPalette.lightSurface);
  });

  test('Finance colors remain semantic rather than all becoming purple', () {
    final dark = AppTheme.dark().extension<FinanceColors>()!;
    final light = AppTheme.light().extension<FinanceColors>()!;
    expect(dark.positive, BalynPalette.incomeDark);
    expect(dark.negative, BalynPalette.expenseDark);
    expect(light.positive, BalynPalette.incomeLight);
    expect(light.negative, BalynPalette.expenseLight);
    expect(dark.positive, isNot(dark.negative));
    expect(dark.positive, isNot(BalynPalette.accent));
  });

  test('All navigation destinations inherit theme; no separate legacy blue', () {
    final theme = File('lib/theme/app_theme.dart').readAsStringSync();
    final settings =
        File('lib/screens/personal_settings_screen.dart').readAsStringSync();
    final backdrop =
        File('lib/widgets/balyn_shader_system.dart').readAsStringSync();
    final surface =
        File('lib/widgets/balyn_editorial_components.dart').readAsStringSync();
    expect(theme, contains('BalynPalette.surface(brightness)'));
    expect(theme, isNot(contains('0xFF0666EB')));
    expect(settings, isNot(contains('0xFF4365F5')));
    expect(settings, isNot(contains('0xFF298B83')));
    expect(settings, contains('accent: BalynPalette.accent'));
    expect(backdrop, contains('BalynPalette.canvas('));
    expect(surface, contains('BalynPalette.surface('));
  });

  testWidgets('The canonical Home surface works in both themes', (
    tester,
  ) async {
    for (final theme in [AppTheme.dark(), AppTheme.light()]) {
      await tester.pumpWidget(MaterialApp(
        theme: theme,
        home: const Scaffold(
          body: BalynEditorialSurface(child: Text('Riepilogo')),
        ),
      ));
      expect(find.byType(BalynEditorialSurface), findsOneWidget);
      expect(find.text('Riepilogo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });
}
