import 'package:balyn/l10n/localized_material.dart';

import '../main.dart';
import '../models/models.dart';
import 'ui_helpers.dart';

/// Left swipe reveals a delete action, inspired by animated_selection_slide.
/// No destructive action is performed merely by swiping.
class BalynSwipeDeleteTile extends StatefulWidget {
  const BalynSwipeDeleteTile({
    required this.item,
    required this.child,
    super.key,
  });

  final FinanceTransaction item;
  final Widget child;

  @override
  State<BalynSwipeDeleteTile> createState() => _BalynSwipeDeleteTileState();
}

class _BalynSwipeDeleteTileState extends State<BalynSwipeDeleteTile> {
  static const double _actionWidth = 88;
  double _offset = 0;
  bool _dragging = false;
  bool _deleting = false;

  Future<void> _delete() async {
    if (_deleting) return;
    final state = AppScope.of(context);
    if (state.isAdvanceProtectedTransaction(widget.item)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gestisci questo movimento dalla sezione Anticipi.'),
        ),
      );
      setState(() => _offset = 0);
      return;
    }
    final approved = await confirmDestructiveAction(
      context,
      title: 'Eliminare il movimento?',
      message: 'Il saldo del conto verrà ricalcolato automaticamente.',
    );
    if (!mounted) return;
    if (!approved) {
      setState(() => _offset = 0);
      return;
    }
    setState(() => _deleting = true);
    try {
      final current = state.transactionById(widget.item.id);
      if (current != null) await state.deleteTransaction(current);
      if (mounted) setState(() => _offset = 0);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _deleting = false;
        _offset = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final color = Theme.of(context).colorScheme.error;
    return ClipRect(
      child: Stack(
        alignment: Alignment.centerRight,
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: SizedBox(
                width: _actionWidth,
                child: Material(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    key: ValueKey('swipe-delete-${widget.item.id}'),
                    onTap: _deleting ? null : _delete,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_deleting)
                          const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        else
                          const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 23,
                          ),
                        const SizedBox(height: 3),
                        const Text(
                          'Elimina',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: (details) => setState(() {
              _offset = (_offset + details.delta.dx).clamp(-_actionWidth, 0.0);
            }),
            onHorizontalDragEnd: (details) => setState(() {
              _dragging = false;
              _offset = _offset < -_actionWidth * .46 ? -_actionWidth : 0;
            }),
            onHorizontalDragCancel: () => setState(() {
              _dragging = false;
              _offset = 0;
            }),
            child: AnimatedContainer(
              duration: _dragging || reducedMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: Material(color: Colors.transparent, child: widget.child),
            ),
          ),
        ],
      ),
    );
  }
}
