import 'dart:async';

import 'package:balyn/l10n/localized_material.dart';
import 'package:pie_menu/pie_menu.dart';

import '../main.dart';
import '../models/models.dart';
import '../models/quick_capture_models.dart';
import '../services/haptic_service.dart';
import '../services/quick_preset_service.dart';
import '../widgets/balyn_quick_action_launcher.dart';
import '../widgets/balyn_data_skeleton.dart';
import '../widgets/smooth_indexed_pages.dart';
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
  final ValueNotifier<Offset> _fabMotion = ValueNotifier(Offset.zero);
  Timer? _exitTimer;

  @override
  void dispose() {
    _exitTimer?.cancel();
    _fabMotion.dispose();
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
      _allowExit = false;
    });
  }

  void _handleBack(bool didPop) {
    if (didPop) return;
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
        onOpenPlanning: () => _selectTab(3),
        onOpenAdvances: () => _selectTab(2),
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

    return PieCanvas(
      child: PopScope(
        canPop: _allowExit,
        onPopInvoked: _handleBack,
        child: Scaffold(
          extendBody: true,
          body: Stack(
            fit: StackFit.expand,
            children: [
              SafeArea(
                bottom: false,
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) {
                    if (notification is ScrollUpdateNotification) {
                      final delta = notification.scrollDelta ?? 0.0;
                      // Bound the deformation, but preserve direction and
                      // proportional speed. Horizontal page swipes count too.
                      final impulse = (delta / 22.0).clamp(-1.0, 1.0);
                      _fabMotion.value =
                          notification.metrics.axis == Axis.horizontal
                          ? Offset(impulse, 0)
                          : Offset(0, impulse);
                    }
                    return false;
                  },
                  child: SmoothIndexedPages(index: index, children: pages),
                ),
              ),
              Positioned(
                right: 19,
                bottom: MediaQuery.viewPaddingOf(context).bottom + 15,
                child: BalynQuickActionLauncher(
                  motion: _fabMotion,
                  onCreate: () => _open(TransactionType.transfer),
                  onAdvances: () => _selectTab(2),
                  onPlanning: () => _selectTab(3),
                  onPresetSelected: (preset) =>
                      _open(preset.type, preset: preset),
                  onAddPreset: _createPreset,
                  loadPresets: () => QuickPresetService(
                    AppScope.of(context).database,
                  ).all(enabledOnly: true),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createPreset() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PresetManagementScreen(startCreating: true),
      ),
    );
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
}
