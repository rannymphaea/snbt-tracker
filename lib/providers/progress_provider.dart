// lib/providers/progress_provider.dart
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'dart:convert';
import '../data/repository.dart';
import '../models/models.dart';

class ProgressProvider extends ChangeNotifier {
  List<SubtestModel> subtests = [];
  Map<String, ProgressModel> progress = {};
  List<ActivityLog> last7Days = [];
  int streak = 0;
  bool isLoading = true;
  bool _seeded = false;

  Future<void> init() async {
    isLoading = true;
    notifyListeners();

    // Seed if needed (v2: 7 subtests)
    _seeded = await SeedRepo.isSeeded();
    if (!_seeded) {
      try {
        final jsonStr = await rootBundle.loadString('assets/materi-snbt.json');
        final json = jsonDecode(jsonStr) as Map<String, dynamic>;
        await SeedRepo.seed(json);
        _seeded = true;
      } catch (e) {
        debugPrint('Seed error: $e');
      }
    }

    await _reload();
  }

  Future<void> _reload() async {
    subtests = await SubtestRepo.getAll();
    progress = await ProgressRepo.getAll();
    last7Days = await ActivityRepo.getLast7Days();
    streak = await ActivityRepo.getStreak();
    isLoading = false;
    notifyListeners();
  }

  Future<void> toggleProgress(String topicId, ProgressField field) async {
    await ProgressRepo.toggle(topicId, field);
    // Update local cache immediately (optimistic)
    final existing = progress[topicId] ?? ProgressModel(topicId: topicId);
    final updated = switch (field) {
      ProgressField.pelajari => existing.copyWith(pelajari: !existing.pelajari),
      ProgressField.latihan  => existing.copyWith(latihan:  !existing.latihan),
      ProgressField.review   => existing.copyWith(review:   !existing.review),
    };
    progress[topicId] = updated;
    last7Days = await ActivityRepo.getLast7Days();
    streak = await ActivityRepo.getStreak();
    notifyListeners();
  }

  Future<void> updateCatatan(String topicId, String catatan) async {
    await ProgressRepo.updateCatatan(topicId, catatan);
    final existing = progress[topicId] ?? ProgressModel(topicId: topicId);
    progress[topicId] = existing.copyWith(catatan: catatan);
    notifyListeners();
  }

  Future<void> resetAll() async {
    await ProgressRepo.resetAll();
    await _reload();
  }

  Future<List<ChapterModel>> getChaptersWithTopics(String subtestId) async {
    final chapters = await ChapterRepo.getBySubtest(subtestId);
    final result = <ChapterModel>[];
    for (final ch in chapters) {
      final topics = await TopicRepo.getByChapter(ch.id);
      result.add(ChapterModel(
        id: ch.id,
        subtestId: ch.subtestId,
        name: ch.name,
        sortOrder: ch.sortOrder,
        topics: topics,
      ));
    }
    return result;
  }

  // ── Computed stats ──────────────────────────────────────────────────────
  double get totalProgress {
    if (progress.isEmpty) return 0;
    final total = progress.length * 3;
    final done = progress.values.fold(0, (sum, p) => sum + p.completedCount);
    return total == 0 ? 0 : done / total;
  }

  Future<double> subtestProgress(String subtestId) async {
    final topics = await TopicRepo.getBySubtest(subtestId);
    if (topics.isEmpty) return 0;
    final total = topics.length * 3;
    final done = topics.fold(0, (sum, t) {
      final p = progress[t.id];
      return sum + (p?.completedCount ?? 0);
    });
    return total == 0 ? 0 : done / total;
  }
}

class SettingsProvider extends ChangeNotifier {
  bool sfxEnabled = true;
  String reminderTime = '07:00';
  bool loaded = false;

  Future<void> init() async {
    sfxEnabled = await SettingsRepo.getBool('sfx_enabled', defaultVal: true);
    reminderTime = await SettingsRepo.get('reminder_time') ?? '07:00';
    loaded = true;
    notifyListeners();
  }

  Future<void> setSfx(bool val) async {
    sfxEnabled = val;
    await SettingsRepo.setBool('sfx_enabled', val);
    notifyListeners();
  }

  Future<void> setReminderTime(String time) async {
    reminderTime = time;
    await SettingsRepo.set('reminder_time', time);
    notifyListeners();
  }
}
