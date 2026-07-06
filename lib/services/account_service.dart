import '../database/app_database.dart';
import '../models/account_model.dart';

class AccountService {
  AccountService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<AccountModel>> getAllAccounts() async {
    final db = await _database.database;
    final rows = await db.query('accounts', orderBy: 'id ASC');
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<List<AccountModel>> getVisibleAccounts() async {
    final db = await _database.database;
    final rows = await db.query(
      'accounts',
      where: 'is_hidden_from_budget = ?',
      whereArgs: [0],
      orderBy: 'id ASC',
    );
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<List<AccountModel>> getHiddenAccounts() async {
    final db = await _database.database;
    final rows = await db.query(
      'accounts',
      where: 'is_hidden_from_budget = ?',
      whereArgs: [1],
      orderBy: 'id ASC',
    );
    return rows.map(AccountModel.fromMap).toList();
  }

  Future<AccountModel?> getAccountById(int id) async {
    final db = await _database.database;
    final rows =
        await db.query('accounts', where: 'id = ?', whereArgs: [id], limit: 1);
    if (rows.isEmpty) {
      return null;
    }
    return AccountModel.fromMap(rows.first);
  }

  Future<int> insertAccount(AccountModel account) async {
    final db = await _database.database;
    return db.insert('accounts', account.toMap()..remove('id'));
  }

  Future<int> updateAccount(AccountModel account) async {
    final id = account.id;
    if (id == null) {
      throw ArgumentError('Account id is required for update.');
    }

    final db = await _database.database;
    return db.update('accounts', account.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAccountBalance(int accountId, double newBalance) async {
    final db = await _database.database;
    return db.update(
      'accounts',
      {'current_balance': newBalance},
      where: 'id = ?',
      whereArgs: [accountId],
    );
  }
}
