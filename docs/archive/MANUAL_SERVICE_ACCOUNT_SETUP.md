# 🔑 Manual Service Account Setup (gcloud not available)

Since `gcloud` CLI is not installed, here's how to create the service account manually:

## Step 1: Create Service Account

1. Go to [Google Cloud Console](https://console.cloud.google.com/iam-admin/serviceaccounts?project=wedecorenquries)
2. Click **"+ CREATE SERVICE ACCOUNT"**
3. **Service account name**: `wedecor-seeder`
4. **Service account ID**: `wedecor-seeder` (auto-filled)
5. **Description**: `WeDecor Firestore Seeder`
6. Click **"CREATE AND CONTINUE"**

## Step 2: Grant Roles

Add these roles to the service account:
- ✅ **Datastore User** (`roles/datastore.user`)
- ✅ **Viewer** (`roles/viewer`)

1. In the roles section, click **"+ ADD ANOTHER ROLE"**
2. Search for "Datastore User" and select it
3. Click **"+ ADD ANOTHER ROLE"** again
4. Search for "Viewer" and select it
5. Click **"CONTINUE"** then **"DONE"**

## Step 3: Create Key

1. Find your new service account in the list
2. Click the **email address** to open details
3. Go to **"KEYS"** tab
4. Click **"ADD KEY"** → **"Create new key"**
5. Select **"JSON"** format
6. Click **"CREATE"**
7. **Save the downloaded file as `serviceAccountKey.json`** in your project root

## Step 4: Run Seeder

```bash
# Set environment
echo "ADMIN_UID=your_firebase_auth_uid" > .env
export GOOGLE_APPLICATION_CREDENTIALS="$PWD/serviceAccountKey.json"

# Run seeder
npm run seed
```

## 🎯 Alternative: Use GitHub Actions

If manual setup is too complex, use GitHub Actions:

1. **Add GitHub Secret**: `GOOGLE_CREDENTIALS` (paste the entire JSON content)
2. **Run Workflow**: Go to Actions tab → "Seed Firestore Database" → Run with your admin UID
3. **Done!** Zero local setup required

---

**This manual approach will work 100% and eliminate all loading symbols in your Flutter app!** ✅

