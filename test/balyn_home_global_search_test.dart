import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home search is editable and indexes sections, money and tags', () {
    final source = File(
      'lib/widgets/balyn_global_search_bar.dart',
    ).readAsStringSync();
    expect(source, contains('SearchAnchor('));
    expect(source, contains('SearchBar('));
    expect(source, contains("ValueKey('home-global-search')"));
    expect(source, contains('suggestionsBuilder:'));
    expect(source, contains('state.transactions'));
    expect(source, contains('...item.tags'));
    expect(source, contains('item.amount.toStringAsFixed(2)'));
    expect(source, contains('TransactionDetailPage('));
    expect(source, contains('transactionId: item.id'));
    expect(source, contains('.take(query.isEmpty ? 5 : 30)'));
    expect(source, contains("ValueKey('search-recent-movements')"));
    expect(source, contains("ValueKey('search-six-sections')"));
    expect(
      source.indexOf("const _SearchHeading('Sezioni')"),
      greaterThan(source.indexOf("Movimenti recenti")),
    );
    expect(source, contains('SliverGridDelegateWithFixedCrossAxisCount('));
    expect(source, contains('crossAxisCount: 2'));
    expect(source, contains('transactionColor(context, item.type)'));
    expect(source, contains('TransactionType.income'));
    expect(source, contains('TransactionType.expense'));
    expect(source, contains('BalynPalette.surface('));
    for (final section in ['Pianifica', 'Anticipi', 'Conti', 'Movimenti']) {
      expect(source, contains("'$section'"));
    }
  });

  test('Home keeps original More icon, now in statistics slot', () {
    final hero = File(
      'lib/widgets/balyn_revolut_home_hero.dart',
    ).readAsStringSync();
    final more = File(
      'lib/widgets/balyn_cue_three_dots_action.dart',
    ).readAsStringSync();
    expect(hero, contains('BalynGlobalSearchBar('));
    expect(hero, contains('BalynCueThreeDotsAction('));
    expect(hero, isNot(contains('Icons.bar_chart_rounded')));
    expect(more, contains('Icons.more_vert_rounded'));
    expect(more, contains('showMenu<String>('));
    expect(more, contains('rightEdge - _menuWidth'));
    expect(more, isNot(contains('BalynCueAnchoredMenu')));
  });

  test(
    'Movement editor shows outlined note and tag suggestions without filters',
    () {
      final editor = File('lib/screens/quick_add_page.dart').readAsStringSync();
      final metadata = File(
        'lib/widgets/transaction_metadata_fields.dart',
      ).readAsStringSync();
      expect(editor, contains('TransactionMetadataSection.description'));
      expect(editor, contains('TransactionMetadataSection.tags'));
      expect(metadata, isNot(contains('SegmentedButton<_MetadataFilter>')));
      expect(metadata, isNot(contains('Es. #Università o #Vacanza')));
      expect(metadata, contains('index.noteSuggestions('));
      expect(metadata, contains('index.tagSuggestions('));
      final strip = File(
        'lib/widgets/quick_suggestion_strip.dart',
      ).readAsStringSync();
      expect(strip, contains('side: BorderSide('));
      expect(strip, contains('shape: const StadiumBorder()'));
    },
  );
  test('Home balance and visibility button remain centered together', () {
    final hero = File(
      'lib/widgets/balyn_revolut_home_hero.dart',
    ).readAsStringSync();
    final section = hero.substring(
      hero.indexOf("height: 48,"),
      hero.indexOf("'Disponibile  \$available'"),
    );
    expect(section, contains('child: Center('));
    expect(section, contains('child: FittedBox('));
    expect(section, contains('mainAxisSize: MainAxisSize.min'));
    expect(section, contains('Icons.visibility_off_outlined'));
    expect(section, contains('Icons.visibility_outlined'));
    expect(section, isNot(contains('Flexible(')));
  });
}
