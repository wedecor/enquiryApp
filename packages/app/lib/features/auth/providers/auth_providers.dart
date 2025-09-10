import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/models/user_model.dart';

final authStateChangesProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges().map((user) {
    print('🔄 Auth state changed: ${user?.uid ?? 'null'}');
    return user;
  });
});

final currentUserDocProvider = StreamProvider<AppUser?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) {
        print('👤 No authenticated user');
        return Stream.value(null);
      }
      
      print('👤 Fetching user document for: ${user.uid}');
              return FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .snapshots()
                  .map((doc) {
                if (!doc.exists) {
                  print('❌ User document does not exist for: ${user.uid}');
                  return null;
                }
                print('✅ User document found for: ${user.uid}');
                final userData = doc.data()!;
                print('📄 User document data: ${userData.toString()}');
                print('👑 Role: ${userData['role']}');
                print('✅ Is approved: ${userData['isApproved']}');
                print('🟢 Is active: ${userData['isActive']}');
                return AppUser.fromJson(userData);
              });
    },
    loading: () {
      print('⏳ Loading auth state...');
      return Stream.value(null);
    },
    error: (error, stack) {
      print('❌ Auth state error: $error');
      return Stream.value(null);
    },
  );
});
