import 'package:balyn/l10n/localized_material.dart';

import 'balyn_cue_anchored_menu.dart';

/// Header action backed by the very same Cue menu as the corner FAB.
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
  Widget build(BuildContext context) => Expanded(
    child: BalynCueAnchoredMenu(
      closeKey: const ValueKey('home-more-close'),
      closeTooltip: 'Chiudi altre azioni',
      actions: [
        BalynCueMenuAction(
          id: 'home-more-accounts',
          label: 'Gestisci conti',
          icon: Icons.account_balance_wallet_outlined,
          onTap: onManageAccounts,
        ),
        BalynCueMenuAction(
          id: 'home-more-advances',
          label: 'Anticipi',
          icon: Icons.handshake_outlined,
          onTap: onAdvances,
        ),
        BalynCueMenuAction(
          id: 'home-more-dashboard',
          label: 'Dashboard avanzata',
          icon: Icons.dashboard_customize_outlined,
          onTap: onAdvancedDashboard,
        ),
        BalynCueMenuAction(
          id: 'home-more-customize',
          label: 'Personalizza Home',
          icon: Icons.tune_rounded,
          onTap: onCustomizeHome,
        ),
      ],
      triggerBuilder: (context, open) => Semantics(
        button: true,
        label: 'Altro',
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            key: const ValueKey('home-more-cue-trigger'),
            onTap: open,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              // No vertical offset: identical alignment open/closed.
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
                    child: const Icon(
                      Icons.more_vert_rounded,
                      color: Colors.white,
                      size: 29,
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
    ),
  );
}
