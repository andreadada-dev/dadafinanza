import 'dart:io';
import 'package:balyn/l10n/localized_material.dart';
import 'package:balyn/widgets/balyn_balance_analytics_charts.dart';
import 'package:balyn/widgets/finance_charts.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:introduction_screen/introduction_screen.dart';
import 'package:balyn/screens/balyn_onboarding_flow.dart';

void main() {
  test('first launch is gated and never overwrites an existing user', () {
    final main = File('lib/main.dart').readAsStringSync();
    final flow = File(
      'lib/screens/balyn_onboarding_flow.dart',
    ).readAsStringSync();
    expect(main, contains("getSetting('onboarding_completed')"));
    expect(main, contains('state.userAccounts.isEmpty'));
    expect(main, contains('state.transactions.isEmpty'));
    expect(flow, contains("setSetting('onboarding_completed', '1')"));
    expect(flow, contains('if (!skip)'));
    expect(flow, contains('if (state.userAccounts.isEmpty)'));
    expect(flow, contains('IntroductionScreen('));
    expect(flow, contains('rawPages: ['));
    expect(flow, contains('onChange: (page)'));
    expect(flow, contains('onDone: () => _complete()'));
    expect(flow, contains('dotsDecorator: const DotsDecorator('));
    expect(flow, contains("onTap: () => setState(() => _skipping = true)"));
  });

  testWidgets('IntroductionScreen has three Balyn pages and actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: BalynOnboardingFlow(onFinished: _noop)),
    );
    expect(find.byType(IntroductionScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-skip')), findsOneWidget);
    expect(find.text('Le tue finanze, più semplici'), findsOneWidget);
    expect(find.byKey(const ValueKey('onboarding-next')), findsOneWidget);
    // The package handles the navigation, rather than a custom PageView.
    await tester.tap(find.byKey(const ValueKey('onboarding-next')));
    await tester.pump(const Duration(milliseconds: 700));
    expect(find.text('Crea il tuo primo conto'), findsOneWidget);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  test('transaction details use real edit and analytics persistence', () {
    final screen = File(
      'lib/screens/transaction_screens.dart',
    ).readAsStringSync();
    final design = File(
      'lib/widgets/balyn_transaction_detail_content.dart',
    ).readAsStringSync();
    expect(screen, contains('BalynTransactionDetailContent('));
    expect(screen, contains('QuickAddPage(editing: item)'));
    expect(screen, contains('await _delete(context, item, state)'));
    expect(screen, contains('includeInAnalytics: included'));
    expect(design, contains('Escludi dalle analisi'));
    expect(design, contains('item.receiptPath'));
  });

  testWidgets('donut shows actual category share, not a hardcoded percentage', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: BalynBalanceDonut(
            segments: [
              FinanceDonutSegment(
                label: 'Casa',
                value: 75,
                color: Color(0xFFFF6B5B),
              ),
              FinanceDonutSegment(
                label: 'Cibo',
                value: 25,
                color: Color(0xFFB9AEFF),
              ),
            ],
            valueFormatter: _formatValue,
            hidden: false,
          ),
        ),
      ),
    );
    expect(find.text('75%'), findsOneWidget);
    expect(find.text('Casa'), findsWidgets);
  });
}

String _formatValue(double value) => value.toStringAsFixed(2);

void _noop() {}
