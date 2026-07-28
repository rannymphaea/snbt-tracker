// lib/data/repository.dart -- All DB repositories
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import 'database_helper.dart';

// -- Settings --
class SettingsRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<String?> get(String key) async {
    final db = await _db;
    final rows = await db.query('settings', where: 'key = ?', whereArgs: [key]);
    if (rows.isEmpty) return null;
    return rows.first['value'] as String?;
  }

  static Future<void> set(String key, String value) async {
    final db = await _db;
    await db.insert('settings', {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<bool> getBool(String key, {bool defaultVal = false}) async {
    final v = await get(key);
    if (v == null) return defaultVal;
    return v == '1' || v == 'true';
  }

  static Future<void> setBool(String key, bool value) =>
      set(key, value ? '1' : '0');
}

// -- Seed (updated for v2 JSON with abbr field) --
class SeedRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<bool> isSeeded() async =>
      await SettingsRepo.getBool('seeded_v2');

  static Future<void> seed(Map<String, dynamic> json) async {
    final db = await _db;
    final subtests = json['subtests'] as List;

    await db.transaction((txn) async {
      for (int si = 0; si < subtests.length; si++) {
        final sub = subtests[si] as Map<String, dynamic>;
        final subId = sub['id'] as String;
        await txn.insert('subtests', {
          'id': subId,
          'name': sub['name'] as String,
          'abbr': sub['abbr'] as String? ?? subId.substring(0, 2).toUpperCase(),
          'color': sub['color'] as String? ?? '#7C3AED',
          'sort_order': si,
        }, conflictAlgorithm: ConflictAlgorithm.replace);

        final chapters = sub['chapters'] as List? ?? [];
        for (int ci = 0; ci < chapters.length; ci++) {
          final ch = chapters[ci] as Map<String, dynamic>;
          final chId = ch['id'] as String;
          await txn.insert('chapters', {
            'id': chId,
            'subtest_id': subId,
            'name': ch['name'] as String,
            'sort_order': ci,
          }, conflictAlgorithm: ConflictAlgorithm.replace);

          final topics = ch['topics'] as List? ?? [];
          for (int ti = 0; ti < topics.length; ti++) {
            final t = topics[ti] as Map<String, dynamic>;
            final tId = t['id'] as String;
            await txn.insert('topics', {
              'id': tId,
              'chapter_id': chId,
              'group_name': t['group'] as String?,
              'name': t['name'] as String,
              'is_custom': 0,
              'sort_order': ti,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
            await txn.insert('progress', {
              'topic_id': tId,
              'pelajari': 0, 'latihan': 0, 'review': 0,
              'catatan': '', 'updated_at': '',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    });
    await SettingsRepo.setBool('seeded_v2', true);
  }
}

// -- Subtest --
class SubtestRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<List<SubtestModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('subtests', orderBy: 'sort_order ASC');
    return rows.map((r) => SubtestModel(
      id: r['id'] as String,
      name: r['name'] as String,
      abbr: r['abbr'] as String,
      color: r['color'] as String,
      sortOrder: r['sort_order'] as int,
    )).toList();
  }

  static Future<SubtestModel?> getById(String id) async {
    final db = await _db;
    final rows = await db.query('subtests', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    final r = rows.first;
    return SubtestModel(
      id: r['id'] as String,
      name: r['name'] as String,
      abbr: r['abbr'] as String,
      color: r['color'] as String,
      sortOrder: r['sort_order'] as int,
    );
  }
}

// -- Chapter --
class ChapterRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<List<ChapterModel>> getBySubtest(String subtestId) async {
    final db = await _db;
    final rows = await db.query('chapters',
        where: 'subtest_id = ?', whereArgs: [subtestId], orderBy: 'sort_order ASC');
    return rows.map((r) => ChapterModel(
      id: r['id'] as String,
      subtestId: r['subtest_id'] as String,
      name: r['name'] as String,
      sortOrder: r['sort_order'] as int,
    )).toList();
  }

  static Future<void> insert(ChapterModel ch) async {
    final db = await _db;
    await db.insert('chapters', {
      'id': ch.id,
      'subtest_id': ch.subtestId,
      'name': ch.name,
      'sort_order': ch.sortOrder,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static Future<void> update(String id, String newName) async {
    final db = await _db;
    await db.update('chapters', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> delete(String id) async {
    final db = await _db;
    // Cascade: delete topics and progress for this chapter
    final topics = await db.query('topics', where: 'chapter_id = ?', whereArgs: [id]);
    for (final t in topics) {
      await db.delete('progress', where: 'topic_id = ?', whereArgs: [t['id']]);
    }
    await db.delete('topics', where: 'chapter_id = ?', whereArgs: [id]);
    await db.delete('chapters', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> reorder(List<String> orderedIds) async {
    final db = await _db;
    await db.transaction((txn) async {
      for (int i = 0; i < orderedIds.length; i++) {
        await txn.update('chapters', {'sort_order': i},
            where: 'id = ?', whereArgs: [orderedIds[i]]);
      }
    });
  }
}

// -- Topic --
class TopicRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<List<TopicModel>> getByChapter(String chapterId) async {
    final db = await _db;
    final rows = await db.query('topics',
        where: 'chapter_id = ?', whereArgs: [chapterId], orderBy: 'sort_order ASC');
    return rows.map(_fromRow).toList();
  }

  static Future<List<TopicModel>> getBySubtest(String subtestId) async {
    final db = await _db;
    final rows = await db.rawQuery('''
      SELECT t.* FROM topics t
      JOIN chapters c ON t.chapter_id = c.id
      WHERE c.subtest_id = ?
      ORDER BY c.sort_order, t.sort_order
    ''', [subtestId]);
    return rows.map(_fromRow).toList();
  }

  static Future<List<TopicModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('topics', orderBy: 'sort_order ASC');
    return rows.map(_fromRow).toList();
  }

  static Future<void> insertCustom({
    required String subtestId,
    required String chapterId,
    required String chapterName,
    required String topicName,
    String? group,
  }) async {
    final db = await _db;
    final id = 'custom-${DateTime.now().millisecondsSinceEpoch}';
    await db.transaction((txn) async {
      await txn.insert('chapters', {
        'id': chapterId,
        'subtest_id': subtestId,
        'name': chapterName,
        'sort_order': 999,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      await txn.insert('topics', {
        'id': id,
        'chapter_id': chapterId,
        'group_name': group,
        'name': topicName,
        'is_custom': 1,
        'sort_order': 999,
      });
      await txn.insert('progress', {
        'topic_id': id,
        'pelajari': 0, 'latihan': 0, 'review': 0,
        'catatan': '', 'updated_at': '',
      });
    });
  }

  static Future<void> delete(String id) async {
    final db = await _db;
    await db.delete('progress', where: 'topic_id = ?', whereArgs: [id]);
    await db.delete('topics', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> update(String id, String newName) async {
    final db = await _db;
    await db.update('topics', {'name': newName}, where: 'id = ?', whereArgs: [id]);
  }

  static TopicModel _fromRow(Map<String, Object?> r) => TopicModel(
    id: r['id'] as String,
    chapterId: r['chapter_id'] as String,
    groupName: r['group_name'] as String?,
    name: r['name'] as String,
    isCustom: (r['is_custom'] as int) == 1,
    sortOrder: r['sort_order'] as int,
  );
}

// -- Progress --
class ProgressRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<Map<String, ProgressModel>> getAll() async {
    final db = await _db;
    final rows = await db.query('progress');
    return {for (final r in rows) r['topic_id'] as String: _fromRow(r)};
  }

  static Future<ProgressModel?> getByTopic(String topicId) async {
    final db = await _db;
    final rows = await db.query('progress', where: 'topic_id = ?', whereArgs: [topicId]);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  static Future<void> toggle(String topicId, ProgressField field) async {
    final db = await _db;
    final existing = await getByTopic(topicId);
    bool newVal;
    switch (field) {
      case ProgressField.pelajari: newVal = !(existing?.pelajari ?? false); break;
      case ProgressField.latihan:  newVal = !(existing?.latihan  ?? false); break;
      case ProgressField.review:   newVal = !(existing?.review   ?? false); break;
    }
    final col = field.key;
    await db.execute('''
      INSERT INTO progress (topic_id, $col, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(topic_id) DO UPDATE SET $col = ?, updated_at = ?
    ''', [topicId, newVal ? 1 : 0, _now(), newVal ? 1 : 0, _now()]);

    if (newVal) await ActivityRepo.incrementToday();
  }

  static Future<void> updateCatatan(String topicId, String catatan) async {
    final db = await _db;
    await db.execute('''
      INSERT INTO progress (topic_id, catatan, updated_at)
      VALUES (?, ?, ?)
      ON CONFLICT(topic_id) DO UPDATE SET catatan = ?, updated_at = ?
    ''', [topicId, catatan, _now(), catatan, _now()]);
  }

  static Future<void> resetAll() async {
    final db = await _db;
    await db.rawUpdate(
      "UPDATE progress SET pelajari=0, latihan=0, review=0, catatan='', updated_at=''");
    await db.delete('activity_log');
  }

  static ProgressModel _fromRow(Map<String, Object?> r) => ProgressModel(
    topicId: r['topic_id'] as String,
    pelajari: (r['pelajari'] as int) == 1,
    latihan:  (r['latihan']  as int) == 1,
    review:   (r['review']   as int) == 1,
    catatan:  r['catatan']   as String? ?? '',
    updatedAt: r['updated_at'] as String? ?? '',
  );

  static String _now() => DateTime.now().toIso8601String();
}

// -- Activity Log --
class ActivityRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static String _today() => DateTime.now().toIso8601String().split('T')[0];

  static Future<void> incrementToday() async {
    final db = await _db;
    final today = _today();
    await db.execute('''
      INSERT INTO activity_log (date, checks_count) VALUES (?, 1)
      ON CONFLICT(date) DO UPDATE SET checks_count = checks_count + 1
    ''', [today]);
  }

  static Future<List<ActivityLog>> getLast7Days() async {
    final db = await _db;
    final results = <ActivityLog>[];
    for (int i = 6; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final dateStr = d.toIso8601String().split('T')[0];
      final rows = await db.query('activity_log', where: 'date = ?', whereArgs: [dateStr]);
      results.add(ActivityLog(
        date: dateStr,
        checksCount: rows.isEmpty ? 0 : (rows.first['checks_count'] as int),
      ));
    }
    return results;
  }

  static Future<int> getStreak() async {
    final db = await _db;
    final rows = await db.query('activity_log',
        where: 'checks_count > 0', orderBy: 'date DESC');
    if (rows.isEmpty) return 0;
    final today = _today();
    final yesterday = DateTime.now().subtract(const Duration(days: 1))
        .toIso8601String().split('T')[0];
    final firstDate = rows.first['date'] as String;
    if (firstDate != today && firstDate != yesterday) return 0;

    int streak = 1;
    for (int i = 1; i < rows.length; i++) {
      final prev = rows[i - 1]['date'] as String;
      final curr = rows[i]['date'] as String;
      final diff = DateTime.parse(prev).difference(DateTime.parse(curr)).inDays;
      if (diff == 1) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }

  // Edit check-in count for a specific date (manual correction)
  static Future<void> setCount(String date, int count) async {
    final db = await _db;
    if (count <= 0) {
      await db.delete('activity_log', where: 'date = ?', whereArgs: [date]);
    } else {
      await db.execute('''
        INSERT INTO activity_log (date, checks_count) VALUES (?, ?)
        ON CONFLICT(date) DO UPDATE SET checks_count = ?
      ''', [date, count, count]);
    }
  }

  // Get all activity log entries (for history screen)
  static Future<List<ActivityLog>> getAll() async {
    final db = await _db;
    final rows = await db.query('activity_log', orderBy: 'date DESC');
    return rows.map((r) => ActivityLog(
      id: r['id'] as int?,
      date: r['date'] as String,
      checksCount: r['checks_count'] as int,
    )).toList();
  }
}

// -- v2: Daily Check-in Sessions --
class CheckinRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static String _today() => DateTime.now().toIso8601String().split('T')[0];
  static String _now() => DateTime.now().toIso8601String();

  /// Record a study session — returns the created DailyCheckin for cloud sync
  static Future<DailyCheckin?> add({
    required String subtestId,
    required String chapterId,
    String? topicId,
    required int durationMinutes,
  }) async {
    final db = await _db;
    final now = _now();
    final today = _today();
    final id = await db.insert('daily_checkins', {
      'date': today,
      'subtest_id': subtestId,
      'chapter_id': chapterId,
      'topic_id': topicId,
      'duration_minutes': durationMinutes,
      'created_at': now,
    });
    // Also increment activity_log
    await ActivityRepo.incrementToday();
    return DailyCheckin(
      id: id.toString(),
      date: today,
      subtestId: subtestId,
      chapterId: chapterId,
      topicId: topicId,
      durationMinutes: durationMinutes,
      createdAt: now,
    );
  }

  /// Upsert for Firestore pull (merge cloud data into local SQLite)
  static Future<void> upsert(DailyCheckin c) async {
    final db = await _db;
    await db.insert('daily_checkins', {
      'date': c.date,
      'subtest_id': c.subtestId,
      'chapter_id': c.chapterId,
      'topic_id': c.topicId,
      'duration_minutes': c.durationMinutes,
      'created_at': c.createdAt,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  /// Get all check-ins for today
  static Future<List<DailyCheckin>> getToday() async {
    final db = await _db;
    final today = _today();
    final rows = await db.query('daily_checkins',
        where: 'date = ?', whereArgs: [today], orderBy: 'created_at DESC');
    return rows.map(_fromRow).toList();
  }

  /// Get total duration (minutes) for today
  static Future<int> getTodayMinutes() async {
    final db = await _db;
    final today = _today();
    final rows = await db.rawQuery(
      'SELECT SUM(duration_minutes) as total FROM daily_checkins WHERE date = ?',
      [today]);
    return (rows.first['total'] as int?) ?? 0;
  }

  /// Get total duration for a date range
  static Future<int> getMinutesInRange(String startDate, String endDate) async {
    final db = await _db;
    final rows = await db.rawQuery(
      'SELECT SUM(duration_minutes) as total FROM daily_checkins WHERE date >= ? AND date <= ?',
      [startDate, endDate]);
    return (rows.first['total'] as int?) ?? 0;
  }

  /// Get breakdown per subtest (for history charts)
  static Future<Map<String, int>> getMinutesPerSubtest({String? startDate, String? endDate}) async {
    final db = await _db;
    String query = 'SELECT subtest_id, SUM(duration_minutes) as total FROM daily_checkins';
    final args = <String>[];
    if (startDate != null && endDate != null) {
      query += ' WHERE date >= ? AND date <= ?';
      args.addAll([startDate, endDate]);
    }
    query += ' GROUP BY subtest_id';
    final rows = await db.rawQuery(query, args);
    return {for (final r in rows) r['subtest_id'] as String: (r['total'] as int?) ?? 0};
  }

  /// Get all check-ins (for history)
  static Future<List<DailyCheckin>> getAll() async {
    final db = await _db;
    final rows = await db.query('daily_checkins', orderBy: 'date DESC, created_at DESC');
    return rows.map(_fromRow).toList();
  }

  /// Get daily totals for last N days
  static Future<List<MapEntry<String, int>>> getDailyTotals(int days) async {
    final db = await _db;
    final results = <MapEntry<String, int>>[];
    for (int i = days - 1; i >= 0; i--) {
      final d = DateTime.now().subtract(Duration(days: i));
      final dateStr = d.toIso8601String().split('T')[0];
      final rows = await db.rawQuery(
        'SELECT SUM(duration_minutes) as total FROM daily_checkins WHERE date = ?',
        [dateStr]);
      results.add(MapEntry(dateStr, (rows.first['total'] as int?) ?? 0));
    }
    return results;
  }

  static DailyCheckin _fromRow(Map<String, Object?> r) => DailyCheckin(
    id: (r['id'] as int?)?.toString() ?? '',
    date: r['date'] as String,
    subtestId: r['subtest_id'] as String,
    chapterId: r['chapter_id'] as String,
    topicId: r['topic_id'] as String?,
    durationMinutes: r['duration_minutes'] as int,
    createdAt: r['created_at'] as String,
  );
}

// -- v2: Tryout Scores --
class TryoutScoreRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<List<TryoutScore>> getAll() async {
    final db = await _db;
    final rows = await db.query('tryout_scores', orderBy: 'date DESC');
    return rows.map(_fromRow).toList();
  }

  static Future<void> add(TryoutScore s) async {
    final db = await _db;
    await db.insert('tryout_scores', {
      'name': s.name,
      'date': s.date,
      'score_expected': s.scoreExpected,
      'score_max': s.scoreMax,
      'scores_detail': jsonEncode(s.scoresDetail),
      'notes': s.notes,
    });
  }

  static Future<void> update(TryoutScore s) async {
    final db = await _db;
    await db.update('tryout_scores', {
      'name': s.name,
      'date': s.date,
      'score_expected': s.scoreExpected,
      'score_max': s.scoreMax,
      'scores_detail': jsonEncode(s.scoresDetail),
      'notes': s.notes,
    }, where: 'id = ?', whereArgs: [s.id]);
  }

  static Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('tryout_scores', where: 'id = ?', whereArgs: [id]);
  }

  static Future<void> upsert(TryoutScore s) async {
    final db = await _db;
    await db.insert('tryout_scores', {
      'name': s.name,
      'date': s.date,
      'score_expected': s.scoreExpected,
      'score_max': s.scoreMax,
      'scores_detail': jsonEncode(s.scoresDetail),
      'notes': s.notes,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  static TryoutScore _fromRow(Map<String, Object?> r) => TryoutScore(
    id: (r['id'] as int?)?.toString() ?? '',
    name: r['name'] as String,
    date: r['date'] as String,
    scoreExpected: r['score_expected'] as int?,
    scoreMax: (r['score_max'] as int?) ?? 1000,
    scoresDetail: Map<String, int>.from(
        (jsonDecode((r['scores_detail'] as String?) ?? '{}') as Map)
            .map((k, v) => MapEntry(k as String, v as int))),
    notes: r['notes'] as String? ?? '',
  );
}

// -- v2: Target PTN --
class TargetPtnRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<TargetPtn?> get() async {
    final db = await _db;
    final rows = await db.query('target_ptn', where: 'id = 1');
    if (rows.isEmpty) return null;
    final r = rows.first;
    return TargetPtn(
      university: r['university'] as String,
      major: r['major'] as String,
      passingGrade: r['passing_grade'] as int?,
    );
  }

  static Future<void> set(TargetPtn t) async {
    final db = await _db;
    await db.insert('target_ptn', {
      'id': 1,
      'university': t.university,
      'major': t.major,
      'passing_grade': t.passingGrade,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

// -- v2: XP & Level --
class XpRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<UserXp> get() async {
    final db = await _db;
    final rows = await db.query('user_xp', where: 'id = 1');
    if (rows.isEmpty) return const UserXp();
    final r = rows.first;
    return UserXp(
      totalXp: (r['total_xp'] as int?) ?? 0,
      level: (r['level'] as int?) ?? 1,
    );
  }

  /// Add XP from a study session (duration * 2)
  static Future<UserXp> addFromCheckin(int durationMinutes) async {
    final current = await get();
    final xpGain = durationMinutes * 2;
    final updated = current.addXp(xpGain);
    final db = await _db;
    await db.update('user_xp', {
      'total_xp': updated.totalXp,
      'level': updated.level,
    }, where: 'id = 1');
    return updated;
  }

  /// Set XP from cloud pull
  static Future<void> set(UserXp xp) async {
    final db = await _db;
    await db.insert('user_xp', {
      'id': 1,
      'total_xp': xp.totalXp,
      'level': xp.level,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }
}

// -- ProgressModel serialization extensions for cloud sync --
extension ProgressModelSync on ProgressModel {
  Map<String, dynamic> toMap() => {
    'topic_id': topicId,
    'pelajari': pelajari ? 1 : 0,
    'latihan': latihan ? 1 : 0,
    'review': review ? 1 : 0,
    'catatan': catatan,
    'completed_count': completedCount,
  };

  static ProgressModel fromMap(Map<String, dynamic> m) => ProgressModel(
    topicId: m['topic_id'] as String,
    pelajari: (m['pelajari'] as int?) == 1,
    latihan: (m['latihan'] as int?) == 1,
    review: (m['review'] as int?) == 1,
    catatan: m['catatan'] as String? ?? '',
  );
}

// -- ProgressRepo upsert for cloud pull --
extension ProgressRepoSync on ProgressRepo {
  static Future<void> upsert(ProgressModel p) async {
    final db = await DatabaseHelper.database;
    await db.insert('progress', {
      'topic_id': p.topicId,
      'pelajari': p.pelajari ? 1 : 0,
      'latihan': p.latihan ? 1 : 0,
      'review': p.review ? 1 : 0,
      'catatan': p.catatan,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }
}
