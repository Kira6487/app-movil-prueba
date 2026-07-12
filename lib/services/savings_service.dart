import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/savings_goal_model.dart';
import '../models/wallet_model.dart';
import 'ledger_service.dart';

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
SELECT COALESCE(SUM(CASE WHEN l.debit > 0 THEN l.base_amount ELSE -l.base_amount END), 0) AS total
FROM journal_entries e
JOIN journal_lines l ON l.journal_entry_id = e.id
JOIN ledger_accounts la ON la.id = l.ledger_account_id
WHERE e.status = 'posted' AND e.savings_item_id = ?
  AND (la.reference_type = 'wallet' OR la.code = 'SYS-SAVINGS')
''', [goalId]);
    return ((rows.first['total'] as num?) ?? 0).toDouble();
  }

  Future<List<WalletModel>> getWalletsByAccount(int accountId) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
SELECT w.*,
       COALESCE(SUM(CASE WHEN e.status = 'posted' THEN l.debit - l.credit ELSE 0 END), 0) AS amount
FROM wallets w
LEFT JOIN journal_lines l ON l.ledger_account_id = w.ledger_account_id
LEFT JOIN journal_entries e ON e.id = l.journal_entry_id
WHERE w.account_id = ? AND w.is_active = 1
GROUP BY w.id
ORDER BY w.name ASC
''', [accountId]);
    return rows.map(WalletModel.fromMap).toList();
  }

  Future<int> insertWallet(WalletModel wallet) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final parentRows = await txn.query('accounts',
          columns: ['id', 'currency'],
          where: 'id = ?',
          whereArgs: [wallet.accountId],
          limit: 1);
      if (parentRows.isEmpty) {
        throw StateError('Parent account does not exist.');
      }
      if (parentRows.first['currency'] != wallet.currency) {
        throw ArgumentError('Wallet currency must match its parent account.');
      }
      final data = wallet.toMap()
        ..remove('id')
        ..['amount'] = 0;
      final id = await txn.insert('wallets', data);
      final parentLedger = await LedgerService.referenceAccountId(
          txn, 'account', wallet.accountId);
      final ledgerId = await LedgerService.ensureReferenceAccount(txn,
          code: 'ASSET-W-$id',
          name: wallet.name,
          type: 'asset',
          currency: wallet.currency,
          referenceType: 'wallet',
          referenceId: id,
          parentAccountId: parentLedger);
      await txn.update('wallets', {'ledger_account_id': ledgerId},
          where: 'id = ?', whereArgs: [id]);
      return id;
    });
  }

  Future<int> updateWallet(WalletModel wallet) async {
    final id = wallet.id;
    if (id == null) throw ArgumentError('Wallet id is required.');
    final db = await _database.database;
    return db.transaction((txn) async {
      final updated = await txn.update(
          'wallets',
          wallet.toMap()
            ..remove('id')
            ..remove('amount'),
          where: 'id = ?',
          whereArgs: [id]);
      await txn.update(
          'ledger_accounts',
          {
            'name': wallet.name,
            'is_active': wallet.isActive ? 1 : 0,
          },
          where: 'reference_type = ? AND reference_id = ?',
          whereArgs: ['wallet', id]);
      return updated;
    });
  }

  Future<int> deleteOrDeactivateWallet(int walletId) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final ledgerId =
          await LedgerService.referenceAccountId(txn, 'wallet', walletId);
      final balanceRows =
          await txn.rawQuery('''SELECT COALESCE(SUM(l.debit-l.credit), 0) total
FROM journal_lines l JOIN journal_entries e ON e.id=l.journal_entry_id
WHERE l.ledger_account_id=? AND e.status='posted' ''', [ledgerId]);
      final balance = (balanceRows.first['total'] as num).toDouble();
      if (balance.abs() >= LedgerService.tolerance) {
        throw StateError('No se puede eliminar una alcancía con saldo.');
      }
      final history = await txn.rawQuery(
          'SELECT COUNT(*) total FROM journal_lines WHERE ledger_account_id = ?',
          [ledgerId]);
      if ((history.first['total'] as num).toInt() > 0) {
        await txn.update('ledger_accounts', {'is_active': 0},
            where: 'id = ?', whereArgs: [ledgerId]);
        return txn.update('wallets', {'is_active': 0},
            where: 'id = ?', whereArgs: [walletId]);
      }
      await txn
          .delete('ledger_accounts', where: 'id = ?', whereArgs: [ledgerId]);
      return txn.delete('wallets', where: 'id = ?', whereArgs: [walletId]);
    });
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
