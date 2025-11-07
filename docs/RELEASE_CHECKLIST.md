# Release Checklist - We Decor Enquiries

## Pre-Release Verification

### 1. Code Quality Gates
```bash
# Analyze code (should have 0 errors)
flutter analyze

# Run all unit tests (should be 105+ passing)
flutter test

# Check test coverage (should be ≥30% for domain logic)
bash test/coverage.sh
```

### 2. Environment-Specific Builds

#### Development Build
```bash
flutter build apk --dart-define=APP_ENV=dev --dart-define=ENABLE_DEBUG_LOGS=true
```

#### Staging Build
```bash
flutter build apk --release \
  --dart-define=APP_ENV=staging \
  --dart-define=ENABLE_CRASHLYTICS=true \
  --dart-define=ENABLE_ANALYTICS=true
```

#### Production Build
```bash
flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=ENABLE_CRASHLYTICS=true \
  --dart-define=ENABLE_PERFORMANCE=true \
  --dart-define=ENABLE_ANALYTICS=true \
  --obfuscate \
  --split-debug-info=build/debug-info/
```

### 3. Platform-Specific Builds

#### Android
```bash
# APK for direct distribution
flutter build apk --release --dart-define=APP_ENV=prod

# App Bundle for Play Store (recommended)
flutter build appbundle --release --dart-define=APP_ENV=prod

# Verify signing
jarsigner -verify -verbose build/app/outputs/flutter-apk/app-release.apk
```

#### iOS (requires macOS)
```bash
# iOS release build
flutter build ios --release --dart-define=APP_ENV=prod

# Archive for App Store (in Xcode)
# 1. Open ios/Runner.xcworkspace in Xcode
# 2. Select "Any iOS Device" 
# 3. Product > Archive
# 4. Upload to App Store Connect
```

#### Web PWA
```bash
# Web build
flutter build web --release --dart-define=APP_ENV=prod

# Serve locally for testing
npx http-server build/web -p 3000

# Run Lighthouse audit
npx lighthouse http://localhost:3000 \
  --output html \
  --output-path build/lighthouse-report.html \
  --chrome-flags="--no-sandbox --headless"
```

### 4. Firebase Emulator Integration Tests
```bash
# Terminal 1: Start emulators
firebase emulators:start --only auth,firestore

# Terminal 2: Run integration tests
flutter test test/emulator/
```

### 5. Security Verification

#### Firestore Security Rules
```bash
# Test rules with emulator
firebase emulators:exec --only firestore "npm test" --project=your-project-id

# Deploy rules to staging first
firebase deploy --only firestore:rules --project=your-staging-project
```

#### Code Obfuscation Check
```bash
# Build with obfuscation
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/

# Verify symbols are obfuscated (should see mangled names)
aapt dump badging build/app/outputs/flutter-apk/app-release.apk | grep -i activity
```

## Release Deployment

### Android (Google Play Store)

1. **Upload to Play Console**
   ```bash
   # Build app bundle
   flutter build appbundle --release --dart-define=APP_ENV=prod
   
   # Upload build/app/outputs/bundle/release/app-release.aab to Play Console
   ```

2. **Configure Store Listing**
   - App description and screenshots
   - Content rating questionnaire
   - Pricing and distribution
   - Privacy policy URL

3. **Release Management**
   - Internal testing → Closed testing → Open testing → Production
   - Staged rollout (start with 5-10%)

### iOS (Apple App Store)

1. **Archive and Upload**
   - Build in Xcode with Release scheme
   - Archive and upload to App Store Connect
   - Wait for processing completion

2. **App Store Connect Configuration**
   - App information and metadata
   - Screenshots for all device sizes
   - App review information
   - Pricing and availability

3. **Submit for Review**
   - Complete app review questionnaire
   - Submit for Apple review (7-14 days)

### Web (Firebase Hosting)

1. **Deploy to Firebase Hosting**
   ```bash
   # Build web
   flutter build web --release --dart-define=APP_ENV=prod
   
   # Deploy to Firebase
   firebase deploy --only hosting
   ```

2. **Custom Domain (Optional)**
   ```bash
   # Add custom domain in Firebase Console
   firebase hosting:channel:deploy live --only hosting
   ```

## Post-Release Monitoring

### 1. Crashlytics Dashboard
- Monitor crash-free users percentage (target: >99.5%)
- Review top crashes and fix in next release
- Set up alerts for crash rate spikes

### 2. Performance Monitoring
- App startup time (target: <3 seconds)
- Screen rendering performance
- Network request latency

### 3. Analytics Review
- User engagement metrics
- Feature adoption rates
- Conversion funnels

### 4. User Feedback
- App Store/Play Store reviews
- In-app feedback mechanisms
- Support ticket trends

## Emergency Procedures

### Rollback Release
```bash
# Android: Use Play Console to halt rollout or rollback
# iOS: Use App Store Connect to remove from sale
# Web: Deploy previous version
firebase hosting:clone your-project:live your-project:previous-version
firebase deploy --only hosting
```

### Hotfix Process
1. Create hotfix branch from release tag
2. Apply minimal fix
3. Fast-track testing (critical path only)
4. Deploy with expedited review request

## Compliance Checklist

- [ ] Privacy policy updated and accessible
- [ ] Terms of service current
- [ ] GDPR consent mechanisms working
- [ ] App permissions justified and minimal
- [ ] Data retention policies implemented
- [ ] Security vulnerability scan completed
- [ ] Accessibility testing completed
- [ ] Performance benchmarks met

## Sign-off

- [ ] **Engineering Lead**: Code quality and testing complete
- [ ] **Product Manager**: Features and requirements verified  
- [ ] **QA Lead**: Testing strategy executed and passed
- [ ] **Security Team**: Security review completed
- [ ] **Legal Team**: Compliance requirements met
- [ ] **Release Manager**: Deployment plan approved

---

**Release Manager**: _________________ **Date**: _________

**Engineering Lead**: _________________ **Date**: _________
