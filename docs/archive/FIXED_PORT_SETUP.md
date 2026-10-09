# Fixed Port Setup for Google Drive

## Fixed Port Configuration

The app is now configured to always run on **port 5000**.

## OAuth Client Configuration

Make sure your OAuth client has these redirect URIs:

### Authorized JavaScript origins:
```
http://localhost:5000
https://wedecorenquries.web.app
https://wedecorenquries.firebaseapp.com
```

### Authorized redirect URIs:
```
http://localhost:5000
https://wedecorenquries.web.app
https://wedecorenquries.firebaseapp.com
```

## Running the App

Always use this command to ensure consistent port:
```bash
flutter run -d chrome --web-port=5000
```

Or create an alias in your shell:
```bash
alias flutter-web="flutter run -d chrome --web-port=5000"
```

Then just run: `flutter-web`

## Benefits

- ✅ Consistent port (always 5000)
- ✅ OAuth redirect URI always matches
- ✅ No need to update OAuth client each time
- ✅ Easier to remember and configure

## Next Steps

1. Add `http://localhost:5000` to your OAuth client redirect URIs (if not already added)
2. Restart the app with: `flutter run -d chrome --web-port=5000`
3. Try "Connect Google Drive" - it should work now!

