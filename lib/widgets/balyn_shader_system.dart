import 'dart:ui' as ui;

import 'package:balyn/l10n/localized_material.dart';

/// Shared clock and GPU programs for Balyn's living-color system.
///
/// One slow clock drives the whole app so colored elements feel like the same
/// material instead of dozens of unrelated animations.
class BalynShaderScope extends StatefulWidget {
  const BalynShaderScope({required this.child, super.key});

  final Widget child;

  static BalynShaderData? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_BalynShaderInherited>()?.data;

  @override
  State<BalynShaderScope> createState() => _BalynShaderScopeState();
}

class BalynShaderData {
  const BalynShaderData({
    required this.clock,
    required this.motionEnabled,
    this.backgroundProgram,
    this.inkProgram,
  });

  final Animation<double> clock;
  final bool motionEnabled;
  final ui.FragmentProgram? backgroundProgram;
  final ui.FragmentProgram? inkProgram;
}

class _BalynShaderScopeState extends State<BalynShaderScope>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _clock;
  ui.FragmentProgram? _backgroundProgram;
  ui.FragmentProgram? _inkProgram;
  bool _reduceMotion = false;
  bool _appActive = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _clock = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 72),
    )..repeat();
    _loadPrograms();
  }

  Future<void> _loadPrograms() async {
    final programs = await Future.wait([
      ui.FragmentProgram.fromAsset('shaders/balyn_background.frag'),
      ui.FragmentProgram.fromAsset('shaders/balyn_ink.frag'),
    ]);
    if (!mounted) return;
    setState(() {
      _backgroundProgram = programs[0];
      _inkProgram = programs[1];
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    if (_reduceMotion != reduce) {
      _reduceMotion = reduce;
      _syncClock();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _appActive = state == AppLifecycleState.resumed;
    _syncClock();
  }

  void _syncClock() {
    final shouldAnimate = mounted && _appActive && !_reduceMotion;
    if (shouldAnimate) {
      if (!_clock.isAnimating) _clock.repeat();
    } else {
      _clock.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final data = BalynShaderData(
      clock: _clock,
      motionEnabled: !_reduceMotion && _appActive,
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
      oldWidget.data.motionEnabled != data.motionEnabled;
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
        if (data?.backgroundProgram != null)
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
    super.key,
  });

  final Color seed;
  final Widget child;
  final bool enabled;

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
    if (!widget.enabled) return widget.child;

    final data = BalynShaderScope.maybeOf(context);
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
            data.motionEnabled ? data.clock.value : 0,
            palette,
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

void _configureInkShader(
  ui.FragmentShader shader,
  Size size,
  double time,
  List<Color> colors,
) {
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
}
