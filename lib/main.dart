import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:lychakingo/features/intro/intro_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp()); 
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    return MaterialApp(
      title: 'lychakingo',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light, 
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green), 
      ),
      themeMode: ThemeMode.light, 
      home: const IntroScreen(), 
      debugShowCheckedModeBanner: false,
    );
  }
}