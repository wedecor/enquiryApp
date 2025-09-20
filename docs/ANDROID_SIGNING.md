# Android Release Signing Setup

## Overview

This document explains how to configure Android release signing for production builds with proper security.

## Step 1: Create Release Keystore

```bash
# Create a new keystore (do this once, store securely)
keytool -genkey -v -keystore ~/release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release

# You'll be prompted for:
# - Keystore password (store securely)
# - Key password (store securely)  
# - Your name and organization details
```

## Step 2: Configure Environment Variables

### Option A: Global Gradle Properties
Create or edit `~/.gradle/gradle.properties`:

```properties
# Android Release Signing (DO NOT COMMIT THESE VALUES)
RELEASE_STORE_FILE=/absolute/path/to/your/release-keystore.jks
RELEASE_STORE_PASSWORD=your_keystore_password
RELEASE_KEY_ALIAS=release
RELEASE_KEY_PASSWORD=your_key_password
```

### Option B: Project-Specific (Recommended for Teams)
Create `android/local.properties`:

```properties
# Android Release Signing (DO NOT COMMIT - add to .gitignore)
RELEASE_STORE_FILE=/absolute/path/to/your/release-keystore.jks
RELEASE_STORE_PASSWORD=your_keystore_password
RELEASE_KEY_ALIAS=release
RELEASE_KEY_PASSWORD=your_key_password
```

### Option C: CI/CD Environment Variables
Set in your CI/CD system:
- `RELEASE_STORE_FILE`
- `RELEASE_STORE_PASSWORD`
- `RELEASE_KEY_ALIAS`
- `RELEASE_KEY_PASSWORD`

## Step 3: Enable Release Signing

Uncomment the signing configuration in `android/app/build.gradle.kts`:

```kotlin
signingConfigs {
    create("release") {
        storeFile = file(project.findProperty("RELEASE_STORE_FILE") ?: "release-keystore.jks")
        storePassword = project.findProperty("RELEASE_STORE_PASSWORD") as String? ?: ""
        keyAlias = project.findProperty("RELEASE_KEY_ALIAS") as String? ?: ""
        keyPassword = project.findProperty("RELEASE_KEY_PASSWORD") as String? ?: ""
    }
}

buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")  // Uncomment this line
        isMinifyEnabled = true
        isShrinkResources = true
        // ... other config
    }
}
```

## Step 4: Build Production APK

```bash
# Standard release build
flutter build apk --release

# With Dart obfuscation (recommended for production)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/

# App Bundle for Play Store (recommended)
flutter build appbundle --release
```

## Step 5: Environment-Specific Builds

```bash
# Development
flutter build apk --dart-define=APP_ENV=dev

# Staging with monitoring
flutter build apk --release --dart-define=APP_ENV=staging --dart-define=ENABLE_CRASHLYTICS=true

# Production with full monitoring
flutter build apk --release --dart-define=APP_ENV=prod --dart-define=ENABLE_CRASHLYTICS=true --dart-define=ENABLE_PERFORMANCE=true --dart-define=ENABLE_ANALYTICS=true
```

## Security Best Practices

### Keystore Security
- **Never commit keystore files** to version control
- Store keystore in secure, backed-up location
- Use different keystores for debug/staging/production
- Document keystore location and backup procedures

### Password Management
- Use strong, unique passwords for keystore and key
- Store passwords in secure password manager
- Never hardcode passwords in build scripts
- Rotate passwords periodically

### CI/CD Security
- Use encrypted environment variables
- Limit access to signing secrets
- Audit who can trigger production builds
- Log signing operations for compliance

## Troubleshooting

### "Keystore not found"
- Verify path in `RELEASE_STORE_FILE` is absolute
- Check file permissions (readable by build process)
- Ensure keystore file exists and is not corrupted

### "Wrong password"
- Verify `RELEASE_STORE_PASSWORD` and `RELEASE_KEY_PASSWORD`
- Test keystore access: `keytool -list -v -keystore release-keystore.jks`

### R8 Minification Issues
- Check `android/app/proguard-rules.pro` for keep rules
- Build logs will show missing classes
- Add minimal keep rules for failing classes only

### Build Performance
- Use `--local-engine-src-path` for faster rebuilds during development
- Enable Gradle daemon: `org.gradle.daemon=true` in gradle.properties
- Increase Gradle memory: `org.gradle.jvmargs=-Xmx4g`

## Verification

```bash
# Verify signed APK
jarsigner -verify -verbose -certs build/app/outputs/flutter-apk/app-release.apk

# Check APK details
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | head -10
```