import 'package:balyn/l10n/localized_material.dart';

import '../main.dart';
import 'balyn_shader_system.dart';
import 'ui_helpers.dart';

class AccountContextSelector extends StatelessWidget {
  const AccountContextSelector({
    required this.accountId,
    required this.onChanged,
    super.key,
  });

  final int? accountId;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final selected = state.accountById(accountId);
    final label = selected == null || selected.isArchived || selected.isSystem
        ? 'Totale'
        : selected.name;

    return PopupMenuButton<int>(
      tooltip: AppI18n.tr('Seleziona conto'),
      initialValue: selected == null ? 0 : selected.id,
      onSelected: (value) => onChanged(value == 0 ? null : value),
      itemBuilder: (context) => [
        const PopupMenuItem<int>(
          value: 0,
          child: Row(
            children: [
              Icon(Icons.account_balance_wallet_outlined),
              SizedBox(width: 12),
              Text('Totale'),
            ],
          ),
        ),
        ...state.activeAccounts.map(
          (account) => PopupMenuItem<int>(
            value: account.id,
            child: Row(
              children: [
                BalynShaderIcon(
                  accountIcon(account.iconKey),
                  seed: Color(account.colorValue),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    account.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
      child: Container(
        constraints: const BoxConstraints(maxWidth: 220, minHeight: 38),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
          ],
        ),
      ),
    );
  }
}
