import 'dart:io';

import 'package:balyn/l10n/localized_material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../models/models.dart';
import 'ui_helpers.dart';

/// Information-first Balyn transaction detail, wired to existing edit actions.
class BalynTransactionDetailContent extends StatelessWidget {
  const BalynTransactionDetailContent({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onAnalyticsChanged,
    super.key,
  });
  final FinanceTransaction item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final ValueChanged<bool> onAnalyticsChanged;

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final account = state.accountById(item.accountId);
    final target = state.accountById(item.toAccountId);
    final category = state.categoryById(item.categoryId);
    final text = Theme.of(context).textTheme;
    final subdued = Theme.of(context).colorScheme.onSurfaceVariant;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = item.type == TransactionType.expense
        ? Theme.of(context).colorScheme.error
        : item.type == TransactionType.income
        ? const Color(0xFF2C9B74)
        : Theme.of(context).colorScheme.primary;
    final amount = state.hideBalance || account?.hideBalance == true
        ? '••••'
        : '${item.type == TransactionType.expense
              ? '-'
              : item.type == TransactionType.income
              ? '+'
              : ''}${moneyFor(state, item.amount)}';
    final refund = state.transactionById(item.refundOfTransactionId);
    final refunds = state.refundsFor(item.id);
    final splits = state.splitsFor(item.id);
    return ColoredBox(
      color: dark ? const Color(0xFF101018) : const Color(0xFFF6F7F9),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 3, 16, 44),
        children: [
          Text(
            amount,
            style: text.displayMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -1.7,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            item.note?.trim().isNotEmpty == true
                ? item.note!.trim()
                : category?.name ?? item.type.label,
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 5),
          Text(
            DateFormat(
              'd MMM yyyy, HH:mm',
              AppI18n.intlLocale,
            ).format(item.date),
            style: text.bodySmall?.copyWith(color: subdued),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _ActionPill(
                  icon: Icons.edit_outlined,
                  label: 'Modifica',
                  onTap: onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPill(
                  icon: Icons.copy_outlined,
                  label: 'Duplica',
                  onTap: onDuplicate,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionPill(
                  icon: Icons.delete_outline_rounded,
                  label: 'Elimina',
                  destructive: true,
                  onTap: onDelete,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _DetailSection(
            children: [
              const _DetailRow(label: 'Stato', value: 'Registrato'),
              _DetailRow(label: 'Tipo', value: item.type.label),
              _DetailRow(
                label: item.type == TransactionType.transfer ? 'Da' : 'Conto',
                value: account?.isSystem == true
                    ? 'Non assegnato'
                    : account?.name ?? 'Conto non disponibile',
                icon: accountIcon(account?.iconKey ?? 'wallet'),
              ),
              if (target != null)
                _DetailRow(
                  label: 'A',
                  value: target.name,
                  icon: accountIcon(target.iconKey),
                ),
              if (category != null)
                _DetailRow(
                  label: 'Categoria',
                  value: category.name,
                  icon: categoryIcon(category.iconKey),
                ),
              if (item.tags.isNotEmpty)
                _DetailRow(label: 'Tag', value: item.tags.join(', ')),
            ],
          ),
          const SizedBox(height: 13),
          _DetailSection(
            children: [
              SwitchListTile.adaptive(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                title: const Text('Escludi dalle analisi'),
                subtitle: const Text(
                  'Non conteggiare questo movimento nei grafici',
                ),
                value: !item.includeInAnalytics,
                onChanged: (excluded) => onAnalyticsChanged(!excluded),
              ),
            ],
          ),
          const SizedBox(height: 13),
          _DetailSection(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Ricevuta'),
                trailing: Text(
                  item.receiptPath?.isNotEmpty == true
                      ? 'Modifica'
                      : 'Aggiungi',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onTap: onEdit,
              ),
              if (item.receiptPath?.isNotEmpty == true)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      File(item.receiptPath!),
                      height: 180,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const ListTile(
                        title: Text('Ricevuta non disponibile'),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 13),
          _DetailSection(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                leading: const Icon(Icons.edit_note_rounded),
                title: const Text('Nota'),
                subtitle: item.note?.isNotEmpty == true
                    ? Text(item.note!)
                    : null,
                trailing: Text(
                  item.note?.isNotEmpty == true ? 'Modifica' : 'Aggiungi nota',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onTap: onEdit,
              ),
            ],
          ),
          if (splits.isNotEmpty) ...[
            const SizedBox(height: 13),
            _DetailSection(
              children: [
                for (final split in splits)
                  _DetailRow(
                    label:
                        state.categoryById(split.categoryId)?.name ??
                        'Categoria',
                    value: state.hideBalance
                        ? '••••'
                        : moneyFor(state, split.amount),
                  ),
              ],
            ),
          ],
          if (refund != null || refunds > 0) ...[
            const SizedBox(height: 13),
            _DetailSection(
              children: [
                if (refund != null)
                  _DetailRow(label: 'Rimborso di', value: '#${refund.id}'),
                if (refunds > 0)
                  _DetailRow(
                    label: 'Rimborsato',
                    value: state.hideBalance
                        ? '••••'
                        : moneyFor(state, refunds),
                  ),
              ],
            ),
          ],
          if (item.recurringId != null) ...[
            const SizedBox(height: 13),
            const _DetailSection(
              children: [
                _DetailRow(label: 'Ricorrenza', value: 'Collegata a Pianifica'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
    this.destructive = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? Theme.of(context).colorScheme.error
        : Theme.of(context).colorScheme.primary;
    return Material(
      color: color.withValues(alpha: .08),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
          child: Column(
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(height: 5),
              FittedBox(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color,
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

class _DetailSection extends StatelessWidget {
  const _DetailSection({required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Theme.of(context).brightness == Brightness.dark
          ? const Color(0xFF252532)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Column(children: children),
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value, this.icon});
  final String label;
  final String value;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Spacer(),
          if (icon != null) ...[
            Icon(icon, color: theme.colorScheme.primary, size: 17),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
