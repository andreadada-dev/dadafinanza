import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_settings_components.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('grouped settings keep all seven sections and their existing actions', () {
    final main = File('lib/screens/personal_settings_screen.dart')
        .readAsStringSync();
    for (final section in [
      'Aspetto',
      'Generali',
      'Privacy locale',
      'Inserimento',
      'Organizzazione',
      'Dati',
      'Comportamento',
    ]) {
      expect(main, contains("title: '$section'"));
    }
    for (final label in [
      'Tema',
      'Lingua',
      'Gradient animati',
      'Nascondi saldi nell’app',
      'Valuta principale',
      'Mostra centesimi',
      'Primo giorno settimana',
      'Inizio mese finanziario',
      'Conferma eliminazioni',
      'Conti',
      'Blocco e schermata recenti',
      'Privacy e dati',
      'Notifiche locali',
      'Inserimento vocale',
      'Smart Suggestions',
      'Preset rapidi',
      'Anticipi',
      'Categorie',
      'Regole automatiche',
      'Personalizza Home',
      'Widget Android',
      'Backup, CSV e ripristino',
      'Permetti “Non assegnato”',
      'Trasferimenti nelle statistiche',
      'Feedback aptico',
    ]) {
      expect(main, contains(label));
    }
    expect(main, contains('DashboardCustomizerScreen()'));
    expect(main, contains('DataManagementScreen()'));
    expect(main, contains("state.setSetting(key, value ? '1' : '0')"));
    for (final key in [
      'shader_icons',
      'shader_charts',
      'shader_text',
      'shader_bars',
      'shader_background',
    ]) {
      expect(main, contains("'$key'"));
    }
    expect(main, isNot(contains('SwitchListTile(')));
  });

  testWidgets('group tiles preserve navigation and tappable switch', (tester) async {
    var navigations = 0;
    var enabled = false;
    late StateSetter update;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              update = setState;
              return ListView(
                children: [
                  BalynSettingsGroup(
                    title: 'Aspetto',
                    accent: const Color(0xFF4365F5),
                    children: [
                      BalynSettingsTile(
                        icon: Icons.palette_outlined,
                        title: 'Tema',
                        subtitle: 'Sistema',
                        onTap: () => navigations++,
                      ),
                      BalynSettingsSwitch(
                        icon: Icons.visibility_off_outlined,
                        title: const Text('Nascondi saldi'),
                        subtitle: const Text('Privacy'),
                        value: enabled,
                        onChanged: (value) => update(() => enabled = value),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    expect(find.text('Aspetto'), findsOneWidget);
    await tester.tap(find.text('Tema'));
    expect(navigations, 1);
    await tester.tap(find.text('Nascondi saldi'));
    await tester.pump();
    expect(enabled, isTrue);
    expect(tester.takeException(), isNull);
  });
}
