// lib/models/models.dart -- All data models

class SubtestModel {
  final String id;
  final String name;
  final String abbr;
  final String color;
  final int sortOrder;
  final List<ChapterModel> chapters;

  const SubtestModel({
    required this.id,
    required this.name,
    required this.abbr,
    required this.color,
    required this.sortOrder,
    this.chapters = const [],
  });
}

class ChapterModel {
  final String id;
  final String subtestId;
  final String name;
  final int sortOrder;
  final List<TopicModel> topics;

  const ChapterModel({
    required this.id,
    required this.subtestId,
    required this.name,
    required this.sortOrder,
    this.topics = const [],
  });
}

class TopicModel {
  final String id;
  final String chapterId;
  final String? groupName;
  final String name;
  final bool isCustom;
  final int sortOrder;

  const TopicModel({
    required this.id,
    required this.chapterId,
    this.groupName,
    required this.name,
    this.isCustom = false,
    this.sortOrder = 0,
  });
}

class ProgressModel {
  final String topicId;
  final bool pelajari;
  final bool latihan;
  final bool review;
  final String catatan;
  final String updatedAt;

  const ProgressModel({
    required this.topicId,
    this.pelajari = false,
    this.latihan = false,
    this.review = false,
    this.catatan = '',
    this.updatedAt = '',
  });

  int get completedCount =>
      (pelajari ? 1 : 0) + (latihan ? 1 : 0) + (review ? 1 : 0);

  ProgressModel copyWith({
    bool? pelajari,
    bool? latihan,
    bool? review,
    String? catatan,
    String? updatedAt,
  }) =>
      ProgressModel(
        topicId: topicId,
        pelajari: pelajari ?? this.pelajari,
        latihan: latihan ?? this.latihan,
        review: review ?? this.review,
        catatan: catatan ?? this.catatan,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}

class ActivityLog {
  final int? id;
  final String date; // YYYY-MM-DD (local timezone)
  final int checksCount;

  const ActivityLog({this.id, required this.date, required this.checksCount});

  ActivityLog copyWith({int? checksCount}) =>
      ActivityLog(id: id, date: date, checksCount: checksCount ?? this.checksCount);
}

// -- v2: Daily check-in session --
class DailyCheckin {
  final int? id;
  final String date;          // yyyy-MM-dd local
  final String subtestId;
  final String chapterId;
  final String? topicId;
  final int durationMinutes;
  final String createdAt;

  const DailyCheckin({
    this.id,
    required this.date,
    required this.subtestId,
    required this.chapterId,
    this.topicId,
    required this.durationMinutes,
    required this.createdAt,
  });
}

// -- v2: Tryout score (replaces old TryoutSession) --
class TryoutScore {
  final int? id;
  final String name;          // "Tryout Nasional 1"
  final String date;          // yyyy-MM-dd
  final int? scoreExpected;
  final int scoreMax;
  final Map<String, int> scoresDetail; // per-subtest
  final String notes;

  const TryoutScore({
    this.id,
    required this.name,
    required this.date,
    this.scoreExpected,
    this.scoreMax = 1000,
    this.scoresDetail = const {},
    this.notes = '',
  });

  int? get delta => null; // computed by caller based on previous score
}

// -- v2: Target PTN --
class TargetPtn {
  final int id;
  final String university;
  final String major;
  final int? passingGrade;

  const TargetPtn({
    this.id = 1,
    required this.university,
    required this.major,
    this.passingGrade,
  });
}

// -- v2: User XP & Level --
class UserXp {
  final int totalXp;
  final int level;

  const UserXp({this.totalXp = 0, this.level = 1});

  int get xpForNextLevel => level * 500;
  double get progress => totalXp / xpForNextLevel;

  UserXp addXp(int amount) {
    int newXp = totalXp + amount;
    int newLevel = level;
    while (newXp >= newLevel * 500) {
      newXp -= newLevel * 500;
      newLevel++;
    }
    return UserXp(totalXp: newXp, level: newLevel);
  }
}

enum ProgressField { pelajari, latihan, review }

extension ProgressFieldExt on ProgressField {
  String get label {
    switch (this) {
      case ProgressField.pelajari: return 'Pelajari';
      case ProgressField.latihan: return 'Latihan';
      case ProgressField.review: return 'Review';
    }
  }
  String get key {
    switch (this) {
      case ProgressField.pelajari: return 'pelajari';
      case ProgressField.latihan: return 'latihan';
      case ProgressField.review: return 'review';
    }
  }
}
