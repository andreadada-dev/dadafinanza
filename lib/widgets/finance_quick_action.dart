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
    final theme = Theme.of(context);
    final enabled = widget.onTap != null;
    final base = widget.color ?? theme.colorScheme.onSurface;
    final resolvedColor = enabled ? base : base.withValues(alpha: .38);
    final circleSurface = resolvedColor.withValues(
      alpha: theme.brightness == Brightness.dark ? .14 : .08,
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: Tooltip(
        message: widget.semanticLabel ?? widget.label,
        child: AnimatedScale(
          scale: _pressed ? .95 : 1,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: widget.onTap,
              onHighlightChanged: enabled
                  ? (value) => setState(() => _pressed = value)
                  : null,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 92, minWidth: 48),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: circleSurface,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(widget.icon, size: 29, color: resolvedColor),
                      ),
                      const SizedBox(height: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          widget.label,
                          maxLines: 1,
                          softWrap: false,
                          style: theme.textTheme.labelLarge?.copyWith(
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
    );
  }
}
