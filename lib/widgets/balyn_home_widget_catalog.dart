import '../models/models.dart';

/// New Home sections use the same persisted widget configuration as the
/// previous dashboard. Stable enum names are stored by the database.
abstract final class BalynHomeWidgetCatalog {
  static const fixed = <DashboardWidgetType>{
    DashboardWidgetType.totalBalance,
    DashboardWidgetType.monthlyIncome,
    DashboardWidgetType.monthlyExpense,
    DashboardWidgetType.safeToSpend,
  };

  static const featured = <DashboardWidgetType>[
    DashboardWidgetType.monthlyOverview,
    DashboardWidgetType.recentTransactions,
    DashboardWidgetType.financialSnapshot,
    DashboardWidgetType.smartHighlights,
  ];

  static const defaultEnabled = <DashboardWidgetType>{
    ...fixed,
    ...featured,
    DashboardWidgetType.topCategories,
    DashboardWidgetType.upcomingRecurring,
    DashboardWidgetType.goals,
    DashboardWidgetType.monthlyBudget,
    DashboardWidgetType.endMonthForecast,
    DashboardWidgetType.unassignedTransactions,
  };

  /// Old installations don't have entries for the new UI sections.
  /// Introduce them once, without modifying the user's saved order or
  /// re-enabling any section they have intentionally disabled.
  /// Each type appears at most once (including corrupt duplicate DB rows).
  static List<DashboardWidgetConfig> normalize(
    List<DashboardWidgetConfig> saved,
  ) {
    final byType = <DashboardWidgetType, DashboardWidgetConfig>{};
    final ordered = [...saved]
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    for (final item in ordered) {
      byType.putIfAbsent(item.type, () => item);
    }

    final result = <DashboardWidgetConfig>[];
    if (saved.isEmpty) {
      final defaults = <DashboardWidgetType>[
        ...fixed,
        ...featured,
        ...DashboardWidgetType.values.where(
          (type) => !fixed.contains(type) && !featured.contains(type),
        ),
      ];
      for (final type in defaults) {
        result.add(DashboardWidgetConfig(
          type: type,
          enabled: defaultEnabled.contains(type),
          orderIndex: result.length,
          size: DashboardWidgetSize.medium,
        ));
      }
    } else {
      // On upgrade, put newly introduced sections before the old secondary
      // widgets; the original relative order remains unchanged.
      final old = ordered.map((item) => item.type).toSet();
      for (final type in featured) {
        if (!old.contains(type)) {
          result.add(DashboardWidgetConfig(
            type: type,
            enabled: true,
            orderIndex: result.length,
            size: DashboardWidgetSize.medium,
          ));
        }
      }
      for (final type in byType.keys) {
        result.add(byType[type]!);
      }
      for (final type in DashboardWidgetType.values) {
        if (!result.any((item) => item.type == type)) {
          result.add(DashboardWidgetConfig(
            type: type,
            enabled: fixed.contains(type),
            orderIndex: result.length,
            size: DashboardWidgetSize.medium,
          ));
        }
      }
    }
    return [
      for (var i = 0; i < result.length; i++)
        DashboardWidgetConfig(
          type: result[i].type,
          enabled: fixed.contains(result[i].type) || result[i].enabled,
          orderIndex: i,
          size: result[i].size,
        ),
    ];
  }

  /// Accounts already appear inside the financial snapshot.
  /// A separately enabled Accounts widget takes precedence: the summary
  /// hides its own account list, while still displaying the metrics.
  static bool showAccountsInsideSnapshot(
    Iterable<DashboardWidgetConfig> configs,
  ) => !configs.any(
    (item) => item.type == DashboardWidgetType.accounts && item.enabled,
  );
}
