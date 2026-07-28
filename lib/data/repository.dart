// lib/data/repository.dart — All DB repositories
import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../models/models.dart';
import 'database_helper.dart';

// ─── Settings ───────────────────────────────────────────────────────────────
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

// ─── Seed ───────────────────────────────────────────────────────────────────
class SeedRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<bool> isSeeded() async =>
      await SettingsRepo.getBool('seeded_flag');

  static Future<void> seed(Map<String, dynamic> json) async {
    final db = await _db;
    final subtests = json['subtests'] as List;
    final colors = [
      '#2E6FF2', '#FF6B4A', '#3BA55C', '#9B59B6', '#F5B942', '#1ABC9C',
    ];
    final abbrs = ['PM', 'LI', 'LE', 'PU', 'PBM', 'PKB'];

    await db.transaction((txn) async {
      for (int si = 0; si < subtests.length; si++) {
        final sub = subtests[si] as Map<String, dynamic>;
        final subId = sub['id'] as String;
        await txn.insert('subtests', {
          'id': subId,
          'name': sub['name'] as String,
          'abbr': abbrs[si % abbrs.length],
          'color': sub['color'] ?? colors[si % colors.length],
          'sort_order': si,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        final chapters = sub['chapters'] as List? ?? [];
        for (int ci = 0; ci < chapters.length; ci++) {
          final ch = chapters[ci] as Map<String, dynamic>;
          final chId = ch['id'] as String;
          await txn.insert('chapters', {
            'id': chId,
            'subtest_id': subId,
            'name': ch['name'] as String,
            'sort_order': ci,
          }, conflictAlgorithm: ConflictAlgorithm.ignore);

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
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
            await txn.insert('progress', {
              'topic_id': tId,
              'pelajari': 0, 'latihan': 0, 'review': 0,
              'catatan': '', 'updated_at': '',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      }
    });
    await SettingsRepo.setBool('seeded_flag', true);
  }
}

// ─── Subtest ────────────────────────────────────────────────────────────────
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

// ─── Chapter ────────────────────────────────────────────────────────────────
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
}

// ─── Topic ──────────────────────────────────────────────────────────────────
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
      // Ensure chapter exists
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

  static TopicModel _fromRow(Map<String, Object?> r) => TopicModel(
    id: r['id'] as String,
    chapterId: r['chapter_id'] as String,
    groupName: r['group_name'] as String?,
    name: r['name'] as String,
    isCustom: (r['is_custom'] as int) == 1,
    sortOrder: r['sort_order'] as int,
  );
}

// ─── Progress ───────────────────────────────────────────────────────────────
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

    // Update activity log for today
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
    await db.rawUpdate('''
      UPDATE progress SET pelajari=0, latihan=0, review=0, catatan='', updated_at=''
    ''');
    await db.delete('activity_log');
  }

  // Count for a list of topic IDs
  static Future<int> countCompleted(List<String> topicIds) async {
    if (topicIds.isEmpty) return 0;
    final db = await _db;
    final placeholders = topicIds.map((_) => '?').join(',');
    final rows = await db.rawQuery('''
      SELECT SUM(pelajari + latihan + review) as total
      FROM progress WHERE topic_id IN ($placeholders)
    ''', topicIds);
    return (rows.first['total'] as int?) ?? 0;
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

// ─── Activity Log ────────────────────────────────────────────────────────────
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
}

// ─── Tryout Sessions ─────────────────────────────────────────────────────────
class TryoutRepo {
  static Future<Database> get _db => DatabaseHelper.database;

  static Future<List<TryoutSession>> getAll() async {
    final db = await _db;
    final rows = await db.query('tryout_sessions', orderBy: 'date DESC');
    return rows.map((r) => TryoutSession(
      id: r['id'] as int?,
      date: r['date'] as String,
      scores: Map<String, int>.from(
          (jsonDecode(r['scores'] as String) as Map).map(
              (k, v) => MapEntry(k as String, v as int))),
      notes: r['notes'] as String? ?? '',
    )).toList();
  }

  static Future<void> add(TryoutSession s) async {
    final db = await _db;
    await db.insert('tryout_sessions', {
      'date': s.date,
      'scores': jsonEncode(s.scores),
      'notes': s.notes,
    });
  }

  static Future<void> delete(int id) async {
    final db = await _db;
    await db.delete('tryout_sessions', where: 'id = ?', whereArgs: [id]);
  }
}
