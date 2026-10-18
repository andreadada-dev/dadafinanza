import 'package:balyn/l10n/localized_material.dart';
import 'package:cue/cue.dart';

/// Shared action sheet for Home "Altro" and the bottom-right "+" trigger.
/// Both use the same Cue motion, dimming, action pills and close behavior.
class BalynCueMenuAction {
  const BalynCueMenuAction({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class BalynCueAnchoredMenu extends StatelessWidget {
  const BalynCueAnchoredMenu({
    required this.actions,
    required this.triggerBuilder,
    this.closeKey,
    this.closeTooltip = 'Chiudi',
    this.closeSlotHeight = 56,
    super.key,
  });

  final List<BalynCueMenuAction> actions;
  final Widget Function(BuildContext context, VoidCallback showModal)
  triggerBuilder;
  final Key? closeKey;
  final String closeTooltip;

  /// Reserve the vertical slot occupied by the original trigger. The Home
  /// trigger has a text label beneath its circle, the floating FAB doesn't.
  final double closeSlotHeight;

  @override
  Widget build(BuildContext context) => CueModalTransition(
    barrierColor: Colors.black54,
    barrierLabel: closeTooltip,
    alignment: Alignment.bottomRight,
    hideTriggerOnTransition: true,
    motion: .bouncy(),
    reverseMotion: .snappy(),
    triggerBuilder: (context, showModal) =>
        triggerBuilder(context, () => showModal()),
    builder: (modalContext, triggerRect) {
      final scheme = Theme.of(modalContext).colorScheme;
      return SizedBox(
        width: 232,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final action in actions)
              Actor(
                acts: [
                  .slideY(from: .45),
                  .zoomIn(),
                  .fadeIn(),
                  .focus(from: 8),
                ],
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: Material(
                    elevation: 5,
                    color: scheme.surface,
                    borderRadius: BorderRadius.circular(28),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      key: ValueKey(action.id),
                      borderRadius: BorderRadius.circular(28),
                      onTap: () {
                        Navigator.of(modalContext).pop();
                        action.onTap();
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 17,
                          vertical: 12,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              action.icon,
                              color: scheme.onSurface,
                              size: 20,
                            ),
                            const SizedBox(width: 11),
                            Flexible(
                              child: Text(
                                action.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            Actor(
              acts: [.fadeIn(), .focus(from: 8), .slideY(from: .6)],
              child: SizedBox(
                height: closeSlotHeight,
                width: 56,
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 56,
                    width: 56,
                    child: IconButton.filledTonal(
                      key: closeKey,
                      tooltip: closeTooltip,
                      onPressed: () => Navigator.of(modalContext).pop(),
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}
