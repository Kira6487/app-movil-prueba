import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/category_model.dart';

class CategoryService {
  CategoryService({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<List<CategoryModel>> getAllCategories({bool activeOnly = true}) async {
    final db = await _database.database;
    final rows = await db.query(
      'categories',
      where: activeOnly ? 'is_active = ?' : null,
      whereArgs: activeOnly ? [1] : null,
      orderBy: 'type ASC, sort_order ASC, name ASC, id ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<List<CategoryModel>> getCategoriesByType(
    String type, {
    bool activeOnly = true,
  }) async {
    final db = await _database.database;
    final where = ['type = ?'];
    final args = <Object?>[type];
    if (activeOnly) {
      where.add('is_active = ?');
      args.add(1);
    }
    final rows = await db.query(
      'categories',
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'sort_order ASC, name ASC, id ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    _validateCategory(category);
    final db = await _database.database;
    final nextOrder = category.sortOrder > 0
        ? category.sortOrder
        : await _nextSortOrder(category.type);
    return db.insert(
      'categories',
      category.copyWith(sortOrder: nextOrder).toMap()..remove('id'),
    );
  }

  Future<CategoryModel> getOrCreateCategory({
    required String name,
    required String type,
    String? icon,
    String? color,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'categories',
      where: 'name = ? AND type = ?',
      whereArgs: [name, type],
      limit: 1,
    );
    if (rows.isNotEmpty) return CategoryModel.fromMap(rows.first);

    final now = DateTime.now().toIso8601String();
    final sortOrder = await _nextSortOrder(type);
    final id = await db.insert(
      'categories',
      CategoryModel(
        name: name,
        type: type,
        icon: icon,
        color: color,
        sortOrder: sortOrder,
        createdAt: now,
      ).toMap()
        ..remove('id'),
    );
    return CategoryModel(
      id: id,
      name: name,
      type: type,
      icon: icon,
      color: color,
      sortOrder: sortOrder,
      createdAt: now,
    );
  }

  Future<int> updateCategory(CategoryModel category) async {
    final id = category.id;
    if (id == null) {
      throw ArgumentError('Category id is required for update.');
    }

    final db = await _database.database;
    _validateCategory(category);
    return db.update('categories', category.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOrDeactivateCategory(int id) async {
    final db = await _database.database;
    final used = await usageCount(id);

    if (used > 0) {
      return db.update('categories', {'is_active': 0},
          where: 'id = ?', whereArgs: [id]);
    }

    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> usageCount(int id) async {
    final db = await _database.database;
    var total = 0;
    for (final table in [
      'financial_transactions',
      'budgets',
      'quick_actions',
      'scheduled_expenses',
      'credit_card_installments',
      'savings_goals',
    ]) {
      final exists = Sqflite.firstIntValue(
            await db.rawQuery(
              "SELECT COUNT(*) FROM sqlite_master WHERE type = 'table' AND name = ?",
              [table],
            ),
          ) ??
          0;
      if (exists == 0) continue;
      total += Sqflite.firstIntValue(
            await db.rawQuery(
              'SELECT COUNT(*) FROM $table WHERE category_id = ?',
              [id],
            ),
          ) ??
          0;
    }
    return total;
  }

  Future<void> reorderCategories(String type, List<int> orderedIds) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      for (var index = 0; index < orderedIds.length; index++) {
        await txn.update(
          'categories',
          {'sort_order': index + 1},
          where: 'id = ? AND type = ?',
          whereArgs: [orderedIds[index], type],
        );
      }
    });
  }

  Future<int> _nextSortOrder(String type) async {
    final db = await _database.database;
    return (Sqflite.firstIntValue(
              await db.rawQuery(
                'SELECT COALESCE(MAX(sort_order), 0) FROM categories WHERE type = ?',
                [type],
              ),
            ) ??
            0) +
        1;
  }

  void _validateCategory(CategoryModel category) {
    if (category.name.trim().isEmpty) {
      throw ArgumentError('Category name is required.');
    }
    if (!CategoryScope.values.contains(category.type)) {
      throw ArgumentError('A valid category type is required.');
    }
  }
}
