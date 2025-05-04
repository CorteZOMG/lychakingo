import 'package:flutter/material.dart';

// Import existing screens
import 'package:lychakingo/features/translator/ui/screens/translator.dart';
import 'package:lychakingo/features/ai_tutor/ui/screens/ai_qa_screen.dart';
// --- ADD Import for the new Lesson List Screen ---
import 'package:lychakingo/features/lessons/ui/screens/lesson_list_screen.dart'; // Adjust path if needed
// -------------------------------------------------


class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  // Start on the first tab (AI) by default
  int _selectedIndex = 0;

  // --- ADD LessonListScreen to the list of widgets ---
  static const List<Widget> _widgetOptions = <Widget>[
    AiQaScreen(),         // Index 0
    TranslationScreen(),  // Index 1
    LessonListScreen(),   // Index 2 <<< ADDED
  ];
  // --------------------------------------------------

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The body automatically updates based on _selectedIndex
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      // --- Add the third item to the BottomNavigationBar ---
      bottomNavigationBar: BottomNavigationBar(
        // Increase items list
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'AI Tutor',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.translate_outlined),
            activeIcon: Icon(Icons.translate),
            label: 'Translator',
          ),
          // --- New Item for Lessons ---
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined), // Example lesson icon
            activeIcon: Icon(Icons.school),     // Example active lesson icon
            label: 'Lessons',                   // Label for the tab
          ),
          // --------------------------
        ],
        currentIndex: _selectedIndex, // This automatically handles highlighting the correct tab
        // Optional: Customize colors, type, etc.
        // selectedItemColor: Theme.of(context).colorScheme.primary,
        // type: BottomNavigationBarType.fixed, // Good for 3 items
        onTap: _onItemTapped, // This handles index changes correctly
      ),
      // ------------------------------------------------------
    );
  }
}