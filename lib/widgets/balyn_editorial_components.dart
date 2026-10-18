import 'package:balyn/l10n/localized_material.dart';
import '../theme/balyn_palette.dart';

/// The same flat, information-first surfaces are used throughout Balyn.
/// Background remains local to each screen, so the shared liquid shader is
/// preserved by navigation and remains configurable in Settings.
class BalynEditorialSurface extends StatelessWidget {
  const BalynEditorialSurface({
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = BalynPalette.radius,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: BalynPalette.surface(Theme.of(context).brightness),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: child,
    );
  }
}

class BalynEditorialHeading extends StatelessWidget {
  const BalynEditorialHeading({
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
    super.key,
  });

  final String title;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -.45,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              actionLabel!,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }
}

class BalynEditorialIcon extends StatelessWidget {
  const BalynEditorialIcon({
    required this.icon,
    this.color,
    this.size = 44,
    super.key,
  });

  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: .11),
        borderRadius: BorderRadius.circular(size * .32),
      ),
      child: Icon(icon, size: size * .48, color: tint),
    );
  }
}

/// Compact top-level section header used in tab pages (not nested editors).
class BalynEditorialPageTitle extends StatelessWidget {
  const BalynEditorialPageTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    super.key,
  });

  final String title;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 4, 0, 19),
    child: Row(
      children: [
        BalynEditorialIcon(icon: icon, size: 46),
        const SizedBox(width: 12),
        Expanded(
          child: BalynEditorialHeading(title: title, subtitle: subtitle),
        ),
      ],
    ),
  );
}
