import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/firebase_config.dart';
import 'core/notifications/fcm_bootstrap.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'firebase_options.dart';

/// Main entry point for the We Decor Enquiries application.
///
/// This function initializes the Flutter application and sets up all
/// necessary services before launching the app. It performs the following
/// initialization steps:
///
/// 1. Ensures Flutter bindings are initialized
/// 2. Initializes Firebase Core services
/// 3. Sets up Firebase Cloud Messaging (FCM) for notifications
/// 4. Launches the main application with Riverpod provider scope
///
/// The application uses Riverpod for state management and Firebase for
/// backend services including authentication, database, and messaging.
void main() async {
  // Ensure Flutter bindings are initialized before using any Flutter services
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core services with platform-specific options
  // Check if Firebase is already initialized to prevent duplicate app error
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('🔥 Firebase initialized successfully');
  } else {
    print('🔥 Firebase already initialized, using existing app');
  }

  // Security check for environment variables
  if (kDebugMode) {
    print(FirebaseConfig.securityWarning);
  }

  // Launch the application with Riverpod provider scope and FCM bootstrap
  runApp(const ProviderScope(child: FcmBootstrap(child: MyApp())));
}

/// Main application widget that handles authentication-based navigation.
///
/// This widget is the root of the application's widget tree and manages
/// the overall app structure. It uses Material Design 3 with a blue-green
/// color scheme and implements role-based navigation through AuthGate.
class MyApp extends ConsumerWidget {
  /// Creates a [MyApp] widget.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'We Decor Enquiries',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB), // Blue
          brightness: Brightness.light,
          primary: const Color(0xFF2563EB), // Blue
          secondary: const Color(0xFF059669), // Green
          tertiary: const Color(0xFFF59E0B), // Amber
          surface: const Color(0xFFF8FAFC), // Light gray
          error: const Color(0xFFDC2626), // Red
          onPrimary: const Color(0xFFFFFFFF), // White
          onSecondary: const Color(0xFFFFFFFF), // White
          onSurface: const Color(0xFF1E293B), // Dark gray
        ),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2563EB),
          foregroundColor: Color(0xFFFFFFFF),
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2563EB),
            foregroundColor: const Color(0xFFFFFFFF),
            elevation: 2,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF059669),
          foregroundColor: Color(0xFFFFFFFF),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
          color: Color(0xFFFFFFFF),
        ),
        inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFF2563EB), width: 2),
          ),
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
        ),
      ),
      home: const AuthGate(),
    );
  }
}
