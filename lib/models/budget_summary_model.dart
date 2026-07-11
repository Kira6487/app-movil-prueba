import 'budget_rule_model.dart';

class BudgetRuleView {
  const BudgetRuleView({
    required this.rule,
    required this.categoryName,
    this.categoryIcon,
    this.categoryColor,
  });

  final BudgetRuleModel rule;
  final String categoryName;
  final String? categoryIcon;
  final String? categoryColor;

  factory BudgetRuleView.fromMap(Map<String, Object?> map) => BudgetRuleView(
        rule: BudgetRuleModel.fromMap(map),
        categoryName: map['category_name'] as String? ?? 'Sin categoría',
        categoryIcon: map['category_icon'] as String?,
        categoryColor: map['category_color'] as String?,
      );
}

class BudgetItemSummary {
  const BudgetItemSummary({
    required this.view,
    required this.limit,
    required this.spent,
    required this.baseLimit,
    required this.baseSpent,
    required this.formula,
  });

  final BudgetRuleView view;
  final double limit;
  final double spent;
  final double baseLimit;
  final double baseSpent;
  final String formula;

  double get available => limit - spent;
  double get usagePercent => limit <= 0 ? 0 : spent / limit;
  BudgetStatus get status => BudgetStatus.from(spent: spent, budget: limit);
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
    required this.items,
    required this.rulesCount,
  });

  final double monthBudget;
  final double accumulatedBudget;
  final double monthSpent;
  final double accumulatedSpent;
  final List<BudgetCategoryComparison> categories;
  final List<BudgetItemSummary> items;
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
  BudgetStatus get monthlyStatus =>
      BudgetStatus.from(spent: monthSpent, budget: monthBudget);
}

enum BudgetStatus {
  empty,
  good,
  warning,
  exceeded;

  static BudgetStatus from({required double spent, required double budget}) {
    if (budget <= 0) return BudgetStatus.empty;
    final ratio = spent / budget;
    if (ratio >= 1) return BudgetStatus.exceeded;
    if (ratio >= 0.8) return BudgetStatus.warning;
    return BudgetStatus.good;
  }

  String get label => switch (this) {
        BudgetStatus.empty => 'Sin presupuesto',
        BudgetStatus.good => 'En control',
        BudgetStatus.warning => 'En alerta',
        BudgetStatus.exceeded => 'Excedido',
      };
}
