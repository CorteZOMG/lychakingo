import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum LessonStatus { locked, unlocked, completed }
extension LessonStatusExtension on LessonStatus {
  String toJson() => describeEnum(this);

  static LessonStatus fromJson(String? jsonString) {
    if (jsonString == null) return LessonStatus.locked;
    try {
      return LessonStatus.values.firstWhere(
        (e) => describeEnum(e).toLowerCase() == jsonString.toLowerCase(),
        orElse: () => LessonStatus.locked,
      );
    } catch (e) {
      return LessonStatus.locked;
    }
  }
}

@immutable
class LessonProgress {
  final String lessonId;
  final LessonStatus status;
  final double? lastScore;
  final int? stars;
  final Timestamp? completedTimestamp;
  final int? lastDurationSeconds; 

  const LessonProgress({
    required this.lessonId,
    this.status = LessonStatus.locked,
    this.lastScore,
    this.stars,
    this.completedTimestamp,
    this.lastDurationSeconds, 
  });

  factory LessonProgress.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>? ?? {};
    return LessonProgress(
      lessonId: snapshot.id,
      status: LessonStatusExtension.fromJson(data['status'] as String?),
      lastScore: (data['lastScore'] as num?)?.toDouble(),
      stars: data['stars'] as int?,
      completedTimestamp: data['completedTimestamp'] as Timestamp?,
      lastDurationSeconds: data['lastDurationSeconds'] as int?, 
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'status': status.toJson(),
      'lastScore': lastScore,
      'stars': stars,
      'completedTimestamp': completedTimestamp,
      'lastDurationSeconds': lastDurationSeconds, 
      'updatedTimestamp': FieldValue.serverTimestamp(),
    };
  }

  bool get isCompleted => status == LessonStatus.completed;
  bool get isUnlocked => status == LessonStatus.unlocked || status == LessonStatus.completed;
}