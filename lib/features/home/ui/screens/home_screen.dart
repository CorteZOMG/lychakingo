import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:lychakingo/features/ai_tutor/ui/screens/ai_qa_screen.dart'; // Adjust path if needed

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await FirebaseAuth.instance.signOut();
      if (context.mounted) { 
          ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Successfully logged out!')),
          );
      }
    } catch (e) {
      print('Error signing out: $e');
       if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Error logging out: $e')),
          );
       }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'),
        automaticallyImplyLeading: false, 
        actions: [ 
          IconButton(
            icon: const Icon(Icons.logout), 
            tooltip: 'Logout', 
            onPressed: () {
              _signOut(context);
            },
          ),
        ],
      ),
      body: Padding( 
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column( 
            mainAxisAlignment: MainAxisAlignment.center, 
            children: [
              Image.asset(
                'assets/images/wave_chibi.png', 
                width: 300, 
                height: 300,
                fit: BoxFit.contain, 
              ),
              const SizedBox(height: 30), 

              ElevatedButton.icon(
                icon: const Icon(Icons.psychology_outlined), 
                label: const Text('Ask Artem Lychak AI'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AiQaScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  textStyle: const TextStyle(fontSize: 16)
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
