import '../database/app_database.dart';
import '../models/account_model.dart';
import '../models/ledger_models.dart';
import 'ledger_service.dart';

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
    _validateAccount(account);
    final db = await _database.database;
    return db.transaction((txn) async {
      final data = account.toMap()..remove('id');
      data['current_balance'] = account.initialBalance;
      final id = await txn.insert('accounts', data);
      final ledgerId = await LedgerService.ensureReferenceAccount(
        txn,
        code: 'ASSET-A-$id',
        name: account.name,
        type: 'asset',
        currency: account.currency,
        referenceType: 'account',
        referenceId: id,
      );
      if (account.initialBalance != 0) {
        final openingId = await LedgerService.codeAccountId(txn, 'SYS-OPENING');
        final amount = account.initialBalance.abs();
        final assetDebit = account.initialBalance > 0;
        await LedgerService.postEntryInTransaction(
          txn,
          JournalEntryDraft(
            date: account.createdAt,
            description: 'Saldo inicial - ${account.name}',
            sourceType: 'opening_balance',
            sourceId: id,
            createdAt: account.createdAt,
            lines: [
              JournalLineDraft(
                ledgerAccountId: assetDebit ? ledgerId : openingId,
                debit: amount,
                currency: account.currency,
                exchangeRate: account.currency == 'SOL' ? null : 1,
              ),
              JournalLineDraft(
                ledgerAccountId: assetDebit ? openingId : ledgerId,
                credit: amount,
                currency: account.currency,
                exchangeRate: account.currency == 'SOL' ? null : 1,
              ),
            ],
          ),
        );
      }
      return id;
    });
  }

  Future<int> updateAccount(AccountModel account) async {
    final id = account.id;
    if (id == null) {
      throw ArgumentError('Account id is required for update.');
    }

    _validateAccount(account);
    final db = await _database.database;
    return db.update('accounts', account.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateAccountBalance(int accountId, double newBalance) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final rows = await txn.query('accounts',
          where: 'id = ?', whereArgs: [accountId], limit: 1);
      if (rows.isEmpty) throw StateError('Account $accountId does not exist.');
      final current = (rows.first['current_balance'] as num).toDouble();
      final difference = newBalance - current;
      if (difference.abs() < LedgerService.tolerance) return 0;
      final assetId =
          await LedgerService.referenceAccountId(txn, 'account', accountId);
      final adjustmentId = await LedgerService.codeAccountId(txn, 'SYS-ADJUST');
      final amount = difference.abs();
      final currency = rows.first['currency'] as String;
      await LedgerService.postEntryInTransaction(
          txn,
          JournalEntryDraft(
            date: DateTime.now().toIso8601String(),
            description: 'Ajuste Manual',
            sourceType: 'manual_adjustment',
            createdAt: DateTime.now().toIso8601String(),
            lines: [
              JournalLineDraft(
                  ledgerAccountId: difference > 0 ? assetId : adjustmentId,
                  debit: amount,
                  currency: currency,
                  exchangeRate: currency == 'SOL' ? null : 1),
              JournalLineDraft(
                  ledgerAccountId: difference > 0 ? adjustmentId : assetId,
                  credit: amount,
                  currency: currency,
                  exchangeRate: currency == 'SOL' ? null : 1),
            ],
          ));
      return txn.update('accounts', {'current_balance': newBalance},
          where: 'id = ?', whereArgs: [accountId]);
    });
  }

  Future<int> countAccountMovements(int accountId) async {
    final db = await _database.database;
    final transactionRows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM financial_transactions WHERE account_id = ?',
      [accountId],
    );
    final transferRows = await db.rawQuery(
      '''
SELECT COUNT(*) AS total
FROM transfers
WHERE from_account_id = ? OR to_account_id = ?
''',
      [accountId, accountId],
    );
    final transactions =
        ((transactionRows.first['total'] as num?) ?? 0).toInt();
    final transfers = ((transferRows.first['total'] as num?) ?? 0).toInt();
    return transactions + transfers;
  }

  Future<int> deleteAccount(int id) async {
    final movements = await countAccountMovements(id);
    if (movements > 0) {
      throw StateError('No se puede eliminar una cuenta con movimientos.');
    }

    final db = await _database.database;
    return db.delete('accounts', where: 'id = ?', whereArgs: [id]);
  }

  void _validateAccount(AccountModel account) {
    if (account.name.trim().isEmpty) {
      throw ArgumentError('Account name is required.');
    }
    if (account.accountType.trim().isEmpty) {
      throw ArgumentError('Account type is required.');
    }
    if (account.currency != 'SOL' && account.currency != 'USD') {
      throw ArgumentError('Currency must be SOL or USD.');
    }
  }
}
