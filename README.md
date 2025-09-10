# WeDecor Enquiry Management App

A production-grade Flutter app for managing event enquiries with role-based access control and admin approval workflow.

## 🚀 Current Status: DEMO MODE

The app is currently running in **demo mode** with mock data to showcase the UI and functionality without requiring Firebase setup.

### What You'll See:
- **Awaiting Approval Screen** - Shows for all users (demo mode)
- **Enquiries List** - Sample enquiries with contact actions
- **Admin Users** - User management interface with demo actions
- **Contact Integration** - WhatsApp and Call buttons (will open web versions)

## 🛠️ Next Steps to Go Live:

### 1. Set up Firebase Project
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login and initialize
firebase login
firebase init

# Deploy rules and functions
firebase deploy --only firestore:rules,functions
```

### 2. Configure Firebase Options
Replace the placeholder values in `lib/firebase_options.dart` with your actual Firebase project configuration.

### 3. Enable Firebase in the App
Uncomment the Firebase initialization in `lib/main.dart`:
```dart
await FirebaseBootstrap.initialize();
```

### 4. Seed Initial Data
```bash
# Seed admin user
node tools/seed-admin.ts

# Seed dropdown options
node tools/seed-dropdowns.ts
```

## 📱 Features Implemented:

### ✅ Core Features:
- **User Management**: Self-signup → admin approval workflow
- **Role-Based Access**: admin, partner, staff, pending roles
- **Enquiry Management**: Full CRUD with status tracking
- **Contact Integration**: WhatsApp & Call deep links
- **Admin Dashboard**: User approval and role management
- **Approval Gate**: Blocks unapproved users from accessing data

### ✅ Security:
- Firestore rules enforce RBAC at database level
- Custom claims for role-based access
- Approval workflow prevents unauthorized access
- Payment validation and balance enforcement

### ✅ UI/UX:
- Material 3 design system
- Responsive layout (web, mobile, desktop)
- Clean, modern interface
- Intuitive navigation

## 🔧 Technical Stack:

- **Frontend**: Flutter 3.24.5, Dart 3.5.4
- **State Management**: Riverpod 2
- **Navigation**: go_router 14+
- **Backend**: Firebase (Auth, Firestore, Functions, FCM)
- **Data Models**: Freezed/JSON serialization
- **Testing**: Jest (Functions), Flutter tests

## 📁 Project Structure:

```
lib/
├── core/
│   ├── models/          # Data models (User, Enquiry, etc.)
│   ├── providers/       # Firebase providers
│   ├── utils/           # Helper functions (phone, contact)
│   └── firebase_init.dart
├── features/
│   ├── auth/            # Authentication providers
│   ├── admin/           # Admin user management
│   └── enquiries/       # Enquiry management screens
└── router/              # App routing configuration
```

## 🚀 Deployment:

### Web (Firebase Hosting):
```bash
flutter build web
firebase deploy --only hosting
```

### Mobile (Private Distribution):
- **Android**: Firebase App Distribution
- **iOS**: TestFlight

## 🔒 Security Notes:

- All data access blocked for unapproved users
- Role-based permissions enforced at database level
- Custom claims for authentication
- Payment validation and balance enforcement
- Audit trail for all changes

## 📞 Support:

For questions or issues, refer to the comprehensive setup guide in the project documentation.

---

**Ready to go live?** Follow the setup steps above to connect to Firebase and deploy your production-ready enquiry management system! 🎉