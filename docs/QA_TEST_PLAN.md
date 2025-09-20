# QA Test Plan - We Decor Enquiries RC1 → RC2

**Version**: 1.0.1+2 (RC1) → 1.0.1+3 (RC2)  
**Testing Period**: September 21-28, 2024  
**QA Lead**: [TO_BE_ASSIGNED]  
**Target**: Zero P0 bugs, ≤3 P1 bugs for RC2 release

---

## 🎯 **Testing Scope**

### **Core Features (P0 - Must Work)**
1. **Authentication Flow**
   - Login with email/password
   - Logout functionality
   - Session persistence
   - Error handling for invalid credentials

2. **Enquiry Management**
   - Create new enquiry with all required fields
   - View enquiry list with filters
   - Update enquiry status and details
   - Delete enquiry (admin only)

3. **Offline Functionality**
   - Network disconnection handling
   - Operation queuing when offline
   - Sync when back online
   - User feedback for offline state

4. **Privacy & Consent**
   - Settings > Privacy tab accessibility
   - Analytics consent toggle (off by default)
   - Crashlytics consent toggle
   - Consent persistence across app restarts

### **Secondary Features (P1 - Should Work)**
1. **Admin Functions**
   - User management (admin only)
   - Dropdown management
   - Analytics dashboard
   - System settings

2. **PWA Functionality**
   - Add to Home Screen
   - Offline page loading
   - Service worker caching
   - Responsive design

3. **Notifications**
   - FCM message reception
   - In-app notification display
   - Notification settings

---

## 📱 **Test Matrix**

### **Android Devices**
| Device Type | OS Version | RAM | Storage | Tester | Status |
|-------------|------------|-----|---------|--------|--------|
| **Samsung Galaxy S21** | Android 13 | 8GB | 128GB | [QA_LEAD] | 🔄 In Progress |
| **Google Pixel 6** | Android 14 | 8GB | 128GB | [DEV_TEAM] | ⏳ Pending |
| **OnePlus 9** | Android 13 | 12GB | 256GB | [STAKEHOLDER] | ⏳ Pending |
| **Budget Device** | Android 12 | 4GB | 64GB | [QA_TEAM] | ⏳ Pending |

### **Web PWA Testing**
| Browser | Platform | Viewport | Tester | Status |
|---------|----------|----------|--------|--------|
| **Chrome** | Windows 11 | Desktop | [QA_LEAD] | ⏳ Pending |
| **Chrome** | Android | Mobile | [DEV_TEAM] | ⏳ Pending |
| **Safari** | iOS 16 | Mobile | [STAKEHOLDER] | ⏳ Pending |
| **Firefox** | macOS | Desktop | [QA_TEAM] | ⏳ Pending |

---

## 🧪 **Test Scenarios**

### **Scenario 1: First-Time User Flow**
1. **Install APK** from download page
2. **Verify SHA256** checksum
3. **Launch app** and observe startup time
4. **Complete onboarding** (if any)
5. **Create account** or login
6. **Navigate main features** (dashboard, enquiries, settings)
7. **Test privacy settings** (toggle analytics/crashlytics)

**Expected**: Smooth onboarding, no crashes, privacy controls work

### **Scenario 2: Core Enquiry Workflow**
1. **Login as admin** user
2. **Create new enquiry** with all fields
3. **Upload reference images** (if supported)
4. **Save enquiry** and verify in list
5. **Update enquiry status** from New → In Progress
6. **Add notes** and save changes
7. **Filter enquiries** by status/date

**Expected**: All CRUD operations work, data persists, UI updates

### **Scenario 3: Offline Resilience**
1. **Login and load enquiries**
2. **Disconnect network** (airplane mode)
3. **Attempt to create enquiry** (should queue)
4. **Attempt to update existing** (should queue)
5. **Reconnect network**
6. **Verify operations sync** automatically

**Expected**: Graceful offline handling, successful sync on reconnect

### **Scenario 4: PWA Installation**
1. **Visit PWA URL** in mobile browser
2. **Add to Home Screen** when prompted
3. **Launch from home screen** icon
4. **Test offline functionality** (disconnect network)
5. **Verify app-like behavior** (no browser UI)

**Expected**: Native app experience, offline functionality works

### **Scenario 5: Privacy & Monitoring**
1. **Navigate to Settings > Privacy**
2. **Toggle analytics** off → on → off
3. **Toggle crashlytics** consent
4. **Restart app** and verify settings persist
5. **Check Firebase console** for event data (with consent)

**Expected**: Consent controls work, data collection respects choices

---

## 📊 **Performance Benchmarks**

### **App Startup Time**
| Device Tier | Target | Measured | Status |
|-------------|--------|----------|--------|
| **High-end** (8GB+ RAM) | ≤1.5s | [TBD] | ⏳ |
| **Mid-tier** (6-8GB RAM) | ≤2.0s | [TBD] | ⏳ |
| **Low-end** (4GB RAM) | ≤3.0s | [TBD] | ⏳ |

### **Key Operations**
| Operation | Target | Measured | Status |
|-----------|--------|----------|--------|
| **Enquiry List Load** | ≤1.0s | [TBD] | ⏳ |
| **Create Enquiry** | ≤2.0s | [TBD] | ⏳ |
| **Image Upload** | ≤5.0s | [TBD] | ⏳ |
| **Offline → Online Sync** | ≤3.0s | [TBD] | ⏳ |

### **Web PWA Lighthouse Scores**
| Metric | Target | Measured | Status |
|--------|--------|----------|--------|
| **Performance** | ≥90 | [TBD] | ⏳ |
| **Accessibility** | ≥90 | [TBD] | ⏳ |
| **Best Practices** | ≥90 | [TBD] | ⏳ |
| **SEO** | ≥90 | [TBD] | ⏳ |

---

## 🔍 **Test Execution**

### **Daily Testing Checklist**
- [ ] **Smoke Test**: App launches without crashes
- [ ] **Login Flow**: Authentication works correctly
- [ ] **Core CRUD**: Enquiry operations functional
- [ ] **Offline Mode**: Network resilience verified
- [ ] **Privacy Settings**: Consent controls operational

### **Bug Reporting Process**
1. **Use bug report template** with all required fields
2. **Add appropriate labels**: type, priority, area
3. **Include screenshots/videos** for UI issues
4. **Verify reproducibility** on multiple devices
5. **Assign to milestone**: RC2

### **Test Data Requirements**
- **Clean Install**: Fresh app with no existing data
- **Sample Data**: Realistic enquiry dataset for testing
- **Edge Cases**: Empty states, large datasets, special characters
- **User Roles**: Admin and staff user accounts

---

## 📈 **Success Criteria**

### **RC2 Release Gates**
- ✅ **P0 Bugs**: 0 (all critical issues resolved)
- ✅ **P1 Bugs**: ≤3 (documented with owners and ETAs)
- ✅ **Crash-Free Sessions**: ≥99% (48-hour window)
- ✅ **Performance**: All benchmarks met
- ✅ **Lighthouse**: All scores ≥90
- ✅ **Test Coverage**: ≥30% for domain logic

### **Quality Metrics**
- **Test Execution**: 100% of planned test cases
- **Device Coverage**: All target devices tested
- **Platform Coverage**: Android APK + Web PWA
- **User Role Coverage**: Admin and staff workflows verified

---

## 📞 **QA Team Contacts**

- **QA Lead**: [TO_BE_ASSIGNED] - Overall test coordination
- **Mobile QA**: [TO_BE_ASSIGNED] - Android APK testing
- **Web QA**: [TO_BE_ASSIGNED] - PWA and browser testing
- **Performance QA**: [TO_BE_ASSIGNED] - Lighthouse and benchmarks
- **Security QA**: [TO_BE_ASSIGNED] - Privacy and consent testing

---

## 📝 **Test Execution Log**

### **Test Session Template**
```
Date: [YYYY-MM-DD]
Tester: [NAME]
Device: [DEVICE_MODEL]
Platform: [Android APK / Web PWA]
Test Scenarios: [List of scenarios tested]
Issues Found: [Link to bug reports]
Overall Status: [PASS / FAIL / BLOCKED]
Notes: [Additional observations]
```

---

## 🎯 **Next Steps**

1. **Assign testers** to device/platform matrix
2. **Execute test scenarios** according to schedule
3. **File bugs** using standardized templates
4. **Triage daily** with development team
5. **Track progress** toward RC2 release gates
6. **Generate final QA report** with go/no-go recommendation
