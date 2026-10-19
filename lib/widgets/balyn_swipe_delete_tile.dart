import 'package:balyn/l10n/localized_material.dart';

import '../main.dart';
import '../models/models.dart';
import 'ui_helpers.dart';

/// Compact edit/delete actions revealed only by a horizontal swipe.
/// The row and action rail share the available width: neither the amount nor
/// the icons can be painted on top of the other.
class BalynSwipeDeleteTile extends StatefulWidget {
  const BalynSwipeDeleteTile({
    required this.item,
    required this.child,
    required this.onEdit,
    super.key,
  });

  final FinanceTransaction item;
  final Widget child;
  final VoidCallback onEdit;

  @override
  State<BalynSwipeDeleteTile> createState() => _BalynSwipeDeleteTileState();
}

class _BalynSwipeDeleteTileState extends State<BalynSwipeDeleteTile> {
  static const double _actionWidth = 94;
  double _reveal = 0;
  bool _dragging = false;
  bool _deleting = false;

  void _close() {
    if (!mounted) return;
    setState(() {
      _dragging = false;
      _reveal = 0;
    });
  }

  Future<void> _delete() async {
    if (_deleting) return;
    final state = AppScope.of(context);
    if (state.isAdvanceProtectedTransaction(widget.item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gestisci questo movimento dalla sezione Anticipi.'),
        ),
      );
      _close();
      return;
    }

    final approved = await confirmDestructiveAction(
      context,
      title: 'Eliminare il movimento?',
      message: 'Il saldo del conto verrà ricalcolato automaticamente.',
    );
    if (!mounted) return;
    if (!approved) {
      _close();
      return;
    }

    setState(() => _deleting = true);
    try {
      final current = state.transactionById(widget.item.id);
      if (current != null) await state.deleteTransaction(current);
      _close();
    } catch (error) {
      if (!mounted) return;
      _close();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  void _edit() {
    _close();
    widget.onEdit();
  }

  Widget _action({
    required String keySuffix,
    required String tooltip,
    required IconData icon,
    required Color background,
    required VoidCallback? onPressed,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('swipe-$keySuffix-${widget.item.id}'),
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: 39,
            height: 39,
            child: Center(child: Icon(icon, color: Colors.white, size: 19)),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        // Keep the content's layout width constant. Resizing it during a
        // horizontal drag causes the Home page to reflow (and conflicts
        // visually with the parent three-page horizontal PageView).
        final rowWidth = constraints.maxWidth;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: (_) => setState(() => _dragging = true),
          onHorizontalDragUpdate: (details) => setState(() {
            _reveal = (_reveal - details.delta.dx).clamp(0.0, _actionWidth);
          }),
          onHorizontalDragEnd: (details) => setState(() {
            _dragging = false;
            _reveal = _reveal >= _actionWidth * .42 ? _actionWidth : 0;
          }),
          onHorizontalDragCancel: _close,
          child: ClipRect(
            child: Stack(
              alignment: Alignment.centerRight,
              children: [
                if (_reveal >= .5)
                  Positioned(
                    top: 0,
                    right: 0,
                    bottom: 0,
                    child: ClipRect(
                      child: Align(
                        alignment: Alignment.centerRight,
                        widthFactor: _reveal / _actionWidth,
                        child: SizedBox(
                          width: _actionWidth,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              _action(
                                keySuffix: 'edit',
                                tooltip: 'Modifica movimento',
                                icon: Icons.edit_rounded,
                                background: const Color(0xFF597DD8),
                                onPressed: _deleting ? null : _edit,
                              ),
                              const SizedBox(width: 7),
                              _action(
                                keySuffix: 'delete',
                                tooltip: 'Elimina movimento',
                                icon: Icons.delete_outline_rounded,
                                background: Theme.of(context).colorScheme.error,
                                onPressed: _deleting ? null : _delete,
                              ),
                              const SizedBox(width: 3),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  key: const ValueKey('swipe-full-width-content'),
                  duration: _dragging || reducedMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 225),
                  curve: Curves.easeOutCubic,
                  transform: Matrix4.translationValues(-_reveal, 0, 0),
                  child: SizedBox(width: rowWidth, child: widget.child),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
