# WeDecor Enquiries App - Complete Setup Guide

This guide will help you set up the WeDecor Enquiries Flutter app from scratch using CLI tools.

## 🚀 Quick Setup (Automated)

### For macOS/Linux:
```bash
chmod +x setup.sh
./setup.sh
```

### For Windows:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
.\setup.ps1
```

## 📋 Manual Setup (Step by Step)

### Prerequisites

1. **Flutter SDK** (3.8.1 or higher)
   ```bash
   # Install Flutter from https://flutter.dev/docs/get-started/install
   flutter --version
   ```

2. **Node.js and npm** (for Firebase CLI)
   ```bash
   # Install from https://nodejs.org/
   node --version
   npm --version
   ```

3. **Firebase CLI**
   ```bash
   npm install -g firebase-tools
   firebase --version
   ```

4. **FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   flutterfire --version
   ```

### Step 1: Clone and Setup Dependencies

```bash
# Navigate to project directory
cd /path/to/wedecorEnquries

# Clean and get dependencies
flutter clean
flutter pub get

# Generate code (Freezed, Riverpod, JSON serialization)
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Step 2: Firebase Configuration

1. **Login to Firebase**
   ```bash
   firebase login
   ```

2. **List your Firebase projects**
   ```bash
   firebase projects:list
   ```

3. **Configure FlutterFire**
   ```bash
   # Replace 'your-project-id' with your actual Firebase project ID
   flutterfire configure --project=your-project-id
   ```

   This command will:
   - Generate `lib/firebase_options.dart`
   - Create/update `android/app/google-services.json`
   - Create/update `ios/Runner/GoogleService-Info.plist`
   - Update Firebase configuration for web

### Step 3: Platform-Specific Setup

#### Android Setup

1. **Ensure Android development is ready**
   ```bash
   flutter doctor
   ```

2. **The FlutterFire configure command should have created the correct `google-services.json`**
   - Location: `android/app/google-services.json`
   - This replaces the template file

3. **Android permissions are already configured in `AndroidManifest.xml`**

#### iOS Setup (macOS only)

1. **Install CocoaPods** (if not already installed)
   ```bash
   sudo gem install cocoapods
   ```

2. **Install iOS dependencies**
   ```bash
   cd ios
   pod install
   cd ..
   ```

#### Web Setup

Web configuration is handled automatically by the FlutterFire configure command.

### Step 4: Environment Configuration

1. **Create environment file**
   ```bash
   cp .env.template .env
   ```

2. **Update `.env` with your actual values** (optional for basic functionality)
   ```env
   FIREBASE_API_KEY=your_actual_api_key
   FIREBASE_PROJECT_ID=your_project_id
   FIREBASE_MESSAGING_SENDER_ID=your_sender_id
   FIREBASE_APP_ID=your_app_id
   ```

### Step 5: Firebase Functions (Optional)

If you want to use the Cloud Functions for user invitations:

```bash
cd functions
npm install
cd ..
```

## 🏃 Running the App

### Option 1: Using Provided Scripts

```bash
# Android
./run_android.sh      # macOS/Linux
run_android.bat       # Windows

# Web
./run_web.sh          # macOS/Linux
run_web.bat           # Windows

# iOS (macOS only)
./run_ios.sh

# Build all platforms
./build.sh            # macOS/Linux
build.bat             # Windows
```

### Option 2: Direct Flutter Commands

```bash
# Run on any available device
flutter run

# Run on specific platform
flutter run -d chrome          # Web
flutter run -d android         # Android
flutter run -d ios             # iOS (macOS only)

# Run with specific device ID
flutter devices                # List devices
flutter run -d emulator-5554   # Android emulator
```

### Option 3: Start Android Emulator First

```bash
# List available emulators
flutter emulators

# Start specific emulator
flutter emulators --launch Pixel_8_Pro_API_35

# Wait for emulator to boot, then run
flutter run -d android
```

## 🔧 Development Workflow

### Hot Reload Development

```bash
flutter run
# Then use:
# r - Hot reload
# R - Hot restart
# q - Quit
```

### Code Generation (when you modify models)

```bash
flutter packages pub run build_runner build --delete-conflicting-outputs
```

### Building for Release

```bash
# Android APK
flutter build apk --release

# Android App Bundle (for Play Store)
flutter build appbundle --release

# iOS (macOS only)
flutter build ios --release

# Web
flutter build web --release
```

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run integration tests
flutter drive --target=integration_test/app_test.dart
```

## 📱 Platform-Specific Notes

### Android
- Minimum SDK: API level set in `android/app/build.gradle.kts`
- Target SDK: Latest Android API
- All required permissions are pre-configured
- Firebase configuration via `google-services.json`

### iOS (macOS only)
- Minimum iOS version: Set in `ios/Runner/Info.plist`
- Firebase configuration via `GoogleService-Info.plist`
- CocoaPods manages native dependencies

### Web
- Runs on Chrome by default
- Firebase configuration embedded in `firebase_options.dart`
- Hosted on port 3000 by default (configurable)

## 🔍 Troubleshooting

### Common Issues

1. **Flutter Doctor Issues**
   ```bash
   flutter doctor -v
   # Follow the specific instructions for each issue
   ```

2. **Firebase Configuration Errors**
   ```bash
   # Re-run FlutterFire configuration
   flutterfire configure --project=your-project-id --overwrite-firebase-options
   ```

3. **Android Build Errors**
   ```bash
   # Clean and rebuild
   flutter clean
   cd android && ./gradlew clean && cd ..
   flutter pub get
   flutter build apk --debug
   ```

4. **iOS Build Errors** (macOS only)
   ```bash
   # Clean iOS build
   cd ios
   rm -rf Pods Podfile.lock
   pod install
   cd ..
   flutter clean
   flutter build ios --debug
   ```

5. **Code Generation Issues**
   ```bash
   # Force rebuild generated code
   flutter packages pub run build_runner clean
   flutter packages pub run build_runner build --delete-conflicting-outputs
   ```

### Firebase Issues

1. **Check Firebase project configuration**
   - Visit [Firebase Console](https://console.firebase.google.com/)
   - Ensure your project exists and is properly configured
   - Check that Authentication, Firestore, and Functions are enabled

2. **Verify Firebase files**
   - `lib/firebase_options.dart` should exist
   - `android/app/google-services.json` should exist (not template)
   - `ios/Runner/GoogleService-Info.plist` should exist (macOS only)

## 📚 Additional Resources

- [Flutter Documentation](https://flutter.dev/docs)
- [Firebase Documentation](https://firebase.google.com/docs)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [Riverpod Documentation](https://riverpod.dev/)

## 🆘 Getting Help

If you encounter issues:

1. Check this troubleshooting section
2. Run `flutter doctor -v` for detailed diagnostics
3. Check the Firebase Console for configuration issues
4. Review the app logs in your IDE or terminal

---

**Happy coding! 🚀**










