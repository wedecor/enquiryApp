import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logging/safe_log.dart';
import '../domain/user_settings.dart';

class UserSettingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _usersCollection => _firestore.collection('users');

  DocumentReference _settingsDoc(String uid) =>
      _usersCollection.doc(uid).collection('settings').doc('preferences');

  /// Load user settings with fallback to defaults
  Future<UserSettings> load(String uid) async {
    try {
      final doc = await _settingsDoc(uid).get();
      if (doc.exists) {
        return UserSettings.fromFirestore(doc);
      }
      return const UserSettings();
    } catch (e, stackTrace) {
      safeLog('user_settings_load_error', {
        'uid': uid,
        'error': e.toString(),
        'hasStackTrace': stackTrace.toString().isNotEmpty,
      });
      return const UserSettings();
    }
  }

  /// Observe user settings stream
  Stream<UserSettings> observe(String uid) {
    return _settingsDoc(uid)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return UserSettings.fromFirestore(doc);
          }
          return const UserSettings();
        })
        .handleError((error, stackTrace) {
          safeLog('user_settings_observe_error', {
            'uid': uid,
            'error': error.toString(),
            'hasStackTrace': stackTrace.toString().isNotEmpty,
          });
          return const UserSettings();
        });
  }

  /// Update user settings with merge
  Future<void> update(String uid, UserSettings settings) async {
    try {
      // Log the attempt with detailed info
      safeLog('user_settings_update_attempt', {
        'uid': uid,
        'theme': settings.theme,
        'language': settings.language,
        'timezone': settings.timezone,
        'docPath': 'users/$uid/settings/preferences',
      });

      await _settingsDoc(uid).set(settings.toFirestore(), SetOptions(merge: true));

      safeLog('user_settings_updated', {
        'uid': uid,
        'theme': settings.theme,
        'language': settings.language,
      });
    } catch (e, stackTrace) {
      // Enhanced error logging
      safeLog('user_settings_update_error', {
        'uid': uid,
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
        'stackTrace': stackTrace.toString(),
        'docPath': 'users/$uid/settings/preferences',
        'settingsData': settings.toFirestore(),
      });
      rethrow;
    }
  }

  /// Initialize settings if missing
  Future<void> initIfMissing(String uid, UserSettings defaults) async {
    try {
      final doc = await _settingsDoc(uid).get();
      if (!doc.exists) {
        await _settingsDoc(uid).set(defaults.toFirestore());
        safeLog('user_settings_initialized', {'uid': uid, 'theme': defaults.theme});
      }
    } catch (e, stackTrace) {
      safeLog('user_settings_init_error', {
        'uid': uid,
        'error': e.toString(),
        'hasStackTrace': stackTrace.toString().isNotEmpty,
      });
    }
  }
}
