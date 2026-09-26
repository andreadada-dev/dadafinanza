import 'package:dadafinanza/l10n/localized_material.dart';

@immutable
class FinanceColors extends ThemeExtension<FinanceColors> {
  const FinanceColors({
    required this.positive,
    required this.negative,
    required this.warning,
    required this.neutral,
  });

  final Color positive;
  final Color negative;
  final Color warning;
  final Color neutral;

  @override
  FinanceColors copyWith({
    Color? positive,
    Color? negative,
    Color? warning,
    Color? neutral,
  }) => FinanceColors(
    positive: positive ?? this.positive,
    negative: negative ?? this.negative,
    warning: warning ?? this.warning,
    neutral: neutral ?? this.neutral,
  );

  @override
  FinanceColors lerp(covariant FinanceColors? other, double t) {
    if (other == null) return this;
    return FinanceColors(
      positive: Color.lerp(positive, other.positive, t)!,
      negative: Color.lerp(negative, other.negative, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      neutral: Color.lerp(neutral, other.neutral, t)!,
    );
  }
}

class AppTheme {
  // DadaFinanza keeps a neutral high-contrast shell. Semantic finance colors
  // carry meaning; navigation and primary chrome stay black/white.
  static const purple = Color(0xFF5C3DF5);
  static const purpleDark = Color(0xFF7B62F5);
  static const muted = Color(0xFF74747A);
  static const surface = Colors.transparent;
  static const border = Colors.transparent;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = dark ? const Color(0xFF09090A) : const Color(0xFFFAFAFC);
    final raised = dark ? const Color(0xFF1C1C1F) : const Color(0xFFF0F0F5);
    final raisedStrong = dark
        ? const Color(0xFF303033)
        : const Color(0xFFE8E8EF);
    final hairline = dark ? const Color(0xFF303033) : const Color(0xFFEBEBF0);
    final onSurface = dark ? const Color(0xFFFAFAFC) : const Color(0xFF09090A);
    final secondaryText = dark
        ? const Color(0xFFCBCBD6)
        : const Color(0xFF74747A);
    final primary = onSurface;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
          surface: background,
          error: dark ? const Color(0xFFFF7373) : const Color(0xFFF53D3D),
        ).copyWith(
          primary: primary,
          onPrimary: background,
          secondary: dark ? const Color(0xFF38E0A8) : const Color(0xFF12B880),
          onSecondary: Colors.white,
          surface: background,
          surfaceContainer: raised,
          surfaceContainerHigh: raisedStrong,
          surfaceContainerHighest: raisedStrong,
          onSurface: onSurface,
          onSurfaceVariant: secondaryText,
          outlineVariant: hairline,
        );

    final underline = UnderlineInputBorder(
      borderSide: BorderSide(color: hairline),
    );
    final focusedUnderline = UnderlineInputBorder(
      borderSide: BorderSide(color: scheme.primary, width: 1.7),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: background,
      dividerColor: hairline,
      visualDensity: VisualDensity.standard,
      splashFactory: InkSparkle.splashFactory,
      extensions: [
        FinanceColors(
          positive: dark ? const Color(0xFF38E0A8) : const Color(0xFF12B880),
          negative: dark ? const Color(0xFFFF7373) : const Color(0xFFF53D3D),
          warning: dark ? const Color(0xFFFFB86B) : const Color(0xFFF57A3D),
          neutral: secondaryText,
        ),
      ],
      textTheme: TextTheme(
        displaySmall: TextStyle(
          color: onSurface,
          letterSpacing: -1.5,
          fontWeight: FontWeight.w800,
        ),
        headlineLarge: TextStyle(
          color: onSurface,
          letterSpacing: -1.1,
          fontWeight: FontWeight.w800,
        ),
        headlineMedium: TextStyle(
          color: onSurface,
          letterSpacing: -.8,
          fontWeight: FontWeight.w800,
        ),
        headlineSmall: TextStyle(
          color: onSurface,
          letterSpacing: -.5,
          fontWeight: FontWeight.w800,
        ),
        titleLarge: TextStyle(
          color: onSurface,
          letterSpacing: -.5,
          fontWeight: FontWeight.w800,
        ),
        titleMedium: TextStyle(
          color: onSurface,
          letterSpacing: -.15,
          fontWeight: FontWeight.w700,
        ),
        bodyLarge: TextStyle(color: onSurface, height: 1.4),
        bodyMedium: TextStyle(color: secondaryText, height: 1.4),
        bodySmall: TextStyle(color: secondaryText, height: 1.35),
        labelLarge: TextStyle(color: onSurface, fontWeight: FontWeight.w700),
      ),
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: background.withValues(alpha: .96),
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
      ),
      cardTheme: const CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: Colors.transparent,
        surfaceTintColor: Colors.transparent,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: background,
        indicatorColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected)
                ? onSurface
                : secondaryText,
            fontSize: 11,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w800
                : FontWeight.w500,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? onSurface
                : secondaryText,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        elevation: 0,
        highlightElevation: 0,
        backgroundColor: onSurface,
        foregroundColor: background,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        hintStyle: TextStyle(color: secondaryText.withValues(alpha: .8)),
        labelStyle: TextStyle(color: secondaryText),
        contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 13),
        border: underline,
        enabledBorder: underline,
        focusedBorder: focusedUnderline,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 52),
          side: BorderSide.none,
          backgroundColor: raised,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: primary,
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: onSurface,
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: raised,
        selectedColor: primary.withValues(alpha: dark ? .20 : .11),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        side: BorderSide.none,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
          side: const WidgetStatePropertyAll(BorderSide.none),
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.selected)
                ? primary.withValues(alpha: dark ? .20 : .11)
                : raised,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected) ? primary : onSurface,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: dark ? const Color(0xFF1C1C1F) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: dark ? const Color(0xFF1C1C1F) : Colors.white,
        modalBackgroundColor: dark ? const Color(0xFF1C1C1F) : Colors.white,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: primary.withValues(alpha: .10),
        circularTrackColor: primary.withValues(alpha: .10),
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
        },
      ),
    );
  }
}

extension FinanceThemeContext on BuildContext {
  FinanceColors get financeColors => Theme.of(this).extension<FinanceColors>()!;
}
