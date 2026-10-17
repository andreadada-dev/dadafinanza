import 'dart:ui';

import 'package:balyn/l10n/localized_material.dart';

/// Floating, translucent navigation bar. The page scrolls beneath the blur,
/// while the bar stays inside the device's bottom safe area.
class BalynGlassNavigation extends StatelessWidget {
  const BalynGlassNavigation({
    required this.index,
    required this.onDestinationSelected,
    super.key,
  });

  final int index;
  final ValueChanged<int> onDestinationSelected;

  static const _items = <(String, IconData, IconData)>[
    ('Home', Icons.home_outlined, Icons.home_rounded),
    ('Attività', Icons.receipt_long_outlined, Icons.receipt_long_rounded),
    ('Anticipi', Icons.handshake_outlined, Icons.handshake_rounded),
    ('Pianifica', Icons.event_note_outlined, Icons.event_note_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final selected = theme.colorScheme.primary;
    return ClipRRect(
      borderRadius: BorderRadius.circular(29),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: dark
                ? const Color(0xF0191922).withValues(alpha: .78)
                : Colors.white.withValues(alpha: .78),
            borderRadius: BorderRadius.circular(29),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: .15)
                  : Colors.white.withValues(alpha: .72),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: dark ? .19 : .07),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SizedBox(
            height: 69,
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: Semantics(
                      button: true,
                      selected: i == index,
                      label: _items[i].$1,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          key: ValueKey('glass-destination-$i'),
                          onTap: () => onDestinationSelected(i),
                          borderRadius: BorderRadius.circular(22),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 260),
                            curve: Curves.easeOutCubic,
                            margin: const EdgeInsets.symmetric(
                              vertical: 5,
                              horizontal: 3,
                            ),
                            decoration: BoxDecoration(
                              color: i == index
                                  ? selected.withValues(alpha: dark ? .19 : .10)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(22),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedScale(
                                  duration: const Duration(milliseconds: 240),
                                  scale: i == index ? 1.09 : 1,
                                  child: Icon(
                                    i == index ? _items[i].$3 : _items[i].$2,
                                    size: 23,
                                    color: i == index
                                        ? selected
                                        : theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    _items[i].$1,
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: i == index
                                          ? FontWeight.w800
                                          : FontWeight.w500,
                                      color: i == index
                                          ? theme.colorScheme.onSurface
                                          : theme.colorScheme.onSurfaceVariant,
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
