import 'package:balyn/l10n/localized_material.dart';
import 'package:cue/cue.dart';

/// Home's "Altro" action, inspired by Cue's three_dots_action example.
/// The modal grows upwards from the same quick-action position; it is not a
/// second bottom sheet, so the current Home page remains visible underneath.
class BalynCueThreeDotsAction extends StatelessWidget {
  const BalynCueThreeDotsAction({
    required this.onManageAccounts,
    required this.onAdvances,
    required this.onAdvancedDashboard,
    required this.onCustomizeHome,
    super.key,
  });

  final VoidCallback onManageAccounts;
  final VoidCallback onAdvances;
  final VoidCallback onAdvancedDashboard;
  final VoidCallback onCustomizeHome;

  @override
  Widget build(BuildContext context) {
    final actions = <_MoreAction>[
      _MoreAction('Gestisci conti', Icons.account_balance_wallet_outlined,
          onManageAccounts),
      _MoreAction('Anticipi', Icons.handshake_outlined, onAdvances),
      _MoreAction('Dashboard avanzata', Icons.dashboard_customize_outlined,
          onAdvancedDashboard),
      _MoreAction('Personalizza Home', Icons.tune_rounded, onCustomizeHome),
    ];

    return Expanded(
      child: CueModalTransition(
        barrierColor: Colors.black38,
        barrierLabel: 'Chiudi altre azioni',
        alignment: Alignment.bottomRight,
        hideTriggerOnTransition: true,
        motion: .bouncy(),
        reverseMotion: .snappy(),
        triggerBuilder: (context, showModal) => Semantics(
          button: true,
          label: 'Altro',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              key: const ValueKey('home-more-cue-trigger'),
              onTap: () => showModal(),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 52,
                      width: 52,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: .26),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          for (var i = 0; i < 3; i++)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 1.5),
                              child: CircleAvatar(
                                radius: 2.5,
                                backgroundColor: Colors.white,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 9),
                    const Text(
                      'Altro',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        builder: (modalContext, rect) {
          final scheme = Theme.of(modalContext).colorScheme;
          return SizedBox(
            width: 218,
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
                        child: InkWell(
                          key: ValueKey('home-more-${action.key}'),
                          borderRadius: BorderRadius.circular(28),
                          onTap: () {
                            Navigator.of(modalContext).pop();
                            action.onTap();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 11,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(action.icon, color: scheme.onSurface, size: 20),
                                const SizedBox(width: 10),
                                Flexible(
                                  child: Text(
                                    action.label,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                    height: 86,
                    width: 76,
                    child: Center(
                      child: IconButton.filledTonal(
                        key: const ValueKey('home-more-close'),
                        tooltip: 'Chiudi',
                        onPressed: () => Navigator.of(modalContext).pop(),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MoreAction {
  const _MoreAction(this.label, this.icon, this.onTap);

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  String get key => switch (label) {
    'Gestisci conti' => 'accounts',
    'Anticipi' => 'advances',
    'Dashboard avanzata' => 'dashboard',
    _ => 'customize',
  };
}
