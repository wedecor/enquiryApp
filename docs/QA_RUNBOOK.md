# QA Runbook - We Decor Enquiries

**Purpose**: Step-by-step guide for QA testing of We Decor Enquiries app  
**Audience**: QA team, developers, stakeholders  
**Last Updated**: September 21, 2024

---

## 🚀 **Getting Started**

### **Download and Install**

#### **Android APK**
1. **Visit download page**: https://wedecorenquries.web.app/internal/rc1/
2. **Scan QR code** with Android device or download directly
3. **Verify integrity**:
   ```bash
   shasum -a 256 app-release.apk
   # Expected: 379d78e8b10bf2dc04f946c144fd40c35ee5d1dd258f815a585cf196c3f144b5
   ```
4. **Enable unknown apps**: Settings → Security → Install unknown apps
5. **Install APK** and launch app

#### **Web PWA**
1. **Visit**: https://wedecorenquries.web.app/pwa/rc1/
2. **Add to Home Screen** when prompted (mobile)
3. **Test offline**: Disconnect network, verify functionality

### **Test Accounts**
```
Admin User:
- Email: admin@wedecor.test
- Password: [PROVIDED_SEPARATELY]

Staff User:  
- Email: staff@wedecor.test
- Password: [PROVIDED_SEPARATELY]
```

---

## 🔧 **Debug Tools & Logging**

### **Enable Debug Logging**
1. **Android**: Use `adb logcat` to view system logs
2. **Web**: Open browser DevTools (F12) → Console
3. **App Logs**: Settings → Admin → View Logs (admin only)

### **Collect Android Logs**
```bash
# Check connected devices
adb devices

# Collect app logs (filter by package)
adb logcat -v time com.example.we_decor_enquiries:V *:S | tee logs/app_log_$(date +%F_%H-%M).txt

# Collect system performance
adb shell top -o PID,CPU,RES,NAME -d 5 | tee logs/device_top_$(date +%F_%H-%M).txt

# Generate bug report
adb bugreport build/bugreports/bugreport_$(date +%F_%H-%M)
```

### **Web PWA Debugging**
```javascript
// In browser console, check service worker
navigator.serviceWorker.getRegistrations().then(registrations => {
  console.log('Service Workers:', registrations);
});

// Check offline capability
console.log('Online status:', navigator.onLine);

// Check app manifest
console.log('Manifest:', window.navigator.userAgent);
```

---

## 🧪 **Test Execution Guide**

### **Pre-Test Setup**
1. **Fresh install** or clear app data
2. **Check network connectivity**
3. **Prepare test data** (sample enquiries, user accounts)
4. **Start logging** (adb logcat for Android)
5. **Document device info** (model, OS version, RAM)

### **Test Case Execution**
1. **Follow test scenarios** from QA_TEST_PLAN.md
2. **Document each step** with screenshots
3. **Record performance metrics** (startup time, operation duration)
4. **Note any unexpected behavior** or UI issues
5. **Verify privacy settings** work correctly

### **Bug Reporting**
1. **Use bug report template**: .github/ISSUE_TEMPLATE/bug_report.md
2. **Include required information**:
   - Environment details (device, OS, app version)
   - Reproduction steps (clear and detailed)
   - Expected vs actual behavior
   - Screenshots/videos
   - Logs (if relevant)
3. **Apply appropriate labels**:
   - `type:bug`, `type:perf`, `type:ux`
   - `priority:P0|P1|P2`
   - `area:auth|enquiry|offline|pwa|notifications|settings`

---

## 🔍 **Common Issues & Troubleshooting**

### **Installation Issues**
| Issue | Cause | Solution |
|-------|-------|----------|
| "App not installed" | Insufficient storage | Free up 100MB+ space |
| "Parse error" | Corrupted download | Re-download, verify SHA256 |
| "Blocked by Play Protect" | Unknown source | Tap "Install anyway" |

### **Runtime Issues**
| Issue | Cause | Solution |
|-------|-------|----------|
| App crashes on startup | Firebase config | Check internet, restart app |
| Login fails | Network/credentials | Verify network, try guest mode |
| Enquiries don't load | Firestore permissions | Check user role, try refresh |
| Offline sync fails | Network timing | Wait 30s, check queue status |

### **PWA Issues**
| Issue | Cause | Solution |
|-------|-------|----------|
| Won't add to home screen | Browser support | Use Chrome/Safari, check manifest |
| Offline doesn't work | Service worker | Check browser console, refresh |
| Slow loading | Network/caching | Check connection, clear cache |

---

## 📊 **Performance Testing**

### **Startup Time Measurement**
```bash
# Android: Use adb to measure app launch
adb shell am start -W com.example.we_decor_enquiries/.MainActivity

# Look for "TotalTime" in output
# Target: ≤2000ms on mid-tier devices
```

### **Memory Usage**
```bash
# Monitor memory during testing
adb shell dumpsys meminfo com.example.we_decor_enquiries

# Watch for memory leaks during extended use
adb shell top -o PID,CPU,RES,NAME | grep we_decor
```

### **Network Performance**
- **Test on different connection types**: WiFi, 4G, 3G, Edge
- **Monitor request times** in browser DevTools → Network
- **Verify offline queue** works during poor connectivity

---

## 🔐 **Security & Privacy Testing**

### **Privacy Compliance**
1. **Default State**: Verify analytics disabled by default
2. **Consent Flow**: Test opt-in/opt-out for all monitoring
3. **Data Collection**: Verify no PII in logs without consent
4. **Settings Persistence**: Consent choices survive app restart

### **Security Verification**
1. **APK Signature**: Verify with `jarsigner -verify`
2. **Code Obfuscation**: Check if symbols are mangled
3. **Network Security**: HTTPS only, no plaintext credentials
4. **Permission Usage**: Only request necessary permissions

---

## 📋 **Test Reporting**

### **Daily Test Report Template**
```markdown
# Daily QA Report - [DATE]

## Summary
- **Tests Executed**: X/Y test cases
- **Bugs Found**: P0: X, P1: Y, P2: Z
- **Devices Tested**: [List]
- **Overall Status**: [ON_TRACK / AT_RISK / BLOCKED]

## Key Findings
- [Major issues discovered]
- [Performance observations]
- [User experience feedback]

## Next Day Plan
- [Planned test activities]
- [Bug verification tasks]
- [Device/platform focus]
```

### **Bug Lifecycle**
1. **Reported**: Bug filed with template
2. **Triaged**: Priority and area assigned
3. **In Progress**: Developer working on fix
4. **Ready for Test**: Fix implemented, needs verification
5. **Verified**: QA confirms fix works
6. **Closed**: Issue resolved and documented

---

## 🎯 **RC2 Release Criteria**

### **Must-Have (P0)**
- [ ] **Zero crashes** during core user flows
- [ ] **Authentication** works on all test devices
- [ ] **Enquiry CRUD** fully functional
- [ ] **Offline sync** reliable and user-friendly
- [ ] **Privacy settings** functional and persistent

### **Should-Have (P1)**
- [ ] **Performance** meets all benchmarks
- [ ] **PWA** installs and works offline
- [ ] **Admin functions** accessible and working
- [ ] **Notifications** deliver successfully
- [ ] **Responsive design** works on all screen sizes

### **Nice-to-Have (P2)**
- [ ] **Advanced analytics** features
- [ ] **Accessibility** improvements
- [ ] **UI polish** and animations
- [ ] **Additional language** support
- [ ] **Export/backup** functionality

---

## 📞 **Escalation & Support**

### **Issue Escalation**
- **P0 (Critical)**: Immediate Slack notification + direct contact
- **P1 (High)**: Daily standup discussion + Slack update
- **P2 (Medium)**: Weekly review + GitHub issue tracking

### **Contact Information**
- **Development Team**: #wedecor-dev Slack channel
- **QA Lead**: [SLACK_HANDLE] / [EMAIL]
- **Product Manager**: [SLACK_HANDLE] / [EMAIL]
- **Release Manager**: [SLACK_HANDLE] / [EMAIL]

### **Emergency Procedures**
- **Showstopper Bug**: Stop testing, escalate immediately
- **Security Issue**: Contact security team, document privately
- **Data Loss**: Preserve logs, contact development team ASAP

---

## 📚 **Resources**

- **Test Plan**: docs/QA_TEST_PLAN.md
- **Bug Triage**: docs/BUG_TRIAGE.md
- **Release Checklist**: docs/RELEASE_CHECKLIST.md
- **Installation Guide**: release/internal-rc1/README_INSTALL.md
- **Firebase Console**: https://console.firebase.google.com/project/wedecorenquries
- **Download Page**: https://wedecorenquries.web.app/internal/rc1/
