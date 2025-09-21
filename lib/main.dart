import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_config.dart';
import 'core/config/firebase_config.dart';
import 'core/notifications/fcm_bootstrap.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/appearance_controller.dart';
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
/// Bootstrap function for Firebase and monitoring setup
Future<void> _bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase Core services
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    print('🔥 Firebase initialized successfully');
  }

  // Configure Crashlytics (gated by environment)
  await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
    kReleaseMode && AppConfig.enableCrashlytics,
  );

  // Configure Performance Monitoring (gated by environment)
  await FirebasePerformance.instance.setPerformanceCollectionEnabled(
    kReleaseMode && AppConfig.enablePerformance,
  );

  // Global error handlers (only in release with Crashlytics enabled)
  if (kReleaseMode && AppConfig.enableCrashlytics) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
  }

  // Security check for environment variables
  if (kDebugMode) {
    print(FirebaseConfig.securityWarning);
    print('🔧 Environment: ${AppConfig.env}');
    print('📊 Analytics: ${AppConfig.enableAnalytics}');
    print('💥 Crashlytics: ${AppConfig.enableCrashlytics}');
    print('⚡ Performance: ${AppConfig.enablePerformance}');
  }
}

void main() {
  runZonedGuarded(
    () async {
      await _bootstrap();
      runApp(const ProviderScope(child: FcmBootstrap(child: MyApp())));
    },
    (error, stack) {
      // Catch any errors not handled by Flutter framework
      if (kReleaseMode && AppConfig.enableCrashlytics) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      } else {
        debugPrint('Unhandled error: $error\n$stack');
      }
    },
  );
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
    final currentTheme = ref.watch(currentThemeProvider);
    
    return ThemeContextProvider(
      child: MaterialApp(
        title: 'We Decor Enquiries',
        theme: currentTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const AuthGate(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
