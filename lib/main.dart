import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
// Note: Removed my_app/firebase_options.dart import for portability
import 'package:flutter/services.dart'; // Used for setting status bar style
import 'package:my_app/screens/splash_screen.dart';
import 'firebase_options.dart';
import 'package:provider/provider.dart';
import 'package:my_app/theme_provider.dart';
import 'package:my_app/providers/favorites_provider.dart';
import 'package:my_app/services/data_seeder.dart';

// Note: Removed my_app/firebase_options.dart import for portability
// Used for setting status bar style

import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (for image storage)
  await Supabase.initialize(
    url: 'https://msvsekcfgjbsvnxrdztt.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdnNla2NmZ2pic3ZueHJkenR0Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzE4MjgwMTYsImV4cCI6MjA4NzQwNDAxNn0.YlWc-5EXl_cCI4ee0f52A92vOpEya-zLq6y19SnBObQ',
  );

  // Initialize Firebase using default configuration (necessary for auth)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Seed initial data to Firestore (safe to call multiple times as it checks for existing docs)
  try {
    await DataSeeder.seedData();
  } catch (e) {
    debugPrint('Data seeding skipped or failed: $e');
  }

  // Set system UI to be transparent for modern full-screen splash look
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, child) {
        return MaterialApp(
          title: 'Kandy Go',
          debugShowCheckedModeBanner: false,
          theme: themeProvider.isDarkMode
              ? themeProvider.darkTheme
              : themeProvider.lightTheme,
          home: const SplashScreen(),
        );
      },
    );
  }
}
