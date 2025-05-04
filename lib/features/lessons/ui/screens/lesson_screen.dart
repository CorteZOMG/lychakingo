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

  @override
  void initState() {
    super.initState(); 
    _userAnswers = List<dynamic>.filled(widget.lesson.tasks.length, null);
  }
  
  void _handleAnswerSelected(dynamic answer) {
    
    setState(() {
      _userAnswers[_currentTaskIndex] = answer;
      print("Answer for task $_currentTaskIndex stored: $answer"); 
    });
    
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
      setState(() {
        _currentTaskIndex++;
      });
    } else {
      
      _completeLesson();
    }
  }

  void _completeLesson() {
    if (_lessonCompleted) return; 

    setState(() { _lessonCompleted = true; }); 

    print("Lesson completed!");
    int correctCount = 0;
    for (int i = 0; i < widget.lesson.tasks.length; i++) {
      bool isCorrect = widget.lesson.tasks[i].isAnswerCorrect(_userAnswers[i]);
      print("Task $i: Answer ${_userAnswers[i]}, Correct? $isCorrect");
      if (isCorrect) {
        correctCount++;
      }
    }

    double score = widget.lesson.tasks.isEmpty ? 1.0 : correctCount / widget.lesson.tasks.length;
    int stars = widget.lesson.calculateStars(score);

    print("Score: $score (${correctCount}/${widget.lesson.tasks.length}), Stars: $stars");    
    _saveLessonProgress(score, stars);
    _showFeedbackDialog(score, stars);
  }
  
  Future<void> _saveLessonProgress(double score, int stars) async {
    if (userId == null) {
      print("Error saving progress: User not logged in.");
      return;
    }

    final progressRef = FirebaseFirestore.instanceFor(app: Firebase.app(), databaseId: 'main-db')
        .collection('userProgress')
        .doc(userId)
        .collection('lessonProgress')
        .doc(widget.lesson.id); 

    try {
      
      await progressRef.set({
        'status': LessonStatus.completed.toJson(), 
        'lastScore': score,
        'stars': stars,
        'completedTimestamp': FieldValue.serverTimestamp(), 
        'updatedTimestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); 
      print("Lesson progress saved successfully!");
    } catch (e) {
      print("Error saving lesson progress: $e");
       if(mounted){
         ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text("Error saving progress: $e"), duration: const Duration(seconds: 2))
          );
       }
    }
  }

  Future<void> _showFeedbackDialog(double score, int stars) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      barrierDismissible: false, 
      builder: (BuildContext dialogContext) {
        int correctCount = (score * widget.lesson.tasks.length).round();
        int totalTasks = widget.lesson.tasks.length;

        return AlertDialog(
          title: const Text("Lesson Complete!"),
          content: Column(
            mainAxisSize: MainAxisSize.min, 
            children: [
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) => Icon(
                  index < stars ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 40,
                )),
              ),
              const SizedBox(height: 16),
              Text("You got $correctCount out of $totalTasks correct.", textAlign: TextAlign.center),
              Text("Score: ${(score * 100).toStringAsFixed(0)}%", style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Retry Lesson'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                _resetLesson(); 
              },
            ),
            ElevatedButton(
              child: const Text('Continue'),
              onPressed: () {
                Navigator.of(dialogContext).pop(); 
                
                if (Navigator.canPop(context)) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        );
      },
    );
  }
  
   void _resetLesson() {
    setState(() {
      _currentTaskIndex = 0;
      _userAnswers = List<dynamic>.filled(widget.lesson.tasks.length, null);
      _lessonCompleted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    
    final Task currentTask = widget.lesson.tasks[_currentTaskIndex];
    final bool isLastTask = _currentTaskIndex == widget.lesson.tasks.length - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.lesson.title),
        
        bottom: PreferredSize(
           preferredSize: const Size.fromHeight(4.0),
           child: LinearProgressIndicator(
              value: (_currentTaskIndex + 1) / widget.lesson.tasks.length,
              backgroundColor: Colors.grey.shade300,
           ),
        )
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            
            Text(
              "Task ${_currentTaskIndex + 1} of ${widget.lesson.tasks.length}",
              style: Theme.of(context).textTheme.titleSmall?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            Expanded(
              child: SingleChildScrollView( 
                child: currentTask.buildTaskWidget(
                  context,
                  _userAnswers[_currentTaskIndex], 
                  _handleAnswerSelected,           
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.only(top: 16.0),
              child: ElevatedButton(
                onPressed: _lessonCompleted ? null : _onContinuePressed, 
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48), 
                   textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                child: Text(isLastTask ? 'Finish Lesson' : 'Check / Next'), 
              ),
            ),
          ],
        ),
      ),
    );
  }
}