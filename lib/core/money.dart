/// Integer minor-unit helpers used at persistence and validation boundaries.
abstract final class Money {
  static const int scale = 100;

  // Keep every cent representable through the legacy double UI/domain API.
  static const int maxCents = 99999999999999;

  static int toCents(num value) {
    if (!value.isFinite) throw ArgumentError.value(value, 'value');
    final cents = _Decimal.parse(value.toString()).roundedCents;
    if (cents.abs() > BigInt.from(maxCents)) {
      throw ArgumentError.value(value, 'value', 'Importo troppo grande');
    }
    return cents.toInt();
  }

  static double fromCents(int cents) => cents / scale;

  static int? nullableToCents(num? value) =>
      value == null ? null : toCents(value);

  static double? nullableFromCents(Object? value) =>
      value == null ? null : fromCents((value as num).toInt());

  static int centsFromMap(
    Map<String, Object?> map,
    String centsKey,
    String legacyKey,
  ) {
    final cents = map[centsKey];
    if (cents is num) return cents.toInt();
    final legacy = map[legacyKey];
    return legacy is num ? toCents(legacy) : 0;
  }

  static double valueFromMap(
    Map<String, Object?> map,
    String centsKey,
    String legacyKey,
  ) => fromCents(centsFromMap(map, centsKey, legacyKey));

  /// A plain amount, without operators or thousands separators.
  static double? parseAmount(String raw) {
    final input = raw.trim();
    if (!RegExp(r'^[+-]?(?:\d+(?:[.,]\d*)?|[.,]\d+)$').hasMatch(input)) {
      return null;
    }
    final negative = input.startsWith('-');
    final unsigned = input.replaceFirst(RegExp(r'^[+-]'), '');
    final value = parseExpression(unsigned);
    return value == null ? null : (negative ? -value : value);
  }

  /// Both comma and dot mean a decimal separator; grouping is not supported.
  /// Arithmetic is exact until the final cent rounding (half away from zero).
  static double? parseExpression(String raw) {
    if (raw.length > 128) return null;
    final input = raw
        .trim()
        .replaceAll(',', '.')
        .replaceAll('×', '*')
        .replaceAll('÷', '/')
        .replaceAll('−', '-')
        .replaceAll(' ', '');
    if (input.isEmpty || !RegExp(r'^[0-9.+\-*/]+$').hasMatch(input)) {
      return null;
    }
    final tokens = RegExp(
      r'(\d+(?:\.\d*)?|\.\d+|[+\-*/])',
    ).allMatches(input).map((match) => match.group(0)!).toList();
    if (tokens.join() != input || tokens.isEmpty) return null;

    final values = <_Decimal>[];
    final ops = <String>[];
    int precedence(String op) => (op == '*' || op == '/') ? 2 : 1;
    bool apply() {
      if (values.length < 2 || ops.isEmpty) return false;
      final b = values.removeLast();
      final a = values.removeLast();
      final op = ops.removeLast();
      if (op == '/' && b.numerator == BigInt.zero) return false;
      values.add(switch (op) {
        '+' => a + b,
        '-' => a - b,
        '*' => a * b,
        '/' => a / b,
        _ => throw StateError('Invalid operator'),
      });
      return true;
    }

    var expectNumber = true;
    for (final token in tokens) {
      final isNumber = RegExp(r'^[0-9.]').hasMatch(token);
      if (expectNumber) {
        if (!isNumber) return null;
        values.add(_Decimal.parse(token));
      } else {
        if (isNumber) return null;
        while (ops.isNotEmpty && precedence(ops.last) >= precedence(token)) {
          if (!apply()) return null;
        }
        ops.add(token);
      }
      expectNumber = !expectNumber;
    }
    if (expectNumber) return null;
    while (ops.isNotEmpty) {
      if (!apply()) return null;
    }
    if (values.length != 1) return null;
    final cents = values.single.roundedCents;
    if (cents.abs() > BigInt.from(maxCents)) return null;
    return fromCents(cents.toInt());
  }
}

/// Rational arithmetic avoids binary floating-point rounding of values such
/// as 1.005 or 2.675, including results of the amount calculator.
class _Decimal {
  _Decimal(BigInt n, BigInt d)
    : numerator = d.isNegative ? -n : n,
      denominator = d.abs();

  factory _Decimal.parse(String text) {
    final parts = text.toLowerCase().split('e');
    final negative = parts.first.startsWith('-');
    final mantissa = parts.first.replaceFirst(RegExp(r'^[+-]'), '');
    final decimal = mantissa.split('.');
    final fraction = decimal.length > 1 ? decimal[1] : '';
    final digits = BigInt.parse(decimal[0] + fraction);
    final exponent =
        (parts.length > 1 ? int.parse(parts[1]) : 0) - fraction.length;
    final n = negative ? -digits : digits;
    final ten = BigInt.from(10);
    return exponent >= 0
        ? _Decimal(n * ten.pow(exponent), BigInt.one)
        : _Decimal(n, ten.pow(-exponent));
  }

  final BigInt numerator;
  final BigInt denominator;

  _Decimal operator +(_Decimal other) => _Decimal(
    numerator * other.denominator + other.numerator * denominator,
    denominator * other.denominator,
  );

  _Decimal operator -(_Decimal other) => _Decimal(
    numerator * other.denominator - other.numerator * denominator,
    denominator * other.denominator,
  );

  _Decimal operator *(_Decimal other) =>
      _Decimal(numerator * other.numerator, denominator * other.denominator);

  _Decimal operator /(_Decimal other) =>
      _Decimal(numerator * other.denominator, denominator * other.numerator);

  BigInt get roundedCents {
    final scaled = numerator.abs() * BigInt.from(Money.scale);
    final quotient = scaled ~/ denominator;
    final remainder = scaled % denominator;
    final rounded = remainder * BigInt.from(2) >= denominator
        ? quotient + BigInt.one
        : quotient;
    return numerator.isNegative ? -rounded : rounded;
  }
}
