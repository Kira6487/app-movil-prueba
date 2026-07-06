import '../database/app_database.dart';
import '../models/exchange_rate_model.dart';

class ExchangeRateService {
  ExchangeRateService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  double usdToSol(double amount, {double exchangeRate = 3.80}) {
    return amount * exchangeRate;
  }

  Future<ExchangeRateModel?> getLatestRate({
    String fromCurrency = 'USD',
    String toCurrency = 'SOL',
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'exchange_rates',
      where: 'from_currency = ? AND to_currency = ?',
      whereArgs: [fromCurrency, toCurrency],
      orderBy: 'date DESC, id DESC',
      limit: 1,
    );
    if (rows.isEmpty) {
      return null;
    }
    return ExchangeRateModel.fromMap(rows.first);
  }

  Future<int> insertExchangeRate(ExchangeRateModel exchangeRate) async {
    final db = await _database.database;
    return db.insert('exchange_rates', exchangeRate.toMap()..remove('id'));
  }
}
