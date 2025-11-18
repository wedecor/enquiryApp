#!/bin/bash

# WeDecor Enquiries App Setup Script
# This script sets up the complete development environment for the WeDecor Enquiries Flutter app

set -e  # Exit on any error

echo "🚀 WeDecor Enquiries App Setup"
echo "=============================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_step() {
    echo -e "${BLUE}📋 Step: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if Flutter is installed
print_step "Checking Flutter installation"
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed. Please install Flutter first:"
    echo "https://flutter.dev/docs/get-started/install"
    exit 1
fi
print_success "Flutter is installed"

# Check Flutter doctor
print_step "Running Flutter doctor"
flutter doctor

# Check if Firebase CLI is installed
print_step "Checking Firebase CLI installation"
if ! command -v firebase &> /dev/null; then
    print_warning "Firebase CLI is not installed. Installing now..."
    if command -v npm &> /dev/null; then
        npm install -g firebase-tools
        print_success "Firebase CLI installed via npm"
    else
        print_error "npm is not available. Please install Node.js and npm first, then run:"
        echo "npm install -g firebase-tools"
        exit 1
    fi
else
    print_success "Firebase CLI is already installed"
fi

# Login to Firebase (if not already logged in)
print_step "Checking Firebase authentication"
if ! firebase projects:list &> /dev/null; then
    print_warning "Please login to Firebase"
    firebase login
fi

# Get current directory
PROJECT_DIR=$(pwd)
echo "Working in directory: $PROJECT_DIR"

# Clean and get dependencies
print_step "Getting Flutter dependencies"
flutter clean
flutter pub get

print_success "Dependencies installed"

# Generate code (Freezed, Riverpod, etc.)
print_step "Generating code (Freezed, Riverpod, JSON serialization)"
flutter packages pub run build_runner build --delete-conflicting-outputs

print_success "Code generation completed"

# Configure Firebase for Flutter
print_step "Configuring Firebase for Flutter"

# Check if flutterfire CLI is installed
if ! command -v flutterfire &> /dev/null; then
    print_warning "FlutterFire CLI is not installed. Installing now..."
    dart pub global activate flutterfire_cli
    print_success "FlutterFire CLI installed"
fi

# List available Firebase projects
echo ""
print_step "Available Firebase projects:"
firebase projects:list

echo ""
read -p "Enter your Firebase project ID (e.g., wedecorenquries): " FIREBASE_PROJECT_ID

if [ -z "$FIREBASE_PROJECT_ID" ]; then
    print_error "Firebase project ID is required"
    exit 1
fi

# Configure FlutterFire
print_step "Configuring FlutterFire for project: $FIREBASE_PROJECT_ID"
flutterfire configure --project=$FIREBASE_PROJECT_ID

print_success "Firebase configuration completed"

# Set up Firebase Functions (if directory exists)
if [ -d "functions" ]; then
    print_step "Setting up Firebase Functions"
    cd functions
    if [ -f "package.json" ]; then
        npm install
        print_success "Firebase Functions dependencies installed"
    fi
    cd ..
fi

# Create environment configuration
print_step "Creating environment configuration"

# Create .env file template
cat > .env.template << EOF
# Firebase Configuration
FIREBASE_API_KEY=your_api_key_here
FIREBASE_PROJECT_ID=$FIREBASE_PROJECT_ID
FIREBASE_MESSAGING_SENDER_ID=your_sender_id_here
FIREBASE_APP_ID=your_app_id_here

# For web deployment
NEXT_PUBLIC_GOOGLE_API_KEY=your_web_api_key_here

# Development settings
FLUTTER_ENV=development
DEBUG_MODE=true
EOF

if [ ! -f ".env" ]; then
    cp .env.template .env
    print_warning "Created .env file from template. Please update with your actual values."
fi

# Set up Android
print_step "Setting up Android configuration"

# Check if Android SDK is available
if flutter doctor | grep -q "Android toolchain"; then
    print_success "Android toolchain is available"
    
    # Check if google-services.json exists and is not a template
    if [ -f "android/app/google-services.json" ]; then
        if grep -q "REPLACE_WITH_YOUR_ANDROID_API_KEY" android/app/google-services.json; then
            print_warning "google-services.json is using template values"
            print_warning "The file will be updated by flutterfire configure command"
        else
            print_success "google-services.json appears to be properly configured"
        fi
    else
        print_warning "google-services.json not found - should be created by flutterfire configure"
    fi
else
    print_warning "Android toolchain not available. Android development will not work."
fi

# Set up iOS (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    print_step "Setting up iOS configuration"
    if flutter doctor | grep -q "Xcode"; then
        print_success "Xcode is available"
        
        # Install CocoaPods if not available
        if ! command -v pod &> /dev/null; then
            print_warning "CocoaPods not installed. Installing..."
            sudo gem install cocoapods
        fi
        
        # Install iOS pods
        if [ -d "ios" ]; then
            cd ios
            pod install
            cd ..
            print_success "iOS pods installed"
        fi
    else
        print_warning "Xcode not available. iOS development will not work."
    fi
fi

# Create run scripts
print_step "Creating run scripts"

# Android run script
cat > run_android.sh << 'EOF'
#!/bin/bash
echo "🤖 Starting Android app..."

# Check if emulator is running
if ! adb devices | grep -q "emulator"; then
    echo "Starting Android emulator..."
    flutter emulators --launch Pixel_8_Pro_API_35 &
    sleep 30
fi

# Run the app
flutter run -d android
EOF
chmod +x run_android.sh

# iOS run script (if on macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    cat > run_ios.sh << 'EOF'
#!/bin/bash
echo "📱 Starting iOS app..."

# Run the app
flutter run -d ios
EOF
    chmod +x run_ios.sh
fi

# Web run script
cat > run_web.sh << 'EOF'
#!/bin/bash
echo "🌐 Starting web app..."

# Run the app
flutter run -d chrome --web-port=3000
EOF
chmod +x run_web.sh

# Build script
cat > build.sh << 'EOF'
#!/bin/bash
echo "🏗️ Building app for all platforms..."

# Clean first
flutter clean
flutter pub get

# Generate code
flutter packages pub run build_runner build --delete-conflicting-outputs

# Build for different platforms
echo "Building for Android..."
flutter build apk --release

if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Building for iOS..."
    flutter build ios --release --no-codesign
fi

echo "Building for Web..."
flutter build web --release

echo "✅ Build completed!"
EOF
chmod +x build.sh

print_success "Run scripts created (run_android.sh, run_web.sh, build.sh)"

# Final setup verification
print_step "Verifying setup"

echo ""
echo "🔍 Setup Verification:"
echo "====================="

# Check Flutter
if flutter doctor --machine | jq -r '.[] | select(.category=="FlutterValidator") | .statusHelp' | grep -q "No issues found"; then
    print_success "Flutter: OK"
else
    print_warning "Flutter: Some issues found (check 'flutter doctor')"
fi

# Check Firebase files
if [ -f "lib/firebase_options.dart" ]; then
    print_success "Firebase options: OK"
else
    print_warning "Firebase options: Missing (run 'flutterfire configure')"
fi

# Check dependencies
if [ -f "pubspec.lock" ]; then
    print_success "Dependencies: OK"
else
    print_warning "Dependencies: Run 'flutter pub get'"
fi

print_step "Setup completed!"

echo ""
echo "🎉 WeDecor Enquiries App Setup Complete!"
echo "========================================"
echo ""
echo "📋 Next Steps:"
echo "1. Update .env file with your actual Firebase configuration values"
echo "2. Run the app using provided scripts:"
echo "   • ./run_android.sh  - Run on Android"
if [[ "$OSTYPE" == "darwin"* ]]; then
echo "   • ./run_ios.sh      - Run on iOS"
fi
echo "   • ./run_web.sh      - Run on Web"
echo "   • ./build.sh        - Build for all platforms"
echo ""
echo "3. For development:"
echo "   • flutter run                    - Run with hot reload"
echo "   • flutter run -d chrome         - Run on web"
echo "   • flutter run -d android        - Run on Android"
echo ""
echo "4. Check Firebase Console to ensure your project is properly configured"
echo ""
print_success "Happy coding! 🚀"
EOF
chmod +x setup.sh











