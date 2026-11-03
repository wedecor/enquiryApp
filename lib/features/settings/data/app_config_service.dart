import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logging/safe_log.dart';
import '../../../core/services/firestore_service.dart';
import '../domain/app_config.dart';

enum AppConfigKind { general, notifications, security }

class AppConfigService {
  AppConfigService(this._firestoreService);

  final FirestoreService _firestoreService;

  CollectionReference get _appConfigCollection =>
      _firestoreService.firestore.collection('app_config');

  DocumentReference _configDoc(AppConfigKind kind) => _appConfigCollection.doc(kind.name);

  /// Observe app general config
  Stream<AppGeneralConfig> observeGeneral() {
    return _configDoc(AppConfigKind.general)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return AppGeneralConfig.fromFirestore(doc);
          }
          return const AppGeneralConfig();
        })
        .handleError((Object error, StackTrace stackTrace) {
          safeLog('app_config_observe_error', {
            'kind': 'general',
            'error': error.toString(),
            'hasStackTrace': stackTrace.toString().isNotEmpty,
          });
          return const AppGeneralConfig();
        });
  }

  /// Observe app notification config
  Stream<AppNotificationConfig> observeNotifications() {
    return _configDoc(AppConfigKind.notifications)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return AppNotificationConfig.fromFirestore(doc);
          }
          return const AppNotificationConfig();
        })
        .handleError((Object error, StackTrace stackTrace) {
          safeLog('app_config_observe_error', {
            'kind': 'notifications',
            'error': error.toString(),
            'hasStackTrace': stackTrace.toString().isNotEmpty,
          });
          return const AppNotificationConfig();
        });
  }

  /// Observe app security config
  Stream<AppSecurityConfig> observeSecurity() {
    return _configDoc(AppConfigKind.security)
        .snapshots()
        .map((doc) {
          if (doc.exists) {
            return AppSecurityConfig.fromFirestore(doc);
          }
          return const AppSecurityConfig();
        })
        .handleError((Object error, StackTrace stackTrace) {
          safeLog('app_config_observe_error', {
            'kind': 'security',
            'error': error.toString(),
            'hasStackTrace': stackTrace.toString().isNotEmpty,
          });
          return const AppSecurityConfig();
        });
  }

  /// Update app general config (admin only)
  Future<void> updateGeneral(AppGeneralConfig config) async {
    try {
      await _configDoc(AppConfigKind.general).set(config.toFirestore(), SetOptions(merge: true));
      safeLog('app_config_updated', {
        'kind': 'general',
        'companyName': config.companyName,
        'currency': config.currency,
      });
    } catch (e, stackTrace) {
      safeLog('app_config_update_error', {
        'kind': 'general',
        'error': e.toString(),
        'hasStackTrace': stackTrace.toString().isNotEmpty,
      });
      rethrow;
    }
  }

  /// `app_config/notifications.followUpsEnabled` (absent = on). Read by the
  /// follow-up Cloud Functions; kept outside [AppNotificationConfig] so older app
  /// builds that save that model (merge) never reset it.
  Stream<bool> watchFollowUpsEnabled() {
    return _configDoc(AppConfigKind.notifications).snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      return data?['followUpsEnabled'] != false;
    });
  }

  /// `app_config/notifications.websiteAssigneeUid`: who website enquiries are
  /// assigned to (null = nobody; admins are notified either way). Read by the
  /// websiteLead function.
  Stream<String?> watchWebsiteAssigneeUid() {
    return _configDoc(AppConfigKind.notifications).snapshots().map((snap) {
      final data = snap.data() as Map<String, dynamic>?;
      final uid = data?['websiteAssigneeUid'];
      return uid is String && uid.trim().isNotEmpty ? uid.trim() : null;
    });
  }

  /// Sets (or clears, with null) the website enquiry assignee (admin only).
  Future<void> setWebsiteAssigneeUid(String? uid) async {
    await _configDoc(AppConfigKind.notifications).set({
      'websiteAssigneeUid': uid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    safeLog('app_config_updated', {'kind': 'notifications', 'websiteAssigneeSet': uid != null});
  }

  /// Turns automatic follow-ups on or off for the whole team (admin only).
  Future<void> setFollowUpsEnabled(bool enabled) async {
    await _configDoc(AppConfigKind.notifications).set({
      'followUpsEnabled': enabled,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    safeLog('app_config_updated', {'kind': 'notifications', 'followUpsEnabled': enabled});
  }

  /// Update app notification config (admin only)
  Future<void> updateNotifications(AppNotificationConfig config) async {
    try {
      await _configDoc(
        AppConfigKind.notifications,
      ).set(config.toFirestore(), SetOptions(merge: true));
      safeLog('app_config_updated', {
        'kind': 'notifications',
        'emailInvitesEnabled': config.emailInvitesEnabled,
        'reminderDaysDefault': config.reminderDaysDefault,
      });
    } catch (e, stackTrace) {
      safeLog('app_config_update_error', {
        'kind': 'notifications',
        'error': e.toString(),
        'hasStackTrace': stackTrace.toString().isNotEmpty,
      });
      rethrow;
    }
  }

  /// Update app security config (admin only)
  Future<void> updateSecurity(AppSecurityConfig config) async {
    try {
      await _configDoc(AppConfigKind.security).set(config.toFirestore(), SetOptions(merge: true));
      safeLog('app_config_updated', {
        'kind': 'security',
        'allowedDomainsCount': config.allowedDomains.length,
        'requireFirstLoginReset': config.requireFirstLoginReset,
      });
    } catch (e, stackTrace) {
      safeLog('app_config_update_error', {
        'kind': 'security',
        'error': e.toString(),
        'hasStackTrace': stackTrace.toString().isNotEmpty,
      });
      rethrow;
    }
  }
}
