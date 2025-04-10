import 'dart:async';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'fog_of_war.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        username TEXT UNIQUE NOT NULL,
        password_hash TEXT NOT NULL
      )
    ''');

    // Create exposed_terrain table
    await db.execute('''
      CREATE TABLE exposed_terrain (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users (id)
      )
    ''');
  }

  // User authentication methods
  Future<String> _hashPassword(String password) async {
    var bytes = utf8.encode(password);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<int> registerUser(String username, String password) async {
    final db = await database;
    String passwordHash = await _hashPassword(password);
    
    try {
      return await db.insert(
        'users',
        {'username': username, 'password_hash': passwordHash},
        conflictAlgorithm: ConflictAlgorithm.abort,
      );
    } catch (e) {
      throw Exception('Username already exists');
    }
  }

  Future<int?> authenticateUser(String username, String password) async {
    final db = await database;
    String passwordHash = await _hashPassword(password);
    
    List<Map<String, dynamic>> result = await db.query(
      'users',
      where: 'username = ? AND password_hash = ?',
      whereArgs: [username, passwordHash],
    );
    
    if (result.isNotEmpty) {
      return result.first['id'] as int;
    }
    return null;
  }

  // Exposed terrain methods
  Future<void> saveExposedTerrain(int userId, double latitude, double longitude) async {
    final db = await database;
    
    // Check if this terrain is already exposed
    List<Map<String, dynamic>> result = await db.query(
      'exposed_terrain',
      where: 'user_id = ? AND latitude = ? AND longitude = ?',
      whereArgs: [userId, latitude, longitude],
    );
    
    if (result.isEmpty) {
      await db.insert(
        'exposed_terrain',
        {
          'user_id': userId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
    }
  }

  Future<List<Map<String, dynamic>>> getExposedTerrain(int userId) async {
    final db = await database;
    
    return await db.query(
      'exposed_terrain',
      where: 'user_id = ?',
      whereArgs: [userId],
    );
  }

  Future<bool> isTerrainExposed(int userId, double latitude, double longitude) async {
    final db = await database;
    
    List<Map<String, dynamic>> result = await db.query(
      'exposed_terrain',
      where: 'user_id = ? AND latitude = ? AND longitude = ?',
      whereArgs: [userId, latitude, longitude],
    );
    
    return result.isNotEmpty;
  }
}
