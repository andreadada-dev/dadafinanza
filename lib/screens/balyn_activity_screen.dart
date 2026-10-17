import 'package:balyn/l10n/localized_material.dart';

import '../widgets/account_context_selector.dart';
import '../widgets/balyn_editorial_components.dart';
import 'account_context_transactions_screen.dart';
import 'account_context_analytics_screen.dart';

/// Movements and Analytics belong to one "Attività" destination: users can
/// move between their activity and insights without losing account context,
/// search filters, period selection or their scroll position.
class BalynActivityScreen extends StatefulWidget {
  const BalynActivityScreen({
    required this.accountId,
    required this.onAccountChanged,
    super.key,
  });

  final int? accountId;
  final ValueChanged<int?> onAccountChanged;

  @override
  State<BalynActivityScreen> createState() => _BalynActivityScreenState();
}

class _BalynActivityScreenState extends State<BalynActivityScreen> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? const Color(0xFF101018) : const Color(0xFFF7F8FA),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: BalynEditorialHeading(
                        title: 'Attività',
                        subtitle: 'Operazioni e andamento delle tue finanze',
                      ),
                    ),
                    AccountContextSelector(
                      accountId: widget.accountId,
                      onChanged: widget.onAccountChanged,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  height: 46,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: dark
                        ? const Color(0xFF2B2A37)
                        : const Color(0xFFE9E9F0),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Row(
                    children: [
                      _ActivityTab(
                        label: 'Movimenti',
                        icon: Icons.receipt_long_outlined,
                        selected: _selected == 0,
                        onTap: () => setState(() => _selected = 0),
                      ),
                      _ActivityTab(
                        label: 'Analisi',
                        icon: Icons.insights_outlined,
                        selected: _selected == 1,
                        onTap: () => setState(() => _selected = 1),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selected,
              children: [
                AccountContextTransactionsScreen(
                  embedded: true,
                  accountId: widget.accountId,
                  onAccountChanged: widget.onAccountChanged,
                ),
                AccountContextAnalyticsScreen(
                  embedded: true,
                  accountId: widget.accountId,
                  onAccountChanged: widget.onAccountChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Expanded(
      child: Material(
        color: selected
            ? (dark ? const Color(0xFF4C466B) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        child: InkWell(
          borderRadius: BorderRadius.circular(21),
          onTap: onTap,
          child: SizedBox(
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
