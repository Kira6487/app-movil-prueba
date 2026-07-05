import '../database/app_database.dart';
import '../models/scheduled_expense_model.dart';

class ScheduledExpenseService {
  const ScheduledExpenseService({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<ScheduledExpenseModel>> getAllScheduledExpenses({bool activeOnly = true}) async {
    final db = await _database.database;
    final rows = await db.query(
      'scheduled_expenses',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'due_date ASC, due_day ASC',
    );
    return rows.map(ScheduledExpenseModel.fromMap).toList();
  }

  Future<int> insertScheduledExpense(ScheduledExpenseModel expense) async {
    final db = await _database.database;
    return db.insert('scheduled_expenses', expense.toMap()..remove('id'));
  }

  Future<int> updateScheduledExpense(ScheduledExpenseModel expense) async {
    final id = expense.id;
    if (id == null) {
      throw ArgumentError('Scheduled expense id is required for update.');
    }
    final db = await _database.database;
    return db.update('scheduled_expenses', expense.toMap()..remove('id'), where: 'id = ?', whereArgs: [id]);
  }
}
