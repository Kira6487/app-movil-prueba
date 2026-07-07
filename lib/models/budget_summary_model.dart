import 'budget_rule_model.dart';

class BudgetRuleView {
  const BudgetRuleView({
    required this.rule,
    required this.categoryName,
  });

  final BudgetRuleModel rule;
  final String categoryName;

  factory BudgetRuleView.fromMap(Map<String, Object?> map) {
    return BudgetRuleView(
      rule: BudgetRuleModel.fromMap(map),
      categoryName: map['category_name'] as String? ?? 'Categoria',
    );
  }
}

class BudgetCategoryComparison {
  const BudgetCategoryComparison({
    required this.categoryId,
    required this.categoryName,
    required this.budgeted,
    required this.spent,
  });

  final int categoryId;
  final String categoryName;
  final double budgeted;
  final double spent;

  double get difference => budgeted - spent;
  double get usagePercent => budgeted <= 0 ? 0 : spent / budgeted;
}

class BudgetOverview {
  const BudgetOverview({
    required this.monthBudget,
    required this.accumulatedBudget,
    required this.monthSpent,
    required this.accumulatedSpent,
    required this.categories,
    required this.rulesCount,
  });

  final double monthBudget;
  final double accumulatedBudget;
  final double monthSpent;
  final double accumulatedSpent;
  final List<BudgetCategoryComparison> categories;
  final int rulesCount;

  double get available => monthBudget - monthSpent;
  double get monthUsagePercent =>
      monthBudget <= 0 ? 0 : monthSpent / monthBudget;
  double get accumulatedUsagePercent =>
      accumulatedBudget <= 0 ? 0 : accumulatedSpent / accumulatedBudget;

  BudgetStatus get dailyStatus => BudgetStatus.from(
        spent: accumulatedSpent,
        budget: accumulatedBudget,
      );

  BudgetStatus get monthlyStatus => BudgetStatus.from(
        spent: monthSpent,
        budget: monthBudget,
      );
}

enum BudgetStatus {
  empty,
  good,
  warning,
  exceeded;

  static BudgetStatus from({required double spent, required double budget}) {
    if (budget <= 0) return BudgetStatus.empty;
    if (spent > budget) return BudgetStatus.exceeded;
    if (spent >= budget * 0.85) return BudgetStatus.warning;
    return BudgetStatus.good;
  }

  String get label {
    return switch (this) {
      BudgetStatus.empty => 'Sin presupuesto',
      BudgetStatus.good => 'Bueno',
      BudgetStatus.warning => 'En alerta',
      BudgetStatus.exceeded => 'Excedido',
    };
  }
}
