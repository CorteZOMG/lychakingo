import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              
              Image.asset(
                'assets/images/wave_chibi.png', 
                height: screenHeight * 0.3, 
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 24),              
              Text(
                'Welcome back!', 
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'Ready to learn something new?',
                 style: Theme.of(context).textTheme.bodyLarge,
                 textAlign: TextAlign.center,
              ),              
            ],
          ),
        ),
      ),
    );
  }
}