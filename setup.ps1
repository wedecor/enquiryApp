# WeDecor Enquiries App Setup Script (PowerShell)
# This script sets up the complete development environment for the WeDecor Enquiries Flutter app

param(
    [string]$FirebaseProjectId = ""
)

Write-Host "🚀 WeDecor Enquiries App Setup" -ForegroundColor Blue
Write-Host "==============================" -ForegroundColor Blue
Write-Host ""

function Write-Step {
    param([string]$Message)
    Write-Host "📋 Step: $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check if Flutter is installed
Write-Step "Checking Flutter installation"
try {
    $flutterVersion = flutter --version 2>$null
    Write-Success "Flutter is installed"
} catch {
    Write-Error "Flutter is not installed. Please install Flutter first:"
    Write-Host "https://flutter.dev/docs/get-started/install"
    exit 1
}

# Check Flutter doctor
Write-Step "Running Flutter doctor"
flutter doctor

# Check if Firebase CLI is installed
Write-Step "Checking Firebase CLI installation"
try {
    $firebaseVersion = firebase --version 2>$null
    Write-Success "Firebase CLI is already installed"
} catch {
    Write-Warning "Firebase CLI is not installed. Please install it first:"
    Write-Host "npm install -g firebase-tools"
    Write-Host "Or download from: https://firebase.google.com/docs/cli"
    
    # Try to install via npm if available
    try {
        npm --version 2>$null | Out-Null
        Write-Warning "Attempting to install Firebase CLI via npm..."
        npm install -g firebase-tools
        Write-Success "Firebase CLI installed via npm"
    } catch {
        Write-Error "Please install Firebase CLI manually and run this script again"
        exit 1
    }
}

# Login to Firebase (if not already logged in)
Write-Step "Checking Firebase authentication"
try {
    firebase projects:list 2>$null | Out-Null
    Write-Success "Firebase authentication OK"
} catch {
    Write-Warning "Please login to Firebase"
    firebase login
}

# Get current directory
$ProjectDir = Get-Location
Write-Host "Working in directory: $ProjectDir"

# Clean and get dependencies
Write-Step "Getting Flutter dependencies"
flutter clean
flutter pub get
Write-Success "Dependencies installed"

# Generate code (Freezed, Riverpod, etc.)
Write-Step "Generating code (Freezed, Riverpod, JSON serialization)"
flutter packages pub run build_runner build --delete-conflicting-outputs
Write-Success "Code generation completed"

# Configure Firebase for Flutter
Write-Step "Configuring Firebase for Flutter"

# Check if flutterfire CLI is installed
try {
    flutterfire --version 2>$null | Out-Null
    Write-Success "FlutterFire CLI is available"
} catch {
    Write-Warning "FlutterFire CLI is not installed. Installing now..."
    dart pub global activate flutterfire_cli
    Write-Success "FlutterFire CLI installed"
}

# List available Firebase projects
Write-Host ""
Write-Step "Available Firebase projects:"
firebase projects:list

Write-Host ""
if ($FirebaseProjectId -eq "") {
    $FirebaseProjectId = Read-Host "Enter your Firebase project ID (e.g., wedecorenquries)"
}

if ($FirebaseProjectId -eq "") {
    Write-Error "Firebase project ID is required"
    exit 1
}

# Configure FlutterFire
Write-Step "Configuring FlutterFire for project: $FirebaseProjectId"
flutterfire configure --project=$FirebaseProjectId
Write-Success "Firebase configuration completed"

# Set up Firebase Functions (if directory exists)
if (Test-Path "functions") {
    Write-Step "Setting up Firebase Functions"
    Push-Location functions
    if (Test-Path "package.json") {
        npm install
        Write-Success "Firebase Functions dependencies installed"
    }
    Pop-Location
}

# Create environment configuration
Write-Step "Creating environment configuration"

# Create .env file template
$envTemplate = @"
# Firebase Configuration
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=$FirebaseProjectId
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_APP_ID=your_app_id_here

# For web deployment
NEXT_PUBLIC_GOOGLE_API_KEY=your_web_api_key_here

# Development settings
FLUTTER_ENV=development
DEBUG_MODE=true
"@

$envTemplate | Out-File -FilePath ".env.template" -Encoding UTF8

if (-not (Test-Path ".env")) {
    Copy-Item ".env.template" ".env"
    Write-Warning "Created .env file from template. Please update with your actual values."
}

# Set up Android
Write-Step "Setting up Android configuration"

# Check if Android SDK is available
$flutterDoctorOutput = flutter doctor
if ($flutterDoctorOutput -match "Android toolchain") {
    Write-Success "Android toolchain is available"
    
    # Check if google-services.json exists and is not a template
    if (Test-Path "android/app/google-services.json") {
        $googleServicesContent = Get-Content "android/app/google-services.json" -Raw
        if ($googleServicesContent -match "REPLACE_WITH_YOUR_ANDROID_API_KEY") {
            Write-Warning "google-services.json is using template values"
            Write-Warning "The file will be updated by flutterfire configure command"
        } else {
            Write-Success "google-services.json appears to be properly configured"
        }
    } else {
        Write-Warning "google-services.json not found - should be created by flutterfire configure"
    }
} else {
    Write-Warning "Android toolchain not available. Android development will not work."
}

# Create run scripts
Write-Step "Creating run scripts"

# Android run script
$androidScript = @'
@echo off
echo 🤖 Starting Android app...

REM Check if emulator is running
adb devices | findstr "emulator" >nul
if errorlevel 1 (
    echo Starting Android emulator...
    start /B flutter emulators --launch Pixel_8_Pro_API_35
    timeout /t 30 /nobreak >nul
)

REM Run the app
flutter run -d android
'@
$androidScript | Out-File -FilePath "run_android.bat" -Encoding ASCII

# Web run script
$webScript = @'
@echo off
echo 🌐 Starting web app...

REM Run the app
flutter run -d chrome --web-port=3000
'@
$webScript | Out-File -FilePath "run_web.bat" -Encoding ASCII

# Build script
$buildScript = @'
@echo off
echo 🏗️ Building app for all platforms...

REM Clean first
flutter clean
flutter pub get

REM Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

REM Build for different platforms
echo Building for Android...
flutter build apk --release

echo Building for Web...
flutter build web --release

echo ✅ Build completed!
'@
$buildScript | Out-File -FilePath "build.bat" -Encoding ASCII

Write-Success "Run scripts created (run_android.bat, run_web.bat, build.bat)"

# Final setup verification
Write-Step "Verifying setup"

Write-Host ""
Write-Host "🔍 Setup Verification:" -ForegroundColor Blue
Write-Host "=====================" -ForegroundColor Blue

# Check Firebase files
if (Test-Path "lib/firebase_options.dart") {
    Write-Success "Firebase options: OK"
} else {
    Write-Warning "Firebase options: Missing (run 'flutterfire configure')"
}

# Check dependencies
if (Test-Path "pubspec.lock") {
    Write-Success "Dependencies: OK"
} else {
    Write-Warning "Dependencies: Run 'flutter pub get'"
}

Write-Step "Setup completed!"

Write-Host ""
Write-Host "🎉 WeDecor Enquiries App Setup Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Next Steps:" -ForegroundColor Blue
Write-Host "1. Update .env file with your actual Firebase configuration values"
Write-Host "2. Run the app using provided scripts:"
Write-Host "   • run_android.bat  - Run on Android"
Write-Host "   • run_web.bat      - Run on Web"
Write-Host "   • build.bat        - Build for all platforms"
Write-Host ""
Write-Host "3. For development:"
Write-Host "   • flutter run                    - Run with hot reload"
Write-Host "   • flutter run -d chrome         - Run on web"
Write-Host "   • flutter run -d android        - Run on Android"
Write-Host ""
Write-Host "4. Check Firebase Console to ensure your project is properly configured"
Write-Host ""
Write-Success "Happy coding! 🚀"












