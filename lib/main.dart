import 'package:flutter/material.dart';
import 'package:lychakingo/features/intro/intro_screen.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'lychakingo',
      home: IntroScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
