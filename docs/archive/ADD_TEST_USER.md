# Add Test User to OAuth Consent Screen

## Quick Fix

Your OAuth consent screen is in "Testing" mode, so you need to add yourself as a test user.

## Steps:

### 1. Go to OAuth Consent Screen

**Direct link:** https://console.cloud.google.com/apis/credentials/consent?project=wedecorenquries

Or navigate:
- Google Cloud Console → APIs & Services → OAuth consent screen

### 2. Scroll to "Test users" section

Look for the section that says **"Test users"**

### 3. Click "+ ADD USERS"

### 4. Add Your Email

Enter your email address:
```
naazgemini@gmail.com
```

### 5. Click "ADD"

### 6. Try Again

After adding your email:
1. Go back to the app
2. Click "Connect Google Drive" again
3. Sign in with `naazgemini@gmail.com`
4. It should work now!

## Alternative: Publish the App (For Production)

If you want anyone to use it (not just test users):

1. Go to OAuth consent screen
2. Click "PUBLISH APP"
3. Complete the verification process (may take a few days)

**For now, just add yourself as a test user - that's the fastest way!**

