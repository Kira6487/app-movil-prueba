import '../database/app_database.dart';
import '../models/budget_rule_model.dart';
import '../models/budget_summary_model.dart';
import '../models/category_model.dart';
import '../models/financial_transaction_model.dart';
import '../models/related_item_option.dart';
import '../utils/date_utils.dart';
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
      'budgets',
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
    final rows = await db.rawQuery('''
SELECT b.*, c.name AS category_name,
       COALESCE(c.icon_key, c.icon) AS category_icon,
       COALESCE(c.color_hex, c.color) AS category_color
FROM budgets b
LEFT JOIN categories c ON c.id = b.category_id
${activeOnly ? 'WHERE b.is_active = 1' : ''}
ORDER BY b.created_at DESC, b.id DESC
''');
    return rows.map(BudgetRuleView.fromMap).toList();
  }

  Future<BudgetRuleView?> getBudgetRuleView(int id) async {
    final views = await getBudgetRuleViews(activeOnly: false);
    for (final view in views) {
      if (view.rule.id == id) return view;
    }
    return null;
  }

  Future<int> insertBudgetRule(BudgetRuleModel rule) async {
    _validateRule(rule);
    await _validateCategoryScope(rule);
    final db = await _database.database;
    return db.insert('budgets', rule.toMap()..remove('id'));
  }

  Future<int> updateBudgetRule(BudgetRuleModel rule) async {
    final id = rule.id;
    if (id == null) {
      throw ArgumentError('Budget rule id is required for update.');
    }
    final updated = rule.copyWith(updatedAt: AppDateUtils.nowIso());
    _validateRule(updated);
    await _validateCategoryScope(updated);
    final db = await _database.database;
    return db.update(
      'budgets',
      updated.toMap()..remove('id'),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deactivateBudgetRule(int id) async {
    final db = await _database.database;
    return db.update(
      'budgets',
      {'is_active': 0, 'updated_at': AppDateUtils.nowIso()},
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
    final views = await getBudgetRuleViews();
    final exchangeRate = await _latestUsdRate();
    final relatedSpent = await _relatedSpentByItem(
      start: DateTime(year, month),
      endExclusive: DateTime(year, month + 1),
    );
    final monthEnd = DateTime(year, month + 1);
    final effectiveEnd =
        effectiveToday.year == year && effectiveToday.month == month
            ? DateTime(year, month, effectiveToday.day + 1)
            : monthEnd;
    final accumulatedRelatedSpent = await _relatedSpentByItem(
      start: DateTime(year, month),
      endExclusive: effectiveEnd.isAfter(monthEnd) ? monthEnd : effectiveEnd,
    );

    final budgetedCategoryIds = views
        .where((view) => view.rule.budgetType != BudgetType.savings)
        .map((view) => view.rule.categoryId)
        .whereType<int>()
        .toSet();
    final items = <BudgetItemSummary>[];
    var monthBudget = 0.0;
    var accumulatedBudget = 0.0;

    for (final view in views) {
      final rule = view.rule;
      final limit = BudgetCalculator.monthlyAmount(rule, year, month);
      final accumulated = BudgetCalculator.accumulatedAmount(
        rule,
        year,
        month,
        effectiveToday,
      );
      final relationType = rule.budgetType == BudgetType.savings
          ? TransactionRelatedType.savings
          : TransactionRelatedType.budget;
      final spentBase = relatedSpent[_relatedKey(relationType, rule.id)] ?? 0;
      final baseLimit = _toBase(limit, rule.currency, exchangeRate);
      monthBudget += baseLimit;
      accumulatedBudget += _toBase(accumulated, rule.currency, exchangeRate);
      items.add(BudgetItemSummary(
        view: view,
        limit: limit,
        spent: _fromBase(spentBase, rule.currency, exchangeRate),
        baseLimit: baseLimit,
        baseSpent: spentBase,
        formula: BudgetCalculator.formula(rule),
      ));
    }

    final monthSpent = items
        .where((item) => item.view.rule.budgetType != BudgetType.savings)
        .fold<double>(
          0,
          (sum, item) => sum + item.baseSpent,
        );
    final accumulatedSpent = views
        .where((view) => view.rule.budgetType != BudgetType.savings)
        .fold<double>(
          0,
          (sum, view) =>
              sum +
              (accumulatedRelatedSpent[_relatedKey(
                      TransactionRelatedType.budget, view.rule.id)] ??
                  0),
        );
    final categories = <BudgetCategoryComparison>[
      for (final id in budgetedCategoryIds)
        BudgetCategoryComparison(
          categoryId: id,
          categoryName: _categoryName(views, id),
          budgeted: items
              .where((item) => item.view.rule.categoryId == id)
              .fold(0, (sum, item) => sum + item.baseLimit),
          spent: items
              .where((item) => item.view.rule.categoryId == id)
              .fold(0, (sum, item) => sum + item.baseSpent),
        ),
    ]..sort((a, b) => b.budgeted.compareTo(a.budgeted));

    return BudgetOverview(
      monthBudget: monthBudget,
      accumulatedBudget: accumulatedBudget,
      monthSpent: monthSpent,
      accumulatedSpent: accumulatedSpent,
      categories: categories,
      items: items,
      rulesCount: views.length,
    );
  }

  Future<BudgetItemSummary?> getItemSummary({
    required int budgetId,
    required int year,
    required int month,
  }) async {
    final overview = await getOverview(year: year, month: month);
    for (final item in overview.items) {
      if (item.view.rule.id == budgetId) return item;
    }
    return null;
  }

  Future<List<BudgetRuleView>> getProjectedRulesForDate(DateTime date) async {
    final views = await getBudgetRuleViews();
    return views.where((view) {
      final occurrences = BudgetCalculator.occurrencesForMonth(
        view.rule,
        date.year,
        date.month,
        until: date,
      );
      return occurrences.any((item) =>
          item.year == date.year &&
          item.month == date.month &&
          item.day == date.day);
    }).toList();
  }

  Future<List<RelatedItemOption>> getRelatedOptions({
    required int categoryId,
    required DateTime date,
    required String operationType,
  }) async {
    final views = await getBudgetRuleViews();
    final day = DateTime(date.year, date.month, date.day);
    final options = <RelatedItemOption>[];
    for (final view in views) {
      final rule = view.rule;
      if (rule.categoryId != categoryId) continue;
      if (!_dateMatchesRule(rule, day)) continue;

      if (operationType == 'expense' && rule.budgetType != BudgetType.savings) {
        options.add(RelatedItemOption(
          type: TransactionRelatedType.budget,
          id: rule.id!,
          name: rule.name,
          subtitle:
              '${BudgetType.label(rule.budgetType)} · ${BudgetRecurrenceType.label(rule.recurrenceType)}',
        ));
      }
      if (operationType == 'savings' && rule.budgetType == BudgetType.savings) {
        options.add(RelatedItemOption(
          type: TransactionRelatedType.savings,
          id: rule.id!,
          name: rule.name,
          subtitle: 'Objetivo de ahorro · ${view.categoryName}',
        ));
      }
    }
    return options;
  }

  Future<Map<String, double>> _relatedSpentByItem({
    required DateTime start,
    required DateTime endExclusive,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
SELECT t.related_type,
       t.related_id,
       SUM(COALESCE(t.amount_in_base_currency, t.amount)) AS total
FROM financial_transactions t
INNER JOIN accounts a ON a.id = t.account_id
WHERE t.related_type IS NOT NULL
  AND t.related_id IS NOT NULL
  AND (
    (t.related_type = 'budget' AND t.type = 'expense')
    OR (t.related_type = 'savings' AND t.type = 'savings')
  )
  AND a.is_hidden_from_budget = 0
  AND t.date >= ? AND t.date < ?
  AND (t.comment IS NULL OR (
    t.comment NOT LIKE 'Transferencia #%'
    AND t.comment NOT LIKE 'Ajuste Manual%'
  ))
GROUP BY t.related_type, t.related_id
''', [start.toIso8601String(), endExclusive.toIso8601String()]);
    return {
      for (final row in rows)
        _relatedKey(
          row['related_type'] as String,
          (row['related_id'] as num).toInt(),
        ): ((row['total'] as num?) ?? 0).toDouble(),
    };
  }

  Future<double> _latestUsdRate() async {
    final db = await _database.database;
    final rows = await db.query(
      'exchange_rates',
      columns: ['rate'],
      where: "from_currency = 'USD' AND to_currency = 'SOL'",
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    return rows.isEmpty ? 1 : (rows.first['rate'] as num).toDouble();
  }

  double _toBase(double amount, String currency, double rate) =>
      currency == 'USD' ? amount * rate : amount;
  double _fromBase(double amount, String currency, double rate) =>
      currency == 'USD' && rate > 0 ? amount / rate : amount;

  String _categoryName(List<BudgetRuleView> views, int categoryId) {
    return views
        .firstWhere((view) => view.rule.categoryId == categoryId)
        .categoryName;
  }

  bool _dateMatchesRule(BudgetRuleModel rule, DateTime date) {
    if (!rule.isActive) return false;
    if (rule.budgetType != BudgetType.recurrence) {
      final start = DateTime.tryParse(rule.startDate ?? '');
      final end = DateTime.tryParse(rule.endDate ?? '');
      final normalizedStart = start == null
          ? DateTime(date.year, date.month)
          : DateTime(start.year, start.month, start.day);
      final normalizedEnd =
          end == null ? null : DateTime(end.year, end.month, end.day);
      if (date.isBefore(normalizedStart)) return false;
      if (normalizedEnd != null && date.isAfter(normalizedEnd)) return false;
      if (rule.recurrenceType == BudgetRecurrenceType.onceThisMonth) {
        return normalizedStart.year == date.year &&
            normalizedStart.month == date.month;
      }
      return true;
    }
    final occurrences = BudgetCalculator.occurrencesForMonth(
      rule,
      date.year,
      date.month,
    );
    return occurrences.any((item) =>
        item.year == date.year &&
        item.month == date.month &&
        item.day == date.day);
  }

  static String _relatedKey(String type, int? id) => '$type:${id ?? 0}';

  void _validateRule(BudgetRuleModel rule) {
    if (rule.name.trim().isEmpty) {
      throw ArgumentError('Budget name is required.');
    }
    if (!BudgetType.values.contains(rule.budgetType)) {
      throw ArgumentError('A valid budget type is required.');
    }
    if (rule.categoryId == null) {
      throw ArgumentError('A category is required.');
    }
    if (rule.amount <= 0 || rule.unitsPerDay <= 0) {
      throw ArgumentError('Budget amounts must be greater than zero.');
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

  Future<void> _validateCategoryScope(BudgetRuleModel rule) async {
    final categoryId = rule.categoryId;
    if (categoryId == null) return;
    final db = await _database.database;
    final rows = await db.query(
      'categories',
      columns: ['type', 'is_active'],
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    final expected = rule.budgetType == BudgetType.savings
        ? CategoryScope.savings
        : CategoryScope.expense;
    if (rows.isEmpty ||
        rows.first['type'] != expected ||
        rows.first['is_active'] != 1) {
      throw ArgumentError('Budget category scope is not compatible.');
    }
  }
}
