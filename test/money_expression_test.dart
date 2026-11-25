import 'package:balyn/core/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quick amount expressions support all four arithmetic operators', () {
    expect(Money.parseExpression('12,50 + 4,20'), 16.70);
    expect(Money.parseExpression('20 - 3,50'), 16.50);
    expect(Money.parseExpression('7 * 3'), 21);
    expect(Money.parseExpression('8 / 4'), 2);
    expect(Money.parseExpression('7 × 3'), 21);
    expect(Money.parseExpression('8 ÷ 4'), 2);
    expect(Money.parseExpression('20 − 3,50'), 16.50);
    expect(Money.parseExpression('10 + 2 * 3'), 16);
  });

  test('decimal separators and exact monetary rounding agree', () {
    for (final input in ['12,50', '12.50', '12,5', '12.5']) {
      expect(Money.parseExpression(input), 12.50);
      expect(Money.parseAmount(input), 12.50);
    }
    expect(Money.parseExpression(',50'), .50);
    expect(Money.parseExpression('.50'), .50);
    expect(Money.parseExpression('12,'), 12);
    expect(Money.parseExpression('12.'), 12);
    expect(Money.parseExpression('1.005'), 1.01);
    expect(Money.parseExpression('2,675'), 2.68);
    expect(Money.parseExpression('0.1 + 0,2'), .30);
    expect(Money.parseExpression('2.01 / 2'), 1.01);
    expect(Money.parseExpression('0 - 2.01 / 2'), -1.01);
    expect(Money.toCents(1.005), 101);
    expect(Money.toCents(-1.005), -101);
    expect(Money.parseAmount('-12,50'), -12.50);
  });

  test('invalid or ambiguous grouped inputs never become another amount', () {
    for (final input in [
      '1.234,56',
      '1,234.56',
      '12,,50',
      '12.3.4',
      '1 / 0',
      'NaN',
      'Infinity',
      '999999999999999999999999999999',
    ]) {
      expect(Money.parseExpression(input), isNull, reason: input);
    }
    expect(Money.parseAmount('1+2'), isNull);
    expect(Money.parseExpression('0.004'), 0);
  });
}
