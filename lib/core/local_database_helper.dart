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
  static const int _dbVersion = 2;

  static const String tableNilai = 'nilai';
  static const String tableRiwayatAktivitas = 'riwayatAktivitas';
  static const String tableDrafAbsen = 'draf_absen';

  /// Offline retry queue for realtime location pings (see
  /// core/services/background_location_service.dart). FIFO, capped at
  /// [locationOutboxCap] rows.
  static const String tableLocationOutbox = 'location_outbox';

  /// Hard cap on queued, undelivered location pings. Oldest rows are
  /// dropped on overflow — this is live-tracking data, so unbounded growth
  /// while offline for days is worse than losing very old stale points.
  static const int locationOutboxCap = 500;

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
        onUpgrade: (db, oldVersion, newVersion) => _migrate(db, oldVersion, newVersion),
      ),
    );
  }

  Future<sqlcipher.Database> _initDbSqlCipher() async {
    final dbPath = await sqlcipher.getDatabasesPath();
    final path = '$dbPath/$_dbName';

    final encryptionKey = await _getOrGenerateKey();

    try {
      return await sqlcipher.openDatabase(
        path,
        password: encryptionKey,
        version: _dbVersion,
        onCreate: (db, version) => _createTables(db),
        onUpgrade: (db, oldVersion, newVersion) => _migrate(db, oldVersion, newVersion),
      );
    } catch (e) {
      // Delete corrupted/un-decryptable database file and recreate it
      try {
        final file = File(path);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      return await sqlcipher.openDatabase(
        path,
        password: encryptionKey,
        version: _dbVersion,
        onCreate: (db, version) => _createTables(db),
        onUpgrade: (db, oldVersion, newVersion) => _migrate(db, oldVersion, newVersion),
      );
    }
  }

  Future<String> _getOrGenerateKey() async {
    try {
      String? key = await _secureStorage.read(key: _keyDbSecret);

      if (key == null) {
        final random = Random.secure();
        final values = List<int>.generate(32, (i) => random.nextInt(256));
        key = base64UrlEncode(values);
        await _secureStorage.write(key: _keyDbSecret, value: key);
      }
      return key;
    } catch (e) {
      // Jika keystore Android corrupted (sering terjadi di Samsung/setelah reinstall),
      // kita bersihkan storage dan buat key baru agar tidak force close.
      await _secureStorage.deleteAll();
      final random = Random.secure();
      final values = List<int>.generate(32, (i) => random.nextInt(256));
      String key = base64UrlEncode(values);
      await _secureStorage.write(key: _keyDbSecret, value: key);
      return key;
    }
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

    batch.execute(_createLocationOutboxSql);

    await batch.commit();
  }

  static const String _createLocationOutboxSql = '''
      CREATE TABLE IF NOT EXISTS $tableLocationOutbox (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        student_id INTEGER NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        activity_location_id TEXT,
        is_mocked INTEGER NOT NULL DEFAULT 0,
        accuracy REAL,
        speed REAL,
        client_timestamp TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
  ''';

  /// Schema migrations, keyed off oldVersion. Additive only — follow this
  /// pattern (bump _dbVersion, add a guarded block here) for future tables.
  Future<void> _migrate(dynamic db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute(_createLocationOutboxSql);
    }
  }

  // ---------------------------------------------------------------------
  // Location outbox (offline retry queue for realtime GPS pings)
  // ---------------------------------------------------------------------

  /// Queues a failed location ping payload for later retry. Trims the
  /// table down to [locationOutboxCap] rows (oldest first) on overflow.
  Future<void> enqueueLocationPing(Map<String, dynamic> payload) async {
    final db = await database;
    await db.insert(tableLocationOutbox, {
      'student_id': payload['student_id'],
      'latitude': payload['latitude'],
      'longitude': payload['longitude'],
      'activity_location_id': payload['activity_location_id'],
      'is_mocked': (payload['is_mocked'] == true) ? 1 : 0,
      'accuracy': payload['accuracy'],
      'speed': payload['speed'],
      'client_timestamp': payload['client_timestamp'],
      'created_at': DateTime.now().toIso8601String(),
    });
    await _trimLocationOutbox(db);
  }

  Future<void> _trimLocationOutbox(dynamic db) async {
    final count = await countPendingLocationPings(db: db);
    if (count > locationOutboxCap) {
      final overflow = count - locationOutboxCap;
      await db.rawDelete('''
        DELETE FROM $tableLocationOutbox WHERE id IN (
          SELECT id FROM $tableLocationOutbox ORDER BY id ASC LIMIT ?
        )
      ''', [overflow]);
    }
  }

  /// Oldest-first page of queued pings, ready to be flushed to the API.
  Future<List<Map<String, dynamic>>> getPendingLocationPings({int limit = 50}) async {
    final db = await database;
    final rows = await db.query(
      tableLocationOutbox,
      orderBy: 'id ASC',
      limit: limit,
    );
    return rows.map<Map<String, dynamic>>((row) => Map<String, dynamic>.from(row)).toList();
  }

  Future<void> deleteLocationPing(int id) async {
    final db = await database;
    await db.delete(tableLocationOutbox, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> countPendingLocationPings({dynamic db}) async {
    final database_ = db ?? await database;
    final result = await database_.rawQuery('SELECT COUNT(*) as c FROM $tableLocationOutbox');
    final raw = result.first['c'];
    if (raw is int) return raw;
    return int.tryParse(raw.toString()) ?? 0;
  }

  Future<void> close() async {
    final db = await instance.database;
    await db.close();
    _database = null;
  }
}
