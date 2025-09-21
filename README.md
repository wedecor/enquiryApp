# We Decor Enquiries

A comprehensive Flutter application for managing customer enquiries in the event decoration business. Built with clean architecture principles, Firebase backend, and role-based access control.

## 📱 PWA Notes

Asset caching is handled by Flutter's generated service worker (`flutter_service_worker.js`). The `firebase-messaging-sw.js` handles only FCM background messages and does not include caching logic to avoid conflicts.

## 📋 Overview

We Decor Enquiries is a modern, scalable Flutter application designed to streamline the enquiry management process for event decoration businesses. The application provides a complete solution for tracking customer enquiries from initial contact to completion, with role-based access for administrators and staff members.

### Key Features

- **🔐 Authentication & Authorization**: Firebase Authentication with role-based access control
- **📊 Dashboard**: Real-time enquiry tracking with status-based filtering
- **📝 Enquiry Management**: Create, assign, and track customer enquiries
- **👥 User Management**: Admin and staff roles with different permissions
- **📱 Push Notifications**: Firebase Cloud Messaging for real-time updates
- **📈 Analytics**: Enquiry statistics and reporting
- **🔄 Real-time Updates**: Live data synchronization with Firestore
- **📱 Cross-platform**: Works on iOS, Android, and Web

### Tech Stack

- **Frontend**: Flutter 3.32.8
- **State Management**: Riverpod 2.6.1
- **Backend**: Firebase (Auth, Firestore, Storage, Cloud Messaging)
- **Code Generation**: Freezed, json_serializable
- **Testing**: Flutter Test, Integration Test
- **Linting**: very_good_analysis

## 🏗️ Architecture

The application follows clean architecture principles with a clear separation of concerns:

### Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    Presentation Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Screens   │  │   Widgets   │  │  Providers  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                     Domain Layer                            │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │   Models    │  │  Services   │  │  Constants  │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                    Data Layer                               │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐        │
│  │  Firestore  │  │   Storage   │  │   Network   │        │
│  └─────────────┘  └─────────────┘  └─────────────┘        │
└─────────────────────────────────────────────────────────────┘
```

### Key Architectural Principles

1. **Separation of Concerns**: Each layer has a specific responsibility
2. **Dependency Inversion**: High-level modules don't depend on low-level modules
3. **Single Responsibility**: Each class has one reason to change
4. **Open/Closed Principle**: Open for extension, closed for modification
5. **Testability**: All components are easily testable in isolation

### State Management

The application uses **Riverpod** for state management, providing:
- **Reactive Programming**: Automatic UI updates when data changes
- **Dependency Injection**: Clean dependency management
- **Provider Composition**: Easy combination of multiple providers
- **Testing Support**: Excellent testing capabilities

## 🔥 Firebase Setup

### Prerequisites

1. **Firebase CLI**: Install the Firebase CLI
   ```bash
   npm install -g firebase-tools
   ```

2. **Flutter SDK**: Ensure Flutter is installed and configured
   ```bash
   flutter doctor
   ```

3. **Dart SDK**: Flutter includes Dart, but ensure it's up to date

### Firebase Project Setup

1. **Create Firebase Project**
   ```bash
   # Login to Firebase
   firebase login
   
   # Create new project (or use existing)
   firebase projects:create we-decor-enquiries
   ```

2. **Initialize Firebase in Project**
   ```bash
   # Navigate to project directory
   cd we_decor_enquiries
   
   # Initialize Firebase
   firebase init
   ```

3. **Enable Firebase Services**
   - **Authentication**: Enable Email/Password authentication
   - **Firestore Database**: Create database in production mode
   - **Storage**: Enable Cloud Storage
   - **Cloud Messaging**: Enable FCM for push notifications

4. **Configure Security Rules**

   **Firestore Rules** (`firestore.rules`):
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       // Allow read/write access to all documents for testing
       match /{document=**} {
         allow read, write: if true;
       }
     }
   }
   ```

   **Storage Rules** (`storage.rules`):
   ```javascript
   rules_version = '2';
   service firebase.storage {
     match /b/{bucket}/o {
       match /{allPaths=**} {
         allow read, write: if true;
       }
     }
   }
   ```

5. **Add Firebase Configuration**

   **Android** (`android/app/google-services.json`):
   - Download from Firebase Console
   - Place in `android/app/` directory

   **iOS** (`ios/Runner/GoogleService-Info.plist`):
   - Download from Firebase Console
   - Add to iOS project

   **Web** (`web/index.html`):
   - Add Firebase SDK configuration

### Environment Configuration

1. **Create Environment Files**
   ```bash
   # Create environment configuration
   touch .env
   touch .env.production
   touch .env.staging
   ```

2. **Configure Environment Variables**
   ```env
   # .env
   FIREBASE_PROJECT_ID=we-decor-enquiries
   FIREBASE_API_KEY=your_api_key
   FIREBASE_APP_ID=your_app_id
   ```

## 🧪 Emulator Instructions

### Prerequisites

1. **Firebase CLI**: Ensure Firebase CLI is installed
2. **Java Runtime**: Required for Firebase emulators
3. **Ports**: Ensure ports 8080, 9099, 9199, 4000 are available

### Running Emulators

1. **Start Firebase Emulators**
   ```bash
   # Start all emulators
   firebase emulators:start
   
   # Start specific emulators
   firebase emulators:start --only auth,firestore,storage
   ```

2. **Access Emulator UI**
   - Open browser to `http://localhost:4000`
   - View Firestore data, authentication, and storage

3. **Configure App for Emulators**
   ```dart
   // In main.dart or test setup
   await FirebaseAuth.instance.useAuthEmulator('localhost', 9099);
   FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);
   ```

### Emulator Ports

| Service | Port | Description |
|---------|------|-------------|
| Auth | 9099 | Authentication emulator |
| Firestore | 8080 | Database emulator |
| Storage | 9199 | Storage emulator |
| UI | 4000 | Emulator dashboard |

### Testing with Emulators

1. **Run Integration Tests**
   ```bash
   # Run simple integration tests
   flutter test test_integration_simple.dart
   
   # Run full integration tests
   flutter test integration_test/app_test.dart
   ```

2. **Manual Testing**
   - Use emulator UI to verify data
   - Test authentication flows
   - Verify real-time updates

## 🚀 CI/CD Notes

### GitHub Actions Workflow

Create `.github/workflows/ci.yml`:

```yaml
name: CI/CD Pipeline

on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    
    steps:
    - uses: actions/checkout@v3
    
    - name: Setup Flutter
      uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.32.8'
        channel: 'stable'
    
    - name: Install dependencies
      run: flutter pub get
    
    - name: Run tests
      run: flutter test
    
    - name: Run integration tests
      run: |
        firebase emulators:start --only auth,firestore,storage &
        sleep 10
        flutter test test_integration_simple.dart
    
    - name: Build APK
      run: flutter build apk --release
    
    - name: Upload APK
      uses: actions/upload-artifact@v3
      with:
        name: app-release
        path: build/app/outputs/flutter-apk/app-release.apk
```

### Build Configuration

1. **Android Build**
   ```bash
   # Debug build
   flutter build apk --debug
   
   # Release build
   flutter build apk --release
   
   # App bundle for Play Store
   flutter build appbundle --release
   ```

2. **iOS Build**
   ```bash
   # Debug build
   flutter build ios --debug
   
   # Release build
   flutter build ios --release
   ```

3. **Web Build**
   ```bash
   # Debug build
   flutter build web --debug
   
   # Release build
   flutter build web --release
   ```

### Deployment

1. **Firebase Hosting (Web)**
   ```bash
   # Build for web
   flutter build web --release
   
   # Deploy to Firebase Hosting
   firebase deploy --only hosting
   ```

2. **App Store Deployment**
   - Build iOS app bundle
   - Upload to App Store Connect
   - Submit for review

3. **Play Store Deployment**
   - Build Android app bundle
   - Upload to Google Play Console
   - Submit for review

## 📁 Folder Structure

```
we_decor_enquiries/
├── android/                          # Android-specific configuration
├── ios/                             # iOS-specific configuration
├── lib/                             # Main application code
│   ├── core/                        # Core application layer
│   │   ├── constants/               # Application constants
│   │   │   └── firestore_schema.dart
│   │   ├── errors/                  # Error handling
│   │   ├── network/                 # Network utilities
│   │   ├── providers/               # Riverpod providers
│   │   │   └── role_provider.dart
│   │   ├── services/                # Core services
│   │   │   ├── firebase_auth_service.dart
│   │   │   ├── firestore_service.dart
│   │   │   └── fcm_service.dart
│   │   └── utils/                   # Utility functions
│   ├── features/                    # Feature-based modules
│   │   ├── auth/                    # Authentication feature
│   │   │   ├── data/                # Data layer
│   │   │   ├── domain/              # Domain layer
│   │   │   └── presentation/        # Presentation layer
│   │   │       └── screens/
│   │   │           └── login_screen.dart
│   │   ├── dashboard/               # Dashboard feature
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   │       └── screens/
│   │   │           └── dashboard_screen.dart
│   │   └── enquiries/               # Enquiries feature
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   │           └── screens/
│   │               ├── enquiry_form_screen.dart
│   │               └── enquiry_details_screen.dart
│   ├── shared/                      # Shared components
│   │   ├── models/                  # Shared data models
│   │   │   └── user_model.dart
│   │   ├── services/                # Shared services
│   │   └── widgets/                 # Shared widgets
│   └── main.dart                    # Application entry point
├── test/                            # Unit and widget tests
│   ├── features/                    # Feature-specific tests
│   └── shared/                      # Shared model tests
├── integration_test/                # Integration tests
│   ├── app_test.dart
│   ├── firebase.json
│   ├── firestore.rules
│   └── firestore.indexes.json
├── assets/                          # Static assets
│   ├── images/
│   ├── fonts/
│   └── icons/
├── pubspec.yaml                     # Dependencies and configuration
├── analysis_options.yaml            # Linting configuration
├── firebase.json                    # Firebase configuration
├── README.md                        # This file
├── DOCUMENTATION_SUMMARY.md         # Documentation overview
├── INTEGRATION_TEST_README.md       # Integration test guide
└── INTEGRATION_TEST_SUMMARY.md      # Integration test overview
```

### Key Directories Explained

- **`lib/core/`**: Core application services, providers, and utilities
- **`lib/features/`**: Feature-based modules following clean architecture
- **`lib/shared/`**: Shared components used across multiple features
- **`test/`**: Unit and widget tests
- **`integration_test/`**: End-to-end integration tests
- **`assets/`**: Static resources like images, fonts, and icons

## 🛠️ Development Setup

### Prerequisites

1. **Flutter SDK**: 3.32.8 or higher
2. **Dart SDK**: 3.8.1 or higher
3. **Firebase CLI**: Latest version
4. **IDE**: VS Code, Android Studio, or IntelliJ IDEA

### Installation

1. **Clone Repository**
   ```bash
   git clone https://github.com/your-org/we-decor-enquiries.git
   cd we-decor-enquiries
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Setup Firebase**
   ```bash
   firebase login
   firebase init
   ```

4. **Run Code Generation**
   ```bash
   flutter packages pub run build_runner build
   ```

5. **Start Development**
   ```bash
   flutter run
   ```

### Development Commands

```bash
# Run the app
flutter run

# Run tests
flutter test

# Run integration tests
flutter test integration_test/app_test.dart

# Generate code
flutter packages pub run build_runner build

# Clean and rebuild
flutter clean && flutter pub get

# Build for release
flutter build apk --release
```

## 🔐 RBAC & Permissions

- **[Feature Matrix](docs/FEATURE_MATRIX.md)**: Complete Staff vs Admin capabilities comparison
- **[RBAC Quick Reference](docs/RBAC_QUICKREF.md)**: Role matrix and 3-layer gating checklist  
- **[Planned Features](docs/PLANNED_FEATURES.md)**: Future role enhancements and roadmap

## 📚 Documentation

- **API Documentation**: Run `dart doc` to generate documentation
- **Integration Tests**: See `INTEGRATION_TEST_README.md`
- **Architecture**: See `DOCUMENTATION_SUMMARY.md`
- **Firebase Setup**: See Firebase Console documentation

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Code Style

- Follow Dart/Flutter style guidelines
- Use `very_good_analysis` for linting
- Write tests for new features
- Update documentation as needed

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue in the GitHub repository
- Check the documentation
- Review the Firebase Console for backend issues

## 🔒 Security

### Security strict mode
- Locally: `npm run sec:all` (non-strict), or `SECURITY_STRICT=1 npm run sec:all` (strict).
- Pre-push: strict mode enforced.
- CI on `main`: strict mode enforced + guard tests must pass.

---

**Built with ❤️ using Flutter and Firebase**
