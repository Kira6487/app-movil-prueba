import 'app_database.dart';

class LocalDatabase {
  const LocalDatabase({AppDatabase? database}) : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> initialize() async {
    await _database.initialize();
  }
}
