import 'package:flutter/material.dart';

class FinanceQuickAction extends StatefulWidget {
  const FinanceQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.semanticLabel,
    this.color,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final Color? color;

  @override
  State<FinanceQuickAction> createState() => _FinanceQuickActionState();
}

class _FinanceQuickActionState extends State<FinanceQuickAction> {
  var _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = widget.color ?? Theme.of(context).colorScheme.primary;
    final resolvedColor = enabled ? base : base.withValues(alpha: .38);
    final surface = resolvedColor.withValues(
      alpha: Theme.of(context).brightness == Brightness.dark ? .14 : .08,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: Tooltip(
        message: widget.semanticLabel ?? widget.label,
        child: AnimatedScale(
          scale: _pressed ? .96 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Material(
              color: surface,
              borderRadius: BorderRadius.circular(22),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: enabled
                    ? (value) => setState(() => _pressed = value)
                    : null,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: 78,
                    minWidth: 48,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 12,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: resolvedColor.withValues(alpha: .12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            widget.icon,
                            size: 21,
                            color: resolvedColor,
                          ),
                        ),
                        const SizedBox(height: 7),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            softWrap: false,
                            overflow: TextOverflow.visible,
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(
                                  color: resolvedColor,
                                  fontWeight: FontWeight.w800,
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
        ),
      ),
    );
  }
}
