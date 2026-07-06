import '../database/app_database.dart';
import '../models/budget_rule_model.dart';

class BudgetService {
  BudgetService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<BudgetRuleModel>> getAllBudgetRules(
      {bool activeOnly = true}) async {
    final db = await _database.database;
    final rows = await db.query(
      'budget_rules',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'created_at DESC',
    );
    return rows.map(BudgetRuleModel.fromMap).toList();
  }

  Future<int> insertBudgetRule(BudgetRuleModel rule) async {
    final db = await _database.database;
    return db.insert('budget_rules', rule.toMap()..remove('id'));
  }

  Future<int> updateBudgetRule(BudgetRuleModel rule) async {
    final id = rule.id;
    if (id == null) {
      throw ArgumentError('Budget rule id is required for update.');
    }
    final db = await _database.database;
    return db.update('budget_rules', rule.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }
}
