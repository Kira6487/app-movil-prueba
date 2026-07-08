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
      orderBy: 'type ASC, name ASC',
    );
    return rows.map(CategoryModel.fromMap).toList();
  }

  Future<int> insertCategory(CategoryModel category) async {
    final db = await _database.database;
    return db.insert('categories', category.toMap()..remove('id'));
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
    final id = await db.insert(
      'categories',
      CategoryModel(
        name: name,
        type: type,
        icon: icon,
        color: color,
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
      createdAt: now,
    );
  }

  Future<int> updateCategory(CategoryModel category) async {
    final id = category.id;
    if (id == null) {
      throw ArgumentError('Category id is required for update.');
    }

    final db = await _database.database;
    return db.update('categories', category.toMap()..remove('id'),
        where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deleteOrDeactivateCategory(int id) async {
    final db = await _database.database;
    final used = Sqflite.firstIntValue(
          await db.rawQuery(
            'SELECT COUNT(*) FROM financial_transactions WHERE category_id = ?',
            [id],
          ),
        ) ??
        0;

    if (used > 0) {
      return db.update('categories', {'is_active': 0},
          where: 'id = ?', whereArgs: [id]);
    }

    return db.delete('categories', where: 'id = ?', whereArgs: [id]);
  }
}
