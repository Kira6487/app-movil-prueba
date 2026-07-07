import '../database/app_database.dart';
import '../models/budget_rule_model.dart';
import '../models/budget_summary_model.dart';
import 'budget_calculator.dart';

class BudgetService {
  BudgetService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<BudgetRuleModel>> getAllBudgetRules({
    bool activeOnly = true,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'budget_rules',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'created_at DESC, id DESC',
    );
    return rows.map(BudgetRuleModel.fromMap).toList();
  }

  Future<List<BudgetRuleView>> getBudgetRuleViews({
    bool activeOnly = true,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
SELECT
  b.id,
  b.name,
  b.category_id,
  b.amount,
  b.currency,
  b.recurrence_type,
  b.selected_weekdays,
  b.start_date,
  b.end_date,
  b.is_active,
  b.created_at,
  c.name AS category_name
FROM budget_rules b
INNER JOIN categories c ON c.id = b.category_id
${activeOnly ? 'WHERE b.is_active = 1' : ''}
ORDER BY b.created_at DESC, b.id DESC
''',
    );
    return rows.map(BudgetRuleView.fromMap).toList();
  }

  Future<int> insertBudgetRule(BudgetRuleModel rule) async {
    _validateRule(rule);
    final db = await _database.database;
    return db.insert('budget_rules', rule.toMap()..remove('id'));
  }

  Future<int> updateBudgetRule(BudgetRuleModel rule) async {
    final id = rule.id;
    if (id == null) {
      throw ArgumentError('Budget rule id is required for update.');
    }
    _validateRule(rule);
    final db = await _database.database;
    return db.update(
      'budget_rules',
      rule.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateBudgetRule(int id) async {
    final db = await _database.database;
    return db.update(
      'budget_rules',
      {'is_active': 0},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<BudgetOverview> getOverview({
    required int year,
    required int month,
    DateTime? today,
  }) async {
    final effectiveToday = today ?? DateTime.now();
    final rules = await getBudgetRuleViews();
    final categoryBudget = <int, _CategoryBudget>{};
    var monthBudget = 0.0;
    var accumulatedBudget = 0.0;

    for (final view in rules) {
      final rule = view.rule;
      final budgeted = BudgetCalculator.monthlyAmount(rule, year, month);
      final accumulated = BudgetCalculator.accumulatedAmount(
        rule,
        year,
        month,
        effectiveToday,
      );
      monthBudget += budgeted;
      accumulatedBudget += accumulated;
      final current = categoryBudget[rule.categoryId];
      categoryBudget[rule.categoryId] = _CategoryBudget(
        categoryName: view.categoryName,
        amount: (current?.amount ?? 0) + budgeted,
      );
    }

    final monthSpentByCategory = await _expenseByCategory(
      start: DateTime(year, month),
      endExclusive: DateTime(year, month + 1),
    );
    final accumulatedEnd = DateTime(
      effectiveToday.year,
      effectiveToday.month,
      effectiveToday.day + 1,
    );
    final accumulatedSpentByCategory = await _expenseByCategory(
      start: DateTime(year, month),
      endExclusive: accumulatedEnd,
    );

    final categoryIds = <int>{
      ...categoryBudget.keys,
      ...monthSpentByCategory.keys,
    };
    final categories = <BudgetCategoryComparison>[];
    for (final categoryId in categoryIds) {
      final budget = categoryBudget[categoryId];
      categories.add(
        BudgetCategoryComparison(
          categoryId: categoryId,
          categoryName: budget?.categoryName ??
              await _categoryNameById(categoryId) ??
              'Categoria',
          budgeted: budget?.amount ?? 0,
          spent: monthSpentByCategory[categoryId] ?? 0,
        ),
      );
    }
    categories.sort((a, b) => b.budgeted.compareTo(a.budgeted));

    return BudgetOverview(
      monthBudget: monthBudget,
      accumulatedBudget: accumulatedBudget,
      monthSpent:
          monthSpentByCategory.values.fold(0, (sum, value) => sum + value),
      accumulatedSpent: accumulatedSpentByCategory.values
          .fold(0, (sum, value) => sum + value),
      categories: categories,
      rulesCount: rules.length,
    );
  }

  Future<List<BudgetRuleView>> getProjectedRulesForDate(DateTime date) async {
    final views = await getBudgetRuleViews();
    final projected = <BudgetRuleView>[];
    for (final view in views) {
      final occurrences = BudgetCalculator.occurrencesForMonth(
        view.rule,
        date.year,
        date.month,
        until: date,
      );
      if (occurrences.any(
        (item) =>
            item.year == date.year &&
            item.month == date.month &&
            item.day == date.day,
      )) {
        projected.add(view);
      }
    }
    return projected;
  }

  Future<Map<int, double>> _expenseByCategory({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
SELECT category_id, SUM(COALESCE(amount_in_base_currency, amount)) AS total
FROM financial_transactions
WHERE type = 'expense' AND date >= ? AND date < ?
GROUP BY category_id
''',
      [start.toIso8601String(), endExclusive.toIso8601String()],
    );
    return {
      for (final row in rows)
        row['category_id'] as int: ((row['total'] as num?) ?? 0).toDouble(),
    };
  }

  Future<String?> _categoryNameById(int categoryId) async {
    final db = await _database.database;
    final rows = await db.query(
      'categories',
      columns: ['name'],
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return rows.first['name'] as String?;
  }

  void _validateRule(BudgetRuleModel rule) {
    if (rule.name.trim().isEmpty) {
      throw ArgumentError('Budget name is required.');
    }
    if (rule.categoryId <= 0) {
      throw ArgumentError('A valid category is required.');
    }
    if (rule.amount <= 0) {
      throw ArgumentError('Budget amount must be greater than zero.');
    }
    if (rule.currency != 'SOL' && rule.currency != 'USD') {
      throw ArgumentError('Currency must be SOL or USD.');
    }
    if (!BudgetRecurrenceType.values.contains(rule.recurrenceType)) {
      throw ArgumentError('A valid recurrence type is required.');
    }
    if (rule.recurrenceType == BudgetRecurrenceType.customWeekdays &&
        BudgetCalculator.parseWeekdays(rule.selectedWeekdays).isEmpty) {
      throw ArgumentError('Select at least one custom weekday.');
    }
  }
}

class _CategoryBudget {
  const _CategoryBudget({
    required this.categoryName,
    required this.amount,
  });

  final String categoryName;
  final double amount;
}
