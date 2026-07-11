import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/financial_transaction_model.dart';
import '../models/savings_goal_model.dart';
import '../models/wallet_model.dart';

class SavingsService {
  SavingsService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<SavingsGoalModel>> getAllSavingsGoals(
      {bool activeOnly = true}) async {
    final db = await _database.database;
    final rows = await db.query(
      'savings_goals',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'created_at DESC',
    );
    return rows.map(SavingsGoalModel.fromMap).toList();
  }

  Future<int> insertSavingsGoal(SavingsGoalModel goal) async {
    await _validateGoal(goal);
    final db = await _database.database;
    return db.insert('savings_goals', goal.toMap()..remove('id'));
  }

  Future<int> updateSavingsGoal(SavingsGoalModel goal) async {
    final id = goal.id;
    if (id == null) {
      throw ArgumentError('Savings goal id is required for update.');
    }
    await _validateGoal(goal);
    final db = await _database.database;
    return db.update('savings_goals', goal.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<double> getGoalProgress(int goalId) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
SELECT SUM(COALESCE(t.amount_in_base_currency, t.amount)) AS total
FROM financial_transactions t
INNER JOIN accounts a ON a.id = t.account_id
WHERE t.type = 'savings'
  AND t.related_type = ?
  AND t.related_id = ?
  AND a.is_hidden_from_budget = 0
''', [TransactionRelatedType.savings, goalId]);
    return ((rows.first['total'] as num?) ?? 0).toDouble();
  }

  Future<List<WalletModel>> getWalletsByAccount(int accountId) async {
    final db = await _database.database;
    final rows = await db.query(
      'wallets',
      where: 'account_id = ? AND is_active = ?',
      whereArgs: [accountId, 1],
      orderBy: 'name ASC',
    );
    return rows.map(WalletModel.fromMap).toList();
  }

  Future<int> insertWallet(WalletModel wallet) async {
    final db = await _database.database;
    return db.insert('wallets', wallet.toMap()..remove('id'));
  }

  Future<void> _validateGoal(SavingsGoalModel goal) async {
    if (goal.name.trim().isEmpty) {
      throw ArgumentError('Savings goal name is required.');
    }
    if (goal.targetAmount <= 0) {
      throw ArgumentError('Savings goal target must be greater than zero.');
    }
    final db = await _database.database;
    final rows = await db.query(
      'categories',
      columns: ['type', 'is_active'],
      where: 'id = ?',
      whereArgs: [goal.categoryId],
      limit: 1,
    );
    if (rows.isEmpty || rows.first['type'] != CategoryScope.savings) {
      throw ArgumentError('A savings category is required.');
    }
  }
}
