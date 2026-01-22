# Fix Redirect URI Mismatch Error

## Error: `redirect_uri_mismatch`

This means the redirect URI your app is using doesn't match what's configured in your OAuth client.

## Solution: Add Localhost Redirect URI

### Step 1: Find Your App's Port

When Flutter runs, it shows the URL like:
```
Launching lib/main.dart on Chrome in debug mode...
Flutter run key commands.
...
The Flutter DevTools debugger and profiler on Chrome is available at: http://127.0.0.1:XXXXX
```

**Note the port number** (usually 5000, 8080, or similar)

### Step 2: Add Redirect URI to OAuth Client

1. Go to: https://console.cloud.google.com/apis/credentials?project=wedecorenquries
2. Click on your **"We Decor Enquiries Web"** OAuth client
3. Under **"Authorized redirect URIs"**, click **"+ ADD URI"**
4. Add these URIs (replace `PORT` with your actual port):
   ```
   http://localhost:PORT
   http://127.0.0.1:PORT
   ```
   
   **Common ports to try:**
   - `http://localhost:5000`
   - `http://localhost:8080`
   - `http://127.0.0.1:5000`
   - `http://127.0.0.1:8080`

5. Click **"SAVE"**

### Step 3: Also Add These (If Not Already Added)

Make sure these are also in your **Authorized redirect URIs**:
```
http://localhost:5000
https://wedecorenquries.web.app
https://wedecorenquries.firebaseapp.com
```

### Step 4: Restart the App

After adding the redirect URIs:
1. Stop the app
2. Run again: `flutter run -d chrome`
3. Try "Connect Google Drive" again

## Quick Check

To find your exact port, look at:
- The terminal output when Flutter launches
- The browser address bar (shows `http://localhost:PORT`)

## Important Notes

- The redirect URI must match **exactly** (including `http://` vs `https://`)
- No trailing slash
- Port number must match exactly
- You can add multiple redirect URIs

