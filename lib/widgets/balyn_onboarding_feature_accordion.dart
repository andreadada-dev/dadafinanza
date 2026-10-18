import 'package:balyn/l10n/localized_material.dart';
import 'package:cue/cue.dart';

import '../l10n/balyn_onboarding_l10n.dart';
import '../theme/balyn_palette.dart';

/// Cue ExpandingCards adapted to Balyn's charcoal Revolut-style surfaces.
/// One section is expanded at a time; the current section can be collapsed.
class BalynOnboardingFeatureAccordion extends StatefulWidget {
  const BalynOnboardingFeatureAccordion({
    required this.languageCode,
    super.key,
  });

  final String languageCode;

  @override
  State<BalynOnboardingFeatureAccordion> createState() =>
      _BalynOnboardingFeatureAccordionState();
}

class _BalynOnboardingFeatureAccordionState
    extends State<BalynOnboardingFeatureAccordion> {
  int _expandedIndex = 0;

  static const _icons = <IconData>[
    Icons.dashboard_customize_outlined,
    Icons.receipt_long_outlined,
    Icons.handshake_outlined,
    Icons.event_note_outlined,
  ];
  static const _titleKeys = <String>[
    'homeTitle',
    'movementTitle',
    'advancesTitle',
    'planTitle',
  ];
  static const _descriptionKeys = <String>[
    'homeDescription',
    'movementDescription',
    'advancesDescription',
    'planDescription',
  ];

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final direction = widget.languageCode == 'ar'
        ? TextDirection.rtl
        : TextDirection.ltr;
    return Directionality(
      textDirection: direction,
      child: Column(
        key: const ValueKey('onboarding-feature-accordion'),
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < _titleKeys.length; i++)
            Cue.onToggle(
              key: ValueKey('onboarding-feature-cue-$i'),
              toggled: _expandedIndex == i,
              motion: reduced ? Spring.snappy() : Spring.smooth(),
              child: Builder(
                builder: (context) {
                  final active = _expandedIndex == i;
                  final isLast = i == _titleKeys.length - 1;
                  final previous = _expandedIndex - 1 == i;
                  final next = _expandedIndex + 1 == i;
                  final topRadius = active || i == 0 || next ? 22.0 : 0.0;
                  final bottomRadius = active || isLast || previous ? 22.0 : 0.0;
                  final title = BalynOnboardingL10n.tr(
                    widget.languageCode,
                    _titleKeys[i],
                  );
                  final description = BalynOnboardingL10n.tr(
                    widget.languageCode,
                    _descriptionKeys[i],
                  );
                  return Actor(
                    acts: [
                      .scale(from: 1.0, to: 1.035),
                      .padding(
                        to: const EdgeInsets.symmetric(vertical: 7),
                      ),
                    ],
                    child: Material(
                      clipBehavior: Clip.antiAlias,
                      color: active
                          ? const Color(0xFF40404A)
                          : BalynPalette.darkSurface,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(topRadius),
                        bottom: Radius.circular(bottomRadius),
                      ),
                      child: InkWell(
                        key: ValueKey('onboarding-feature-$i'),
                        onTap: () => setState(() {
                          _expandedIndex = active ? -1 : i;
                        }),
                        child: Semantics(
                          button: true,
                          expanded: active,
                          label: title,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(18, 15, 15, 13),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      _icons[i],
                                      size: 19,
                                      color: BalynPalette.darkText,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: const TextStyle(
                                          color: BalynPalette.darkText,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                    Actor(
                                      acts: [.rotate(to: -180)],
                                      child: const Icon(
                                        Icons.expand_more_rounded,
                                        color: BalynPalette.darkMuted,
                                        size: 21,
                                      ),
                                    ),
                                  ],
                                ),
                                Actor(
                                  acts: [
                                    .clipHeight(fromFactor: .3),
                                    .fadeIn(),
                                    .slideY(from: .5),
                                    .blur(from: 8),
                                  ],
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      left: 3,
                                      right: 5,
                                      top: 12,
                                      bottom: 2,
                                    ),
                                    child: Text(
                                      description,
                                      key: ValueKey(
                                        'onboarding-feature-description-$i',
                                      ),
                                      style: const TextStyle(
                                        color: Color(0xFFC6C6D0),
                                        fontSize: 12.5,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
