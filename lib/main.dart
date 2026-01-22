import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_config.dart';
import 'core/config/firebase_config.dart';
import 'core/notifications/fcm_bootstrap.dart';
import 'core/services/update_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/appearance_controller.dart';
import 'features/auth/presentation/widgets/auth_gate.dart';
import 'firebase_options.dart';
import 'utils/logger.dart';

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
    Log.i('Firebase initialized');
  }

  // Configure Firestore offline persistence
  // Web: Persistence is automatic via IndexedDB, cache size can be configured
  // Mobile: Explicitly enable persistence with cache size limit
  try {
    final firestore = FirebaseFirestore.instance;
    const cacheSizeBytes = 100 * 1024 * 1024; // 100MB cache limit

    if (kIsWeb) {
      // Web: Persistence is automatic, just set cache size for better offline support
      firestore.settings = const Settings(cacheSizeBytes: cacheSizeBytes);
      Log.i('Firestore web persistence configured (100MB cache)');
    } else {
      // Mobile: Enable persistence with 100MB cache limit
      firestore.settings = const Settings(persistenceEnabled: true, cacheSizeBytes: cacheSizeBytes);
      Log.i('Firestore mobile persistence enabled (100MB cache)');
    }
  } catch (e, st) {
    // Persistence may fail if already initialized or on unsupported platforms
    // Log but don't crash - app will work without offline persistence
    Log.w('Firestore persistence configuration failed', data: {'error': e.toString()});
    if (kDebugMode) {
      Log.d('Firestore persistence error details', data: st.toString());
    }
  }

  // Configure Crashlytics (gated by environment)
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
      kReleaseMode && AppConfig.enableCrashlytics,
    );
  }

  // Configure Performance Monitoring (gated by environment)
  if (!kIsWeb) {
    await FirebasePerformance.instance.setPerformanceCollectionEnabled(
      kReleaseMode && AppConfig.enablePerformance,
    );
  }

  // Global error handlers (only in release with Crashlytics enabled)
  if (!kIsWeb && kReleaseMode && AppConfig.enableCrashlytics) {
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterFatalError(details);
    };
  }

  // Security check for environment variables
  if (kDebugMode) {
    Log.w('Firebase security warning', data: FirebaseConfig.securityWarning);
    Log.d(
      'Runtime configuration',
      data: {
        'env': AppConfig.env,
        'analyticsEnabled': AppConfig.enableAnalytics,
        'crashlyticsEnabled': AppConfig.enableCrashlytics,
        'performanceEnabled': AppConfig.enablePerformance,
      },
    );
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
        Log.e('Unhandled zone error', error: error, stackTrace: stack);
      }
    },
  );
}

/// Custom scroll behavior that disables interactive scrollbars on web
/// to prevent ScrollController conflicts with nested scrollable widgets
class NoScrollbarScrollBehavior extends ScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.trackpad,
  };

  @override
  Widget buildScrollbar(BuildContext context, Widget child, ScrollableDetails details) {
    // Disable scrollbars on web to prevent conflicts with nested scrollables
    if (kIsWeb) {
      return child;
    }
    return super.buildScrollbar(context, child, details);
  }

  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // Use glow effect instead of stretch on web
    if (kIsWeb) {
      return child;
    }
    return super.buildOverscrollIndicator(context, child, details);
  }
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
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'We Decor Enquiries',
      theme: AppTheme.lightTheme.copyWith(
        scrollbarTheme: ScrollbarThemeData(
          // Disable interactive scrollbars on web to prevent conflicts
          interactive: !kIsWeb,
        ),
      ),
      darkTheme: AppTheme.darkTheme.copyWith(
        scrollbarTheme: ScrollbarThemeData(
          // Disable interactive scrollbars on web to prevent conflicts
          interactive: !kIsWeb,
        ),
      ),
      scrollBehavior: NoScrollbarScrollBehavior(),
      themeMode: themeMode,
      home: const AuthGate().withUpdateChecker(),
      debugShowCheckedModeBanner: false,
    );
  }
}
