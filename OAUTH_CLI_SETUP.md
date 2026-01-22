# OAuth Client IDs Creation Guide

## Quick Setup Guide

Unfortunately, **doesn't have a direct command to create standard OAuth 2.0 client IDs (the ones used for Google Sign-In). 

## Recommended: Use Google Cloud Console

The fastest way:

1. **Go to:** https://console.cloud.google.com/apis/credentials?project=wedecorenquries

2. **Create Web Application:**
   - Click "Create Credentials" > "OAuth client ID"
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
   - Click **Create**

3. **Create Android Application:**
   - Click "Create Credentials" > "OAuth client ID"
   - Application type: **Android**
   - Name: **We Decor Enquiries Android**
   - Package name: `com.example.we_decor_enquiries`
   - SHA-1 fingerprint: Get from:
     ```bash
     keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
     ```
   - Click **Create**

4. **Create iOS Application:**
   - Click "Create Credentials" > "OAuth client ID"
   - Application type: **iOS**
   - Name: **We Decor Enquiries iOS**
   - Bundle ID: `com.example.weDecorEnquiries`
   - Click **Create**

## Alternative: Use REST API

If you really want to use CLI, you can use curl with Google Cloud API:

```bash
# First, get an access token
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Create Web OAuth Client
curl -X POST \
  "https://iam.googleapis.com/v1/projects/wedecorenquries/locations/global/oauthClients" \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "We Decor Enquiries Web",
    "web": {
      "redirectUris": [
        "http://localhost:5000",
        "https://wedecorenquries.web.app",
        "https://wedecorenquries.firebaseapp.com"
      ],
      "javascriptOrigins": [
        "http://localhost:5000",
        "https://wedecorenquries.web.app",
        "https://wedecorenquries.firebaseapp.com"
      ]
    }
  }'
```

But the web console is much easier! 🚀

