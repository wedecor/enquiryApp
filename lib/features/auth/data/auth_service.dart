import 'package:firebase_auth/firebase_auth.dart';

/// Accounts are created only through the admin `inviteUser` callable — there
/// is deliberately no client-side sign-up. Sign out through
/// `firebaseAuthServiceProvider` so the FCM token is removed.
class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> signIn(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  Future<void> reset(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  static String messageForException(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'The email address is malformed.';
      case 'user-disabled':
        return 'This user has been disabled.';
      case 'user-not-found':
        return 'No user found for that email.';
      case 'wrong-password':
        return 'Incorrect password provided.';
      case 'weak-password':
        return 'Please choose a stronger password (min 6 characters).';
      case 'email-already-in-use':
        return 'An account already exists for that email.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      case 'network-request-failed':
        return 'Network error. Check your connection and try again.';
      default:
        return e.message ?? 'Authentication error: ${e.code}';
    }
  }
}
