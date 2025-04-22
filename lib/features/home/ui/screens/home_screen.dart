import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart'; 

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
      body: Center(
        child: Image.asset(
          'assets/images/wave_chibi.png', 
           width: 200,
           height: 200,
           fit: BoxFit.contain,
        ),
      ),
    );
  }
}
