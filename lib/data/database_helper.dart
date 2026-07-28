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

  // -- Web: try ffi_web, fall back to in-memory --
  static Future<Database> _initWebDB() async {
    try {
      databaseFactory = databaseFactoryFfiWebNoWebWorker;
      return await databaseFactory.openDatabase(
        'snbt_tracker.db',
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreateV2,
          onUpgrade: _onUpgrade,
        ),
      );
    } catch (e) {
      databaseFactory = databaseFactoryFfi;
      sqfliteFfiInit();
      return await databaseFactory.openDatabase(
        inMemoryDatabasePath,
        options: OpenDatabaseOptions(
          version: 2,
          onCreate: _onCreateV2,
          onUpgrade: _onUpgrade,
        ),
      );
    }
  }

  // -- Mobile (Android / iOS) --
  static Future<Database> _initMobileDB() async {
    final dbPath = await native_sqflite.getDatabasesPath();
    final path = p.join(dbPath, 'snbt_tracker.db');
    return native_sqflite.openDatabase(
      path,
      version: 2,
      onCreate: _onCreateV2,
      onUpgrade: _onUpgrade,
    );
  }

  // -- Desktop (Windows / Linux / macOS) --
  static Future<Database> _initDesktopDB() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    final dbPath = await databaseFactory.getDatabasesPath();
    final path = p.join(dbPath, 'snbt_tracker.db');
    return databaseFactory.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: _onCreateV2,
        onUpgrade: _onUpgrade,
      ),
    );
  }

  // -- Schema v2 (full) --
  static Future<void> _onCreateV2(Database db, int version) async {
    final batch = db.batch();

    // -- Original tables --
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

    batch.execute('''CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY, value TEXT NOT NULL)''');

    // -- v2: Daily check-in sessions --
    batch.execute('''CREATE TABLE IF NOT EXISTS daily_checkins (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL,
        subtest_id TEXT NOT NULL,
        chapter_id TEXT NOT NULL,
        topic_id TEXT,
        duration_minutes INTEGER NOT NULL DEFAULT 0,
        created_at TEXT NOT NULL)''');

    // -- v2: Tryout scores --
    batch.execute('''CREATE TABLE IF NOT EXISTS tryout_scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        date TEXT NOT NULL,
        score_expected INTEGER,
        score_max INTEGER DEFAULT 1000,
        scores_detail TEXT DEFAULT '{}',
        notes TEXT DEFAULT '')''');

    // -- v2: Target PTN --
    batch.execute('''CREATE TABLE IF NOT EXISTS target_ptn (
        id INTEGER PRIMARY KEY,
        university TEXT NOT NULL,
        major TEXT NOT NULL,
        passing_grade INTEGER)''');

    // -- v2: XP & level --
    batch.execute('''CREATE TABLE IF NOT EXISTS user_xp (
        id INTEGER PRIMARY KEY,
        total_xp INTEGER NOT NULL DEFAULT 0,
        level INTEGER NOT NULL DEFAULT 1)''');

    // -- v2: Insert default XP row --
    batch.execute(
        '''INSERT OR IGNORE INTO user_xp (id, total_xp, level) VALUES (1, 0, 1)''');

    await batch.commit(noResult: true);
  }

  // -- Migration from v1 to v2 --
  static Future<void> _onUpgrade(Database db, int oldV, int newV) async {
    if (oldV < 2) {
      final batch = db.batch();

      batch.execute('''CREATE TABLE IF NOT EXISTS daily_checkins (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL,
          subtest_id TEXT NOT NULL,
          chapter_id TEXT NOT NULL,
          topic_id TEXT,
          duration_minutes INTEGER NOT NULL DEFAULT 0,
          created_at TEXT NOT NULL)''');

      batch.execute('''CREATE TABLE IF NOT EXISTS tryout_scores (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          date TEXT NOT NULL,
          score_expected INTEGER,
          score_max INTEGER DEFAULT 1000,
          scores_detail TEXT DEFAULT '{}',
          notes TEXT DEFAULT '')''');

      batch.execute('''CREATE TABLE IF NOT EXISTS target_ptn (
          id INTEGER PRIMARY KEY,
          university TEXT NOT NULL,
          major TEXT NOT NULL,
          passing_grade INTEGER)''');

      batch.execute('''CREATE TABLE IF NOT EXISTS user_xp (
          id INTEGER PRIMARY KEY,
          total_xp INTEGER NOT NULL DEFAULT 0,
          level INTEGER NOT NULL DEFAULT 1)''');

      batch.execute(
          '''INSERT OR IGNORE INTO user_xp (id, total_xp, level) VALUES (1, 0, 1)''');

      // Drop old tryout_sessions if exists (replaced by tryout_scores)
      batch.execute('DROP TABLE IF EXISTS tryout_sessions');

      await batch.commit(noResult: true);
    }
  }

  static Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
