import 'package:balyn/l10n/localized_material.dart';
import 'balyn_palette.dart';

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
  // Balyn keeps a neutral high-contrast shell. Semantic finance colors
  // carry meaning; navigation and primary chrome stay black/white.
  static const purple = BalynPalette.accentLight;
  static const purpleDark = BalynPalette.accentTextDark;
  static const muted = BalynPalette.lightMuted;
  static const surface = Colors.transparent;
  static const border = Colors.transparent;

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    final background = BalynPalette.canvas(brightness);
    final raised = BalynPalette.surface(brightness);
    final raisedStrong = dark
        ? BalynPalette.darkSurfaceHigh
        : BalynPalette.lightSurfaceHigh;
    final hairline = dark
        ? BalynPalette.darkHairline
        : BalynPalette.lightHairline;
    final onSurface = dark ? BalynPalette.darkText : BalynPalette.lightText;
    final secondaryText = dark
        ? BalynPalette.darkMuted
        : BalynPalette.lightMuted;
    final primary = dark
        ? BalynPalette.accentTextDark
        : BalynPalette.accentLight;
    final accent = BalynPalette.accent;

    final scheme =
        ColorScheme.fromSeed(
          seedColor: primary,
          brightness: brightness,
          surface: background,
          error: dark ? const Color(0xFFFF7373) : const Color(0xFFF53D3D),
        ).copyWith(
          primary: primary,
          onPrimary: dark ? BalynPalette.darkCanvas : Colors.white,
          primaryContainer: accent,
          onPrimaryContainer: Colors.white,
          secondary: dark ? const Color(0xFF38E0A8) : const Color(0xFF12B880),
          onSecondary: Colors.white,
          tertiary: accent,
          onTertiary: Colors.white,
          surface: background,
          surfaceContainer: raised,
          surfaceContainerHigh: raisedStrong,
          surfaceContainerHighest: raisedStrong,
          onSurface: onSurface,
          onSurfaceVariant: secondaryText,
          outlineVariant: hairline,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: Colors.transparent,
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
        backgroundColor: background.withValues(alpha: dark ? .62 : .78),
        foregroundColor: onSurface,
        titleTextStyle: TextStyle(
          color: onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
      ),
      cardTheme: CardThemeData(
        margin: EdgeInsets.zero,
        elevation: 0,
        color: raised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(BalynPalette.radius),
        ),
      ),
      listTileTheme: ListTileThemeData(
        iconColor: primary,
        textColor: onSurface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 72,
        elevation: 0,
        backgroundColor: background.withValues(alpha: dark ? .68 : .82),
        indicatorColor: onSurface.withValues(alpha: dark ? .10 : .06),
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
        backgroundColor: accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: raised,
        hintStyle: TextStyle(color: secondaryText.withValues(alpha: .8)),
        labelStyle: TextStyle(color: secondaryText),
        floatingLabelStyle: TextStyle(color: primary),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BalynPalette.fieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BalynPalette.fieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(BalynPalette.fieldRadius),
          borderSide: BorderSide(color: primary, width: 1.3),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(48, 52),
          elevation: 0,
          backgroundColor: accent,
          foregroundColor: Colors.white,
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
        selectedColor: accent.withValues(alpha: dark ? .24 : .12),
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
                ? accent.withValues(alpha: dark ? .22 : .12)
                : raised,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) => onSurface,
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: raised,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: raised,
        modalBackgroundColor: raised,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accent : raisedStrong,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.selected) ? accent : raisedStrong,
        ),
        checkColor: const WidgetStatePropertyAll(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),
      radioTheme: RadioThemeData(fillColor: WidgetStatePropertyAll(primary)),
      sliderTheme: SliderThemeData(
        activeTrackColor: accent,
        thumbColor: accent,
        inactiveTrackColor: raisedStrong,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: primary,
        unselectedLabelColor: secondaryText,
        indicatorColor: accent,
        dividerColor: Colors.transparent,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: raised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: raisedStrong,
        contentTextStyle: TextStyle(color: onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      datePickerTheme: DatePickerThemeData(
        backgroundColor: raised,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: raised,
        headerForegroundColor: onSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: primary,
        linearTrackColor: onSurface.withValues(alpha: .10),
        circularTrackColor: onSurface.withValues(alpha: .10),
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
  FinanceColors get financeColors {
    final theme = Theme.of(this);
    final configured = theme.extension<FinanceColors>();
    if (configured != null) return configured;
    final dark = theme.brightness == Brightness.dark;
    return FinanceColors(
      positive: dark ? const Color(0xFF38E0A8) : const Color(0xFF12B880),
      negative: dark ? const Color(0xFFFF7373) : const Color(0xFFF53D3D),
      warning: dark ? const Color(0xFFFFB86B) : const Color(0xFFF57A3D),
      neutral: theme.colorScheme.onSurfaceVariant,
    );
  }
}
