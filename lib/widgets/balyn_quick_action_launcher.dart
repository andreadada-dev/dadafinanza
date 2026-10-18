import 'dart:math' as math;

import 'package:balyn/l10n/localized_material.dart';

import '../theme/balyn_palette.dart';
import 'balyn_cue_anchored_menu.dart';

/// One Cue menu implementation shared by the hero's "Altro" and the FAB.
/// The FAB alone reacts to scroll velocity with a small elastic deformation.
class BalynQuickActionLauncher extends StatelessWidget {
  const BalynQuickActionLauncher({
    required this.showHome,
    required this.onCreate,
    required this.onAdvances,
    required this.onPlanning,
    required this.onHome,
    this.motion,
    this.onLongPress,
    super.key,
  });

  final bool showHome;
  final VoidCallback onCreate;
  final VoidCallback onAdvances;
  final VoidCallback onPlanning;
  final VoidCallback onHome;
  final ValueListenable<Offset>? motion;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) => BalynCueAnchoredMenu(
    closeKey: const ValueKey('quick-launcher-close'),
    closeTooltip: 'Chiudi azioni',
    actions: [
      if (showHome)
        BalynCueMenuAction(
          id: 'quick-nav-home',
          label: 'Home',
          icon: Icons.home_rounded,
          onTap: onHome,
        ),
      BalynCueMenuAction(
        id: 'quick-nav-create',
        label: 'Movimento',
        icon: Icons.add_rounded,
        onTap: onCreate,
      ),
      BalynCueMenuAction(
        id: 'quick-nav-advances',
        label: 'Anticipi',
        icon: Icons.handshake_outlined,
        onTap: onAdvances,
      ),
      BalynCueMenuAction(
        id: 'quick-nav-planning',
        label: 'Pianifica',
        icon: Icons.event_note_outlined,
        onTap: onPlanning,
      ),
    ],
    triggerBuilder: (context, open) => BalynMorphingFab(
      motion: motion,
      onPressed: open,
      onLongPress: onLongPress,
    ),
  );
}

/// The circle subtly compresses or stretches in the direction of travel,
/// then springs to rest. This only transforms the 56dp trigger; hit targets
/// and actual action pills remain stable. Reduced motion disables it.
class BalynMorphingFab extends StatefulWidget {
  const BalynMorphingFab({
    required this.onPressed,
    this.onLongPress,
    this.motion,
    super.key,
  });

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
            child: const Icon(Icons.add_rounded, size: 30),
          ),
        ),
      ),
    );
  }
}
