import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final textTheme = Theme.of(context).textTheme; 

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/backgrounds/lychakingo_bg.png'), 
          fit: BoxFit.cover, 
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 100), 
              Image.asset(
                'assets/images/wave_chibi.webp', 
                height: screenHeight * 0.5, 
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
              
              Card(
                color: Colors.white, 
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0), 
                ),
                  margin: const EdgeInsets.only(top: 20.0, left: 16.0, right: 16.0),                
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0), 
                  child: Column(
                    mainAxisSize: MainAxisSize.min, 
                    children: [
                      Text(
                        "Радий вас бачити!", 
                        style: textTheme.headlineSmall?.copyWith(
                          color: Colors.black, 
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Готові до нових знань?", 
                         style: textTheme.bodyLarge?.copyWith(
                          color: Colors.black, 
                         ),
                         textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),              
            ],
          ),
        ),
      ),
    );
  }
}