// lib/models/models.dart — All data models

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
  final String date; // YYYY-MM-DD
  final int checksCount;

  const ActivityLog({this.id, required this.date, required this.checksCount});

  ActivityLog copyWith({int? checksCount}) =>
      ActivityLog(id: id, date: date, checksCount: checksCount ?? this.checksCount);
}

class TryoutSession {
  final int? id;
  final String date;
  final Map<String, int> scores; // subtestId → score 0-100
  final String notes;

  const TryoutSession({
    this.id,
    required this.date,
    required this.scores,
    this.notes = '',
  });

  int get avgScore {
    if (scores.isEmpty) return 0;
    return scores.values.reduce((a, b) => a + b) ~/ scores.length;
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
