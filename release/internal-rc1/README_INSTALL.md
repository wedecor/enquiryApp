# We Decor Enquiries v1.0.1+2 - Installation Guide

## 🔐 Security First

**Always verify APK integrity before installation:**

```bash
# On macOS/Linux:
shasum -a 256 app-release.apk

# Expected SHA256:
379d78e8b10bf2dc04f946c144fd40c35ee5d1dd258f815a585cf196c3f144b5
```

**⚠️ Only install if the checksums match exactly!**

## 📱 Android Installation

### Step 1: Enable Unknown Apps
1. Open **Settings** on your Android device
2. Navigate to **Security** (or **Privacy & Security**)
3. Find **Install unknown apps** (or **Unknown sources**)
4. Select your **Browser** or **File Manager**
5. Toggle **Allow from this source** to ON

### Step 2: Download & Install
1. Download `app-release.apk` to your device
2. Verify the SHA256 checksum (see above)
3. Tap the downloaded APK file
4. Tap **Install** when prompted
5. Tap **Open** to launch the app

### Step 3: First Launch
1. The app will initialize Firebase services
2. Grant necessary permissions when prompted:
   - **Camera**: For taking enquiry photos
   - **Storage**: For saving attachments
   - **Notifications**: For enquiry updates
3. Sign in with your credentials

## 🌐 Web PWA Alternative

If you prefer the web version:
1. Visit: [PWA_URL.txt](PWA_URL.txt)
2. On mobile: Tap **Add to Home Screen**
3. Works offline with cached data

## ⚙️ App Configuration

### Environment Settings
- **Environment**: Production
- **Monitoring**: Crashlytics + Performance enabled
- **Analytics**: Disabled by default (opt-in via Settings > Privacy)

### Privacy Controls
Navigate to **Settings > Privacy** to:
- Enable/disable anonymous analytics
- Control crash reporting
- View privacy policy and terms

## 🔧 Troubleshooting

### Installation Issues
- **"App not installed"**: Check available storage (need ~100MB free)
- **"Parse error"**: Re-download APK, verify checksum
- **"Blocked by Play Protect"**: Tap "Install anyway" (this is a known app)

### Runtime Issues
- **Login fails**: Check internet connection, try guest mode first
- **Crashes**: Enable crash reporting in Settings > Privacy
- **Slow performance**: Clear app cache in Android Settings

### Network Issues
- **Offline mode**: App queues operations, syncs when online
- **Firestore errors**: Check Firebase project status
- **FCM notifications**: Ensure notifications are enabled in Android settings

## 📊 Monitoring & Feedback

### What's Being Monitored (with consent)
- **Crashlytics**: Automatic crash reports (helps fix bugs)
- **Performance**: App startup time, screen rendering
- **Analytics**: Anonymous usage patterns (opt-in only)

### Privacy Safeguards
- **PII Redaction**: Emails and phone numbers never logged
- **User Control**: All monitoring can be disabled
- **GDPR Compliant**: Opt-in approach, clear consent

### Reporting Issues
1. **Internal Team**: Use #wedecor-app Slack channel
2. **Include**: Device model, Android version, steps to reproduce
3. **Screenshots**: Help us understand the issue
4. **Logs**: Available in Settings > Admin (admin users only)

## 🏢 Internal Use Only

**This is a Release Candidate for internal testing:**
- Do not distribute outside the organization
- Test all core features: login, enquiries, offline mode
- Report any issues immediately via Slack
- Expected testing period: 1-2 weeks

## 📞 Support

- **Slack**: #wedecor-app channel
- **Email**: support@wedecor.com (external stakeholders)
- **Emergency**: Contact development team directly

---

**Build Information**
- Version: 1.0.1+2
- Build Date: September 21, 2024
- Environment: Production
- Signed: Yes (release keystore)
- Obfuscated: Yes (R8 minification)
- Size: 54.3MB
