import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = 'password_manager.db';
  static const _databaseVersion = 1;
  static const table = 'passwords';

  static const columnId = 'id';
  static const columnWebsite = 'website';
  static const columnUsername = 'username';
  static const columnPassword = 'password';

  static Database? _database;

  // Singleton pattern
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $table (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnWebsite TEXT NOT NULL,
        $columnUsername TEXT NOT NULL,
        $columnPassword TEXT NOT NULL
      )
    ''');
  }

  // Insert a password entry
  Future<int> insertPassword(Map<String, dynamic> row) async {
    Database db = await instance.database;
    return await db.insert(table, row);
  }

  // Get all password entries
  Future<List<Map<String, dynamic>>> queryAllPasswords() async {
    Database db = await instance.database;
    return await db.query(table);
  }

  // Update a password entry
  Future<int> updatePassword(Map<String, dynamic> row) async {
    Database db = await instance.database;
    int id = row[columnId];
    return await db.update(table, row, where: '$columnId = ?', whereArgs: [id]);
  }

  // Delete a password entry
  Future<int> deletePassword(int id) async {
    Database db = await instance.database;
    return await db.delete(table, where: '$columnId = ?', whereArgs: [id]);
  }

  // Clear all password entries
  Future<int> deleteAllPasswords() async {
    Database db = await instance.database;
    return await db.delete(table);
  }
}
