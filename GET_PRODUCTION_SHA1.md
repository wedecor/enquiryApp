# Get Production SHA-1 Fingerprint

## Option 1: If You Have a Release Keystore

If you already have a release keystore file (`.jks` or `.keystore`), run:

```bash
keytool -list -v -keystore /path/to/your/release.keystore -alias your-alias
```

**You'll need:**
- Keystore file path
- Keystore password
- Key alias
- Key password

Then look for the line:
```
SHA1: XX:XX:XX:XX:...
```

## Option 2: Create a New Release Keystore

If you don't have one yet, create it:

```bash
keytool -genkey -v -keystore ~/release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias release
```

**You'll be asked for:**
- Keystore password (remember this!)
- Key password (can be same as keystore password)
- Your name, organization, etc.

**Then get the SHA-1:**
```bash
keytool -list -v -keystore ~/release-keystore.jks -alias release
```

## Option 3: Check Google Play Console

If your app is already published on Google Play:
1. Go to Google Play Console
2. Your app → Setup → App signing
3. You'll see the SHA-1 fingerprint there

## Option 4: Use Debug Keystore for Now

For testing, you can use the debug SHA-1 we already got:
```
54:BA:5F:E4:00:AD:1A:3F:05:7E:09:B0:32:25:8E:D2:14:D4:D0:5B
```

You can add the production SHA-1 later when you have it.

## Important Notes

- **Debug SHA-1**: For development/testing (what we got earlier)
- **Production SHA-1**: For release builds (from release keystore)
- You can add **multiple SHA-1 fingerprints** to the same OAuth client ID
- Add both debug and production SHA-1s to cover all scenarios

