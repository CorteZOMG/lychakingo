import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:lychakingo/features/translator/ui/screens/translation_screen.dart';
import 'package:lychakingo/features/ai_tutor/ui/screens/ai_qa_screen.dart';
import 'package:lychakingo/features/lessons/ui/screens/lesson_list_screen.dart';
import 'package:lychakingo/features/home/ui/screens/home_screen.dart'; 

class MainAppShell extends StatefulWidget {
  const MainAppShell({super.key});

  @override
  State<MainAppShell> createState() => _MainAppShellState();
}

class _MainAppShellState extends State<MainAppShell> {
  int _selectedIndex = 0;

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const List<Widget> _widgetOptions = <Widget>[
    HomeScreen(),      
    AiQaScreen(),         
    TranslationScreen(),  
    LessonListScreen(),   
  ];

   static const List<String> _appBarTitles = <String>[
    'Home',             
    'Ask AI Tutor',     
    'Translator',       
    'Lessons',          
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _signOut(BuildContext context) async {
    if (_scaffoldKey.currentState?.isEndDrawerOpen ?? false) {
       Navigator.of(context).pop(); 
    }
    await Future.delayed(const Duration(milliseconds: 100)); 

    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Successfully logged out!')),
        );
      }
    } catch (e) {
      print('Error signing out: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  Widget _buildEndDrawer(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser; 

    return Drawer(
      child: Column( 
          children: [
            Expanded( 
              child: ListView(
                padding: EdgeInsets.zero, 
                children: [

                  UserAccountsDrawerHeader(
                    accountName: null, 
                    accountEmail: Text(currentUser?.email ?? "Not logged in"),
                    currentAccountPicture: CircleAvatar(
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                          Icons.person_outline,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                       ),
                    ),
                    decoration: BoxDecoration(
                       color: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(), 
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                _signOut(context); 
              },
            ),
             SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
       ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, 
      appBar: AppBar(
        title: Text(_appBarTitles[_selectedIndex]),
         automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu), 
            tooltip: 'User Menu',
            onPressed: () {
              _scaffoldKey.currentState?.openEndDrawer();
            },
          ),
        ],
      ),

      endDrawer: _buildEndDrawer(context),
      body: IndexedStack( 
         index: _selectedIndex,
         children: _widgetOptions,
      ),

      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
           BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
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
          BottomNavigationBarItem(
            icon: Icon(Icons.school_outlined),
            activeIcon: Icon(Icons.school),
            label: 'Lessons',
          ),
        ],
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
      ),
      // ------------------------------------------------------
    );
  }
}