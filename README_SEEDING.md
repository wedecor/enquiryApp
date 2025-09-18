# WeDecor Firestore Seeding - Complete Automation

## 🚀 Three Ways to Seed (Choose One)

### Option A: Local (Recommended)
```bash
# 1. Create service account automatically
chmod +x scripts/*.sh
export PROJECT_ID=wedecorenquries
./scripts/01_create_service_account_and_key.sh

# 2. Set admin UID and seed
echo "ADMIN_UID=your_firebase_auth_uid" > .env
./scripts/02_seed_local.sh
```

### Option B: Docker
```bash
# 1. Ensure serviceAccountKey.json exists (from Option A step 1)
# 2. Set admin UID and seed
echo "ADMIN_UID=your_firebase_auth_uid" > .env
./scripts/03_seed_docker.sh
```

### Option C: GitHub Actions
```bash
# 1. Add secret GOOGLE_CREDENTIALS (full service account JSON)
# 2. Run workflow with admin_uid=your_firebase_auth_uid
# 3. Done! (Re-run anytime - it's idempotent)
```

## Run the GitHub Actions workflow

1) Add secret once:
   - Repo → Settings → Secrets and variables → Actions → New repository secret
   - Name: GOOGLE_CREDENTIALS
   - Value: paste the full JSON of the 'wedecor-seeder' service account key

2) Ensure workflow is on default branch:
   - File: .github/workflows/seed.yml
   - Commit to main (or master)

3) Validate locally:
```bash
npm run check-workflow
```

**Trigger from GitHub UI:**
Actions → Seed Firestore (WeDecor) → Run workflow → admin_uid=<YOUR_AUTH_UID>

**Or trigger from CLI:**
```bash
export ADMIN_UID=<YOUR_AUTH_UID>
npm run gh-run-seed
```

## 📊 What Gets Created

### Dropdown Collections (Fixes Loading Symbols):
- `dropdowns/statuses/items/*` (8 status options)
- `dropdowns/event_types/items/*` (6 event types) 
- `dropdowns/priorities/items/*` (4 priority levels)
- `dropdowns/payment_statuses/items/*` (4 payment statuses)

### User & Sample Data:
- `users/{ADMIN_UID}` (admin user)
- Sample enquiry with history (for testing)

## ✅ Features

- **🔒 Production-Ready**: Zod validation, TypeScript, error handling
- **🔄 Idempotent**: Safe to re-run multiple times
- **⚡ Automated**: Zero manual Firebase Console work
- **🐳 Multi-Platform**: Local, Docker, GitHub Actions support
- **📝 Comprehensive**: Complete data model with audit trails

## 🎯 Expected Results

After seeding:
- ✅ **No more loading symbols** in Flutter app
- ✅ **All dropdowns work perfectly**
- ✅ **Clean console output** (no Firestore errors)
- ✅ **Professional UX** with instant loading

## 🛠️ Troubleshooting

### gcloud not found
```bash
# Install Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud auth login
```

### Permission denied
```bash
# Ensure you're project owner/editor
gcloud projects get-iam-policy wedecorenquries
```

### Docker issues
```bash
# Ensure Docker is running
docker --version
docker-compose --version
```

## 📋 Files Generated

- ✅ `scripts/01_create_service_account_and_key.sh` - Auto SA creation
- ✅ `scripts/02_seed_local.sh` - Local seeding automation  
- ✅ `scripts/02_seed_local.ps1` - Windows PowerShell version
- ✅ `scripts/03_seed_docker.sh` - Docker seeding
- ✅ `Dockerfile` + `docker-compose.yml` - Container setup
- ✅ `.github/workflows/seed.yml` - CI/CD seeding
- ✅ TypeScript seeder with Zod validation
- ✅ Complete Firebase Admin SDK setup

## Local one-shot seeding

```bash
# 0) Install deps
npm i

# 1) Put your Firebase service account at:
#    ./serviceAccountKey.json
#    OR export GOOGLE_APPLICATION_CREDENTIALS to its absolute path.

# 2) Run the full pipeline (UID → seed → verify)
npm run seed:local
```

**Defaults:**

Admin email: admin@wedecorevents.com

Temp password: admin12 (change later in Firebase Console)

**This is the ultimate, enterprise-grade solution for your Firestore seeding needs!** 🚀
