import '../database/app_database.dart';
import '../models/category_model.dart';
import '../models/quick_action_model.dart';

class QuickActionService {
  QuickActionService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<QuickActionModel>> getAllQuickActions(
      {bool activeOnly = true}) async {
    final db = await _database.database;
    final rows = await db.query(
      'quick_actions',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'sort_order ASC, id ASC',
    );
    return rows.map(QuickActionModel.fromMap).toList();
  }

  Future<int> insertQuickAction(QuickActionModel quickAction) async {
    _validateQuickAction(quickAction);
    await _validateExpenseCategory(quickAction.categoryId);
    final db = await _database.database;
    return db.insert('quick_actions', quickAction.toMap()..remove('id'));
  }

  Future<int> updateQuickAction(QuickActionModel quickAction) async {
    final id = quickAction.id;
    if (id == null) {
      throw ArgumentError('Quick action id is required for update.');
    }

    _validateQuickAction(quickAction);
    await _validateExpenseCategory(quickAction.categoryId);
    final db = await _database.database;
    return db.update('quick_actions', quickAction.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deactivateQuickAction(int id) async {
    final db = await _database.database;
    return db.update('quick_actions', {'is_active': 0},
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteQuickAction(int id) async {
    final db = await _database.database;
    return db.delete('quick_actions', where: 'id = ?', whereArgs: [id]);
  }

  void _validateQuickAction(QuickActionModel quickAction) {
    if (quickAction.name.trim().isEmpty) {
      throw ArgumentError('Quick action name is required.');
    }
    if (quickAction.amount <= 0) {
      throw ArgumentError('Quick action amount must be greater than zero.');
    }
    if (quickAction.currency != 'SOL' && quickAction.currency != 'USD') {
      throw ArgumentError('Currency must be SOL or USD.');
    }
  }

  Future<void> _validateExpenseCategory(int? categoryId) async {
    if (categoryId == null) return;
    final db = await _database.database;
    final rows = await db.query(
      'categories',
      columns: ['type', 'is_active'],
      where: 'id = ?',
      whereArgs: [categoryId],
      limit: 1,
    );
    if (rows.isEmpty ||
        rows.first['type'] != CategoryScope.expense ||
        rows.first['is_active'] != 1) {
      throw ArgumentError('Quick actions require an active expense category.');
    }
  }
}
