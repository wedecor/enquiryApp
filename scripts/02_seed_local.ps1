# PowerShell script for Windows users
param(
    [string]$KeyFile = "serviceAccountKey.json",
    [string]$EnvFile = ".env"
)

$ErrorActionPreference = "Stop"

Write-Host "🌱 WeDecor Local Seeding (Windows)" -ForegroundColor Green
Write-Host "Environment: $EnvFile"
Write-Host "Service Account: $KeyFile"
Write-Host ""

# Check if .env file exists
if (-Not (Test-Path $EnvFile)) {
    Write-Host "❌ Environment file not found: $EnvFile" -ForegroundColor Red
    Write-Host "   Create it with: echo 'ADMIN_UID=your_firebase_auth_uid' > $EnvFile"
    exit 1
}

# Read ADMIN_UID from .env
$envContent = Get-Content $EnvFile -Raw
if ($envContent -notmatch "ADMIN_UID=") {
    Write-Host "❌ ADMIN_UID not found in $EnvFile" -ForegroundColor Red
    Write-Host "   Add it with: echo 'ADMIN_UID=your_firebase_auth_uid' >> $EnvFile"
    exit 1
}

$adminUidLine = ($envContent -split "`n" | Where-Object { $_ -match "ADMIN_UID=" })[0]
$adminUid = ($adminUidLine -split "=", 2)[1].Trim().Trim('"').Trim("'")

if ([string]::IsNullOrWhiteSpace($adminUid) -or $adminUid -eq "your_firebase_auth_uid") {
    Write-Host "❌ ADMIN_UID not properly set in $EnvFile" -ForegroundColor Red
    Write-Host "   Current value: '$adminUid'"
    Write-Host "   Set it to your actual Firebase Auth UID"
    exit 1
}

Write-Host "✅ ADMIN_UID found: $adminUid" -ForegroundColor Green

# Set up credentials
if ($env:GOOGLE_APPLICATION_CREDENTIALS) {
    Write-Host "✅ Using existing GOOGLE_APPLICATION_CREDENTIALS: $env:GOOGLE_APPLICATION_CREDENTIALS" -ForegroundColor Green
} elseif (Test-Path $KeyFile) {
    $env:GOOGLE_APPLICATION_CREDENTIALS = (Resolve-Path $KeyFile).Path
    Write-Host "✅ Using service account key: $env:GOOGLE_APPLICATION_CREDENTIALS" -ForegroundColor Green
} else {
    Write-Host "❌ No authentication method found" -ForegroundColor Red
    Write-Host "   Either:"
    Write-Host "   1. Set GOOGLE_APPLICATION_CREDENTIALS environment variable"
    Write-Host "   2. Create $KeyFile using gcloud or Firebase Console"
    exit 1
}

# Install dependencies
Write-Host "📦 Installing dependencies..." -ForegroundColor Yellow
if (Test-Path "package-lock.json") {
    npm ci
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies with npm ci" -ForegroundColor Red
        exit 1
    }
} else {
    npm install
    if ($LASTEXITCODE -ne 0) {
        Write-Host "❌ Failed to install dependencies with npm install" -ForegroundColor Red
        exit 1
    }
}

Write-Host "✅ Dependencies installed" -ForegroundColor Green

# Run TypeScript type checking
Write-Host "🔍 Running type check..." -ForegroundColor Yellow
npm run typecheck
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ TypeScript type check failed" -ForegroundColor Red
    exit 1
}

Write-Host "✅ Type check passed" -ForegroundColor Green

# Run the seeder
Write-Host "🌱 Running Firestore seeder..." -ForegroundColor Yellow
npm run seed
if ($LASTEXITCODE -ne 0) {
    Write-Host "❌ Seeding failed" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "🎉 Seeding completed successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "🎯 Next steps:"
Write-Host "   1. Restart your Flutter app"
Write-Host "   2. Loading symbols should be eliminated"
Write-Host "   3. All dropdowns should work perfectly"
Write-Host ""
Write-Host "📊 Your Firestore now contains:"
Write-Host "   • Dropdown collections (statuses, event_types, priorities, payment_statuses)"
Write-Host "   • Admin user document"
Write-Host "   • Sample enquiry with history"

