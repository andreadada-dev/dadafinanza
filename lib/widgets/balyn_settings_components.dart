import 'package:balyn/l10n/localized_material.dart';
import '../theme/balyn_palette.dart';

/// Revolut-inspired grouped settings, based on the information hierarchy of
/// Babstrap Settings Screen. No dependency on its pre-Dart-3 package.
class BalynSettingsGroup extends StatelessWidget {
  const BalynSettingsGroup({
    required this.title,
    required this.children,
    this.accent,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final tint = accent ?? theme.colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 10),
            child: Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: .15,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Material(
            color: BalynPalette.surface(theme.brightness),
            borderRadius: BorderRadius.circular(22),
            clipBehavior: Clip.antiAlias,
            child: Theme(
              data: theme.copyWith(
                colorScheme: theme.colorScheme.copyWith(primary: tint),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[
                    if (i != 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 64, right: 16),
                        child: Divider(
                          height: 1,
                          thickness: .65,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: dark ? .09 : .065,
                          ),
                        ),
                      ),
                    children[i],
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-width navigation row with a soft icon tile and a trailing chevron.
class BalynSettingsTile extends StatelessWidget {
  const BalynSettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      key: ValueKey('setting-$title'),
      onTap: onTap,
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13),
      horizontalTitleGap: 12,
      leading: _SettingsIcon(icon: icon),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(
        subtitle,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.35,
        ),
      ),
      trailing: Icon(
        Icons.chevron_right_rounded,
        size: 20,
        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: .8),
      ),
    );
  }
}

/// Tapping either the row or its switch updates the actual stored preference.
class BalynSettingsSwitch extends StatelessWidget {
  const BalynSettingsSwitch({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final IconData icon;
  final Widget title;
  final Widget? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      minVerticalPadding: 12,
      contentPadding: const EdgeInsets.only(left: 13, right: 10),
      horizontalTitleGap: 12,
      leading: _SettingsIcon(icon: icon),
      title: DefaultTextStyle.merge(
        style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700),
        child: title,
      ),
      subtitle: subtitle == null
          ? null
          : DefaultTextStyle.merge(
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
              child: subtitle!,
            ),
      trailing: Switch.adaptive(value: value, onChanged: onChanged),
      onTap: onChanged == null ? null : () => onChanged!(!value),
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    return Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: .105),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Icon(icon, color: color, size: 21),
    );
  }
}
