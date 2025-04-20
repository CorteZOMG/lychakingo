import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main Screen'), // Temporary title
        automaticallyImplyLeading: false, 
      ),
      body: Center( 
        child: Image.asset(
          'assets/images/wave_chibi.png', 
        ),
      ),
    );
  }
}