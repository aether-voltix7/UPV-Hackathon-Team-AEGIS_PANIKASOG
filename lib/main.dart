import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';
import 'core/constants/colors.dart';
import 'core/theme/app_theme.dart';
import 'providers/auth_provider.dart';
import 'services/auth_service.dart';
import 'screens/auth/landing_screen.dart';
import 'screens/main_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/rankings/rankings_screen.dart';
import 'firebase_options.dart';
import 'providers/post_provider.dart';
import 'services/post_service.dart';
import 'providers/task_provider.dart';
import 'services/task_service.dart';
import 'providers/location_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    androidProvider: AndroidProvider.debug,
  );
  // Fix "unknown calling package" SecurityException
  final GoogleMapsFlutterPlatform mapsImplementation =
      GoogleMapsFlutterPlatform.instance;

  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    // Forces  app to register its package name correctly with Google Play Services
    await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }

  runApp(const PanikasogApp());
}

class PanikasogApp extends StatelessWidget {
  const PanikasogApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider(AuthService())),
        ChangeNotifierProvider(create: (_) => PostProvider(PostService())),
        ChangeNotifierProvider(create: (_) => TaskProvider(TaskService())),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
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
          '/rankings': (_) => const RankingsScreen(),
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
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: AppColors.splashGradient,
          ),
        ),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: 80,
            height: 80,
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