import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:flutter/foundation.dart';
import 'package:balyn/widgets/balyn_omesh_hero_background.dart';
import 'package:balyn/widgets/balyn_quick_action_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

double hueDistance(double a, double b) {
  final difference = (a - b).abs() % 360;
  return difference > 180 ? 360 - difference : difference;
}

void main() {
  test('Purple, green and blue accounts keep analogous OMesh shades', () {
    for (final color in [
      const Color(0xFF7645ED),
      const Color(0xFF23934A),
      const Color(0xFF336ECC),
    ]) {
      final baseHue = HSLColor.fromColor(color).hue;
      final swatches = balynHeroMeshColors(color, useBasicPalette: false);
      expect(swatches, hasLength(9));
      for (final swatch in swatches) {
        expect(
          hueDistance(baseHue, HSLColor.fromColor(swatch).hue),
          lessThan(48),
        );
      }
    }
  });

  test('Hero retains swipe and dropdown without visible side diamonds', () {
    final hero = File(
      'lib/widgets/balyn_revolut_home_hero.dart',
    ).readAsStringSync();
    expect(hero, contains('onHorizontalDragEnd:'));
    expect(hero, contains('_showAccountSelector(context)'));
    expect(hero, contains('Icons.keyboard_arrow_down_rounded'));
    expect(hero, isNot(contains('_AnimatedAccountDiamond')));
  });

  test('Hero More keeps its three-dots trigger while corner + stays radial', () {
    final header = File(
      'lib/widgets/balyn_cue_three_dots_action.dart',
    ).readAsStringSync();
    final fab = File(
      'lib/widgets/balyn_quick_action_launcher.dart',
    ).readAsStringSync();
    final menu = File(
      'lib/widgets/balyn_cue_anchored_menu.dart',
    ).readAsStringSync();
    expect(header, contains('PopupMenuButton<String>('));
    expect(header, contains('position: PopupMenuPosition.under'));
    expect(header, contains("'Conti'"));
    expect(header, contains("'Pianifica'"));
    expect(header, contains("'Anticipi'"));
    expect(header, contains('Icons.more_vert_rounded'));
    expect(header, isNot(contains('hideTriggerOnTransition')));
    expect(fab, contains('return PieMenu('));
    expect(fab, contains('overlayColor: Colors.black.withValues(alpha: .54)'));
    expect(fab, contains('pointerSize: 0'));
    expect(fab, contains('longPressShowsMenu: true'));
    expect(fab, contains('longPressDuration: holdDuration'));
    expect(fab, contains('onPressed: _openTransferOnce'));
    expect(fab, contains('scheduleMicrotask(() => _tapInProgress = false)'));
    expect(fab, contains('math.pi * 2 * progress.clamp(0.0, 1.0)'));
    expect(menu, contains('barrierColor: Colors.black54'));
    expect(menu, contains('motion: .bouncy()'));
    expect(menu, contains('reverseMotion: .snappy()'));
    expect(menu, contains('alignment: Alignment.bottomRight'));
    expect(menu, contains('Navigator.of(modalContext).pop()'));
    expect(menu, contains('height: closeSlotHeight'));
    expect(header, contains("ValueKey('home-more-cue-trigger')"));
    expect(menu, contains('alignment: Alignment.topCenter'));
    expect(menu, contains('offset: Offset((56 - triggerRect.width) / 2, 0)'));
  });

  testWidgets('FAB changes shape with scrolling and springs back to circle', (
    tester,
  ) async {
    final signal = ValueNotifier<Offset>(Offset.zero);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: BalynMorphingFab(motion: signal, onPressed: () {}),
          ),
        ),
      ),
    );
    final finder = find.ancestor(
      of: find.byKey(const ValueKey('quick-launcher')),
      matching: find.byType(Transform),
    );
    expect(finder, findsWidgets);
    signal.value = const Offset(.90, .12);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 55));
    final moving = tester.widget<Transform>(finder.first).transform;
    expect(moving.isIdentity(), isFalse);
    await tester.pumpAndSettle();
    final resting = tester.widget<Transform>(finder.first).transform;
    expect(resting.isIdentity(), isTrue);
    signal.dispose();
    expect(tester.takeException(), isNull);
  });
}
