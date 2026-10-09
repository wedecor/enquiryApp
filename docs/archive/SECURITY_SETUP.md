# 🔒 Security Setup Guide

This guide explains how to securely manage API keys and environment variables for the We Decor Enquiries app.

## 🚨 **CRITICAL: API Key Security**

Your Firebase API keys have been removed from the codebase for security. You must set up environment variables before deploying.

## 📋 **Required Environment Variables**

### For Vercel Deployment:
```bash
NEXT_PUBLIC_GOOGLE_API_KEY=your_new_firebase_api_key_here
FIREBASE_API_KEY=your_new_firebase_api_key_here
```

### For Local Development:
Create a `.env` file in the project root:
```bash
FIREBASE_API_KEY=your_new_firebase_api_key_here
```

## 🔧 **Setup Instructions**

### 1. Generate New API Keys

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Navigate to your Firebase project
3. Go to **APIs & Services** > **Credentials**
4. **Revoke the old API key** that was leaked
5. **Create new API keys** for each platform:
   - Web API key
   - Android API key
   - iOS API key

### 2. Set Up Vercel Environment Variables

1. Go to your Vercel dashboard
2. Select your project
3. Go to **Settings** > **Environment Variables**
4. Add the following variables:
   ```
   Name: NEXT_PUBLIC_GOOGLE_API_KEY
   Value: your_new_web_api_key
   Environment: Production, Preview, Development
   ```

### 3. Local Development Setup

1. Create a `.env` file in the project root
2. Add your API key:
   ```
   FIREBASE_API_KEY=your_new_api_key
   ```
3. **Never commit the `.env` file** (it's already in `.gitignore`)

## 🏗️ **Build Commands**

### For Vercel (Automatic):
Vercel will automatically use the environment variables set in the dashboard.

### For Local Development:
```bash
# Set environment variable and build
export FIREBASE_API_KEY=your_api_key
flutter build web --release

# Or use the build script
./scripts/build_with_env.sh
```

## 🔍 **Security Verification**

The app includes security checks that will warn you if:
- API keys are not using environment variables
- Placeholder values are being used in production

### Check Security Status:
```bash
flutter run -d chrome
# Look for security warnings in the console
```

## 🚫 **What NOT to Do**

- ❌ Never hardcode API keys in source code
- ❌ Never commit `.env` files
- ❌ Never share API keys in public repositories
- ❌ Never use the old leaked API key

## ✅ **What TO Do**

- ✅ Always use environment variables
- ✅ Keep API keys secure and private
- ✅ Regularly rotate API keys
- ✅ Monitor API key usage
- ✅ Use different keys for different environments

## 🔄 **API Key Rotation**

If you suspect an API key has been compromised:

1. **Immediately revoke** the key in Google Cloud Console
2. **Generate a new key**
3. **Update all environment variables**
4. **Redeploy your application**
5. **Monitor for unauthorized usage**

## 📞 **Support**

If you need help with security setup:
1. Check the Firebase documentation
2. Review Vercel environment variable guides
3. Contact your development team

---

**Remember: Security is everyone's responsibility!** 🔒 