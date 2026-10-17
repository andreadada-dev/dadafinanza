import 'package:balyn/l10n/localized_material.dart';

/// Slides the previous Home section away while the next arrives from the
/// opposite side, without adding Navigator routes or discarding the hero.
class BalynHomeSectionTransition extends StatelessWidget {
  const BalynHomeSectionTransition({
    required this.index,
    required this.direction,
    required this.child,
    super.key,
  });

  final int index;
  final int direction;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return ClipRect(
      child: AnimatedSwitcher(
        duration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 390),
        reverseDuration: reduceMotion
            ? Duration.zero
            : const Duration(milliseconds: 390),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (currentChild, previousChildren) => Stack(
          alignment: Alignment.topCenter,
          children: [
            ...previousChildren,
            if (currentChild != null) currentChild,
          ],
        ),
        transitionBuilder: (page, animation) {
          final entering = page.key == ValueKey<int>(index);
          final offset = entering ? direction.toDouble() : -direction.toDouble();
          return SlideTransition(
            position: Tween<Offset>(
              begin: Offset(offset, 0),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: IgnorePointer(
                ignoring: !entering,
                child: ExcludeSemantics(
                  excluding: !entering,
                  child: page,
                ),
              ),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(index),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}
