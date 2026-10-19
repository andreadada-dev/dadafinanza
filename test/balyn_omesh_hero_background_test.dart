import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_omesh_hero_background.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mesh/mesh.dart';

void main() {
  test('Home gradient uses recognizable OMesh Basic Usage 3x3 positions', () {
    final vertices = balynHeroMeshVertices(0);
    expect(vertices, hasLength(9));
    expect(vertices.first.x, closeTo(-0.06, 0.0001));
    expect(vertices.first.y, closeTo(-0.08, 0.0001));
    expect(vertices[4].x, closeTo(0.44, 0.0001));
    expect(vertices[4].y, closeTo(0.657, 0.0001));
  });

  test(
    'Mesh makes only gentle periodic movements without moving its corners',
    () {
      final first = balynHeroMeshVertices(0);
      final later = balynHeroMeshVertices(0.125);
      final cycle = balynHeroMeshVertices(0.5);
      for (final i in [0, 2, 6, 8]) {
        expect(later[i].x, first[i].x);
        expect(later[i].y, first[i].y);
      }
      expect(later[4].x, isNot(first[4].x));
      expect((later[4].x - first[4].x).abs(), lessThan(0.05));
      for (var i = 0; i < 9; i++) {
        expect(cycle[i].x, closeTo(first[i].x, 0.00001));
        expect(cycle[i].y, closeTo(first[i].y, 0.00001));
      }
    },
  );

  test('Gradient remains within the account hue family', () {
    const violet = Color(0xFF6221E9);
    const green = Color(0xFF259B50);
    final total = balynHeroMeshColors(violet, useBasicPalette: true);
    final violetShades = balynHeroMeshColors(violet, useBasicPalette: false);
    final greenShades = balynHeroMeshColors(green, useBasicPalette: false);
    expect(total, hasLength(9));
    expect(total.toSet().length, greaterThan(2));
    expect(violetShades[0], isNot(greenShades[0]));
    for (final color in violetShades) {
      final hue = HSLColor.fromColor(color).hue;
      expect(hue, inInclusiveRange(235, 335));
    }
    for (final color in greenShades) {
      final hue = HSLColor.fromColor(color).hue;
      expect(hue, inInclusiveRange(70, 180));
    }
  });

  testWidgets('Hero background is composed of a mesh and contrast scrim', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            height: 340,
            child: BalynOMeshHeroBackground(
              accent: Color(0xFF6221E9),
              useBasicPalette: true,
            ),
          ),
        ),
      ),
    );
    expect(find.byType(OMeshGradient), findsOneWidget);
    expect(find.byKey(const ValueKey('hero-omesh-gradient')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('The original static wave ribbon is removed from Home', () {
    final hero = File(
      'lib/widgets/balyn_revolut_home_hero.dart',
    ).readAsStringSync();
    final mesh = File(
      'lib/widgets/balyn_omesh_hero_background.dart',
    ).readAsStringSync();
    expect(hero, contains('BalynOMeshHeroBackground('));
    expect(hero, isNot(contains('_AccountWavesPainter')));
    expect(hero, contains('Color(matching.first.colorValue)'));
    expect(mesh, contains('data!.clock'));
    expect(mesh, contains('TickerMode.of(context)'));
    expect(mesh, contains('MediaQuery.disableAnimationsOf(context)'));
    expect(mesh, contains('tessellation: 10'));
  });
}
