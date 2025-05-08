import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lychakingo/features/lessons/domain/models/lesson.dart'; 
import 'package:lychakingo/features/lessons/domain/models/lesson_progress.dart'; 
import 'package:lychakingo/features/lessons/data/lesson_data.dart'; 
import 'package:lychakingo/features/lessons/ui/screens/theory_screen.dart'; 

class LessonListScreen extends StatefulWidget {
  const LessonListScreen({super.key});

  @override
  State<LessonListScreen> createState() => _LessonListScreenState();
}

class _LessonListScreenState extends State<LessonListScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;

  final Map<String, IconData> lessonIcons = {
    'article_icon': Icons.article_outlined,
    'plural_icon': Icons.group_work_outlined,
    'verb_icon': Icons.speaker_notes_outlined,
    'present_simple_icon': Icons.access_time,
    'preposition_icon': Icons.location_on_outlined,
    'default': Icons.school_outlined,
  };

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return const Center(child: Text("Please log in to see lessons."));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'main-db')
          .collection('userProgress')
          .doc(userId)
          .collection('lessonProgress')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error loading progress: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final progressDocs = snapshot.data?.docs ?? [];
        final Map<String, LessonProgress> progressMap = {
          for (var doc in progressDocs) doc.id: LessonProgress.fromSnapshot(doc)
        };

        double averageStars = 0.0;
        int completedCount = 0;
        int totalStars = 0;
        for (var progress in progressMap.values) {
          if (progress.isCompleted && progress.stars != null) {
            completedCount++;
            totalStars += progress.stars!;
          }
        }
        if (completedCount > 0) {
          averageStars = totalStars / completedCount;
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stars, color: Colors.orangeAccent.shade700),
                  const SizedBox(width: 8),
                  Text(
                    completedCount > 0
                        ? 'Середня оцінка: ${averageStars.toStringAsFixed(1)} зірочок'
                        : 'Проходьте уроки щоб покращити оцінку!',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: allLessons.length,
                itemBuilder: (context, index) {
                  final lesson = allLessons[index];
                  final lessonProgress = progressMap[lesson.id];
                  bool isLocked = true;
                  int stars = lessonProgress?.stars ?? 0;
                  if (lesson.prerequisiteLessonId == null) { isLocked = false; }
                  else {
                    final prerequisiteProgress = progressMap[lesson.prerequisiteLessonId];
                    if (prerequisiteProgress != null && prerequisiteProgress.isCompleted) { isLocked = false; }
                  }
                  bool isCompleted = lessonProgress?.isCompleted ?? false;
                  bool canStartLesson = !isLocked;

                  return _buildLessonTile(
                    context: context, lesson: lesson, isLocked: isLocked,
                    isCompleted: isCompleted, stars: stars, canStart: canStartLesson,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLessonTile({
    required BuildContext context,
    required Lesson lesson,
    required bool isLocked,
    required bool isCompleted,
    required int stars,
    required bool canStart,
  }) {
     final iconData = lessonIcons[lesson.iconName] ?? lessonIcons['default']!;
     final theme = Theme.of(context);
     final tileColor = isCompleted ? Colors.green.shade50 : (isLocked ? Colors.grey.shade300 : null);
     final leadingColor = isLocked ? Colors.grey.shade600 : (isCompleted ? Colors.green.shade700 : theme.colorScheme.primary);

     return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      elevation: canStart ? 2 : 0,
      color: tileColor,
      child: ListTile(
        leading: Icon(isLocked ? Icons.lock_outline : iconData, color: leadingColor, size: 30),
        title: Text(
          lesson.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isLocked ? Colors.grey.shade700 : null,
          ),
        ),
        subtitle: Text(
          lesson.description,
           style: TextStyle(color: isLocked ? Colors.grey.shade700 : null),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: isCompleted
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) => Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 18,
                )),
              )
            : (isLocked ? null : const Icon(Icons.arrow_forward_ios, size: 16)),
        enabled: canStart,
        onTap: canStart
            ? () {
                print("Navigating to theory for lesson: ${lesson.title}");
                Navigator.push( context,
                  MaterialPageRoute(builder: (context) => TheoryScreen(lesson: lesson)),
                );
              }
            : null,
      ),
    );
  }
}