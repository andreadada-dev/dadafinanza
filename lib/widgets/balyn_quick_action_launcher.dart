import 'dart:math' as math;

import 'package:balyn/l10n/localized_material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:pie_menu/pie_menu.dart';

import '../services/quick_preset_service.dart';

import '../theme/balyn_palette.dart';

/// Regular taps open the transfer editor; a 700ms hold charges the
/// button clockwise and reveals the preset radial menu from pie_menu.
/// The independent Hero "Altro" keeps its original Cue pills.
class BalynQuickActionLauncher extends StatefulWidget {
  const BalynQuickActionLauncher({
    required this.onCreate,
    required this.onAdvances,
    required this.onPlanning,
    required this.onPresetSelected,
    required this.onAddPreset,
    required this.loadPresets,
    this.motion,
    super.key,
  });

  /// Fast tap opens a fresh transfer (never the former vertical Cue sheet).
  final VoidCallback onCreate;
  final VoidCallback onAdvances;
  final VoidCallback onPlanning;
  final ValueChanged<QuickPreset> onPresetSelected;
  final Future<void> Function() onAddPreset;
  final Future<List<QuickPreset>> Function() loadPresets;
  final ValueListenable<Offset>? motion;

  @override
  State<BalynQuickActionLauncher> createState() =>
      _BalynQuickActionLauncherState();
}

class _BalynQuickActionLauncherState extends State<BalynQuickActionLauncher>
    with SingleTickerProviderStateMixin {
  static const holdDuration = Duration(milliseconds: 700);
  late final AnimationController _charge = AnimationController(
    vsync: this,
    duration: holdDuration,
  );
  List<QuickPreset> _presets = const [];
  bool _menuOpen = false;

  @override
  void initState() {
    super.initState();
    _refreshPresets();
  }

  Future<void> _refreshPresets() async {
    try {
      final latest = await widget.loadPresets();
      if (mounted) setState(() => _presets = latest.take(4).toList());
    } catch (_) {
      // The preset table can still be initializing on first launch.
      if (mounted) setState(() => _presets = const []);
    }
  }

  @override
  void dispose() {
    _charge.dispose();
    super.dispose();
  }

  void _startCharge(PointerDownEvent event) {
    if (!_menuOpen) _charge.forward(from: 0);
  }

  void _stopCharge(PointerEvent event) {
    if (!_menuOpen) _charge.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return PieMenu(
      key: const ValueKey('quick-radial-pie-menu'),
      theme: PieTheme(
        overlayColor: Colors.black54,
        radius: 115,
        buttonSize: 54,
        spacing: 8,
        regularPressShowsMenu: false,
        longPressShowsMenu: true,
        longPressDuration: holdDuration,
        buttonTheme: const PieButtonTheme(
          backgroundColor: BalynPalette.darkSurface,
          iconColor: BalynPalette.darkText,
        ),
        buttonThemeHovered: const PieButtonTheme(
          backgroundColor: BalynPalette.accent,
          iconColor: Colors.white,
        ),
      ),
      onToggle: (open) {
        _menuOpen = open;
        if (open) {
          _charge.value = 1;
        } else {
          _charge.reverse();
          _refreshPresets();
        }
      },
      onPressed: widget.onCreate,
      actions: [
        for (final preset in _presets)
          PieAction(
            tooltip: Text(preset.name),
            onSelect: () => widget.onPresetSelected(preset),
            child: const Icon(Icons.bookmark_rounded),
          ),
        PieAction(
          tooltip: const Text('Nuovo preset'),
          onSelect: () async {
            await widget.onAddPreset();
            if (mounted) await _refreshPresets();
          },
          child: const Icon(Icons.add_circle_outline_rounded),
        ),
        PieAction(
          tooltip: const Text('Anticipi'),
          onSelect: widget.onAdvances,
          child: const Icon(Icons.handshake_outlined),
        ),
        PieAction(
          tooltip: const Text('Pianifica'),
          onSelect: widget.onPlanning,
          child: const Icon(Icons.event_note_outlined),
        ),
      ],
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _startCharge,
        onPointerUp: _stopCharge,
        onPointerCancel: _stopCharge,
        child: BalynMorphingFab(
          motion: widget.motion,
          progress: _charge,
          onPressed: () {},
        ),
      ),
    );
  }
}

class _WhiteChargePainter extends CustomPainter {
  const _WhiteChargePainter(this.progress);
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final sector = Path()
      ..moveTo(center.dx, center.dy)
      ..arcTo(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        math.pi * 2 * progress.clamp(0.0, 1.0),
        false,
      )
      ..close();
    canvas.drawPath(sector, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_WhiteChargePainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// The circle subtly compresses or stretches in the direction of travel,
/// then springs to rest. This only transforms the 56dp trigger; hit targets
/// and actual action pills remain stable. Reduced motion disables it.
class BalynMorphingFab extends StatefulWidget {
  const BalynMorphingFab({
    required this.onPressed,
    this.onLongPress,
    this.motion,
    this.progress,
    super.key,
  });

  final Animation<double>? progress;
  final VoidCallback onPressed;
  final VoidCallback? onLongPress;
  final ValueListenable<Offset>? motion;

  @override
  State<BalynMorphingFab> createState() => _BalynMorphingFabState();
}

class _BalynMorphingFabState extends State<BalynMorphingFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rebound = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 520),
    value: 1,
  );
  Offset _impulse = Offset.zero;

  @override
  void initState() {
    super.initState();
    widget.motion?.addListener(_onMotion);
  }

  @override
  void didUpdateWidget(covariant BalynMorphingFab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.motion != widget.motion) {
      oldWidget.motion?.removeListener(_onMotion);
      widget.motion?.addListener(_onMotion);
    }
  }

  void _onMotion() {
    if (!mounted || MediaQuery.disableAnimationsOf(context)) return;
    final value = widget.motion?.value ?? Offset.zero;
    if (value.distanceSquared < .001) return;
    _impulse = Offset(
      value.dx.clamp(-1.0, 1.0).toDouble(),
      value.dy.clamp(-1.0, 1.0).toDouble(),
    );
    _rebound.forward(from: 0);
  }

  @override
  void dispose() {
    widget.motion?.removeListener(_onMotion);
    _rebound.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return AnimatedBuilder(
      animation: _rebound,
      builder: (context, child) {
        final elapsed = Curves.easeOutCubic.transform(_rebound.value);
        final spring = reduced
            ? 0.0
            : (1 - elapsed) *
                  (1 + .09 * math.sin(_rebound.value * 3 * math.pi));
        final dx = _impulse.dx * .10 * spring;
        final dy = _impulse.dy * .10 * spring;
        final matrix = Matrix4.identity()
          ..translate(dx * 14, dy * 14)
          ..rotateZ(dx * .12)
          ..scale(1 + dx.abs() - dy.abs() * .45, 1 + dy.abs() - dx.abs() * .45);
        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: child,
        );
      },
      child: Semantics(
        button: true,
        label: 'Apri azioni rapide',
        child: GestureDetector(
          onLongPress: widget.onLongPress,
          child: FloatingActionButton(
            key: const ValueKey('quick-launcher'),
            heroTag: 'balyn-quick-launcher',
            elevation: 9,
            backgroundColor: BalynPalette.accent,
            foregroundColor: Colors.white,
            shape: const CircleBorder(),
            onPressed: widget.onPressed,
            child: ClipOval(
              child: AnimatedBuilder(
                animation: widget.progress ?? _rebound,
                builder: (context, _) {
                  final progress = widget.progress?.value ?? 0;
                  return CustomPaint(
                    key: const ValueKey('quick-fab-white-charge'),
                    size: const Size(56, 56),
                    painter: _WhiteChargePainter(progress),
                    child: Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: progress > .5
                            ? BalynPalette.accent
                            : Colors.white,
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
