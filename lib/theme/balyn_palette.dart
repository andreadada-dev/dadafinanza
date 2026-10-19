import 'package:balyn/l10n/localized_material.dart';

/// Balyn visual baseline: the redesigned Home is the reference for every
/// screen. Do not introduce screen-specific blue, teal, orange, or gray chrome.
/// Account and category colors and semantic financial colors remain dynamic.
abstract final class BalynPalette {
  static const accent = Color(0xFF7955EB);
  static const accentLight = Color(0xFF6B43D4);
  static const accentTextDark = Color(0xFFAE94FF);

  static const darkCanvas = Color(0xFF101018);
  static const darkSurface = Color(0xFF252532);
  static const darkSurfaceHigh = Color(0xFF30303D);
  static const darkText = Color(0xFFF5F4F9);
  static const darkMuted = Color(0xFFA3A5B6);
  static const darkHairline = Color(0xFF383847);

  static const lightCanvas = Color(0xFFF7F8FA);
  static const lightSurface = Colors.white;
  static const lightSurfaceHigh = Color(0xFFF0F0F6);
  static const lightText = Color(0xFF191721);
  static const lightMuted = Color(0xFF676779);
  static const lightHairline = Color(0xFFE6E5EE);

  static const incomeDark = Color(0xFF38E0A8);
  static const incomeLight = Color(0xFF12B880);
  static const expenseDark = Color(0xFFFF7373);
  static const expenseLight = Color(0xFFF53D3D);

  static const double radius = 22;
  static const double fieldRadius = 16;

  static Color canvas(Brightness brightness) =>
      brightness == Brightness.dark ? darkCanvas : lightCanvas;

  static Color surface(Brightness brightness) =>
      brightness == Brightness.dark ? darkSurface : lightSurface;
}
