import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Home search is editable and indexes sections, money and tags', () {
    final source = File('lib/widgets/balyn_global_search_bar.dart')
        .readAsStringSync();
    expect(source, contains('SearchAnchor('));
    expect(source, contains('SearchBar('));
    expect(source, contains("ValueKey('home-global-search')"));
    expect(source, contains('suggestionsBuilder:'));
    expect(source, contains('state.transactions'));
    expect(source, contains('...item.tags'));
    expect(source, contains('item.amount.toStringAsFixed(2)'));
    expect(source, contains('TransactionDetailPage(transactionId: item.id)'));
    for (final section in ['Pianifica', 'Anticipi', 'Conti', 'Movimenti']) {
      expect(source, contains("'$section'"));
    }
  });

  test('Home keeps original More icon, now in statistics slot', () {
    final hero = File('lib/widgets/balyn_revolut_home_hero.dart')
        .readAsStringSync();
    final more = File('lib/widgets/balyn_cue_three_dots_action.dart')
        .readAsStringSync();
    expect(hero, contains('BalynGlobalSearchBar('));
    expect(hero, contains('BalynCueThreeDotsAction('));
    expect(hero, isNot(contains('Icons.bar_chart_rounded')));
    expect(more, contains('Icons.more_vert_rounded'));
    expect(more, contains('PopupMenuPosition.under'));
    expect(more, isNot(contains('BalynCueAnchoredMenu')));
  });

  test('New movement separates Tag and Description cards and filters', () {
    final editor = File('lib/screens/quick_add_page.dart').readAsStringSync();
    final metadata = File('lib/widgets/transaction_metadata_fields.dart')
        .readAsStringSync();
    expect(editor, contains('TransactionMetadataSection.description'));
    expect(editor, contains('TransactionMetadataSection.tags'));
    expect(metadata, contains("Text('Tutti')"));
    expect(metadata, contains("Text('Recenti')"));
    expect(metadata, contains("Text('Preferiti')"));
    expect(metadata, contains('item.favorite'));
    expect(metadata, contains('lastUsed.compareTo'));
  });
}
