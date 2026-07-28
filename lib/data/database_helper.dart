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

    // -- Seed subtests, chapters, topics --
    await _seedCurriculum(db);
  }

  static Future<void> _seedCurriculum(Database db) async {
    // Check if already seeded
    final existing = await db.query('subtests', limit: 1);
    if (existing.isNotEmpty) return;

    final b = db.batch();

    // ── 7 Subtests ────────────────────────────────────────────────────────
    final subtests = [
      {'id': 'pu',  'name': 'Penalaran Umum',         'abbr': 'PU',  'color': '0xFF6C63FF', 'sort_order': 1},
      {'id': 'ppu', 'name': 'Pengetahuan & Pem. Umum','abbr': 'PPU', 'color': '0xFF43B89C', 'sort_order': 2},
      {'id': 'pbm', 'name': 'Pem. Bacaan & Menulis',  'abbr': 'PBM', 'color': '0xFFF4A261', 'sort_order': 3},
      {'id': 'pm',  'name': 'Pengetahuan Matematika', 'abbr': 'PM',  'color': '0xFFE76F51', 'sort_order': 4},
      {'id': 'lb',  'name': 'Literasi Bahasa Inggris','abbr': 'LB',  'color': '0xFF4CC9F0', 'sort_order': 5},
      {'id': 'pk',  'name': 'Penalaran Matematika',   'abbr': 'PM2', 'color': '0xFFA8DADC', 'sort_order': 6},
      {'id': 'sains','name': 'Literasi Sains',        'abbr': 'LS',  'color': '0xFFBDE0FE', 'sort_order': 7},
    ];
    for (final s in subtests) {
      b.insert('subtests', s, conflictAlgorithm: ConflictAlgorithm.ignore);
    }

    // ── Chapters & Topics ────────────────────────────────────────────────

    // PU — Penalaran Umum
    _addChapter(b, 'pu_1', 'pu', 'Penalaran Induktif', 1, [
      ('pu_1_1', 'Analogi', null), ('pu_1_2', 'Silogisme', null),
      ('pu_1_3', 'Deret angka', null), ('pu_1_4', 'Deret huruf', null),
    ]);
    _addChapter(b, 'pu_2', 'pu', 'Penalaran Deduktif', 2, [
      ('pu_2_1', 'Modus Ponens & Tollens', null),
      ('pu_2_2', 'Pernyataan Majemuk', null),
      ('pu_2_3', 'Pengambilan Kesimpulan', null),
    ]);
    _addChapter(b, 'pu_3', 'pu', 'Penalaran Kuantitatif', 3, [
      ('pu_3_1', 'Perbandingan kuantitatif', null),
      ('pu_3_2', 'Interpretasi data', null),
      ('pu_3_3', 'Soal cerita logika', null),
    ]);
    _addChapter(b, 'pu_4', 'pu', 'Penalaran Analitis', 4, [
      ('pu_4_1', 'Hubungan sebab akibat', null),
      ('pu_4_2', 'Kekuatan argumen', null),
    ]);

    // PPU — Pengetahuan & Pemahaman Umum
    _addChapter(b, 'ppu_1', 'ppu', 'Pengetahuan IPA', 1, [
      ('ppu_1_1', 'Biologi dasar', null), ('ppu_1_2', 'Fisika dasar', null),
      ('ppu_1_3', 'Kimia dasar', null), ('ppu_1_4', 'Matematika SMP-SMA', null),
    ]);
    _addChapter(b, 'ppu_2', 'ppu', 'Pengetahuan IPS', 2, [
      ('ppu_2_1', 'Sejarah Indonesia', null), ('ppu_2_2', 'Geografi', null),
      ('ppu_2_3', 'Ekonomi dasar', null), ('ppu_2_4', 'Sosiologi', null),
    ]);
    _addChapter(b, 'ppu_3', 'ppu', 'Bahasa Indonesia', 3, [
      ('ppu_3_1', 'Tata bahasa', null), ('ppu_3_2', 'Kosakata', null),
      ('ppu_3_3', 'Ejaan & tanda baca', null),
    ]);
    _addChapter(b, 'ppu_4', 'ppu', 'Budaya & Seni', 4, [
      ('ppu_4_1', 'Budaya Nusantara', null),
      ('ppu_4_2', 'Seni & sastra', null),
    ]);

    // PBM — Pemahaman Bacaan & Menulis
    _addChapter(b, 'pbm_1', 'pbm', 'Pemahaman Bacaan', 1, [
      ('pbm_1_1', 'Ide pokok & gagasan utama', null),
      ('pbm_1_2', 'Inferensi & simpulan', null),
      ('pbm_1_3', 'Pernyataan sesuai/tidak sesuai teks', null),
      ('pbm_1_4', 'Makna kata dalam konteks', null),
    ]);
    _addChapter(b, 'pbm_2', 'pbm', 'Menulis & Penyuntingan', 2, [
      ('pbm_2_1', 'Pengembangan paragraf', null),
      ('pbm_2_2', 'Perbaikan kalimat tidak efektif', null),
      ('pbm_2_3', 'Perbaikan ejaan & tanda baca', null),
      ('pbm_2_4', 'Koherensi & kohesi teks', null),
    ]);
    _addChapter(b, 'pbm_3', 'pbm', 'Jenis Teks', 3, [
      ('pbm_3_1', 'Teks argumentasi', null),
      ('pbm_3_2', 'Teks eksposisi', null),
      ('pbm_3_3', 'Teks narasi', null),
    ]);

    // PM — Pengetahuan Matematika
    _addChapter(b, 'pm_1', 'pm', 'Aljabar', 1, [
      ('pm_1_1', 'Persamaan linear & kuadrat', null),
      ('pm_1_2', 'Sistem persamaan', null),
      ('pm_1_3', 'Pertidaksamaan', null),
      ('pm_1_4', 'Fungsi & komposisi', null),
    ]);
    _addChapter(b, 'pm_2', 'pm', 'Geometri & Pengukuran', 2, [
      ('pm_2_1', 'Bangun datar', null), ('pm_2_2', 'Bangun ruang', null),
      ('pm_2_3', 'Trigonometri', null), ('pm_2_4', 'Koordinat kartesius', null),
    ]);
    _addChapter(b, 'pm_3', 'pm', 'Statistika & Peluang', 3, [
      ('pm_3_1', 'Mean, median, modus', null),
      ('pm_3_2', 'Varians & standar deviasi', null),
      ('pm_3_3', 'Peluang & kombinatorika', null),
    ]);
    _addChapter(b, 'pm_4', 'pm', 'Bilangan', 4, [
      ('pm_4_1', 'Aritmatika & bilangan bulat', null),
      ('pm_4_2', 'Pecahan & rasio', null),
      ('pm_4_3', 'Barisan & deret', null),
      ('pm_4_4', 'Eksponen & logaritma', null),
    ]);

    // LB — Literasi Bahasa Inggris
    _addChapter(b, 'lb_1', 'lb', 'Reading Comprehension', 1, [
      ('lb_1_1', 'Main idea & detail', null),
      ('lb_1_2', 'Inference & implication', null),
      ('lb_1_3', 'Vocabulary in context', null),
      ('lb_1_4', 'Text structure & organization', null),
    ]);
    _addChapter(b, 'lb_2', 'lb', 'Grammar & Usage', 2, [
      ('lb_2_1', 'Tenses & verb forms', null),
      ('lb_2_2', 'Subject-verb agreement', null),
      ('lb_2_3', 'Prepositions & articles', null),
      ('lb_2_4', 'Sentence structure', null),
    ]);
    _addChapter(b, 'lb_3', 'lb', 'Writing Skills', 3, [
      ('lb_3_1', 'Paragraph development', null),
      ('lb_3_2', 'Cohesion & coherence', null),
    ]);

    // PK — Penalaran Matematika (Higher Order)
    _addChapter(b, 'pk_1', 'pk', 'Penalaran Aljabar', 1, [
      ('pk_1_1', 'Pola & generalisasi', null),
      ('pk_1_2', 'Persamaan & pertidaksamaan kompleks', null),
      ('pk_1_3', 'Fungsi lanjut', null),
    ]);
    _addChapter(b, 'pk_2', 'pk', 'Penalaran Data', 2, [
      ('pk_2_1', 'Interpretasi grafik & tabel', null),
      ('pk_2_2', 'Pemodelan matematika', null),
      ('pk_2_3', 'Probabilitas lanjut', null),
    ]);
    _addChapter(b, 'pk_3', 'pk', 'Penalaran Geometri', 3, [
      ('pk_3_1', 'Geometri analitik', null),
      ('pk_3_2', 'Transformasi geometri', null),
    ]);

    // SAINS — Literasi Sains (Fisika, Kimia, Biologi)
    _addChapter(b, 'sains_f', 'sains', 'Fisika', 1, [
      ('sains_f1', 'Mekanika & gerak', 'Fisika'),
      ('sains_f2', 'Termodinamika', 'Fisika'),
      ('sains_f3', 'Gelombang & optik', 'Fisika'),
      ('sains_f4', 'Listrik & magnet', 'Fisika'),
      ('sains_f5', 'Fisika modern', 'Fisika'),
    ]);
    _addChapter(b, 'sains_k', 'sains', 'Kimia', 2, [
      ('sains_k1', 'Struktur atom & ikatan', 'Kimia'),
      ('sains_k2', 'Stoikiometri', 'Kimia'),
      ('sains_k3', 'Larutan & asam-basa', 'Kimia'),
      ('sains_k4', 'Termokimia & kinetika', 'Kimia'),
      ('sains_k5', 'Kimia organik dasar', 'Kimia'),
    ]);
    _addChapter(b, 'sains_b', 'sains', 'Biologi', 3, [
      ('sains_b1', 'Sel & biomolekul', 'Biologi'),
      ('sains_b2', 'Genetika & evolusi', 'Biologi'),
      ('sains_b3', 'Fisiologi manusia', 'Biologi'),
      ('sains_b4', 'Ekologi & lingkungan', 'Biologi'),
      ('sains_b5', 'Kingdom & klasifikasi', 'Biologi'),
    ]);

    await b.commit(noResult: true);
  }

  static void _addChapter(
    Batch b,
    String chapId,
    String subtestId,
    String chapName,
    int order,
    List<(String, String, String?)> topics,
  ) {
    b.insert('chapters', {
      'id': chapId, 'subtest_id': subtestId,
      'name': chapName, 'sort_order': order,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);

    for (int i = 0; i < topics.length; i++) {
      final (tid, tname, group) = topics[i];
      b.insert('topics', {
        'id': tid, 'chapter_id': chapId,
        'group_name': group, 'name': tname,
        'is_custom': 0, 'sort_order': i + 1,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
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
