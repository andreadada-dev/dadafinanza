import 'package:balyn/l10n/localized_material.dart';

/// The same Home "Altro" circle stays fixed in its header slot. Only the
/// menu route is drawn above the screen; the trigger never morphs or moves.
class BalynCueThreeDotsAction extends StatefulWidget {
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
  State<BalynCueThreeDotsAction> createState() =>
      _BalynCueThreeDotsActionState();
}

class _BalynCueThreeDotsActionState extends State<BalynCueThreeDotsAction> {
  final GlobalKey _triggerKey = GlobalKey();
  static const double _menuWidth = 206;

  Future<void> _showMoreMenu() async {
    final anchor = _triggerKey.currentContext?.findRenderObject();
    final overlay = Overlay.of(context).context.findRenderObject();
    if (anchor is! RenderBox || overlay is! RenderBox) return;

    // Compute coordinates against the actual overlay, not the whole Hero
    // or a centered dialog. The menu's RIGHT edge follows the trigger's
    // right edge, and its top starts just below the original 40dp circle.
    final origin = anchor.localToGlobal(Offset.zero, ancestor: overlay);
    final width = overlay.size.width;
    final height = overlay.size.height;
    final rightEdge = (origin.dx + anchor.size.width)
        .clamp(_menuWidth + 8, width - 8)
        .toDouble();
    final topEdge = origin.dy + anchor.size.height + 7;
    final position = RelativeRect.fromLTRB(
      rightEdge - _menuWidth,
      topEdge,
      width - rightEdge,
      height - topEdge,
    );

    final selection = await showMenu<String>(
      context: context,
      position: position,
      constraints: const BoxConstraints.tightFor(width: _menuWidth),
      elevation: 7,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      items: const [
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
    );
    if (!mounted) return;
    switch (selection) {
      case 'accounts':
        widget.onManageAccounts();
      case 'planning':
        widget.onPlanning();
      case 'advances':
        widget.onAdvances();
      case null:
        break;
    }
  }

  @override
  Widget build(BuildContext context) => Tooltip(
    message: 'Altro',
    child: Material(
      key: _triggerKey,
      color: Colors.white.withValues(alpha: .26),
      shape: const CircleBorder(),
      child: InkWell(
        key: const ValueKey('home-more-cue-trigger'),
        customBorder: const CircleBorder(),
        onTap: _showMoreMenu,
        child: const SizedBox.square(
          dimension: 40,
          child: Icon(
            Icons.more_vert_rounded,
            size: 26,
            color: Colors.white,
          ),
        ),
      ),
    ),
  );
}
