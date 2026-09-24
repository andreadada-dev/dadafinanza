import 'package:dadafinanza/app_state.dart';
import 'package:dadafinanza/data/app_database.dart';
import 'package:dadafinanza/main.dart';
import 'package:dadafinanza/screens/personal_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpSettings(
    WidgetTester tester, {
    required double width,
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(Size(width, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final state = AppState(AppDatabase());

    await tester.pumpWidget(
      AppScope(
        notifier: state,
        child: MaterialApp(
          home: MediaQuery(
            data: MediaQueryData(
              size: Size(width, 900),
              textScaler: TextScaler.linear(textScale),
            ),
            child: const PersonalSettingsScreen(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final width in const [320.0, 360.0, 390.0, 430.0]) {
    testWidgets('PersonalSettings has no overflow at ${width.toInt()}dp', (
      tester,
    ) async {
      await pumpSettings(tester, width: width);
      expect(find.text('Impostazioni'), findsOneWidget);
      expect(find.text('Valuta principale'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('PersonalSettings supports large text', (tester) async {
    await pumpSettings(tester, width: 320, textScale: 1.5);
    expect(tester.takeException(), isNull);
  });

  testWidgets('financial month picker opens without flex overflow', (
    tester,
  ) async {
    await pumpSettings(tester, width: 320);
    await tester.scrollUntilVisible(
      find.text('Inizio mese finanziario'),
      260,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Inizio mese finanziario'));
    await tester.pumpAndSettle();

    expect(find.text('Giorno 1'), findsOneWidget);
    expect(find.byType(ChoiceChip), findsNWidgets(28));
    expect(tester.takeException(), isNull);
  });
}
