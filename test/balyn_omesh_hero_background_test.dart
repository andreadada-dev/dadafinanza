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

  test('Mesh makes only gentle periodic movements without moving its corners', () {
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
  });

  test('Basic palette retains its pink cyan and cream while accounts vary', () {
    const violet = Color(0xFF6221E9);
    final basic = balynHeroMeshColors(violet, useBasicPalette: true);
    final account = balynHeroMeshColors(violet, useBasicPalette: false);
    const orange = Color(0xFFF5833C);
    final second = balynHeroMeshColors(orange, useBasicPalette: false);
    expect(basic, hasLength(9));
    expect(basic[0], const Color(0xFFA52B68));
    expect(basic[1], const Color(0xFF4693A9));
    expect(basic[4], const Color(0xFFE8DAD4));
    expect(account[0], isNot(second[0]));
    expect(account[4], isNot(second[4]));
  });

  testWidgets('Hero background is composed of a mesh and contrast scrim', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          height: 340,
          child: BalynOMeshHeroBackground(
            accent: Color(0xFF6221E9),
            useBasicPalette: true,
          ),
        ),
      ),
    ));
    expect(find.byType(OMeshGradient), findsOneWidget);
    expect(find.byKey(const ValueKey('hero-omesh-gradient')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('The original static wave ribbon is removed from Home', () {
    final hero = File('lib/widgets/balyn_revolut_home_hero.dart')
        .readAsStringSync();
    final mesh = File('lib/widgets/balyn_omesh_hero_background.dart')
        .readAsStringSync();
    expect(hero, contains('BalynOMeshHeroBackground('));
    expect(hero, isNot(contains('_AccountWavesPainter')));
    expect(hero, contains('Color(matching.first.colorValue)'));
    expect(mesh, contains('data!.clock'));
    expect(mesh, contains('TickerMode.of(context)'));
    expect(mesh, contains('MediaQuery.disableAnimationsOf(context)'));
    expect(mesh, contains('tessellation: 10'));
  });
}
