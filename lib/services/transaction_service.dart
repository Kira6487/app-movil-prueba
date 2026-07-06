import '../database/app_database.dart';
import '../models/financial_transaction_model.dart';
import '../utils/money_utils.dart';

class TransactionService {
  TransactionService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<int> insertTransaction(FinancialTransactionModel transaction) async {
    if (transaction.type != 'income' && transaction.type != 'expense') {
      throw ArgumentError(
          'Financial transaction type must be income or expense.');
    }

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
}
