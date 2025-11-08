import 'firebase_app_distribution_adapter_interface.dart';
import 'firebase_app_distribution_adapter_stub.dart'
    if (dart.library.io) 'firebase_app_distribution_adapter_io.dart';

FirebaseAppDistributionAdapter get firebaseAppDistributionAdapter =>
    createFirebaseAppDistributionAdapter();

