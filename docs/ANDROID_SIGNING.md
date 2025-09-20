# Android Release Signing Setup

## Overview

This document explains how to configure Android release signing for production builds.

## Prerequisites

- Android Studio or command line tools
- Java keytool (included with JDK)

## Step 1: Create Release Keystore

```bash
# Create a new keystore (do this once)
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release

# You'll be prompted for:
# - Keystore password
# - Key password  
# - Your name and organization details
```

## Step 2: Configure Gradle Properties

Create or edit `~/.gradle/gradle.properties` (global) or `android/local.properties` (project-specific):

```properties
# Android Release Signing (DO NOT COMMIT THESE VALUES)
RELEASE_STORE_FILE=/absolute/path/to/your/release-keystore.jks
RELEASE_STORE_PASSWORD=your_keystore_password
RELEASE_KEY_ALIAS=release
RELEASE_KEY_PASSWORD=your_key_password
```

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
        // ... other release config
    }
}
```

## Step 4: Build Release APK

```bash
# Build with release signing
flutter build apk --release

# Build with obfuscation (recommended for production)
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/

# Build app bundle for Play Store
flutter build appbundle --release
```

## Security Notes

- **Never commit keystore files or passwords to version control**
- Store keystore in secure location with backups
- Use different keystores for debug/staging/production
- Consider using CI/CD secrets management for production builds

## Troubleshooting

### Build Fails with "Keystore not found"
- Check the path in `RELEASE_STORE_FILE`
- Ensure keystore file exists and is readable

### Build Fails with "Wrong password"
- Verify `RELEASE_STORE_PASSWORD` and `RELEASE_KEY_PASSWORD`
- Check keystore with: `keytool -list -v -keystore release-keystore.jks`

### R8 Minification Issues
- Check `android/app/proguard-rules.pro` for keep rules
- Add specific keep rules for classes that fail minification
- Test with `--no-shrink` to isolate R8 vs other issues
