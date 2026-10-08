import 'package:balyn/widgets/smooth_indexed_pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _LivePage extends StatefulWidget {
  const _LivePage({required this.name, required this.mounts});

  final String name;
  final Map<String, int> mounts;

  @override
  State<_LivePage> createState() => _LivePageState();
}

class _LivePageState extends State<_LivePage> {
  @override
  void initState() {
    super.initState();
    widget.mounts[widget.name] = (widget.mounts[widget.name] ?? 0) + 1;
  }

  @override
  Widget build(BuildContext context) =>
      Text(widget.name, key: ValueKey(widget.name));
}

void main() {
  testWidgets('section transition keeps inactive tabs mounted', (tester) async {
    final mounts = <String, int>{};
    final pages = <Widget>[
      _LivePage(name: 'Home', mounts: mounts),
      _LivePage(name: 'Movimenti', mounts: mounts),
      _LivePage(name: 'Analisi', mounts: mounts),
    ];

    Widget shell(int selected) => MaterialApp(
      home: Scaffold(
        body: SmoothIndexedPages(index: selected, children: pages),
      ),
    );

    await tester.pumpWidget(shell(0));
    expect(mounts, {'Home': 1, 'Movimenti': 1, 'Analisi': 1});
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Movimenti'), findsNothing);

    await tester.pumpWidget(shell(1));
    await tester.pump(const Duration(milliseconds: 100));
    // Both pages are still mounted and in the middle of a crossfade.
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Movimenti'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Home'), findsNothing);
    expect(find.text('Movimenti'), findsOneWidget);

    await tester.pumpWidget(shell(0));
    await tester.pump(const Duration(milliseconds: 250));
    expect(mounts, {'Home': 1, 'Movimenti': 1, 'Analisi': 1});
    expect(find.text('Home'), findsOneWidget);
  });

  testWidgets('rapid section changes do not unmount the tab trees', (
    tester,
  ) async {
    final mounts = <String, int>{};
    final pages = <Widget>[
      _LivePage(name: 'Home', mounts: mounts),
      _LivePage(name: 'Analisi', mounts: mounts),
      _LivePage(name: 'Pianifica', mounts: mounts),
    ];

    Widget shell(int selected) => MaterialApp(
      home: Scaffold(
        body: SmoothIndexedPages(index: selected, children: pages),
      ),
    );

    await tester.pumpWidget(shell(0));
    await tester.pumpWidget(shell(1));
    await tester.pump(const Duration(milliseconds: 40));
    await tester.pumpWidget(shell(2));
    await tester.pump(const Duration(milliseconds: 250));
    expect(find.text('Pianifica'), findsOneWidget);
    expect(mounts, {'Home': 1, 'Analisi': 1, 'Pianifica': 1});
  });
}
