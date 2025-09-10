import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/auth_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

final authRepoProvider = Provider<AuthRepository>((ref) => AuthRepository());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authRepoProvider).authStateChanges();
});

final userDocProvider = StreamProvider<DocumentSnapshot<Map<String, dynamic>>?>((ref) {
  final repo = ref.watch(authRepoProvider);
  return repo.userDocStream();
});

class LoginState {
  const LoginState({
    this.email = '',
    this.password = '',
    this.loading = false,
    this.error,
  });
  final String email;
  final String password;
  final bool loading;
  final String? error;

  LoginState copyWith({String? email, String? password, bool? loading, String? error}) {
    return LoginState(
      email: email ?? this.email,
      password: password ?? this.password,
      loading: loading ?? this.loading,
      error: error,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  LoginController(this._repo) : super(const LoginState());
  final AuthRepository _repo;

  void setEmail(String v) => state = state.copyWith(email: v, error: null);
  void setPassword(String v) => state = state.copyWith(password: v, error: null);

  Future<bool> login() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signIn(email: state.email, password: state.password);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _mapAuthError(e.code));
      return false;
    } catch (e) {
      state = state.copyWith(error: 'Something went wrong. Try again.');
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<bool> signup() async {
    state = state.copyWith(loading: true, error: null);
    try {
      await _repo.signUp(email: state.email, password: state.password);
      return true;
    } on FirebaseAuthException catch (e) {
      state = state.copyWith(error: _mapAuthError(e.code));
      return false;
    } catch (_) {
      state = state.copyWith(error: 'Something went wrong. Try again.');
      return false;
    } finally {
      state = state.copyWith(loading: false);
    }
  }

  Future<String?> forgot(String email) async {
    try {
      await _repo.sendPasswordReset(email);
      return null;
    } on FirebaseAuthException catch (e) {
      return _mapAuthError(e.code);
    } catch (_) {
      return 'Could not send reset email. Try again.';
    }
  }

  String _mapAuthError(String code) {
    switch (code) {
      case 'invalid-email': return 'Invalid email address';
      case 'user-disabled': return 'This account is disabled';
      case 'user-not-found': return 'No user found with this email';
      case 'wrong-password': return 'Incorrect password';
      case 'email-already-in-use': return 'Email already in use';
      case 'weak-password': return 'Password is too weak';
      case 'too-many-requests': return 'Too many attempts. Try later.';
      default: return 'Authentication failed ($code)';
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
  return LoginController(ref.watch(authRepoProvider));
});
