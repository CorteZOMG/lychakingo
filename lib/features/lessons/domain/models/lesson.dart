import 'package:flutter/foundation.dart'; 
import 'package:lychakingo/features/lessons/domain/models/task.dart'; 

@immutable
abstract class Lesson {
  final String id;
  final String title;
  final String description;
  final String theoryTitle;
  final String theoryContent;
  final List<Task> tasks;
  final String? prerequisiteLessonId;
  final String iconName;

  Lesson({
    required this.id,
    required this.title,
    required this.description,
    required this.theoryTitle,
    required this.theoryContent,
    required this.tasks,
    this.prerequisiteLessonId,
    required this.iconName,
  });
  
  int calculateStars(double scorePercentage) {
    if (scorePercentage < 0.5) { return 0; }
    else if (scorePercentage < 0.75) { return 1; }
    else if (scorePercentage < 1.0) { return 2; }
    else { return 3; }
  }
}

class StandardLesson extends Lesson {
   StandardLesson({
    required super.id,
    required super.title,
    required super.description,
    required super.theoryTitle,
    required super.theoryContent,
    required super.tasks,
    super.prerequisiteLessonId,
    required super.iconName,
  });
}