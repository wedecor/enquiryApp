import 'firebase_app_distribution_adapter_interface.dart';

class _NoopFirebaseAppDistributionAdapter
    implements FirebaseAppDistributionAdapter {
  const _NoopFirebaseAppDistributionAdapter();

  @override
  Future<bool> tryLaunchUpdate() async => false;
}

FirebaseAppDistributionAdapter createFirebaseAppDistributionAdapter() =>
    const _NoopFirebaseAppDistributionAdapter();

