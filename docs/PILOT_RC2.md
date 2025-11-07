# RC2 Pilot Program - We Decor Enquiries

**Version**: v1.0.1+3 (RC2)  
**Pilot Period**: September 21-28, 2024  
**Objective**: Validate stability and collect real-world usage feedback  
**Target**: Zero P0 bugs, ≤2 P1 bugs for RC3 release

---

## 👥 **Pilot Cohort (Internal Testers)**

### **Primary Testers (Core Team)**
| Name | Role | Email | Device | Focus Area |
|------|------|-------|---------|------------|
| [QA_LEAD] | QA Lead | qa.lead@company.com | Samsung Galaxy S21 | Full feature testing |
| [DEV_LEAD] | Dev Lead | dev.lead@company.com | Google Pixel 6 | Technical validation |
| [PRODUCT_MANAGER] | PM | pm@company.com | iPhone 13 (PWA) | User experience |
| [DESIGNER] | UX Designer | ux@company.com | iPad (PWA) | Design & accessibility |

### **Secondary Testers (Stakeholders)**
| Name | Role | Email | Device | Focus Area |
|------|------|-------|---------|------------|
| [BUSINESS_USER_1] | Operations Manager | ops@company.com | OnePlus 9 | Daily workflow |
| [BUSINESS_USER_2] | Event Coordinator | events@company.com | Samsung A54 | Enquiry management |
| [ADMIN_USER] | System Admin | admin@company.com | Desktop (PWA) | Admin functions |
| [STAFF_USER] | Staff Member | staff@company.com | Budget Android | Basic operations |

---

## 🎯 **Top 10 Testing Scenarios**

### **P0 Scenarios (Must Work Perfectly)**
1. **App Launch & Authentication**
   - Install APK → Launch → Login → Dashboard appears
   - **Success Criteria**: No crashes, ≤2s startup time
   - **Test Data**: Valid user credentials

2. **Create New Enquiry**
   - Login → Enquiries → Add New → Fill form → Save
   - **Success Criteria**: Enquiry saves, appears in list
   - **Test Data**: Customer details, event info

3. **View & Update Enquiry**
   - Select enquiry → View details → Update status → Save
   - **Success Criteria**: Changes persist, UI updates
   - **Test Data**: Existing enquiry

4. **Offline Functionality**
   - Disconnect network → Create/update enquiry → Reconnect
   - **Success Criteria**: Operations queue, sync when online
   - **Test Data**: Any enquiry data

5. **Privacy Settings**
   - Settings → Privacy → Toggle analytics → Restart app
   - **Success Criteria**: Settings persist, monitoring respects choice
   - **Test Data**: N/A

### **P1 Scenarios (Should Work Well)**
6. **PWA Installation**
   - Visit web URL → Add to Home Screen → Launch
   - **Success Criteria**: Native app experience, offline works
   - **Test Data**: N/A

7. **Admin Functions**
   - Login as admin → User management → Dropdown management
   - **Success Criteria**: Admin features accessible and functional
   - **Test Data**: Admin credentials

8. **Image Upload**
   - Create enquiry → Add reference images → Save
   - **Success Criteria**: Images upload, display correctly
   - **Test Data**: Sample images

9. **Search & Filtering**
   - Enquiries list → Search by name → Filter by status
   - **Success Criteria**: Results accurate, performance good
   - **Test Data**: Multiple enquiries

10. **Logout & Session**
    - Use app → Logout → Close app → Reopen
    - **Success Criteria**: Stays logged out, no session issues
    - **Test Data**: N/A

---

## 📋 **Testing Instructions**

### **Getting Started**
1. **Download RC2**: https://wedecorenquries.web.app/internal/rc2/
2. **Verify SHA256**: `1eeeac9d41d8db28455318d7190d8d357c11cb522f5f38a18fcb1887e47fe700`
3. **Install APK**: Enable unknown apps, install
4. **Test Web PWA**: https://wedecorenquries.web.app/pwa/rc2/

### **Daily Testing Routine**
- **Morning**: Check for crashes in Firebase Console
- **During Use**: Follow top 10 scenarios, note any issues
- **Evening**: Submit feedback via in-app form or GitHub template

### **What to Look For**
- **Crashes**: App closes unexpectedly
- **Performance**: Slow startup, laggy navigation
- **UI Issues**: Layout problems, missing elements
- **Data Issues**: Enquiries not saving/loading
- **Offline Issues**: Sync problems, data loss

---

## 🐛 **How to Report Issues**

### **Option 1: In-App Feedback (Recommended)**
1. **Settings → Help → Send Feedback**
2. **Fill required fields**: Summary, steps to reproduce
3. **Attach logs**: Tap "Include Debug Info" 
4. **Submit**: Creates GitHub issue automatically

### **Option 2: GitHub Template**
1. **Use**: `.github/ISSUE_TEMPLATE/bug_report.md`
2. **Label**: `type:bug`, `priority:P0|P1|P2`, `milestone:RC3`
3. **Include**: Device info, screenshots, reproduction steps

### **Emergency Issues (P0)**
- **Slack**: #wedecor-app channel (immediate notification)
- **Email**: dev.lead@company.com (for critical issues)
- **Phone**: [EMERGENCY_CONTACT] (complete app failure)

---

## 📊 **Success Metrics**

### **Quality Gates for RC3**
| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| **Crash-Free Sessions** | ≥99% | [Monitor] | 🔄 Tracking |
| **App Startup Time** | ≤2.0s | [Monitor] | 🔄 Tracking |
| **Critical Bugs (P0)** | 0 | 0 | ✅ Met |
| **High Priority (P1)** | ≤2 | [TBD] | 🔄 Tracking |
| **User Satisfaction** | ≥4/5 | [Survey] | 🔄 Tracking |

### **Performance Benchmarks**
- **App Launch**: Target ≤2000ms on mid-tier devices
- **Enquiry List**: Target ≤1000ms first load
- **Create Enquiry**: Target ≤2000ms save operation
- **Image Upload**: Target ≤5000ms per image

---

## 📈 **Monitoring & Health Checks**

### **Daily Health Check (10:00 AM)**
```bash
# Check Firebase Console dashboards
# 1. Crashlytics: https://console.firebase.google.com/project/wedecorenquries/crashlytics
# 2. Performance: https://console.firebase.google.com/project/wedecorenquries/performance
# 3. Analytics: https://console.firebase.google.com/project/wedecorenquries/analytics

# Review metrics:
# - Crash-free users percentage
# - Top crashes by frequency
# - App start time trends
# - Screen rendering performance
```

### **Weekly Review (Fridays)**
- **Bug Triage**: Review all issues filed during the week
- **Performance Trends**: Analyze week-over-week improvements
- **User Feedback**: Summarize common themes and requests
- **Release Decision**: Go/No-Go for RC3 based on criteria

---

## 🔄 **Feedback Loop Process**

### **Tester → Development**
1. **Issue Discovery**: Tester finds problem during usage
2. **Feedback Submission**: Via in-app form or GitHub template
3. **Auto-Triage**: Labeled and assigned to milestone
4. **Developer Assignment**: Based on area and priority
5. **Fix Implementation**: With unit tests and verification
6. **QA Verification**: Tester confirms fix works
7. **Release Integration**: Fix included in RC3

### **Monitoring → Action**
1. **Firebase Alerts**: Crash rate spike or performance degradation
2. **Immediate Triage**: Assess severity and impact
3. **Hotfix Decision**: Critical issues get immediate attention
4. **Communication**: Update pilot cohort on status

---

## 📱 **Test Devices & Environments**

### **Android Devices (APK)**
- **High-end**: Samsung Galaxy S21, Google Pixel 6 (8GB+ RAM)
- **Mid-tier**: OnePlus 9, Samsung A54 (6-8GB RAM)
- **Budget**: Generic Android 12 device (4GB RAM)

### **Web PWA (Browsers)**
- **Desktop**: Chrome, Firefox, Safari on Windows/macOS
- **Mobile**: Chrome on Android, Safari on iOS
- **Tablet**: iPad Safari, Android Chrome

### **Network Conditions**
- **WiFi**: Fast, reliable connection
- **Mobile Data**: 4G/5G with occasional drops
- **Poor Network**: Simulated slow/unstable connection
- **Offline**: Complete network disconnection

---

## 📞 **Communication & Support**

### **Daily Standup (10:30 AM)**
- **Attendees**: QA Lead, Dev Lead, Product Manager
- **Duration**: 15 minutes
- **Format**:
  - Bugs found yesterday
  - Fixes implemented
  - Blockers or concerns
  - Today's focus

### **Pilot Support Channels**
- **Primary**: #wedecor-app Slack channel
- **Secondary**: dev.lead@company.com
- **Emergency**: [PHONE_NUMBER] for critical issues
- **Documentation**: docs/QA_RUNBOOK.md

### **Escalation Matrix**
| Issue Severity | Response Time | Contact |
|----------------|---------------|---------|
| **P0 (Critical)** | 1 hour | Dev Lead + Product Manager |
| **P1 (High)** | 4 hours | Dev Lead |
| **P2 (Medium)** | 24 hours | Assigned Developer |
| **P3 (Low)** | 72 hours | Backlog Review |

---

## 🎯 **RC3 Release Criteria**

### **Must-Have (Release Blockers)**
- [ ] **Zero P0 bugs** in production usage
- [ ] **Crash-free sessions ≥99%** over 48-hour period
- [ ] **App startup ≤2000ms** on mid-tier devices
- [ ] **Core workflows functional** on all test devices
- [ ] **Privacy compliance verified** with consent toggles

### **Should-Have (Strong Preference)**
- [ ] **≤2 P1 bugs** with documented owners and ETAs
- [ ] **Lighthouse scores ≥90** for PWA
- [ ] **Performance budgets met** for all traced operations
- [ ] **User feedback positive** (≥4/5 satisfaction)
- [ ] **No regressions** from RC1 functionality

### **Nice-to-Have (Future Consideration)**
- [ ] **Enhanced performance** beyond budget requirements
- [ ] **Additional accessibility** improvements
- [ ] **UI polish** based on user feedback
- [ ] **Feature requests** for v1.1 planning

---

## 📋 **Pilot Success Checklist**

### **Week 1 (Days 1-3)**
- [ ] **Cohort Onboarded**: All testers have RC2 installed
- [ ] **Initial Feedback**: First round of issues filed
- [ ] **Monitoring Active**: Crashlytics/Performance data flowing
- [ ] **Critical Issues**: Any P0 bugs identified and fixed

### **Week 1 (Days 4-7)**
- [ ] **Stability Confirmed**: No new critical issues
- [ ] **Performance Validated**: Budgets met consistently
- [ ] **User Experience**: Positive feedback on core workflows
- [ ] **RC3 Decision**: Go/No-Go based on criteria

### **RC3 Release**
- [ ] **Fixes Applied**: All P0 and critical P1 issues resolved
- [ ] **Quality Gates**: All automated checks passing
- [ ] **Documentation**: Updated release notes and deployment
- [ ] **Deployment**: RC3 live at /internal/rc3/ and /pwa/rc3/

---

## 📚 **Resources for Pilot Testers**

### **Getting Started**
- **Download Guide**: release/internal-rc2/README_INSTALL.md
- **QA Runbook**: docs/QA_RUNBOOK.md
- **Bug Templates**: .github/ISSUE_TEMPLATE/bug_report.md

### **Monitoring Dashboards**
- **Firebase Console**: https://console.firebase.google.com/project/wedecorenquries
- **Crashlytics**: Monitor app stability and crash reports
- **Performance**: Track app startup and operation timing

### **Support Resources**
- **Slack**: #wedecor-app for questions and issues
- **Documentation**: Complete QA and testing guides
- **Emergency**: Direct contact for critical issues

---

**Pilot Program Goals**: Validate RC2 stability, collect actionable feedback, and ensure RC3 is ready for broader internal rollout with confidence in production readiness.
