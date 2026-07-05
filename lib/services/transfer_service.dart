import '../database/app_database.dart';
import '../models/transfer_model.dart';

class TransferService {
  const TransferService({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<int> insertTransfer(TransferModel transfer) async {
    final db = await _database.database;
    return db.transaction((txn) async {
      final fromRows = await txn.query(
        'accounts',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [transfer.fromAccountId],
        limit: 1,
      );
      final toRows = await txn.query(
        'accounts',
        columns: ['current_balance'],
        where: 'id = ?',
        whereArgs: [transfer.toAccountId],
        limit: 1,
      );
      if (fromRows.isEmpty || toRows.isEmpty) {
        throw StateError('Transfer accounts must exist.');
      }

      final fromBalance = (fromRows.first['current_balance'] as num).toDouble();
      final toBalance = (toRows.first['current_balance'] as num).toDouble();
      await txn.update(
        'accounts',
        {'current_balance': fromBalance - transfer.amountFrom},
        where: 'id = ?',
        whereArgs: [transfer.fromAccountId],
      );
      await txn.update(
        'accounts',
        {'current_balance': toBalance + transfer.amountTo},
        where: 'id = ?',
        whereArgs: [transfer.toAccountId],
      );

      return txn.insert('transfers', transfer.toMap()..remove('id'));
    });
  }

  Future<List<TransferModel>> getAllTransfers() async {
    final db = await _database.database;
    final rows = await db.query('transfers', orderBy: 'date DESC, id DESC');
    return rows.map(TransferModel.fromMap).toList();
  }

  Future<List<TransferModel>> getTransfersByAccount(int accountId) async {
    final db = await _database.database;
    final rows = await db.query(
      'transfers',
      where: 'from_account_id = ? OR to_account_id = ?',
      whereArgs: [accountId, accountId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(TransferModel.fromMap).toList();
  }
}
