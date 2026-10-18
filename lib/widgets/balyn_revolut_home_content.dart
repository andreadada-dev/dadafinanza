import 'package:balyn/l10n/localized_material.dart';

import '../main.dart';
import '../models/models.dart';
import 'ui_helpers.dart';

/// Native Flutter content below the purple hero, inspired by the white
/// portfolio panels in the Revolut reference. Uses live Balyn data.
class BalynRevolutHomeContent extends StatelessWidget {
  const BalynRevolutHomeContent({
    required this.income,
    required this.expense,
    required this.available,
    required this.hideValues,
    required this.showAccounts,
    required this.onSelectAccount,
    required this.onManageAccounts,
    super.key,
  });

  final double income;
  final double expense;
  final double available;
  final bool hideValues;
  final bool showAccounts;
  final ValueChanged<int?> onSelectAccount;
  final VoidCallback onManageAccounts;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final scheme = Theme.of(context).colorScheme;
    final accountList = state.activeAccounts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showAccounts) ...[
          Row(
            children: [
              Expanded(
                child: _BalanceMetric(
                  title: 'Entrate',
                  value: hideValues ? '••••' : moneyFor(state, income),
                  icon: Icons.south_west_rounded,
                  color: context.financeColors.positive,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _BalanceMetric(
                  title: 'Spese',
                  value: hideValues ? '••••' : moneyFor(state, expense),
                  icon: Icons.north_east_rounded,
                  color: context.financeColors.negative,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _AvailableSummary(
            value: hideValues ? '••••' : moneyFor(state, available),
          ),
          const SizedBox(height: 23),
        ],
        Row(
          children: [
            Expanded(
              child: Text(
                'I tuoi conti',
                style: Theme.of(context).textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            TextButton(
              onPressed: onManageAccounts,
              child: const Text('Gestisci'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(19),
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF242431)
                : Colors.white,
          ),
          child: accountList.isEmpty
              ? ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text('Nessun conto'),
                  subtitle: const Text('Aggiungi il primo conto per iniziare'),
                  trailing: const Icon(Icons.add_rounded),
                  onTap: onManageAccounts,
                )
              : Column(
                  children: [
                    for (var i = 0; i < accountList.length; i++) ...[
                      if (i > 0)
                        Divider(
                          height: 1,
                          indent: 70,
                          color: scheme.outlineVariant,
                        ),
                      _LiveAccountTile(
                        account: accountList[i],
                        hideValues: hideValues,
                        onTap: () => onSelectAccount(accountList[i].id),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class _BalanceMetric extends StatelessWidget {
  const _BalanceMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      height: 112,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: theme.brightness == Brightness.dark
            ? const Color(0xFF242431)
            : Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const Spacer(),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall,
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              maxLines: 1,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableSummary extends StatelessWidget {
  const _AvailableSummary({required this.value});
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: dark ? const Color(0xFF242431) : Colors.white,
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            color: theme.colorScheme.primary,
            size: 23,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              'Disponibile',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Flexible(
            child: FittedBox(
              alignment: Alignment.centerRight,
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveAccountTile extends StatelessWidget {
  const _LiveAccountTile({
    required this.account,
    required this.hideValues,
    required this.onTap,
  });
  final Account account;
  final bool hideValues;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final color = Color(account.colorValue);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      leading: Container(
        height: 44,
        width: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(15),
        ),
        child: Icon(accountIcon(account.iconKey), color: color),
      ),
      title: Text(
        account.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontWeight: FontWeight.w700),
      ),
      subtitle: Text(account.accountType.label),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 118),
        child: Text(
          hideValues || account.hideBalance
              ? '••••'
              : moneyFor(state, account.balance),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.end,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      onTap: onTap,
    );
  }
}
