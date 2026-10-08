import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:balyn/l10n/localized_material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

enum BalynShaderFeature { generic, text, icon, bar, chart }

class BalynShaderPrograms {
  BalynShaderPrograms._();

  static ui.FragmentProgram? _background;
  static ui.FragmentProgram? _ink;
  static Future<void>? _loading;

  static ui.FragmentProgram? get background => _background;
  static ui.FragmentProgram? get ink => _ink;
  static bool get ready => _background != null && _ink != null;

  static Future<void> preload() async {
    if (ready) return;
    final existing = _loading;
    if (existing != null) {
      await existing;
      return;
    }

    final loading = _load();
    _loading = loading;
    try {
      await loading;
    } finally {
      if (!ready) _loading = null;
    }
  }

  static Future<void> _load() async {
    final programs = await Future.wait([
      ui.FragmentProgram.fromAsset('shaders/balyn_background.frag'),
      ui.FragmentProgram.fromAsset('shaders/balyn_ink.frag'),
    ]);
    _background = programs[0];
    _ink = programs[1];
  }
}

/// Shared clock and GPU programs for Balyn's living-color system.
///
/// One slow clock drives the whole app so colored elements feel like the same
/// material instead of dozens of unrelated animations.
class BalynShaderScope extends StatefulWidget {
  const BalynShaderScope({
    required this.child,
    this.loadPrograms = true,
    this.backgroundEnabled = true,
    this.textEnabled = true,
    this.iconEnabled = true,
    this.chartEnabled = true,
    this.barEnabled = true,
    super.key,
  });

  final Widget child;

  @visibleForTesting
  final bool loadPrograms;
  final bool backgroundEnabled;
  final bool textEnabled;
  final bool iconEnabled;
  final bool chartEnabled;
  final bool barEnabled;

  static BalynShaderData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BalynShaderInherited>()?.data;

  @override
  State<BalynShaderScope> createState() => _BalynShaderScopeState();
}

class BalynShaderData {
  const BalynShaderData({
    required this.clock,
    required this.motionEnabled,
    required this.backgroundEnabled,
    required this.textEnabled,
    required this.iconEnabled,
    required this.chartEnabled,
    required this.barEnabled,
    this.backgroundProgram,
    this.inkProgram,
  });

  final ValueListenable<double> clock;
  final bool motionEnabled;
  final bool backgroundEnabled;
  final bool textEnabled;
  final bool iconEnabled;
  final bool chartEnabled;
  final bool barEnabled;
  final ui.FragmentProgram? backgroundProgram;
  final ui.FragmentProgram? inkProgram;

  bool isEnabled(BalynShaderFeature feature) => switch (feature) {
    BalynShaderFeature.generic => true,
    BalynShaderFeature.text => textEnabled,
    BalynShaderFeature.icon => iconEnabled,
    BalynShaderFeature.bar => barEnabled,
    BalynShaderFeature.chart => chartEnabled,
  };
}

class _BalynShaderScopeState extends State<BalynShaderScope>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const _backgroundCycle = Duration(seconds: 72);
  static const _frameInterval = Duration(milliseconds: 33);

  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  late final Ticker _ticker;
  Duration _lastPublished = Duration.zero;
  ui.FragmentProgram? _backgroundProgram;
  ui.FragmentProgram? _inkProgram;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _backgroundProgram = BalynShaderPrograms.background;
    _inkProgram = BalynShaderPrograms.ink;
    _ticker = createTicker(_onTick)..start();
    if (widget.loadPrograms && !BalynShaderPrograms.ready) {
      _loadPrograms();
    }
  }

  void _onTick(Duration elapsed) {
    if (!_appActive) return;
    if (elapsed - _lastPublished < _frameInterval) return;
    _lastPublished = elapsed;

    final cycleMicros = _backgroundCycle.inMicroseconds;
    final phaseMicros = elapsed.inMicroseconds % cycleMicros;
    _clock.value = phaseMicros / cycleMicros;
  }

  Future<void> _loadPrograms() async {
    await BalynShaderPrograms.preload();
    if (!mounted) return;
    setState(() {
      _backgroundProgram = BalynShaderPrograms.background;
      _inkProgram = BalynShaderPrograms.ink;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncClock();
  }

  void _syncClock() {
    if (_appActive) {
      if (!_ticker.isActive) _ticker.start();
    } else if (_ticker.isActive) {
      _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = BalynShaderData(
      clock: _clock,
      motionEnabled: _appActive,
      backgroundEnabled: widget.backgroundEnabled,
      textEnabled: widget.textEnabled,
      iconEnabled: widget.iconEnabled,
      chartEnabled: widget.chartEnabled,
      barEnabled: widget.barEnabled,
      backgroundProgram: _backgroundProgram,
      inkProgram: _inkProgram,
    );
    return _BalynShaderInherited(data: data, child: widget.child);
  }
}

class _BalynShaderInherited extends InheritedWidget {
  const _BalynShaderInherited({required this.data, required super.child});

  final BalynShaderData data;

  @override
  bool updateShouldNotify(_BalynShaderInherited oldWidget) =>
      oldWidget.data.backgroundProgram != data.backgroundProgram ||
      oldWidget.data.inkProgram != data.inkProgram ||
      oldWidget.data.motionEnabled != data.motionEnabled ||
      oldWidget.data.backgroundEnabled != data.backgroundEnabled ||
      oldWidget.data.textEnabled != data.textEnabled ||
      oldWidget.data.iconEnabled != data.iconEnabled ||
      oldWidget.data.chartEnabled != data.chartEnabled ||
      oldWidget.data.barEnabled != data.barEnabled;
}

/// App-wide black/white surface with extremely slow liquid waves.
///
/// Dark mode stays visually black: the colored energy is intentionally faint
/// and only becomes obvious after looking at the surface for a few seconds.
class BalynShaderBackdrop extends StatelessWidget {
  const BalynShaderBackdrop({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final data = BalynShaderScope.maybeOf(context);
    final fallback = dark ? Colors.black : Colors.white;

    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: fallback),
        if (data?.backgroundEnabled == true && data?.backgroundProgram != null)
          Positioned.fill(
            child: IgnorePointer(
              child: RepaintBoundary(
                child: AnimatedBuilder(
                  animation: data!.clock,
                  builder: (context, _) => CustomPaint(
                    painter: _BalynBackgroundPainter(
                      program: data.backgroundProgram!,
                      time: data.motionEnabled ? data.clock.value : 0,
                      dark: dark,
                    ),
                  ),
                ),
              ),
            ),
          ),
        child,
      ],
    );
  }
}

class _BalynBackgroundPainter extends CustomPainter {
  const _BalynBackgroundPainter({
    required this.program,
    required this.time,
    required this.dark,
  });

  final ui.FragmentProgram program;
  final double time;
  final bool dark;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final shader = program.fragmentShader()
      ..setFloat(0, size.width)
      ..setFloat(1, size.height)
      ..setFloat(2, time)
      ..setFloat(3, dark ? 1 : 0);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(_BalynBackgroundPainter oldDelegate) =>
      oldDelegate.time != time ||
      oldDelegate.dark != dark ||
      oldDelegate.program != program;
}

/// Applies the Balyn animated material to any alpha-masked child.
///
/// Use this for semantic colors (income, expense, accent, categories) while
/// ordinary copy remains neutral black/white/gray.
class BalynShaderInk extends StatefulWidget {
  const BalynShaderInk({
    required this.seed,
    required this.child,
    this.enabled = true,
    this.strength = .68,
    this.sheen = .45,
    this.motionMultiplier = 6,
    this.feature = BalynShaderFeature.generic,
    super.key,
  });

  final Color seed;
  final Widget child;
  final bool enabled;
  final double strength;
  final double sheen;
  final double motionMultiplier;
  final BalynShaderFeature feature;

  @override
  State<BalynShaderInk> createState() => _BalynShaderInkState();
}

class _BalynShaderInkState extends State<BalynShaderInk> {
  ui.FragmentProgram? _program;
  ui.FragmentShader? _shader;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = BalynShaderScope.maybeOf(context)?.inkProgram;
    if (!identical(next, _program)) {
      _program = next;
      _shader = next?.fragmentShader();
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = BalynShaderScope.maybeOf(context);
    if (!widget.enabled || (data != null && !data.isEnabled(widget.feature))) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(widget.seed, BlendMode.srcIn),
        child: widget.child,
      );
    }

    final shader = _shader;
    if (data == null || shader == null) {
      return ColorFiltered(
        colorFilter: ColorFilter.mode(widget.seed, BlendMode.srcIn),
        child: widget.child,
      );
    }

    final palette = balynShaderPalette(widget.seed);
    final animation = data.motionEnabled
        ? data.clock
        : const AlwaysStoppedAnimation<double>(0);

    return AnimatedBuilder(
      animation: animation,
      child: widget.child,
      builder: (context, child) => ShaderMask(
        blendMode: BlendMode.srcIn,
        shaderCallback: (bounds) {
          _configureInkShader(
            shader,
            bounds.size,
            data.motionEnabled
                ? _scaledPhase(data.clock.value, widget.motionMultiplier)
                : 0,
            palette,
            strength: widget.strength,
            sheen: widget.sheen,
          );
          return shader;
        },
        child: child,
      ),
    );
  }
}

class BalynShaderText extends StatelessWidget {
  const BalynShaderText(
    this.data, {
    required this.seed,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.softWrap,
    super.key,
  });

  final String data;
  final Color seed;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final bool? softWrap;

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? DefaultTextStyle.of(context).style;
    return BalynShaderInk(
      seed: seed,
      feature: BalynShaderFeature.text,
      strength: .78,
      sheen: .58,
      child: Text(
        data,
        textAlign: textAlign,
        maxLines: maxLines,
        overflow: overflow,
        softWrap: softWrap,
        style: baseStyle.copyWith(color: Colors.white),
      ),
    );
  }
}

class BalynShaderLinearProgress extends StatelessWidget {
  const BalynShaderLinearProgress({
    required this.value,
    required this.seed,
    this.minHeight = 6,
    this.borderRadius = const BorderRadius.all(Radius.circular(999)),
    super.key,
  });

  final double value;
  final Color seed;
  final double minHeight;
  final BorderRadiusGeometry borderRadius;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(
      context,
    ).colorScheme.onSurface.withValues(alpha: .10);
    return Stack(
      children: [
        LinearProgressIndicator(
          value: 1,
          minHeight: minHeight,
          borderRadius: borderRadius,
          color: track,
          backgroundColor: Colors.transparent,
        ),
        BalynShaderInk(
          seed: seed,
          feature: BalynShaderFeature.bar,
          strength: .62,
          sheen: .32,
          motionMultiplier: 5,
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0).toDouble(),
            minHeight: minHeight,
            borderRadius: borderRadius,
            color: Colors.white,
            backgroundColor: Colors.transparent,
          ),
        ),
      ],
    );
  }
}

class BalynShaderIcon extends StatelessWidget {
  const BalynShaderIcon(
    this.icon, {
    required this.seed,
    this.size,
    this.semanticLabel,
    super.key,
  });

  final IconData icon;
  final Color seed;
  final double? size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) => BalynShaderInk(
    seed: seed,
    feature: BalynShaderFeature.icon,
    strength: .88,
    sheen: .68,
    child: Icon(
      icon,
      size: size,
      color: Colors.white,
      semanticLabel: semanticLabel,
    ),
  );
}

/// Generates three related colors rather than a generic rainbow.
///
/// The source hue stays recognizable while nearby hues and lightness create
/// the metallic/iridescent travel seen in ShaderGradient-like materials.
List<Color> balynShaderPalette(Color seed) {
  final hsl = HSLColor.fromColor(seed);
  Color tone(double hueShift, double saturationShift, double lightnessShift) {
    final hue = (hsl.hue + hueShift + 360) % 360;
    final saturation = (hsl.saturation + saturationShift)
        .clamp(0.42, 1.0)
        .toDouble();
    final lightness = (hsl.lightness + lightnessShift)
        .clamp(0.32, 0.78)
        .toDouble();
    return HSLColor.fromAHSL(1, hue, saturation, lightness).toColor();
  }

  return [tone(-18, .10, -.03), tone(5, .14, .10), tone(24, .08, -.01)];
}

double _scaledPhase(double backgroundPhase, double multiplier) =>
    (backgroundPhase * multiplier) % 1.0;

/// Rebuilds large chart/donut materials on a slower phase than text and icons.
///
/// With the 72 s global clock, the default 4.5x multiplier gives large charts
/// a ~16 s cycle. Text/icons use 6x (~12 s), while progress bars use 5x
/// (~14.4 s), so small accents feel alive without making large charts frantic.
class BalynShaderMotionBuilder extends StatelessWidget {
  const BalynShaderMotionBuilder({
    required this.builder,
    this.motionMultiplier = 4.5,
    super.key,
  });

  final Widget Function(BuildContext context, double phase, bool enabled)
  builder;
  final double motionMultiplier;

  @override
  Widget build(BuildContext context) {
    final data = BalynShaderScope.maybeOf(context);
    final enabled = data?.chartEnabled ?? true;
    if (data == null || !data.motionEnabled || !enabled) {
      return builder(context, 0, enabled);
    }
    return AnimatedBuilder(
      animation: data.clock,
      builder: (context, _) => builder(
        context,
        _scaledPhase(data.clock.value, motionMultiplier),
        enabled,
      ),
    );
  }
}

/// Animated chart gradient for APIs such as fl_chart that cannot accept a
/// FragmentShader directly. The palette stays close to the seed colour; only
/// the broad light direction travels.
LinearGradient balynAnimatedGradient(
  Color seed,
  double phase, {
  double opacity = 1,
}) {
  final angle = phase * math.pi * 2;
  final x = math.cos(angle);
  final y = math.sin(angle);
  final palette = balynShaderPalette(
    seed,
  ).map((color) => color.withValues(alpha: opacity)).toList();
  return LinearGradient(
    begin: Alignment(-x, -y),
    end: Alignment(x, y),
    colors: palette,
    stops: const [0, .50, 1],
  );
}

void _configureInkShader(
  ui.FragmentShader shader,
  Size size,
  double time,
  List<Color> colors, {
  required double strength,
  required double sheen,
}) {
  shader
    ..setFloat(0, size.width)
    ..setFloat(1, size.height)
    ..setFloat(2, time);
  var index = 3;
  for (final color in colors) {
    shader
      ..setFloat(index++, color.r)
      ..setFloat(index++, color.g)
      ..setFloat(index++, color.b)
      ..setFloat(index++, color.a);
  }
  shader
    ..setFloat(index++, strength.clamp(0.0, 1.0).toDouble())
    ..setFloat(index, sheen.clamp(0.0, 1.0).toDouble());
}
