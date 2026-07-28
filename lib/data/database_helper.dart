// lib/data/database_helper.dart
// Platform-aware SQLite:
//   - Android/iOS  : sqflite native
//   - Windows/Linux: sqflite_common_ffi
//   - Web (Chrome) : sqflite_common_ffi_web (no-worker mode)

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:sqflite/sqflite.dart' as native_sqflite;

class DatabaseHelper {
  static Database? _db;

  static Future<Database> get database async {
    _db ??= await _initDB();
    return _db!;
  }

  static Future<Database> _initDB() async {
    if (kIsWeb) {
      return _initWebDB();
    } else if (Platform.isAndroid || Platform.isIOS) {
      return _initMobileDB();
    } else {
      return _initDesktopDB();
    }
  }

  // ── Web: try ffi_web, fall back to in-memory ──────────────────────────────
  static Future<Database> _initWebDB() async {
    try {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
      return await databaseFactory.openDatabase(
        'snbt_tracker.db',
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (e) {
      // WASM unavailable — fall back to pure in-memory for preview
      databaseFactory = databaseFactoryFfi;
      sqfliteFfiInit();
      return await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _onCreate,
          onUpgrade: _onUpgrade,
        ),
      );
    }
  }

  // ── Mobile (Android / iOS) ────────────────────────────────────────────────
  static Future<Database> _initMobileDB() async {
    final dbPath = await native_sqflite.getDatabasesPath();
    final path = p.join(dbPath, 'snbt_tracker.db');
    return native_sqflite.openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // ── Desktop (Windows / Linux / macOS) ────────────────────────────────────
  static Future<Database> _initDesktopDB() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, 'snbt_tracker.db');
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  // ── Schema ─────────────────────────────────────────────────────────────────
  static Future<void> _onCreate(Database db, int version) async {
    final batch = db.batch();
    batch.execute('''CREATE TABLE IF NOT EXISTS subtests (
        id TEXT PRIMARY KEY, name TEXT NOT NULL, abbr TEXT NOT NULL,
        color TEXT NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS chapters (
        id TEXT PRIMARY KEY, subtest_id TEXT NOT NULL REFERENCES subtests(id),
        name TEXT NOT NULL, sort_order INTEGER NOT NULL DEFAULT 0)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS topics (
        id TEXT PRIMARY KEY, chapter_id TEXT NOT NULL REFERENCES chapters(id),
        group_name TEXT, name TEXT NOT NULL,
        is_custom INTEGER NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS progress (
        topic_id TEXT PRIMARY KEY REFERENCES topics(id),
        pelajari INTEGER NOT NULL DEFAULT 0,
        latihan INTEGER NOT NULL DEFAULT 0,
        review INTEGER NOT NULL DEFAULT 0,
        catatan TEXT NOT NULL DEFAULT '',
        updated_at TEXT NOT NULL DEFAULT '')''');
    batch.execute('''CREATE TABLE IF NOT EXISTS activity_log (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        checks_count INTEGER NOT NULL DEFAULT 0)''');
    batch.execute('''CREATE TABLE IF NOT EXISTS tryout_sessions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        scores TEXT NOT NULL DEFAULT '{}',
        notes TEXT NOT NULL DEFAULT '')''');
    batch.execute('''CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY, value TEXT NOT NULL)''');
    await batch.commit(noResult: true);
  }

  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {}

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
