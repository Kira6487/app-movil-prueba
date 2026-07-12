import 'package:sqflite/sqflite.dart';

/// Kept as a compatibility hook for older callers.
///
/// Production databases are intentionally never seeded. Tests must insert
/// their own fixtures explicitly.
class SeedData {
  const SeedData._();

  static Future<void> insertIfEmpty(Database db) async {}
}
