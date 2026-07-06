import '../database/app_database.dart';
import '../models/financial_transaction_model.dart';
import '../models/transaction_history_item.dart';
import '../utils/money_utils.dart';

class TransactionService {
  TransactionService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<int> insertTransaction(FinancialTransactionModel transaction) async {
    _validateTransaction(transaction);

    final db = await _database.database;
    return db.transaction((txn) async {
      final accountRows = await txn.query(
        'accounts',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [transaction.accountId],
        limit: 1,
      );
      if (accountRows.isEmpty) {
        throw StateError('Account ${transaction.accountId} does not exist.');
      }

      final categoryRows = await txn.query(
        'categories',
        columns: ['id'],
        where: 'id = ?',
        whereArgs: [transaction.categoryId],
        limit: 1,
      );
      if (categoryRows.isEmpty) {
        throw StateError('Category ${transaction.categoryId} does not exist.');
      }

      final currentBalance =
          (accountRows.first['current_balance'] as num).toDouble();
      final delta = transaction.type == 'income'
          ? transaction.amount
          : -transaction.amount;
      await txn.update(
        'accounts',
        {'current_balance': currentBalance + delta},
        where: 'id = ?',
        whereArgs: [transaction.accountId],
      );

      final amountInBaseCurrency = transaction.amountInBaseCurrency ??
          MoneyUtils.amountInBaseCurrency(
            amount: transaction.amount,
            currency: transaction.currency,
            baseCurrency: 'SOL',
            exchangeRate: transaction.exchangeRate,
          );

      final data = transaction
          .copyWith(amountInBaseCurrency: amountInBaseCurrency)
          .toMap()
        ..remove('id');
      return txn.insert('financial_transactions', data);
    });
  }

  Future<List<FinancialTransactionModel>> getAllTransactions() async {
    final db = await _database.database;
    final rows =
        await db.query('financial_transactions', orderBy: 'date DESC, id DESC');
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  Future<List<TransactionHistoryItem>> getLatestTransactions({
    int limit = 10,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
SELECT
  t.id,
  t.type,
  t.amount,
  t.currency,
  t.exchange_rate,
  t.amount_in_base_currency,
  t.account_id,
  t.category_id,
  t.date,
  t.comment,
  t.created_at,
  a.name AS account_name,
  c.name AS category_name
FROM financial_transactions t
INNER JOIN accounts a ON a.id = t.account_id
INNER JOIN categories c ON c.id = t.category_id
ORDER BY t.date DESC, t.id DESC
LIMIT ?
''',
      [limit],
    );
    return rows.map(TransactionHistoryItem.fromMap).toList();
  }

  Future<List<FinancialTransactionModel>> getTransactionsByMonth(
      int year, int month) async {
    final start = DateTime(year, month).toIso8601String();
    final end = DateTime(year, month + 1).toIso8601String();
    final db = await _database.database;
    final rows = await db.query(
      'financial_transactions',
      where: 'date >= ? AND date < ?',
      whereArgs: [start, end],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  Future<List<FinancialTransactionModel>> getTransactionsByAccount(
      int accountId) async {
    final db = await _database.database;
    final rows = await db.query(
      'financial_transactions',
      where: 'account_id = ?',
      whereArgs: [accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  Future<List<FinancialTransactionModel>> getTransactionsByCategory(
      int categoryId) async {
    final db = await _database.database;
    final rows = await db.query(
      'financial_transactions',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(FinancialTransactionModel.fromMap).toList();
  }

  void _validateTransaction(FinancialTransactionModel transaction) {
    if (transaction.type != 'income' && transaction.type != 'expense') {
      throw ArgumentError(
        'Financial transaction type must be income or expense.',
      );
    }
    if (transaction.amount <= 0) {
      throw ArgumentError('Transaction amount must be greater than zero.');
    }
    if (transaction.accountId <= 0) {
      throw ArgumentError('A valid account is required.');
    }
    if (transaction.categoryId <= 0) {
      throw ArgumentError('A valid category is required.');
    }
    if (transaction.currency != 'SOL' && transaction.currency != 'USD') {
      throw ArgumentError('Currency must be SOL or USD.');
    }
    if (transaction.currency == 'USD' &&
        transaction.exchangeRate != null &&
        transaction.exchangeRate! <= 0) {
      throw ArgumentError('Exchange rate must be greater than zero.');
    }
  }
}
