# Create OAuth Clients - Manual Guide

Since the CLI API approach has limitations, here's the **fastest way** to create OAuth clients:

## Quick Steps (5 minutes)

### 1. Go to Google Cloud Console
**Direct link:** https://console.cloud.google.com/apis/credentials?project=wedecorenquries

### 2. Create Web Application Client

1. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
2. If prompted, configure OAuth consent screen:
   - User Type: **External**
   - App name: **We Decor Enquiries**
   - User support email: Your email
   - Developer contact: Your email
   - Click **"SAVE AND CONTINUE"**
   - Scopes: Click **"ADD OR REMOVE SCOPES"**
     - Search: `drive.file`
     - Check: `https://www.googleapis.com/auth/drive.file`
     - Click **"UPDATE"** → **"SAVE AND CONTINUE"**
   - Test users: Add your email → **"SAVE AND CONTINUE"**
   - Summary: **"BACK TO DASHBOARD"**

3. Create OAuth Client:
   - Application type: **Web application**
   - Name: **We Decor Enquiries Web**
   - Authorized JavaScript origins:
     ```
     http://localhost:5000
     https://wedecorenquries.web.app
     https://wedecorenquries.firebaseapp.com
     ```
   - Authorized redirect URIs:
     ```
     http://localhost:5000
     https://wedecorenquries.web.app
     https://wedecorenquries.firebaseapp.com
     ```
   - Click **"CREATE"**
   - **Copy the Client ID** (you'll see it in a popup)

### 3. Create Android Application Client

1. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
2. Application type: **Android**
3. Name: **We Decor Enquiries Android**
4. Package name: `com.example.we_decor_enquiries`
5. SHA-1 certificate fingerprint:
   - Run this command to get it:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Copy the SHA-1 value (looks like: `AA:BB:CC:DD:...`)
   - Paste it in the form
6. Click **"CREATE"**
7. **Copy the Client ID**

### 4. Create iOS Application Client (Optional)

1. Click **"+ CREATE CREDENTIALS"** → **"OAuth client ID"**
2. Application type: **iOS**
3. Name: **We Decor Enquiries iOS**
4. Bundle ID: `com.example.weDecorEnquiries`
5. Click **"CREATE"**
6. **Copy the Client ID**

## That's It! ✅

Once you have the Client IDs, the app will automatically use them. No additional configuration needed!

## Get SHA-1 Fingerprint

For Android client, run:
```bash
keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
```

Look for the line that says:
```
SHA1: AA:BB:CC:DD:EE:FF:...
```

Copy the SHA1 value (without spaces or colons, or with colons - both formats work).

