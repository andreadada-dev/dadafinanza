import 'package:balyn/l10n/localized_material.dart';

import 'ui_helpers.dart';

/// Large live account preview shared by account creation and editing.
class BalynAccountLivePreview extends StatelessWidget {
  const BalynAccountLivePreview({
    required this.iconKey,
    required this.color,
    super.key,
  });

  final String iconKey;
  final Color color;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: AnimatedContainer(
        key: const ValueKey('account-live-preview'),
        width: 106,
        height: 106,
        alignment: Alignment.center,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .14),
          borderRadius: BorderRadius.circular(31),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            accountIcon(iconKey),
            key: ValueKey(iconKey),
            color: color,
            size: 57,
          ),
        ),
      ),
    ),
  );
}
