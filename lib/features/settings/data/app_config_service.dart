import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/logging/safe_log.dart';
import '../domain/app_config.dart';

enum AppConfigKind { general, notifications, security }

class AppConfigService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _appConfigCollection => _firestore.collection('app_config');

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
        .handleError((error, stackTrace) {
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
        .handleError((error, stackTrace) {
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
        .handleError((error, stackTrace) {
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



