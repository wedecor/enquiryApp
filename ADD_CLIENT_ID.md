# Add OAuth Client ID to Web App

## Quick Fix

The error shows: **"ClientID not set"**

You need to add your OAuth Client ID to the web app.

### Step 1: Get Your Web Client ID

1. Go to: https://console.cloud.google.com/apis/credentials?project=wedecorenquries
2. Find your **"We Decor Enquiries Web"** OAuth client
3. Copy the **Client ID** (looks like: `xxxxxx-xxxxx.apps.googleusercontent.com`)

### Step 2: Add to web/index.html

Open `web/index.html` and find this line:
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

Replace `YOUR_WEB_CLIENT_ID.apps.googleusercontent.com` with your actual Client ID.

**Example:**
```html
<meta name="google-signin-client_id" content="123456789-abcdefghijklmnop.apps.googleusercontent.com">
```

### Step 3: Restart the App

After adding the Client ID:
1. Stop the app (Ctrl+C in terminal)
2. Run again: `flutter run -d chrome`

## That's It! ✅

Once you add the Client ID, Google Sign-In will work and you can connect to Google Drive.

