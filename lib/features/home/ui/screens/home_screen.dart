import 'package:flutter/material.dart';
import 'package:lychakingo/features/translator/ui/screens/translator.dart';     
import 'package:lychakingo/features/ai_tutor/ui/screens/ai_qa_screen.dart'; 


class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0; 
  static const List<Widget> _widgetOptions = <Widget>[
    AiQaScreen(),         
    TranslationScreen(),  
    
  ];
  
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),

      bottomNavigationBar: BottomNavigationBar(
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
          
        ],
        currentIndex: _selectedIndex,     
        
        onTap: _onItemTapped,             
        
      ),
    );
  }
}