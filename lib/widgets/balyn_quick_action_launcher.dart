import 'package:balyn/l10n/localized_material.dart';

/// A single contrasting action button with a staggered, size-aware expansion.
class BalynQuickActionLauncher extends StatefulWidget {
  const BalynQuickActionLauncher({
    required this.expanded,
    required this.showHome,
    required this.onToggle,
    required this.onCreate,
    required this.onAdvances,
    required this.onPlanning,
    required this.onHome,
    this.onLongPress,
    super.key,
  });

  final bool expanded;
  final bool showHome;
  final VoidCallback onToggle;
  final VoidCallback onCreate;
  final VoidCallback onAdvances;
  final VoidCallback onPlanning;
  final VoidCallback onHome;
  final VoidCallback? onLongPress;

  @override
  State<BalynQuickActionLauncher> createState() =>
      _BalynQuickActionLauncherState();
}

class _BalynQuickActionLauncherState extends State<BalynQuickActionLauncher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 380),
    reverseDuration: const Duration(milliseconds: 270),
    value: widget.expanded ? 1 : 0,
  );

  @override
  void didUpdateWidget(covariant BalynQuickActionLauncher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expanded == widget.expanded) return;
    if (widget.expanded) {
      _controller.forward();
    } else {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _entry({
    required int position,
    required String id,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final delay = position * .11;
    final curved = CurvedAnimation(
      parent: _controller,
      curve: Interval(
        delay,
        (delay + .65).clamp(0.0, 1.0),
        curve: Curves.easeOutCubic,
      ),
      reverseCurve: Curves.easeInCubic,
    );
    return ClipRect(
      child: SizeTransition(
        sizeFactor: curved,
        axisAlignment: 1,
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(.18, .20),
              end: Offset.zero,
            ).animate(curved),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                width: 172,
                height: 49,
                child: Material(
                  elevation: 7,
                  color: const Color(0xFF262331),
                  borderRadius: BorderRadius.circular(25),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('quick-nav-$id'),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(icon, size: 22, color: Colors.white),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: !widget.expanded,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (widget.showHome)
                _entry(
                  position: 0,
                  id: 'home',
                  label: 'Home',
                  icon: Icons.home_rounded,
                  onTap: widget.onHome,
                ),
              _entry(
                position: 0,
                id: 'create',
                label: 'Movimento',
                icon: Icons.add_rounded,
                onTap: widget.onCreate,
              ),
              _entry(
                position: 1,
                id: 'advances',
                label: 'Anticipi',
                icon: Icons.handshake_outlined,
                onTap: widget.onAdvances,
              ),
              _entry(
                position: 2,
                id: 'planning',
                label: 'Pianifica',
                icon: Icons.event_note_outlined,
                onTap: widget.onPlanning,
              ),
              const SizedBox(height: 7),
            ],
          ),
        ),
        Semantics(
          button: true,
          label: widget.expanded ? 'Chiudi azioni' : 'Apri azioni',
          expanded: widget.expanded,
          child: GestureDetector(
            onLongPress: widget.onLongPress,
            child: FloatingActionButton(
              key: const ValueKey('quick-launcher'),
              heroTag: 'balyn-quick-launcher',
              elevation: 9,
              backgroundColor: const Color(0xFF8157F7),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: widget.onToggle,
              child: AnimatedRotation(
                turns: widget.expanded ? .125 : 0,
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 310),
                curve: Curves.easeOutCubic,
                child: const Icon(Icons.add_rounded, size: 30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
