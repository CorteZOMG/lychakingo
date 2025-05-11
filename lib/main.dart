import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:lychakingo/features/intro/intro_screen.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    
    const Color scaffoldBackgroundColor = Color(0xFF66AB68); 
    const Color appBarBackgroundColor = Color(0xFF74C476);   
    const Color onPrimaryAndAppBarColor = Colors.white;     
    const Color onBackgroundTextColor = Colors.white;       
    final Color surfaceColor = Colors.green.shade50; 
    const Color onSurfaceTextColor = Colors.black87;      

    return MaterialApp(
      title: 'Lychakingo',
      home: const IntroScreen(), 
      debugShowCheckedModeBanner: false,

      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: scaffoldBackgroundColor,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appBarBackgroundColor, 
          brightness: Brightness.light,     
        ).copyWith(
          
          primary: appBarBackgroundColor,       
          onPrimary: onPrimaryAndAppBarColor, 
          background: scaffoldBackgroundColor,    
          onBackground: onBackgroundTextColor,  
          surface: surfaceColor,              
          onSurface: onSurfaceTextColor,       
          error: Colors.red.shade400,
          onError: Colors.white,
        ),
        
        appBarTheme: AppBarTheme(
          backgroundColor: appBarBackgroundColor,
          foregroundColor: onPrimaryAndAppBarColor, 
          iconTheme: const IconThemeData(color: onPrimaryAndAppBarColor), 
          actionsIconTheme: const IconThemeData(color: onPrimaryAndAppBarColor), 
        ),
        
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: appBarBackgroundColor, 
            foregroundColor: onPrimaryAndAppBarColor, 
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: onPrimaryAndAppBarColor, 
          )
        ),

        textTheme: Theme.of(context).textTheme.apply(
          bodyColor: onBackgroundTextColor,
          displayColor: onBackgroundTextColor,
        ).copyWith(
          
          titleMedium: TextStyle(color: onBackgroundTextColor.withOpacity(0.9)),
          bodySmall: TextStyle(color: onBackgroundTextColor.withOpacity(0.7)),
        ),
        
        iconTheme: const IconThemeData(
          color: onBackgroundTextColor, 
        ),
        
        cardTheme: CardTheme(
          color: surfaceColor, 
          elevation: 1.0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
        ),

        dialogTheme: DialogTheme(
          backgroundColor: surfaceColor,
          titleTextStyle: TextStyle(color: onSurfaceTextColor, fontSize: 20, fontWeight: FontWeight.bold),
          contentTextStyle: TextStyle(color: onSurfaceTextColor, fontSize: 16),
        ),
        
        bottomNavigationBarTheme: BottomNavigationBarThemeData(
          backgroundColor: appBarBackgroundColor.withOpacity(0.95), 
          selectedItemColor: onPrimaryAndAppBarColor,
          unselectedItemColor: onPrimaryAndAppBarColor.withOpacity(0.7),
          type: BottomNavigationBarType.fixed,
        ),
      ),     
    );
  }
}