import 'package:cloud_functions/cloud_functions.dart';

class FunctionsService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;
  
  // Callable functions
  static Future<Map<String, dynamic>> approveUser({
    required String uid,
    required String role,
  }) async {
    final callable = _functions.httpsCallable('approveUser');
    final result = await callable.call({
      'uid': uid,
      'role': role,
    });
    return Map<String, dynamic>.from(result.data);
  }
  
  static Future<Map<String, dynamic>> deactivateUser({
    required String uid,
  }) async {
    final callable = _functions.httpsCallable('deactivateUser');
    final result = await callable.call({
      'uid': uid,
    });
    return Map<String, dynamic>.from(result.data);
  }
}

