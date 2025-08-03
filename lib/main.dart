import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:we_decor_enquiries/core/services/firebase_auth_service.dart';
import 'package:we_decor_enquiries/core/services/fcm_service.dart';
import 'package:we_decor_enquiries/features/auth/presentation/screens/login_screen.dart';
import 'package:we_decor_enquiries/features/dashboard/presentation/screens/dashboard_screen.dart';

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
  
  // Initialize Firebase Core services
  await Firebase.initializeApp();
  
  // Initialize Firebase Cloud Messaging for push notifications
  final container = ProviderContainer();
  await container.read(fcmServiceProvider).initialize();
  container.dispose();
  
  // Launch the application with Riverpod provider scope
  runApp(const ProviderScope(child: MyApp()));
}

/// Main application widget that handles authentication-based navigation.
/// 
/// This widget is the root of the application's widget tree and manages
/// the overall app structure. It listens to authentication state changes
/// and navigates users to the appropriate screen based on their
/// authentication status.
/// 
/// The app uses Material Design 3 with a deep purple color scheme and
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
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
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/branding
            Icon(
              Icons.home,
              size: 80,
              color: Colors.deepPurple,
            ),
            SizedBox(height: 24),
            // App title
            Text(
              'We Decor Enquiries',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.deepPurple,
              ),
            ),
            SizedBox(height: 32),
            // Loading indicator
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.deepPurple),
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
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error icon
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 24),
              // Error title
              const Text(
                'Authentication Error',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              // Error details
              Text(
                error.toString(),
                style: const TextStyle(color: Colors.grey),
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
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
