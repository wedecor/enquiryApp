# Android Setup - WeDecor Enquiries

## 🔧 Missing Configuration

The Android app requires a `google-services.json` file to build successfully.

### 📱 **Error Seen:**
```
File google-services.json is missing. The Google Services Plugin cannot function without it.
```

### 🚀 **Solution:**

1. **Download from Firebase Console:**
   - Go to [Firebase Console](https://console.firebase.google.com/project/wedecorenquries/settings/general)
   - Select "Project Settings" → "General" tab
   - Scroll to "Your apps" section
   - Find the Android app or click "Add app" if not present
   - Download `google-services.json`

2. **Place the File:**
   ```bash
   # Copy to the correct location
   cp google-services.json android/app/
   ```

3. **Verify Configuration:**
   - Package name should match: `com.example.we_decor_enquiries`
   - Project ID should be: `wedecorenquries`

### 🔨 **After Adding the File:**

```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run -d emulator-5554
```

### ✅ **Expected Result:**
- Android app builds successfully
- Firebase services work properly
- Authentication and Firestore function correctly

### 🔒 **Security Note:**
- The `google-services.json` contains public configuration (not secrets)
- Safe to commit to version control
- Contains API keys that are meant to be public for client apps



