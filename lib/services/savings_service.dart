import '../database/app_database.dart';
import '../models/savings_goal_model.dart';
import '../models/wallet_model.dart';

class SavingsService {
  const SavingsService({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<SavingsGoalModel>> getAllSavingsGoals({bool activeOnly = true}) async {
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
    final db = await _database.database;
    return db.insert('savings_goals', goal.toMap()..remove('id'));
  }

  Future<int> updateSavingsGoal(SavingsGoalModel goal) async {
    final id = goal.id;
    if (id == null) {
      throw ArgumentError('Savings goal id is required for update.');
    }
    final db = await _database.database;
    return db.update('savings_goals', goal.toMap()..remove('id'), where: 'id = ?', whereArgs: [id]);
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
}
