import 'package:balyn/l10n/localized_material.dart';

import 'balyn_cue_section_bar.dart';
import 'balyn_cue_three_dots_action.dart';
import 'balyn_omesh_hero_background.dart';

import '../main.dart';
import '../models/models.dart';
import 'ui_helpers.dart';

/// Revolut Invest-inspired, full-width Home header. All amounts and callbacks
/// are supplied by the finance state; this is not a screenshot or mock data.
class BalynRevolutHomeHero extends StatelessWidget {
  const BalynRevolutHomeHero({
    required this.title,
    required this.balance,
    required this.available,
    required this.hideBalance,
    required this.accounts,
    required this.currentAccountId,
    required this.onAccountChanged,
    required this.selectedTab,
    required this.sectionPage,
    required this.onTabChanged,
    required this.onSearch,
    required this.onAnalytics,
    required this.onSettings,
    required this.onVisibility,
    required this.onExpense,
    required this.onIncome,
    required this.onTransfer,
    required this.onManageAccounts,
    required this.onAdvances,
    required this.onAdvancedDashboard,
    required this.onCustomizeHome,
    super.key,
  });

  final String title;
  final String balance;
  final String available;
  final bool hideBalance;
  final List<Account> accounts;
  final int? currentAccountId;
  final ValueChanged<int?> onAccountChanged;
  final int selectedTab;
  final double sectionPage;
  final ValueChanged<int> onTabChanged;
  final VoidCallback onSearch;
  final VoidCallback onAnalytics;
  final VoidCallback onSettings;
  final VoidCallback onVisibility;
  final VoidCallback onExpense;
  final VoidCallback onIncome;
  final VoidCallback onTransfer;
  final VoidCallback onManageAccounts;
  final VoidCallback onAdvances;
  final VoidCallback onAdvancedDashboard;
  final VoidCallback onCustomizeHome;

  static const _balynAccent = Color(0xFF7955EB);

  Color get _accent {
    final matching = accounts.where(
      (account) => account.id == currentAccountId,
    );
    if (matching.isEmpty) return _balynAccent;
    // Honor the real saved account color; hue companions are derived by
    // balynHeroMeshColors, never chosen from a complementary palette.
    return Color(matching.first.colorValue);
  }

  void _switchAccount(int direction) {
    if (accounts.isEmpty) return;
    final ids = <int?>[null, ...accounts.map((account) => account.id)];
    final index = ids.indexOf(currentAccountId);
    final next =
        ((index < 0 ? 0 : index) + direction + ids.length) % ids.length;
    onAccountChanged(ids[next]);
  }

  void _showAccountSelector(BuildContext context) {
    final state = AppScope.of(context);
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(sheetContext).height * .70,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Seleziona conto',
                  style: Theme.of(
                    sheetContext,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                children: [
                  _HeroAccountOption(
                    title: 'Patrimonio totale',
                    subtitle: 'Tutti i conti',
                    icon: Icons.account_balance_wallet_outlined,
                    color: _balynAccent,
                    selected: currentAccountId == null,
                    onTap: () {
                      Navigator.pop(sheetContext);
                      onAccountChanged(null);
                    },
                  ),
                  if (accounts.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(13, 12, 13, 6),
                      child: Text(
                        'I TUOI CONTI',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: .8,
                        ),
                      ),
                    ),
                  for (final account in accounts)
                    _HeroAccountOption(
                      key: ValueKey('hero-account-${account.id}'),
                      title: account.name,
                      subtitle: account.hideBalance || state.hideBalance
                          ? account.accountType.label
                          : '${account.accountType.label} · ${moneyFor(state, account.balance)}',
                      icon: accountIcon(account.iconKey),
                      color: Color(account.colorValue),
                      selected: account.id == currentAccountId,
                      onTap: () {
                        Navigator.pop(sheetContext);
                        onAccountChanged(account.id);
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight = MediaQuery.sizeOf(context).height;
    final height = (availableHeight * .41).clamp(300.0, 356.0).toDouble();
    final largeText = MediaQuery.textScalerOf(context).scale(1) > 1.25;

    return SizedBox(
      height: height + 23,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: height,
            child: TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: _accent),
              duration: const Duration(milliseconds: 550),
              curve: Curves.easeInOutCubic,
              builder: (context, color, _) => BalynOMeshHeroBackground(
                accent: color ?? _accent,
                useBasicPalette: currentAccountId == null,
              ),
            ),
          ),
          Positioned.fill(
            bottom: 23,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                children: [
                  Row(
                    children: [
                      Tooltip(
                        message: 'Impostazioni Balyn',
                        child: Material(
                          color: Colors.white.withValues(alpha: .18),
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: onSettings,
                            child: const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: Text(
                                  'B',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 21,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Material(
                          color: Colors.white.withValues(alpha: .28),
                          borderRadius: BorderRadius.circular(24),
                          child: InkWell(
                            onTap: onSearch,
                            borderRadius: BorderRadius.circular(24),
                            child: const SizedBox(
                              height: 40,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 14),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.search_rounded,
                                      color: Colors.white,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Cerca movimenti',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
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
                      const SizedBox(width: 8),
                      _RoundHeaderAction(
                        icon: Icons.bar_chart_rounded,
                        tooltip: 'Analisi',
                        onTap: onAnalytics,
                      ),
                      const SizedBox(width: 6),
                      _RoundHeaderAction(
                        icon: Icons.tune_rounded,
                        tooltip: 'Impostazioni',
                        onTap: onSettings,
                      ),
                    ],
                  ),

                  const Spacer(flex: 3),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onHorizontalDragEnd: (details) {
                            final velocity = details.primaryVelocity ?? 0;
                            if (velocity.abs() >= 110) {
                              _switchAccount(velocity < 0 ? 1 : -1);
                            }
                          },
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  key: const ValueKey('hero-account-dropdown'),
                                  onTap: () => _showAccountSelector(context),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 6,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            title.toUpperCase(),
                                            textAlign: TextAlign.center,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.white.withValues(
                                                alpha: .9,
                                              ),
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              letterSpacing: .45,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 7),
                                        Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          size: 21,
                                          color: Colors.white.withValues(
                                            alpha: .92,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 5),
                              SizedBox(
                                height: 48,
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned.fill(
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 29,
                                        ),
                                        child: Center(
                                          child: AnimatedSwitcher(
                                            duration: const Duration(
                                              milliseconds: 250,
                                            ),
                                            child: FittedBox(
                                              key: ValueKey(
                                                'hero-balance-${currentAccountId ?? "total"}-$balance',
                                              ),
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                balance,
                                                key: const ValueKey(
                                                  'balyn-revolut-balance',
                                                ),
                                                textAlign: TextAlign.center,
                                                maxLines: 1,
                                                style: const TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 37,
                                                  height: 1.05,
                                                  fontWeight: FontWeight.w800,
                                                  letterSpacing: -1.6,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      right: 0,
                                      child: IconButton(
                                        tooltip: hideBalance
                                            ? 'Mostra saldi'
                                            : 'Nascondi saldi',
                                        onPressed: onVisibility,
                                        iconSize: 18,
                                        color: Colors.white.withValues(
                                          alpha: .88,
                                        ),
                                        constraints: const BoxConstraints(
                                          minWidth: 35,
                                          minHeight: 40,
                                        ),
                                        icon: Icon(
                                          hideBalance
                                              ? Icons.visibility_off_outlined
                                              : Icons.visibility_outlined,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Disponibile  $available',
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: .85),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(flex: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _HeroAction(
                        icon: Icons.arrow_upward_rounded,
                        label: 'Spesa',
                        onTap: onExpense,
                      ),
                      _HeroAction(
                        icon: Icons.arrow_downward_rounded,
                        label: 'Entrata',
                        onTap: onIncome,
                      ),
                      _HeroAction(
                        icon: Icons.swap_horiz_rounded,
                        label: 'Trasferisci',
                        onTap: onTransfer,
                      ),
                      BalynCueThreeDotsAction(
                        onManageAccounts: onManageAccounts,
                        onAdvances: onAdvances,
                        onAdvancedDashboard: onAdvancedDashboard,
                        onCustomizeHome: onCustomizeHome,
                      ),
                    ],
                  ),
                  SizedBox(height: largeText ? 23 : 13),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 1,
            left: 16,
            right: 16,
            child: Semantics(
              label: 'Sezione Home',
              child: BalynCueSectionBar(
                selectedTab: selectedTab,
                page: sectionPage,
                onSelected: onTabChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroAccountOption extends StatelessWidget {
  const _HeroAccountOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Material(
        color: selected
            ? scheme.primary.withValues(alpha: .09)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          leading: Container(
            height: 42,
            width: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: color.withValues(alpha: .13),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          title: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: selected
              ? Icon(Icons.check_circle_rounded, color: scheme.primary)
              : const Icon(Icons.chevron_right_rounded),
          onTap: onTap,
        ),
      ),
    );
  }
}

class _RoundHeaderAction extends StatelessWidget {
  const _RoundHeaderAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: .27),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 39,
            height: 39,
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _HeroAction extends StatelessWidget {
  const _HeroAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 52,
                    width: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: .26),
                    ),
                    child: Icon(icon, color: Colors.white, size: 24),
                  ),
                  const SizedBox(height: 9),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
