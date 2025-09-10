import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class AuthRepository {
  AuthRepository({
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
    FirebaseMessaging? messaging,
  })  : _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance,
        _messaging = messaging ?? FirebaseMessaging.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _db;
  final FirebaseMessaging _messaging;

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email.trim(), password: password);
    await _postAuthBoot(cred.user);
    return cred;
  }

  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email.trim(), password: password);
    // Minimal pending profile; Functions may also write this.
    await _db.doc('users/${cred.user!.uid}').set({
      'uid': cred.user!.uid,
      'email': cred.user!.email,
      'role': 'pending',
      'isApproved': false,
      'isActive': false,
      'fcmTokens': [],
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await _postAuthBoot(cred.user);
    return cred;
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Listen to the current user's Firestore profile (users/{uid})
  Stream<DocumentSnapshot<Map<String, dynamic>>?> userDocStream() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _db.doc('users/${user.uid}').snapshots();
  }

  /// Save FCM token and subscribe to topics.
  Future<void> _postAuthBoot(User? user) async {
    if (user == null) return;
    // Request perm (web asks the user; mobile prompt too)
    await _messaging.requestPermission();
    final token = await _messaging.getToken();
    if (token != null) {
      final ref = _db.doc('users/${user.uid}');
      await _db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        final arr = List<String>.from((snap.data()?['fcmTokens'] ?? []) as List);
        if (!arr.contains(token)) arr.add(token);
        tx.set(ref, {'fcmTokens': arr, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
      });
    }
  }

  /// Subscribe to per-user + role topics. Call after you know the role (from user doc).
  Future<void> subscribeTopics({required String uid, required String role}) async {
    final fcm = _messaging;
    await fcm.subscribeToTopic('user-$uid');
    if (role != 'pending') {
      await fcm.subscribeToTopic('wedecor-role-$role');
    }
  }
}
