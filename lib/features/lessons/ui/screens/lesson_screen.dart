import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:lychakingo/features/lessons/domain/models/lesson.dart';
import 'package:lychakingo/features/lessons/domain/models/task.dart';
import 'package:lychakingo/features/lessons/domain/models/lesson_progress.dart';

class LessonScreen extends StatefulWidget {
  final Lesson lesson;
  const LessonScreen({required this.lesson, super.key});

  @override
  State<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends State<LessonScreen> {
  int _currentTaskIndex = 0;
  late List<dynamic> _userAnswers;
  bool _lessonCompleted = false;
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _userAnswers = List<dynamic>.filled(widget.lesson.tasks.length, null);
    _startTime = DateTime.now();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _handleAnswerSelected(dynamic answer) {
    if(_lessonCompleted) return;
    setState(() {
      _userAnswers[_currentTaskIndex] = answer;
    });
    print("Answer for task $_currentTaskIndex stored: $answer");
  }

  void _onContinuePressed() {
    if (_userAnswers[_currentTaskIndex] == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Please select or enter an answer."),
        duration: Duration(seconds: 2),
      ));
      return;
    }
    if (_currentTaskIndex < widget.lesson.tasks.length - 1) {
      setState(() { _currentTaskIndex++; });
    } else {
      _completeLesson();
    }
  }

  void _completeLesson() {
    if (_lessonCompleted || _startTime == null) return;
    setState(() { _lessonCompleted = true; });

    final Duration duration = DateTime.now().difference(_startTime!);
    print("Lesson attempt finished!");
    int correctCount = 0;
     for (int i = 0; i < widget.lesson.tasks.length; i++) {
      bool isCorrect = widget.lesson.tasks[i].isAnswerCorrect(_userAnswers[i]);
      if (isCorrect) { correctCount++; }
    }
    double score = widget.lesson.tasks.isEmpty ? 1.0 : correctCount / widget.lesson.tasks.length;
    int stars = widget.lesson.calculateStars(score);
    print("Score: $score (${correctCount}/${widget.lesson.tasks.length}), Stars: $stars, Duration: ${duration.inSeconds}s");
    _saveLessonProgress(score, stars, duration.inSeconds);
    _showFeedbackDialog(score, stars, duration);
  }

  Future<void> _saveLessonProgress(double score, int stars, int durationInSeconds) async {
     if (userId == null) { print("Error saving progress: User not logged in."); return; }
     final progressRef = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'main-db')
        .collection('userProgress').doc(userId)
        .collection('lessonProgress').doc(widget.lesson.id);

     Map<String, dynamic> progressData;
     if (stars > 0) {
       progressData = {
        'status': LessonStatus.completed.toJson(),
        'lastScore': score, 'stars': stars,
        'completedTimestamp': FieldValue.serverTimestamp(),
        'updatedTimestamp': FieldValue.serverTimestamp(),
        'lastDurationSeconds': durationInSeconds,
      };
       print("Saving PASSED lesson progress.");
     } else {
       progressData = {
        'lastScore': score, 'stars': 0,
        'updatedTimestamp': FieldValue.serverTimestamp(),
        'lastDurationSeconds': durationInSeconds,
      };
       print("Saving FAILED lesson attempt progress (score/duration only).");
     }

     try {
      await progressRef.set(progressData, SetOptions(merge: true));
      print("Lesson progress update saved successfully!");
     } catch (e) {
       print("Error saving lesson progress: $e");
       if(mounted){
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error saving progress: $e"), duration: const Duration(seconds: 2))
          );
       }
     }
  }

   String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }

  Future<void> _showFeedbackDialog(double score, int stars, Duration duration) async {
    if (!mounted) return;

    final bool passed = stars > 0;
    final String titleText = passed ? "Lesson Complete!" : "Try Again!";
    final int correctCount = (score * widget.lesson.tasks.length).round();
    final int totalTasks = widget.lesson.tasks.length;
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final Color onSurfaceColor = colorScheme.onSurface; 

    Widget content;
    List<Widget> actions;

    if (passed) {
      content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row( mainAxisAlignment: MainAxisAlignment.center, children: List.generate(3, (index) => Icon( index < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 40,))),
            const SizedBox(height: 16),
            Text("You got $correctCount out of $totalTasks correct.", textAlign: TextAlign.center, style: TextStyle(color: onSurfaceColor)),
            Text("Score: ${(score * 100).toStringAsFixed(0)}%", style: textTheme.titleMedium?.copyWith(color: onSurfaceColor)),
            const SizedBox(height: 8),
            Text("Time: ${_formatDuration(duration)}", style: textTheme.bodyMedium?.copyWith(color: onSurfaceColor)),
          ],
        );
       actions = <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: onSurfaceColor), 
              child: const Text('Retry Lesson'),
              onPressed: () { Navigator.of(context).pop(); _resetLesson(); },
            ),
            ElevatedButton( 
              child: const Text('Continue'),
              onPressed: () { Navigator.of(context).pop(); if (Navigator.canPop(context)) { Navigator.of(context).pop(); } },
            ),
          ];
    } else {
       content = Column(
          mainAxisSize: MainAxisSize.min,
          children: [
             Icon(Icons.sentiment_dissatisfied_outlined, color: Colors.red.shade700, size: 40),
             const SizedBox(height: 16),
             Text("You got $correctCount out of $totalTasks correct.", textAlign: TextAlign.center, style: TextStyle(color: onSurfaceColor)),
             Text("You need at least 50% to pass this lesson.", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold, color: onSurfaceColor)),
             const SizedBox(height: 8),
             Text("Time: ${_formatDuration(duration)}", style: textTheme.bodyMedium?.copyWith(color: onSurfaceColor)),
          ],
        );
        actions = <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: onSurfaceColor), 
              child: const Text('Back to Lessons'),
              onPressed: () { Navigator.of(context).pop(); if (Navigator.canPop(context)) { Navigator.of(context).pop(); } },
            ),
            ElevatedButton( 
              child: const Text('Retry Lesson'),
              onPressed: () { Navigator.of(context).pop(); _resetLesson(); },
            ),
          ];
    }

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(titleText, style: TextStyle(color: onSurfaceColor)), 
          content: content, 
          actions: actions,
        );
      },
    );
  }

   void _resetLesson() {
    setState(() {
      _currentTaskIndex = 0;
      _userAnswers = List<dynamic>.filled(widget.lesson.tasks.length, null);
      _lessonCompleted = false;
      _startTime = DateTime.now();
    });
  }

  Future<void> _showExitConfirmationDialog() async {
    
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    final bool? exitConfirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          
          title: Text('Exit Lesson?', style: TextStyle(color: onSurfaceColor)), 
          content: Text( 
            'Are you sure you want to exit? Your progress in this lesson will not be saved.',
            style: TextStyle(color: onSurfaceColor),
          ),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(foregroundColor: onSurfaceColor), 
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade700),
              child: const Text('Exit'),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
            ),
          ],
        );
      },
    );
        if (exitConfirmed == true && mounted) { Navigator.of(context).pop(); }
    }

  @override
  Widget build(BuildContext context) {
    final Task currentTask = widget.lesson.tasks[_currentTaskIndex];
    final bool isLastTask = _currentTaskIndex == widget.lesson.tasks.length - 1;

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 16.0),
        child: Column(
          children: [
            Row(
               mainAxisAlignment: MainAxisAlignment.spaceBetween,
               crossAxisAlignment: CrossAxisAlignment.center,
               children: [
                   Text( "Task ${_currentTaskIndex + 1} of ${widget.lesson.tasks.length}", style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),),
                   IconButton( icon: const Icon(Icons.close), tooltip: 'Exit Lesson', iconSize: 28, visualDensity: VisualDensity.compact, onPressed: _showExitConfirmationDialog,)
               ],
            ),
             Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: LinearProgressIndicator( value: (_currentTaskIndex + 1) / widget.lesson.tasks.length, backgroundColor: Colors.grey.shade300, minHeight: 6,),
             ),
            Expanded(
              child: SingleChildScrollView(
                child: currentTask.buildTaskWidget( context, _userAnswers[_currentTaskIndex], _handleAnswerSelected,),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: _lessonCompleted ? null : _onContinuePressed,
                style: ElevatedButton.styleFrom( minimumSize: const Size(double.infinity, 48), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
                child: Text(isLastTask ? 'Finish Lesson' : 'Check / Next'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}