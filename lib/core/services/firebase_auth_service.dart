import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'fcm_service.dart';

/// Custom exception thrown when authentication operations fail.
///
/// This exception provides user-friendly error messages for authentication
/// failures such as invalid credentials, network issues, or Firebase errors.
class AuthException implements Exception {
  /// Creates an [AuthException] with the given error message.
  ///
  /// [message] should be a user-friendly description of what went wrong
  /// during the authentication process.
  const AuthException(this.message);

  /// The user-friendly error message describing the authentication failure.
  ///
  /// This message is suitable for display to end users and explains
  /// what went wrong during the authentication process.
  final String message;
}

/// Service class for handling Firebase Authentication operations.
///
/// This service provides a clean abstraction over Firebase Authentication,
/// handling user sign-in, sign-out, and authentication state management.
/// It also integrates with FCM (Firebase Cloud Messaging) for proper
/// cleanup during sign-out operations.
///
/// Example usage:
/// ```dart
/// final authService = FirebaseAuthService();
/// await authService.signInWithEmailAndPassword(
///   email: 'user@example.com',
///   password: 'password123'
/// );
/// ```
class FirebaseAuthService {
  /// The underlying Firebase Auth instance.
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Gets the currently signed-in user, or null if no user is signed in.
  ///
  /// This getter provides immediate access to the current user without
  /// waiting for authentication state changes.
  ///
  /// Returns:
  /// - [User] if a user is currently signed in
  /// - `null` if no user is signed in
  User? get currentUser => _auth.currentUser;

  /// Stream of authentication state changes.
  ///
  /// This stream emits events whenever the user's authentication state
  /// changes (sign-in, sign-out, token refresh, etc.).
  ///
  /// Returns a [Stream<User?>] that emits:
  /// - [User] when a user signs in
  /// - `null` when a user signs out
  /// - Current user on app startup if already signed in
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Signs in a user with email and password.
  ///
  /// This method attempts to authenticate a user using Firebase Authentication.
  /// If successful, the user will be signed in and the authentication state
  /// will be updated throughout the app.
  ///
  /// Parameters:
  /// - [email]: The user's email address
  /// - [password]: The user's password
  ///
  /// Returns a [Future<UserCredential>] containing the user's credentials
  /// and additional information about the sign-in operation.
  ///
  /// Throws:
  /// - [AuthException] if the sign-in fails (invalid credentials, network error, etc.)
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   final credential = await authService.signInWithEmailAndPassword(
  ///     email: 'user@example.com',
  ///     password: 'password123'
  ///   );
  ///   print('Signed in: ${credential.user?.email}');
  /// } on AuthException catch (e) {
  ///   print('Sign-in failed: ${e.message}');
  /// }
  /// ```
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw AuthException(_handleAuthError(e));
    }
  }

  /// Signs out the current user and cleans up related resources.
  ///
  /// This method performs a complete sign-out operation, including:
  /// - Signing out the user from Firebase Authentication
  /// - Unsubscribing from all FCM topics
  /// - Removing the FCM token from the user's profile
  ///
  /// After calling this method, the user will be signed out and the
  /// authentication state will be updated throughout the app.
  ///
  /// Returns a [Future<void>] that completes when the sign-out is finished.
  ///
  /// Throws:
  /// - [AuthException] if the sign-out process fails
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await authService.signOut();
  ///   print('User signed out successfully');
  /// } on AuthException catch (e) {
  ///   print('Sign-out failed: ${e.message}');
  /// }
  /// ```
  Future<void> signOut() async {
    try {
      // Clean up FCM subscriptions and token before signing out
      final fcmService = FCMService();
      await fcmService.unsubscribeFromAllTopics();
      await fcmService.deleteTokenFromProfile();

      await _auth.signOut();
    } catch (e) {
      throw AuthException(_handleAuthError(e));
    }
  }

  /// Converts Firebase Auth errors to user-friendly error messages.
  ///
  /// This private method handles various Firebase Authentication error codes
  /// and converts them into human-readable messages that can be displayed
  /// to users.
  ///
  /// Parameters:
  /// - [error]: The error object from Firebase Authentication
  ///
  /// Returns a [String] containing a user-friendly error message.
  ///
  /// Supported error codes:
  /// - `user-not-found`: No user found with the provided email
  /// - `wrong-password`: Incorrect password provided
  /// - `invalid-email`: Invalid email address format
  /// - `user-disabled`: User account has been disabled
  /// - `too-many-requests`: Too many failed sign-in attempts
  /// - `operation-not-allowed`: Email/password sign-in is disabled
  String _handleAuthError(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'user-not-found':
          return 'No user found with this email address.';
        case 'wrong-password':
          return 'Incorrect password.';
        case 'invalid-email':
          return 'Invalid email address.';
        case 'user-disabled':
          return 'This account has been disabled.';
        case 'too-many-requests':
          return 'Too many failed attempts. Please try again later.';
        case 'operation-not-allowed':
          return 'Email/password sign in is not enabled.';
        default:
          return 'Authentication failed: ${error.message}';
      }
    }
    return 'An unexpected error occurred.';
  }
}

/// Riverpod provider that creates and provides a [FirebaseAuthService] instance.
///
/// This provider ensures that the authentication service is properly
/// initialized and can be accessed throughout the app using Riverpod.
///
/// Usage:
/// ```dart
/// final authService = ref.read(firebaseAuthServiceProvider);
/// ```
final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService();
});

/// Riverpod provider that streams the current user's authentication state.
///
/// This provider listens to authentication state changes and provides
/// the current user (or null if not authenticated) to all widgets
/// that depend on it.
///
/// Returns a [StreamProvider<User?>] that emits:
/// - [User] when a user is signed in
/// - `null` when no user is signed in
///
/// Usage:
/// ```dart
/// final userAsync = ref.watch(currentUserProvider);
/// userAsync.when(
///   data: (user) => user != null ? Text('Welcome ${user.email}') : Text('Please sign in'),
///   loading: () => CircularProgressIndicator(),
///   error: (error, stack) => Text('Error: $error'),
/// );
/// ```
final currentUserProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return authService.authStateChanges;
});

/// Riverpod provider that streams the application's authentication state.
///
/// This provider converts the raw user object into a more abstract
/// [AuthState] enum, making it easier to handle authentication logic
/// in the UI layer.
///
/// Returns a [StreamProvider<AuthState>] that emits:
/// - [AuthState.authenticated] when a user is signed in
/// - [AuthState.unauthenticated] when no user is signed in
///
/// Usage:
/// ```dart
/// final authState = ref.watch(authStateProvider);
/// authState.when(
///   data: (state) {
///     switch (state) {
///       case AuthState.authenticated:
///         return DashboardScreen();
///       case AuthState.unauthenticated:
///         return LoginScreen();
///       case AuthState.loading:
///         return LoadingScreen();
///     }
///   },
///   loading: () => LoadingScreen(),
///   error: (error, stack) => ErrorScreen(error: error),
/// );
/// ```
final authStateProvider = StreamProvider<AuthState>((ref) {
  final authService = ref.watch(firebaseAuthServiceProvider);
  return Stream.value(AuthState.loading).asyncExpand((_) {
    return authService.authStateChanges.map((user) {
      if (user == null) {
        return AuthState.unauthenticated;
      }
      // You can add role-based logic here later
      return AuthState.authenticated;
    });
  });
});

/// Enum representing the different authentication states in the application.
///
/// This enum provides a clear way to handle authentication logic
/// throughout the app, making it easier to show appropriate UI
/// based on the user's authentication status.
enum AuthState {
  /// The user is authenticated and logged in.
  ///
  /// This state indicates that a valid user session exists
  /// and the user can access authenticated features.
  authenticated,

  /// The user is not authenticated.
  ///
  /// This state indicates that no user is currently signed in
  /// and the user should be prompted to sign in.
  unauthenticated,

  /// The authentication state is being determined.
  ///
  /// This state is typically shown while the app is checking
  /// if a user is already signed in (e.g., on app startup).
  loading,
}
