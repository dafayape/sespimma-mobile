import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:sqflite_common_ffi/sqflite_ffi.dart' as ffi;
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalDatabaseHelper {
  LocalDatabaseHelper._privateConstructor();
  static final LocalDatabaseHelper instance =
      LocalDatabaseHelper._privateConstructor();

  static dynamic _database;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static const String _dbName = 'sespimma_local.db';
  static const String _keyDbSecret = 'db_encryption_key';
  static const int _dbVersion = 1;

  static const String tableNilai = 'nilai';
  static const String tableRiwayatAktivitas = 'riwayatAktivitas';
  static const String tableDrafAbsen = 'draf_absen';

  static bool get _useDesktopDb {
    try {
      return Platform.isWindows || Platform.isLinux || Platform.isMacOS;
    } catch (e) {
      return false;
    }
  }

  Future<dynamic> get database async {
    if (_database != null) return _database!;
    _database = await _initDb();
    return _database!;
  }

  Future<dynamic> _initDb() async {
    if (_useDesktopDb) {
      return await _initDbFfi();
    } else {
      return await _initDbSqlCipher();
    }
  }

  Future<ffi.Database> _initDbFfi() async {
    ffi.sqfliteFfiInit();
    final dbFactory = ffi.databaseFactoryFfi;

    final dbPath = await dbFactory.getDatabasesPath();
    final path = '$dbPath/$_dbName';

    return await dbFactory.openDatabase(
      path,
      options: ffi.OpenDatabaseOptions(
        version: _dbVersion,
        onCreate: (db, version) => _createTables(db),
        onUpgrade: (db, oldVersion, newVersion) async {},
      ),
    );
  }

  Future<sqlcipher.Database> _initDbSqlCipher() async {
    final dbPath = await sqlcipher.getDatabasesPath();
    final path = '$dbPath/$_dbName';

    final encryptionKey = await _getOrGenerateKey();

    return await sqlcipher.openDatabase(
      path,
      password: encryptionKey,
      version: _dbVersion,
      onCreate: (db, version) => _createTables(db),
      onUpgrade: (db, oldVersion, newVersion) async {},
    );
  }

  Future<String> _getOrGenerateKey() async {
    String? key = await _secureStorage.read(key: _keyDbSecret);

    if (key == null) {
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      key = base64UrlEncode(values);
      await _secureStorage.write(key: _keyDbSecret, value: key);
    }

    return key;
  }

  Future<void> _createTables(dynamic db) async {
    final batch = db.batch();

    batch.execute('''
      CREATE TABLE $tableNilai (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        siswaID TEXT NOT NULL,
        pengajarID TEXT NOT NULL,
        kategoriID TEXT NOT NULL,
        nilai REAL NOT NULL,
        keterangan TEXT,
        tanggalInput TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableRiwayatAktivitas (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userID TEXT NOT NULL,
        aktivitas TEXT NOT NULL,
        waktu TEXT NOT NULL
      )
    ''');

    batch.execute('''
      CREATE TABLE $tableDrafAbsen (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        timestamp TEXT NOT NULL,
        status_sinkronisasi INTEGER DEFAULT 0
      )
    ''');

    await batch.commit();
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
