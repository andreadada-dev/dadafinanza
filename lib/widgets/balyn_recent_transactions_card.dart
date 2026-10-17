import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';

import '../main.dart';
import '../models/models.dart';
import '../screens/transaction_screens.dart';
import 'ui_helpers.dart';

/// Figma Home transaction panel. No mock movements or invented statuses.
class BalynRecentTransactionsCard extends StatelessWidget {
  const BalynRecentTransactionsCard({
    required this.items,
    required this.onSeeAll,
    super.key,
  });

  final List<FinanceTransaction> items;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final light = theme.brightness == Brightness.light;
    final visible = items.take(3).toList(growable: false);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: light ? Colors.white : const Color(0xFF252532),
        borderRadius: BorderRadius.circular(21),
      ),
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 8),
      child: Column(
        children: [
          Row(
            children: [
              Text('Movimento', style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
              const Spacer(),
              Text('Importo', style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500)),
            ],
          ),
          const SizedBox(height: 11),
          if (visible.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Row(
                children: [
                  Icon(Icons.receipt_long_outlined, size: 22),
                  SizedBox(width: 12),
                  Expanded(child: Text('Non ci sono ancora movimenti')),
                ],
              ),
            )
          else
            for (final movement in visible)
              _RecentMovementRow(
                key: ValueKey('recent-movement-${movement.id}'),
                movement: movement,
              ),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: onSeeAll,
              child: const Text('Vedi tutti'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentMovementRow extends StatelessWidget {
  const _RecentMovementRow({required this.movement, super.key});

  final FinanceTransaction movement;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final theme = Theme.of(context);
    final category = state.categoryById(movement.categoryId);
    final account = state.accountById(movement.accountId);
    final destination = state.accountById(movement.toAccountId);
    final title = movement.note?.trim().isNotEmpty == true
        ? movement.note!.trim()
        : movement.type == TransactionType.transfer
            ? 'Trasferimento'
            : category?.name ?? 'Senza categoria';
    final accent = category == null
        ? transactionColor(context, movement.type)
        : Color(category.colorValue);
    final subtitle = movement.type == TransactionType.transfer
        ? '${account?.name ?? 'Conto'} → ${destination?.name ?? 'Conto'}'
        : account?.name ?? 'Conto';
    final amount = movement.type == TransactionType.expense
        ? '-${moneyFor(state, movement.amount)}'
        : movement.type == TransactionType.income
            ? '+${moneyFor(state, movement.amount)}'
            : moneyFor(state, movement.amount);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailPage(transactionId: movement.id),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: 46,
                width: 46,
                child: Stack(
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: .16),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        movement.type == TransactionType.transfer
                            ? Icons.swap_horiz_rounded
                            : category == null
                                ? Icons.receipt_long_outlined
                                : categoryIcon(category.iconKey),
                        color: accent,
                        size: 23,
                      ),
                    ),
                    Positioned(
                      bottom: 1,
                      right: 1,
                      child: Container(
                        height: 17,
                        width: 17,
                        decoration: BoxDecoration(
                          color: accent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.colorScheme.surface,
                            width: 1.5,
                          ),
                        ),
                        child: Icon(
                          movement.type == TransactionType.income
                              ? Icons.south_west_rounded
                              : movement.type == TransactionType.expense
                                  ? Icons.north_east_rounded
                                  : Icons.swap_horiz_rounded,
                          size: 10,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${DateFormat('d MMM, HH:mm', AppI18n.intlLocale).format(movement.date)} · $subtitle',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      movement.type.label,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 112),
                child: Text(
                  state.hideBalance ? '••••' : amount,
                  textAlign: TextAlign.end,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
