import 'dart:async';

import 'package:balyn/l10n/localized_material.dart';

import '../app_state.dart';
import '../main.dart';
import '../models/models.dart';
import '../models/quick_capture_models.dart';
import '../services/haptic_service.dart';
import '../services/quick_preset_service.dart';
import '../widgets/balyn_quick_action_launcher.dart';
import '../widgets/balyn_data_skeleton.dart';
import '../widgets/smooth_indexed_pages.dart';
import '../widgets/ui_helpers.dart';
import 'balyn_activity_screen.dart';
import 'account_context_home_screen.dart';
import 'advances_screen.dart';
import 'planning_screens.dart';
import 'preset_management_screen.dart';
import 'quick_add_page.dart';

/// The single navigation shell exposed by Balyn.
///
/// Home and Attività share one account context. `null` means Totale.
class BalynAppShell extends StatefulWidget {
  const BalynAppShell({super.key});

  @override
  State<BalynAppShell> createState() => _BalynAppShellState();
}

class _BalynAppShellState extends State<BalynAppShell> {
  int index = 0;
  int? accountId;
  int _homeSection = 0;
  int _homeDirection = 1;
  bool _allowExit = false;
  bool _launcherOpen = false;
  Timer? _exitTimer;

  @override
  void dispose() {
    _exitTimer?.cancel();
    super.dispose();
  }

  void _selectAccount(int? value) {
    if (accountId == value) return;
    final state = AppScope.of(context);
    unawaited(HapticService.light(enabled: state.haptics));
    setState(() => accountId = value);
  }

  void _selectHomeSection(int next) {
    if (_homeSection == next) return;
    final state = AppScope.of(context);
    unawaited(HapticService.light(enabled: state.haptics));
    setState(() {
      _homeDirection = next > _homeSection ? 1 : -1;
      _homeSection = next;
    });
  }

  void _showHomeActivity(int innerTab) {
    _selectHomeSection(innerTab == 0 ? 1 : 2);
  }

  void _selectTab(int value) {
    if (index != value) {
      final state = AppScope.of(context);
      unawaited(HapticService.light(enabled: state.haptics));
    }
    _exitTimer?.cancel();
    setState(() {
      index = value;
      _launcherOpen = false;
      _allowExit = false;
    });
  }

  void _handleBack(bool didPop) {
    if (didPop) return;
    if (_launcherOpen) {
      setState(() => _launcherOpen = false);
      return;
    }
    if (index != 0) {
      _selectTab(0);
      return;
    }
    if (_homeSection != 0) {
      _selectHomeSection(0);
      return;
    }
    _exitTimer?.cancel();
    setState(() => _allowExit = true);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Premi di nuovo Indietro per chiudere.')),
      );
    _exitTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _allowExit = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = AppScope.of(context);
    final effectiveAccountId =
        state.activeAccounts.any((a) => a.id == accountId) ? accountId : null;
    if (effectiveAccountId != accountId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && accountId != effectiveAccountId) {
          setState(() => accountId = effectiveAccountId);
        }
      });
    }

    final pages = [
      AccountContextHomeScreen(
        accountId: effectiveAccountId,
        onAccountChanged: _selectAccount,
        selectedSection: _homeSection,
        slideDirection: _homeDirection,
        onSectionChanged: _selectHomeSection,
        onShowActivity: _showHomeActivity,
      ),
      BalynActivityScreen(
        accountId: effectiveAccountId,
        onAccountChanged: _selectAccount,
      ),
      const AdvancesScreen(showFab: false),
      const PlanningScreen(),
    ];

    if (state.loading) {
      return Scaffold(body: BalynDataSkeletonView(section: index));
    }

    return PopScope(
      canPop: _allowExit,
      onPopInvoked: _handleBack,
      child: Scaffold(
        extendBody: true,
        body: Stack(
          fit: StackFit.expand,
          children: [
            SafeArea(
              bottom: false,
              child: SmoothIndexedPages(index: index, children: pages),
            ),
            if (_launcherOpen)
              Positioned.fill(
                child: GestureDetector(
                  key: const ValueKey('quick-nav-dismiss'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _launcherOpen = false),
                  child: ColoredBox(color: Colors.black.withValues(alpha: .12)),
                ),
              ),
            Positioned(
              right: 19,
              bottom: MediaQuery.viewPaddingOf(context).bottom + 15,
              child: BalynQuickActionLauncher(
                expanded: _launcherOpen,
                showHome: index != 0,
                onToggle: () => setState(() => _launcherOpen = !_launcherOpen),
                onCreate: () {
                  setState(() => _launcherOpen = false);
                  _open(TransactionType.expense);
                },
                onAdvances: () => _selectTab(2),
                onPlanning: () => _selectTab(3),
                onHome: () => _selectTab(0),
                onLongPress: () {
                  setState(() => _launcherOpen = false);
                  _showQuickMenu();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAdvance() async {
    final state = AppScope.of(context);
    await HapticService.light(enabled: state.haptics);
    if (!mounted) return;
    await showAdvanceEditor(context);
  }

  Future<void> _open(
    TransactionType type, {
    QuickPreset? preset,
    bool voice = false,
  }) async {
    final state = AppScope.of(context);
    await HapticService.light(enabled: state.haptics);
    int? selectedAccount = preset?.accountId ?? accountId;
    int? destinationId = preset?.toAccountId;
    if (selectedAccount == null) {
      final key = switch (type) {
        TransactionType.expense => 'preferred_expense_account',
        TransactionType.income => 'preferred_income_account',
        TransactionType.transfer => 'preferred_transfer_source',
      };
      selectedAccount = int.tryParse(
        await state.database.getSetting(key) ?? '',
      );
    }
    if (type == TransactionType.transfer && destinationId == null) {
      destinationId = int.tryParse(
        await state.database.getSetting('preferred_transfer_destination') ?? '',
      );
    }
    if (destinationId == selectedAccount) destinationId = null;
    if (!mounted) return;

    final draft = preset != null
        ? preset.toTransactionDraft(
            resolvedAccountId: selectedAccount,
            resolvedToAccountId: destinationId,
          )
        : TransactionDraft(
            type: type,
            accountId: selectedAccount,
            toAccountId: destinationId,
            source: voice
                ? QuickCaptureSource.voice
                : QuickCaptureSource.manual,
            startVoice: voice,
          );
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => QuickAddPage(initialDraft: draft)),
    );
  }

  Future<void> _showQuickMenu() async {
    final state = AppScope.of(context);
    await HapticService.medium(enabled: state.haptics);
    final presets = await QuickPresetService(
      state.database,
    ).all(enabledOnly: true);
    if (!mounted) return;

    final choice = await showGeneralDialog<Object>(
      context: context,
      barrierDismissible: true,
      barrierLabel: AppI18n.tr('Chiudi scorciatoie'),
      barrierColor: Theme.of(context).colorScheme.scrim.withOpacity(0.32),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (dialogContext, _, __) => SafeArea(
        child: LayoutBuilder(
          builder: (dialogContext, constraints) {
            final maxHeight = (constraints.maxHeight - 180)
                .clamp(220.0, 460.0)
                .toDouble();
            return Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 144),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 360,
                    maxHeight: maxHeight,
                  ),
                  child: _QuickFabMenu(
                    presets: presets,
                    state: state,
                    onSelected: (value) => Navigator.pop(dialogContext, value),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      transitionBuilder: (dialogContext, animation, _, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        );
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.08),
              end: Offset.zero,
            ).animate(curved),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
              alignment: Alignment.bottomCenter,
              child: child,
            ),
          ),
        );
      },
    );

    if (!mounted || choice == null) return;
    if (choice is _AdvanceChoice) {
      await _openAdvance();
    } else if (choice is QuickPreset) {
      await _open(choice.type, preset: choice);
    } else if (choice is _VoiceChoice) {
      await _open(TransactionType.expense, voice: true);
    } else if (choice is _ManagePresetsChoice) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const PresetManagementScreen()),
      );
    }
  }
}

class _QuickFabMenu extends StatelessWidget {
  const _QuickFabMenu({
    required this.presets,
    required this.state,
    required this.onSelected,
  });

  final List<QuickPreset> presets;
  final AppState state;
  final ValueChanged<Object> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surface,
      elevation: 8,
      shadowColor: theme.colorScheme.shadow.withOpacity(0.18),
      borderRadius: BorderRadius.circular(28),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Scorciatoie', style: theme.textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(
                    'Tocca un preset per aprire il movimento già compilato.',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (presets.isNotEmpty) ...[
              const _QuickFabSectionLabel('Preset'),
              ...presets.map(
                (preset) => _QuickFabMenuItem(
                  icon: Icons.bookmark_outline_rounded,
                  title: preset.name,
                  subtitle: [
                    preset.type.label,
                    if (preset.amount != null) moneyFor(state, preset.amount!),
                  ].join(' · '),
                  onTap: () => onSelected(preset),
                ),
              ),
            ] else ...[
              const _QuickFabSectionLabel('Preset'),
              _QuickFabMenuItem(
                icon: Icons.bookmark_add_outlined,
                title: 'Crea il primo preset',
                subtitle: 'Salva un movimento ricorrente come scorciatoia',
                onTap: () => onSelected(const _ManagePresetsChoice()),
              ),
            ],
            const Divider(height: 1, indent: 20, endIndent: 20),
            const _QuickFabSectionLabel('Azioni'),
            _QuickFabMenuItem(
              icon: Icons.mic_none_rounded,
              title: 'Voce',
              subtitle: 'Compila il movimento parlando',
              onTap: () => onSelected(const _VoiceChoice()),
            ),
            _QuickFabMenuItem(
              icon: Icons.handshake_outlined,
              title: 'Anticipo',
              subtitle: 'Soldi da ricevere o da restituire',
              onTap: () => onSelected(const _AdvanceChoice()),
            ),
            _QuickFabMenuItem(
              icon: Icons.tune_rounded,
              title: 'Gestisci preset',
              subtitle: 'Crea, modifica e riordina le scorciatoie',
              onTap: () => onSelected(const _ManagePresetsChoice()),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickFabSectionLabel extends StatelessWidget {
  const _QuickFabSectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
    child: Text(text, style: Theme.of(context).textTheme.labelLarge),
  );
}

class _QuickFabMenuItem extends StatelessWidget {
  const _QuickFabMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => ListTile(
    minVerticalPadding: 10,
    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
    leading: Icon(icon),
    title: Text(title),
    subtitle: subtitle == null ? null : Text(subtitle!),
    trailing: const Icon(Icons.chevron_right_rounded),
    onTap: onTap,
  );
}

class _VoiceChoice {
  const _VoiceChoice();
}

class _AdvanceChoice {
  const _AdvanceChoice();
}

class _ManagePresetsChoice {
  const _ManagePresetsChoice();
}
