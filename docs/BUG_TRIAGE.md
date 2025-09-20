# Bug Triage Guide - We Decor Enquiries

**Purpose**: Standardized process for triaging and prioritizing bugs during QA  
**Scope**: RC1 → RC2 stabilization phase  
**Owner**: QA Lead + Development Team

---

## 🏷️ **Priority Classification**

### **P0 - Critical (Fix Immediately)**
- **Definition**: Blocks core functionality, prevents app use
- **SLA**: Fix within 24 hours
- **Examples**:
  - App crashes on launch
  - Cannot login/authenticate
  - Cannot create or view enquiries
  - Data corruption or loss
  - Security vulnerabilities

### **P1 - High (Fix for RC2)**
- **Definition**: Significantly impacts user experience
- **SLA**: Fix within 72 hours
- **Examples**:
  - Offline sync failures
  - Performance degradation (>3s startup)
  - PWA installation issues
  - Privacy settings not working
  - Admin features broken

### **P2 - Medium (Fix for v1.1)**
- **Definition**: Minor issues, workarounds available
- **SLA**: Fix within 1 week
- **Examples**:
  - UI polish issues
  - Minor UX improvements
  - Non-critical feature requests
  - Accessibility enhancements
  - Analytics tracking issues

### **P3 - Low (Future Consideration)**
- **Definition**: Nice-to-have improvements
- **SLA**: No immediate timeline
- **Examples**:
  - Feature requests
  - Performance optimizations
  - Code refactoring
  - Documentation improvements

---

## 🔄 **Triage Process**

### **Daily Triage Meeting**
- **When**: Every day at 10:00 AM during QA sprint
- **Duration**: 30 minutes maximum
- **Attendees**: QA Lead, Dev Lead, Product Manager
- **Agenda**:
  1. Review new bugs filed in last 24h
  2. Assign priority, area, and owner
  3. Update milestone (RC2 vs v1.1)
  4. Discuss blockers and dependencies

### **Triage Workflow**
1. **New Bug Filed** → Automatically labeled `status:triage`
2. **QA Lead Reviews** → Adds priority, area labels
3. **Dev Lead Assigns** → Assigns to developer
4. **Developer Accepts** → Changes to `status:in-progress`
5. **Fix Implemented** → Changes to `status:ready-for-test`
6. **QA Verifies** → Changes to `status:verified` or reopens
7. **QA Closes** → Final resolution

---

## 🏷️ **Labeling System**

### **Type Labels**
- `type:bug` - Something is broken
- `type:perf` - Performance issue
- `type:ux` - User experience problem
- `type:security` - Security concern
- `type:enhancement` - New feature request

### **Priority Labels**
- `priority:P0` - Critical, blocks release
- `priority:P1` - High, should fix for RC2
- `priority:P2` - Medium, can defer to v1.1
- `priority:P3` - Low, future consideration

### **Area Labels**
- `area:auth` - Authentication and session management
- `area:enquiry` - Enquiry CRUD operations
- `area:offline` - Offline functionality and sync
- `area:pwa` - Progressive Web App features
- `area:notifications` - FCM and in-app notifications
- `area:settings` - App settings and privacy controls
- `area:admin` - Admin-only features
- `area:build` - Build and deployment issues

### **Status Labels**
- `status:triage` - Needs initial review and prioritization
- `status:accepted` - Confirmed bug, ready for assignment
- `status:in-progress` - Developer working on fix
- `status:ready-for-test` - Fix implemented, needs QA verification
- `status:verified` - QA confirmed fix works
- `status:wontfix` - Issue won't be addressed
- `status:duplicate` - Duplicate of existing issue

---

## 📊 **Triage Metrics**

### **Daily Tracking**
| Date | New Bugs | P0 | P1 | P2 | P3 | Resolved | Remaining |
|------|----------|----|----|----|----|----------|-----------|
| 2024-09-21 | 0 | 0 | 0 | 0 | 0 | 0 | 0 |
| 2024-09-22 | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |

### **RC2 Release Gates**
- **P0 Bugs**: Must be 0
- **P1 Bugs**: ≤3 with documented owners and ETAs
- **P2 Bugs**: Can defer to v1.1 if needed
- **Total Open**: ≤10 bugs across all priorities

---

## 🛠️ **Fix Implementation Guidelines**

### **Branch Strategy**
```bash
# Create fix branch from stabilization branch
git checkout stabilization/rc1-qa
git checkout -b fix/auth-login-timeout

# Implement fix, test locally
flutter test
flutter analyze

# Commit with clear message
git commit -m "fix(auth): resolve login timeout on slow networks

- Increase timeout from 10s to 30s
- Add retry logic with exponential backoff
- Show loading indicator during authentication
- Add user feedback for network issues

Fixes #123"

# Push and create PR
git push origin fix/auth-login-timeout
```

### **PR Requirements**
- [ ] **Clear description** of problem and solution
- [ ] **Test plan** with verification steps
- [ ] **Screenshots** for UI changes
- [ ] **Risk assessment** and rollback plan
- [ ] **All tests passing** (analyzer + unit tests)

### **Merge Criteria**
- [ ] **Code review** approved by dev lead
- [ ] **QA verification** on target device
- [ ] **No regressions** in core functionality
- [ ] **Performance impact** assessed
- [ ] **Documentation** updated if needed

---

## 📈 **Quality Gates**

### **Before Each Fix Merge**
```bash
# Code quality
flutter analyze  # Must have 0 new errors
flutter test     # All tests must pass

# Build verification
flutter build apk --release  # Must succeed
flutter build web --release  # Must succeed

# Integration check
flutter test integration_test  # If available
```

### **Before RC2 Release**
```bash
# Complete quality check
bash test/coverage.sh        # Coverage ≥30%
bash tools/lighthouse_pwa.sh # Lighthouse ≥90
./tools/collect_android_logs.sh  # Performance check

# Final builds
flutter build apk --release --obfuscate --split-debug-info=build/debug-info/
flutter build web --release
```

---

## 📞 **Communication & Escalation**

### **Daily Standup Format**
```
Yesterday:
- Bugs triaged: [count]
- Fixes implemented: [count]
- Tests executed: [scenarios]

Today:
- Priority bugs to address: [list]
- Test focus areas: [areas]
- Blockers: [if any]

Blockers/Escalations:
- [Any issues needing management attention]
```

### **Escalation Matrix**
| Issue Type | First Contact | Escalation 1 | Escalation 2 |
|------------|---------------|--------------|--------------|
| **P0 Bug** | Dev Lead (Slack) | Product Manager | Engineering Manager |
| **Testing Blocked** | QA Lead | Dev Lead | Product Manager |
| **Release Risk** | QA Lead | Product Manager | Engineering Manager |
| **Security Issue** | Security Team | CISO | CTO |

---

## 📋 **RC2 Go/No-Go Checklist**

### **Quality Gates**
- [ ] **P0 bugs**: 0 (all critical issues resolved)
- [ ] **P1 bugs**: ≤3 (documented with owners/ETAs)
- [ ] **Crash-free sessions**: ≥99% (48-hour window)
- [ ] **Performance benchmarks**: All targets met
- [ ] **Lighthouse scores**: ≥90 across all metrics
- [ ] **Test coverage**: ≥30% for domain logic

### **Testing Completeness**
- [ ] **All devices tested**: Android matrix complete
- [ ] **All platforms tested**: APK + PWA verified
- [ ] **All user roles tested**: Admin + staff workflows
- [ ] **All scenarios tested**: Core + edge cases covered
- [ ] **Regression testing**: Previous bugs re-verified

### **Documentation & Deployment**
- [ ] **QA report**: Complete with metrics and recommendations
- [ ] **Release notes**: Updated with bug fixes
- [ ] **Installation guide**: Verified and current
- [ ] **Deployment plan**: Reviewed and approved

---

## 📚 **Resources & References**

### **Internal Resources**
- **Firebase Console**: https://console.firebase.google.com/project/wedecorenquries
- **Download Page**: https://wedecorenquries.web.app/internal/rc1/
- **PWA**: https://wedecorenquries.web.app/pwa/rc1/
- **Slack Channel**: #wedecor-app

### **External Tools**
- **Android Debug Bridge**: `adb` command line tool
- **Lighthouse**: `npx lighthouse` for PWA auditing
- **Firebase CLI**: `firebase` for deployment and emulators

### **Documentation**
- **Test Plan**: docs/QA_TEST_PLAN.md
- **Release Checklist**: docs/RELEASE_CHECKLIST.md
- **Android Signing**: docs/ANDROID_SIGNING.md
- **Bug Templates**: .github/ISSUE_TEMPLATE/
