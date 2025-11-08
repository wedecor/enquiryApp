import 'package:firebase_app_distribution/firebase_app_distribution.dart'
    as firebase_app_distribution;

import 'firebase_app_distribution_adapter_interface.dart';

class _FirebaseAppDistributionAdapter
    implements FirebaseAppDistributionAdapter {
  const _FirebaseAppDistributionAdapter();

  @override
  Future<bool> tryLaunchUpdate() async {
    await firebase_app_distribution.signInTester();
    final hasUpdate =
        await firebase_app_distribution.isNewReleaseAvailable();
    if (hasUpdate) {
      await firebase_app_distribution.updateIfNewReleaseAvailable();
      return true;
    }
    return false;
  }
}

FirebaseAppDistributionAdapter createFirebaseAppDistributionAdapter() =>
    const _FirebaseAppDistributionAdapter();

