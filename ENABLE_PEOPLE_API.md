# Enable People API (Quick Fix)

## The Issue

The `google_sign_in` package tries to fetch user profile information using the People API, but this API is not enabled in your Google Cloud project.

## Solution: Enable People API

### Step 1: Go to People API Page

**Direct link:** https://console.developers.google.com/apis/api/people.googleapis.com/overview?project=747327664982

Or navigate:
- Google Cloud Console → APIs & Services → Library
- Search for "People API"
- Click on "People API"
- Click "ENABLE"

### Step 2: Wait a Few Minutes

After enabling, wait 2-3 minutes for the API to propagate.

### Step 3: Try Again

Go back to your app and try "Connect Google Drive" again.

## Alternative: Code Workaround

The code has been updated to handle this error gracefully. Even if the People API is not enabled, the Drive API should still work. However, enabling the People API is the recommended solution.

## Why This Happens

The `google_sign_in` package automatically tries to fetch user profile information (email, name, photo) using the People API after authentication. This is optional for Drive API operations, but the package expects it to be available.

