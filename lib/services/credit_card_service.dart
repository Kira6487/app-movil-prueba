import '../database/app_database.dart';
import '../models/credit_card_installment_model.dart';
import '../models/credit_card_model.dart';

class CreditCardService {
  const CreditCardService({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<CreditCardModel>> getAllCreditCards({bool activeOnly = true}) async {
    final db = await _database.database;
    final rows = await db.query(
      'credit_cards',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'name ASC',
    );
    return rows.map(CreditCardModel.fromMap).toList();
  }

  Future<int> insertCreditCard(CreditCardModel card) async {
    final db = await _database.database;
    return db.insert('credit_cards', card.toMap()..remove('id'));
  }

  Future<int> updateCreditCard(CreditCardModel card) async {
    final id = card.id;
    if (id == null) {
      throw ArgumentError('Credit card id is required for update.');
    }
    final db = await _database.database;
    return db.update('credit_cards', card.toMap()..remove('id'), where: 'id = ?', whereArgs: [id]);
  }

  Future<List<CreditCardInstallmentModel>> getInstallmentsByCard(int creditCardId) async {
    final db = await _database.database;
    final rows = await db.query(
      'credit_card_installments',
      where: 'credit_card_id = ?',
      whereArgs: [creditCardId],
      orderBy: 'first_payment_date ASC, id ASC',
    );
    return rows.map(CreditCardInstallmentModel.fromMap).toList();
  }

  Future<int> insertInstallment(CreditCardInstallmentModel installment) async {
    final db = await _database.database;
    return db.insert('credit_card_installments', installment.toMap()..remove('id'));
  }
}
