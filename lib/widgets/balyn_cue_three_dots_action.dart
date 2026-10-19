import 'package:balyn/l10n/localized_material.dart';

/// The original "Altro" three-dots button, now in the Home header.
/// The PopupMenu is anchored *under* the original button: opening it never
/// swaps the trigger with a separate animated close button.
class BalynCueThreeDotsAction extends StatelessWidget {
  const BalynCueThreeDotsAction({
    required this.onManageAccounts,
    required this.onPlanning,
    required this.onAdvances,
    super.key,
  });

  final VoidCallback onManageAccounts;
  final VoidCallback onPlanning;
  final VoidCallback onAdvances;

  @override
  Widget build(BuildContext context) => PopupMenuButton<String>(
    key: const ValueKey('home-more-cue-trigger'),
    tooltip: 'Altro',
    position: PopupMenuPosition.under,
    offset: const Offset(0, 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    onSelected: (value) {
      switch (value) {
        case 'accounts':
          onManageAccounts();
        case 'planning':
          onPlanning();
        case 'advances':
          onAdvances();
      }
    },
    itemBuilder: (_) => const [
      PopupMenuItem(
        value: 'accounts',
        child: Row(
          children: [
            Icon(Icons.account_balance_wallet_outlined, size: 20),
            SizedBox(width: 12),
            Text('Conti'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'planning',
        child: Row(
          children: [
            Icon(Icons.event_note_outlined, size: 20),
            SizedBox(width: 12),
            Text('Pianifica'),
          ],
        ),
      ),
      PopupMenuItem(
        value: 'advances',
        child: Row(
          children: [
            Icon(Icons.handshake_outlined, size: 20),
            SizedBox(width: 12),
            Text('Anticipi'),
          ],
        ),
      ),
    ],
    child: Material(
      color: Colors.white.withValues(alpha: .26),
      shape: const CircleBorder(),
      child: const SizedBox.square(
        dimension: 40,
        child: Icon(Icons.more_vert_rounded, size: 26, color: Colors.white),
      ),
    ),
  );
}
