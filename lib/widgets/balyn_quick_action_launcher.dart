import 'package:balyn/l10n/localized_material.dart';
import 'package:cue/cue.dart';

/// A single corner action that reveals the app's destinations. Inspired by
/// the separated circular action in Cue's bottom_bar.dart example.
class BalynQuickActionLauncher extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        IgnorePointer(
          ignoring: !expanded,
          child: Cue.onToggle(
            toggled: expanded,
            motion: .smooth(),
            acts: [.fadeIn(), .scale(from: .88), .slideY(from: .12)],
            child: Padding(
              padding: const EdgeInsets.only(bottom: 13),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (showHome)
                    _QuickDestination(
                      id: 'home',
                      label: 'Home',
                      icon: Icons.home_rounded,
                      onTap: onHome,
                    ),
                  _QuickDestination(
                    id: 'create',
                    label: 'Nuovo movimento',
                    icon: Icons.add_rounded,
                    onTap: onCreate,
                  ),
                  _QuickDestination(
                    id: 'advances',
                    label: 'Anticipi',
                    icon: Icons.handshake_outlined,
                    onTap: onAdvances,
                  ),
                  _QuickDestination(
                    id: 'planning',
                    label: 'Pianifica',
                    icon: Icons.event_note_outlined,
                    onTap: onPlanning,
                  ),
                ],
              ),
            ),
          ),
        ),
        Semantics(
          button: true,
          label: expanded ? 'Chiudi azioni' : 'Apri azioni',
          expanded: expanded,
          child: GestureDetector(
            onLongPress: onLongPress,
            child: FloatingActionButton(
              key: const ValueKey('quick-launcher'),
              heroTag: 'balyn-quick-launcher',
              elevation: 7,
              backgroundColor: const Color(0xFF19181F),
              foregroundColor: Colors.white,
              shape: const CircleBorder(),
              onPressed: onToggle,
              child: AnimatedRotation(
                turns: expanded ? .125 : 0,
                duration: reduced
                    ? Duration.zero
                    : const Duration(milliseconds: 310),
                curve: Curves.easeOutCubic,
                child: const Icon(Icons.add_rounded, size: 29),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickDestination extends StatelessWidget {
  const _QuickDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: const Color(0xFF19181F),
        elevation: 5,
        shadowColor: Colors.black26,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('quick-nav-$id'),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Icon(icon, size: 22, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
