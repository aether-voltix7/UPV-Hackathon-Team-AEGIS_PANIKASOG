import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/constants/colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/landing_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'firebase_options.dart'; 
import 'providers/post_provider.dart';
import 'services/post_service.dart';
import 'providers/task_provider.dart';
import 'services/task_service.dart';
import 'providers/location_provider.dart';
import 'providers/google_maps_provider.dart';
import 'screens/home/example_maps_screen.dart';
import 'screens/auth/google_sign_in_example.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform, // ← UNCOMMENT this line
  );
  runApp(const PanikasogApp());
}

class PanikasogApp extends StatelessWidget {
  const PanikasogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Auth & Core
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        // Posts & Tasks
        ChangeNotifierProvider(create: (_) => PostProvider(PostService())),
        ChangeNotifierProvider(create: (_) => TaskProvider(TaskService())),
        // Location & Maps
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => GoogleMapsProvider()),
      ],
      child: MaterialApp(
        title: 'PANIKASOG',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const _AppEntry(),
        routes: {
          '/home': (_) => const MainScreen(),
          '/landing': (_) => const LandingScreen(),
          '/profile': (_) => const ProfileScreen(),
          '/settings': (_) => const SettingsScreen(),
          // Google APIs
          '/map': (_) => const ExampleMapsScreen(),
          '/google-sign-in': (_) => const GoogleSignInScreen(),
        },
      ),
    );
  }
}

class _AppEntry extends StatelessWidget {
  const _AppEntry();
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    switch (auth.status) {
      case AuthStatus.authenticated:
        return const MainScreen();
      case AuthStatus.unauthenticated:
      case AuthStatus.error:
        return const LandingScreen();
      default:
        return const _SplashScreen();
    }
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity, height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: AppColors.splashGradient,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
            child: const Icon(Icons.directions_run, color: Colors.white, size: 44),
          ),
          const SizedBox(height: 16),
          const Text('PANIKASOG', style: TextStyle(fontFamily: 'Poppins', fontSize: 28, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 2)),
          const SizedBox(height: 8),
          Text('Community Disaster Response', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Colors.white.withValues(alpha: 0.8), letterSpacing: 0.5)),
          const SizedBox(height: 40),
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
        ]),
      ),
    );
  }
}
