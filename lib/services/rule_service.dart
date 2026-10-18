import '../app_state.dart';
import '../models/models.dart';

class RuleMatchPreview {
  const RuleMatchPreview({required this.matches});
  final List<FinanceTransaction> matches;
  int get count => matches.length;
}

class RuleService {
  const RuleService();

  bool matches(AutomationRule rule, FinanceTransaction item) {
    if (!rule.enabled) return false;
    if (rule.type != null && rule.type != item.type) return false;
    if (rule.minAmount != null && item.amount < rule.minAmount!) return false;
    if (rule.maxAmount != null && item.amount > rule.maxAmount!) return false;
    final text = (item.note ?? '').toLowerCase();
    final needle = rule.containsText?.trim().toLowerCase();
    if (needle?.isNotEmpty == true && !text.contains(needle!)) return false;
    return true;
  }

  RuleMatchPreview preview(
    AppState state,
    AutomationRule rule,
  ) => RuleMatchPreview(
    matches: state.transactions
        .where(
          (item) =>
              !state.isAdvanceProtectedTransaction(item) && matches(rule, item),
        )
        .toList(),
  );

  void validate(AppState state, AutomationRule rule) {
    if (rule.categoryId == null) return;
    if (rule.type == null || rule.type == TransactionType.transfer) {
      throw StateError(
        'Per assegnare una categoria la regola deve avere un tipo Spesa o Entrata.',
      );
    }
    final category = state.categoryById(rule.categoryId);
    if (category == null || category.type != rule.type) {
      throw StateError(
        'La categoria non è compatibile con il tipo della regola.',
      );
    }
  }

  Future<void> update(AppState state, AutomationRule rule) async {
    validate(state, rule);
    await state.database.db.update(
      'automation_rules',
      {
        'name': rule.name,
        'enabled': rule.enabled ? 1 : 0,
        'contains_text': rule.containsText,
        'type': rule.type?.dbValue,
        'min_amount': rule.minAmount,
        'max_amount': rule.maxAmount,
        'category_id': rule.categoryId,
        'account_id': rule.accountId,
        'add_tag': rule.addTag,
        'include_in_analytics': rule.includeInAnalytics == null
            ? null
            : (rule.includeInAnalytics! ? 1 : 0),
        'priority': rule.priority,
      },
      where: 'id = ?',
      whereArgs: [rule.id],
    );
    await state.load();
  }

  Future<void> duplicate(AppState state, AutomationRule rule) async {
    await state.addRule(
      rule.copyWith(name: '${rule.name} copia', priority: rule.priority + 1),
    );
  }

  Future<void> reorder(AppState state, List<AutomationRule> ordered) async {
    await state.database.db.transaction((txn) async {
      for (var index = 0; index < ordered.length; index++) {
        await txn.update(
          'automation_rules',
          {'priority': ordered.length - index},
          where: 'id = ?',
          whereArgs: [ordered[index].id],
        );
      }
    });
    await state.load();
  }

  Future<int> applyToHistory(AppState state, AutomationRule rule) async {
    validate(state, rule);
    final matched = preview(state, rule).matches;
    final changed = await state.database.applyRuleToHistory(rule, matched);
    if (changed > 0) await state.load();
    return changed;
  }
}
