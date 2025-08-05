import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'package:we_decor_enquiries/core/services/firebase_auth_service.dart';
import 'package:we_decor_enquiries/core/services/fcm_service.dart';
import 'package:we_decor_enquiries/features/auth/presentation/screens/login_screen.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:we_decor_enquiries/shared/seed_data.dart';

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
/// 
/// Example usage:
/// ```dart
/// void main() async {
///   // This function is called automatically when the app starts
/// }
/// ```
void main() async {
  // Ensure Flutter bindings are initialized before using any Flutter services
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase Core services with platform-specific options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Seed data for admin debug runs (optional)
  // Uncomment the following lines to seed data on app startup
  // await _seedDataForDebug();
  
  // Launch the application with Riverpod provider scope
  runApp(const ProviderScope(child: MyApp()));
}

/// Seeds data for admin debug runs
/// 
/// This function can be called manually or uncommented in main()
/// to populate the database with initial data for testing.
Future<void> _seedDataForDebug() async {
  try {
    print('🌱 Seeding data for debug run...');
    
    final firestore = FirebaseFirestore.instance;
    final auth = FirebaseAuth.instance;
    
    // Connect to emulator if running locally
    if (const bool.fromEnvironment('USE_FIRESTORE_EMULATOR')) {
      firestore.useFirestoreEmulator('localhost', 8080);
      print('📡 Connected to Firestore emulator for seeding');
    }
    
    // Seed all data
    await seedAllData(firestore, auth: auth);
    
    print('✅ Debug data seeding completed!');
  } catch (e) {
    print('❌ Error during debug data seeding: $e');
    // Don't rethrow - seeding failure shouldn't prevent app from running
  }
}

/// Main application widget that handles authentication-based navigation.
/// 
/// This widget is the root of the application's widget tree and manages
/// the overall app structure. It listens to authentication state changes
/// and navigates users to the appropriate screen based on their
/// authentication status.
/// 
/// The app uses Material Design 3 with a blue-green color scheme and
/// implements role-based navigation:
/// - Authenticated users are directed to the [DashboardScreen]
/// - Unauthenticated users are directed to the [LoginScreen]
/// - Loading and error states are handled with appropriate UI feedback
/// 
/// Example usage:
/// ```dart
/// runApp(const ProviderScope(child: MyApp()));
/// ```
class MyApp extends ConsumerWidget {
  /// Creates a [MyApp] widget.
  /// 
  /// The [key] parameter is passed to the superclass constructor.
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch authentication state changes
    final authState = ref.watch(authStateProvider);

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
          background: const Color(0xFFFFFFFF), // White
          error: const Color(0xFFDC2626), // Red
          onPrimary: const Color(0xFFFFFFFF), // White
          onSecondary: const Color(0xFFFFFFFF), // White
          onSurface: const Color(0xFF1E293B), // Dark gray
          onBackground: const Color(0xFF1E293B), // Dark gray
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFF059669),
          foregroundColor: Color(0xFFFFFFFF),
        ),
        cardTheme: const CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(12)),
          ),
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
      home: authState.when(
        data: (state) {
          // Navigate based on authentication state
          switch (state) {
            case AuthState.authenticated:
              return const DashboardScreen();
            case AuthState.unauthenticated:
              return const LoginScreen();
            case AuthState.loading:
              return const _LoadingScreen();
          }
        },
        loading: () => const _LoadingScreen(),
        error: (error, stack) => _ErrorScreen(error: error),
      ),
    );
  }
}

/// Loading screen displayed while determining the user's authentication state.
/// 
/// This screen is shown during app startup while the authentication state
/// is being determined, or when the authentication state is explicitly
/// in a loading state. It provides visual feedback to users that the
/// app is working and not frozen.
/// 
/// The screen displays:
/// - We Decor Enquiries branding
/// - A loading indicator
/// - Consistent styling with the app's theme
/// 
/// This is a private widget (prefixed with underscore) as it's only used
/// internally within this file.
class _LoadingScreen extends StatelessWidget {
  /// Creates a [_LoadingScreen] widget.
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/branding with gradient
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF2563EB), // Blue
                    Color(0xFF059669), // Green
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.home,
                size: 60,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const SizedBox(height: 32),
            // App title
            const Text(
              'We Decor Enquiries',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E293B),
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Event Management System',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 48),
            // Loading indicator
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2563EB)),
              strokeWidth: 3,
            ),
            const SizedBox(height: 24),
            const Text(
              'Loading...',
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF64748B),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Error screen displayed when authentication state cannot be determined.
/// 
/// This screen is shown when there's an error determining the user's
/// authentication state, such as network issues or Firebase service
/// unavailability. It provides users with information about the error
/// and an option to retry or navigate to the login screen.
/// 
/// The screen displays:
/// - Error icon and title
/// - Detailed error message
/// - Retry button that navigates to login screen
/// 
/// This is a private widget (prefixed with underscore) as it's only used
/// internally within this file.
class _ErrorScreen extends StatelessWidget {
  /// Creates an [_ErrorScreen] widget.
  /// 
  /// The [error] parameter contains the error that occurred during
  /// authentication state determination.
  const _ErrorScreen({required this.error});

  /// The error that occurred during authentication state determination.
  /// 
  /// This error is displayed to the user to help them understand
  /// what went wrong and potentially report the issue.
  final Object error;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon with gradient background
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFFDC2626), // Red
                      Color(0xFFEF4444), // Light red
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Color(0xFFFFFFFF),
                ),
              ),
              const SizedBox(height: 32),
              // Error title
              const Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),
              // Error details
              Text(
                error.toString(),
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Retry button
              ElevatedButton(
                onPressed: () {
                  // Navigate to login screen as a fallback
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute<void>(
                      builder: (context) => const LoginScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  foregroundColor: const Color(0xFFFFFFFF),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Try Again',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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
