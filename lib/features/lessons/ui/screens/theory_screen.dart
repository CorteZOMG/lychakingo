import 'package:flutter/material.dart';
import 'package:lychakingo/features/lessons/domain/models/lesson.dart';
import 'package:lychakingo/features/lessons/ui/screens/lesson_screen.dart';

class TheoryScreen extends StatelessWidget {
  final Lesson lesson; 

  const TheoryScreen({required this.lesson, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        
        title: Text(lesson.theoryTitle),
        
        leading: IconButton(
           icon: const Icon(Icons.arrow_back),
           onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea( 
        child: SingleChildScrollView( 
          child: Padding(
            padding: const EdgeInsets.all(20.0), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, 
              children: [
                
                SelectableText( 
                  lesson.theoryContent,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    height: 1.6, 
                    fontSize: 16, 
                  ),
                ),
                const SizedBox(height: 32), 
                
                ElevatedButton.icon(
                  icon: const Icon(Icons.play_lesson_outlined), 
                  label: const Text('Start Lesson Tasks'),
                  onPressed: () {
                    print("Starting tasks for lesson: ${lesson.title}");
                                                          
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => LessonScreen(lesson: lesson)),
                    );
                    
                  },
                  style: ElevatedButton.styleFrom(
                     padding: const EdgeInsets.symmetric(vertical: 14), 
                     textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                     shape: RoundedRectangleBorder( 
                        borderRadius: BorderRadius.circular(12),
                     ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}