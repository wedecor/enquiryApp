# gcloud Authentication Guide

## Step-by-Step Authentication

### 1. Open Terminal
Open your terminal (Terminal.app on macOS)

### 2. Add gcloud to PATH (if not already added)
```bash
export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"
```

### 3. Run Authentication Command
```bash
gcloud auth login
```

### 4. What Happens Next:

**Option A: Browser Opens Automatically**
- Your default browser will open
- Sign in with your Google account (the one associated with Firebase project)
- Grant permissions to Google Cloud SDK
- You'll see "You are now authenticated" message

**Option B: Manual Authentication (if browser doesn't open)**
- You'll see a URL like:
  ```
  https://accounts.google.com/o/oauth2/auth?response_type=code&client_id=...
  ```
- Copy this URL
- Open it in your browser
- Sign in and grant permissions
- You'll get a verification code
- Paste the code back into terminal

### 5. Set Your Project
After authentication, set your Firebase project:
```bash
gcloud config set project wedecorenquries
```

### 6. Verify Authentication
Check if you're authenticated:
```bash
gcloud auth list
```

You should see your email address listed.

## Alternative: Application Default Credentials

For API access, you may also need:
```bash
gcloud auth application-default login
```

This sets up credentials for applications to use Google Cloud APIs.

## Troubleshooting

### "Command not found: gcloud"
- Make sure gcloud is installed: `brew install --cask google-cloud-sdk`
- Add to PATH: `export PATH="/opt/homebrew/share/google-cloud-sdk/bin:$PATH"`

### "Permission denied"
- Make sure you're using the correct Google account
- Check that the account has access to the Firebase project

### "Project not found"
- Verify project ID: `wedecorenquries`
- Check Firebase Console: https://console.firebase.google.com/

## Quick Test

After authentication, test it:
```bash
gcloud projects list
```

You should see your project listed.

