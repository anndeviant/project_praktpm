import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'firebase_options.dart';
import 'views/splash_screen.dart';
import 'models/favorite_model.dart';
import 'utils/hive_box.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize Hive
  await Hive.initFlutter();

  // Register Hive adapters
  Hive.registerAdapter(FavoriteQuestAdapter());

  // Open Hive boxes
  await Hive.openBox<FavoriteQuest>(HiveBox.favorites);
  // Initialize notification service
  await NotificationService().initialize();

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KKN Quest - Petualangan Mahasiswa',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: const Color(0xFF667eea),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF667eea),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        // Compact text theme for mobile
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.25,
            fontSize: 24, // Reduced from default
          ),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.15,
            fontSize: 20, // Reduced from default
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18, // Reduced from default
          ),
          titleMedium: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16, // Reduced from default
          ),
          bodyLarge: TextStyle(
            letterSpacing: 0.15,
            fontSize: 14, // Reduced from default
          ),
          bodyMedium: TextStyle(
            letterSpacing: 0.25,
            fontSize: 13, // Reduced from default
          ),
          labelLarge: TextStyle(
            fontSize: 14, // Reduced from default
            fontWeight: FontWeight.w500,
          ),
        ),
        // Compact button theme
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 10,
            ), // Reduced padding
            minimumSize: const Size(0, 44), // Reduced minimum height
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            minimumSize: const Size(0, 44),
          ),
        ),
        // Compact card theme
        cardTheme: CardTheme(
          elevation: 3, // Reduced elevation
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ), // Reduced radius
          clipBehavior: Clip.antiAlias,
          margin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ), // Compact margins
        ),
        // Compact AppBar theme
        appBarTheme: const AppBarTheme(
          elevation: 0,
          centerTitle: true,
          foregroundColor: Colors.white,
          titleTextStyle: TextStyle(
            fontSize: 18, // Reduced font size
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
        ),
        // Compact input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ), // Compact padding
          labelStyle: const TextStyle(fontSize: 14),
          hintStyle: const TextStyle(fontSize: 14),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
