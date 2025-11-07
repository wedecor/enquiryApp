# Release Health Dashboard - RC2 Monitoring

**Version**: We Decor Enquiries v1.0.1+3 (RC2)  
**Monitoring Period**: September 21-28, 2024  
**Dashboard Owner**: Dev Lead + QA Lead  
**Update Frequency**: Daily (10:00 AM)

---

## 🔥 **Crashlytics Dashboard**

### **Quick Access Links**
- **Main Dashboard**: https://console.firebase.google.com/project/wedecorenquries/crashlytics
- **Crash-Free Users**: https://console.firebase.google.com/project/wedecorenquries/crashlytics/app/android:com.example.we_decor_enquiries/issues
- **Performance**: https://console.firebase.google.com/project/wedecorenquries/performance

### **Key Metrics to Monitor**

#### **Crash-Free Sessions (Target: ≥99%)**
| Date | Crash-Free % | Sessions | New Crashes | Top Crash |
|------|--------------|----------|-------------|-----------|
| 2024-09-21 | [Monitor] | [Monitor] | [Monitor] | [Monitor] |
| 2024-09-22 | [Monitor] | [Monitor] | [Monitor] | [Monitor] |
| 2024-09-23 | [Monitor] | [Monitor] | [Monitor] | [Monitor] |

#### **Top Crashes (Last 48 Hours)**
| Crash Title | Count | Impact | Status | Owner |
|-------------|--------|--------|--------|-------|
| [TBD] | [TBD] | [TBD] | [TBD] | [TBD] |

---

## ⚡ **Performance Dashboard**

### **App Startup Performance**
| Date | P50 (ms) | P95 (ms) | Target | Status | Notes |
|------|----------|----------|--------|--------|-------|
| 2024-09-21 | [Monitor] | [Monitor] | ≤2000ms | 🔄 | [TBD] |
| 2024-09-22 | [Monitor] | [Monitor] | ≤2000ms | 🔄 | [TBD] |
| 2024-09-23 | [Monitor] | [Monitor] | ≤2000ms | 🔄 | [TBD] |

### **Operation Performance**
| Operation | P50 (ms) | P95 (ms) | Target | Status |
|-----------|----------|----------|--------|--------|
| **Enquiry List Load** | [Monitor] | [Monitor] | ≤1000ms | 🔄 |
| **Create Enquiry** | [Monitor] | [Monitor] | ≤2000ms | 🔄 |
| **Image Upload** | [Monitor] | [Monitor] | ≤5000ms | 🔄 |
| **Login Flow** | [Monitor] | [Monitor] | ≤3000ms | 🔄 |

---

## 📊 **Daily Health Checklist**

### **Morning Review (10:00 AM)**
```bash
# 1. Check Crashlytics Dashboard
# - Overall crash-free percentage
# - New crashes since yesterday
# - Trending issues

# 2. Check Performance Dashboard  
# - App startup time trends
# - Screen rendering performance
# - Network request latency

# 3. Check User Feedback
# - New GitHub issues with 'source:feedback' label
# - In-app feedback submissions
# - Slack channel reports

# 4. Review Analytics (if consented users)
# - Active users count
# - Feature usage patterns
# - User journey completion rates
```

### **Health Status Template**
```markdown
## Daily Health Report - [DATE]

### Crashlytics
- **Crash-Free Sessions**: X.X%
- **New Crashes**: X (vs Y yesterday)
- **Top Crash**: [Title] (X occurrences)
- **Alert Level**: 🟢 Healthy / 🟡 Monitor / 🔴 Critical

### Performance
- **App Startup (P50)**: Xms (target: ≤2000ms)
- **App Startup (P95)**: Xms (target: ≤3000ms)
- **Enquiry Load (P50)**: Xms (target: ≤1000ms)
- **Alert Level**: 🟢 Healthy / 🟡 Monitor / 🔴 Critical

### User Feedback
- **New Issues**: X bugs filed
- **Priority Breakdown**: P0: X, P1: Y, P2: Z
- **Common Themes**: [Summary]
- **Action Required**: [If any]

### Overall Health: 🟢 Healthy / 🟡 Monitor / 🔴 Critical
```

---

## 🚨 **Alert Thresholds**

### **Critical Alerts (Immediate Action)**
- **Crash-Free Sessions**: <95%
- **App Startup P95**: >5000ms
- **New Critical Crash**: >10 occurrences in 1 hour
- **Complete App Failure**: Unable to launch

### **Warning Alerts (Monitor Closely)**
- **Crash-Free Sessions**: <99%
- **App Startup P95**: >3000ms
- **Performance Regression**: >20% slower than baseline
- **User Complaints**: Multiple similar reports

### **Info Alerts (Track Trends)**
- **New Crash Types**: Any new crash signatures
- **Performance Trends**: Gradual degradation
- **Feature Usage**: Unexpected usage patterns
- **Device Compatibility**: Issues on specific devices

---

## 🔧 **How to Access Dashboards**

### **Firebase Console Navigation**
1. **Go to**: https://console.firebase.google.com/project/wedecorenquries
2. **Crashlytics**: Left sidebar → Crashlytics
3. **Performance**: Left sidebar → Performance
4. **Analytics**: Left sidebar → Analytics (if enabled)

### **Key Dashboard Views**
```bash
# Crashlytics - Main View
# - Crash-free users percentage (last 7 days)
# - Issue list sorted by impact
# - New vs recurring crashes

# Performance - App Start
# - App start duration trends
# - Breakdown by device/OS version
# - 50th vs 95th percentile metrics

# Performance - Custom Traces
# - enquiry_list_load duration
# - user_login duration
# - image_upload duration
```

---

## 📈 **Performance Budget Monitoring**

### **Automated Budget Checks**
The app includes performance budgets that log warnings when exceeded:

```dart
// Performance budgets (enforced in PerfTraces)
appStart: ≤2000ms
enquiryListLoad: ≤1000ms  
userLogin: ≤3000ms
imageUpload: ≤5000ms
```

### **Budget Violation Response**
1. **Warning Logged**: Check app logs for budget violations
2. **Investigate**: Identify performance bottleneck
3. **Fix**: Optimize code or adjust budget if realistic
4. **Verify**: Confirm improvement in next build

---

## 🔍 **Troubleshooting Common Issues**

### **No Data in Dashboards**
- **Cause**: Monitoring disabled or no user consent
- **Check**: Settings → Privacy → monitoring toggles
- **Fix**: Enable monitoring with user consent

### **Crash Data Missing**
- **Cause**: Debug build or Crashlytics disabled
- **Check**: Build configuration and AppConfig settings
- **Fix**: Use release build with ENABLE_CRASHLYTICS=true

### **Performance Data Sparse**
- **Cause**: Performance monitoring disabled
- **Check**: ENABLE_PERFORMANCE flag and user consent
- **Fix**: Enable performance monitoring in build

---

## 📋 **Weekly Review Template**

### **Weekly Health Summary**
```markdown
# Weekly Health Report - Week of [DATE]

## Summary Metrics
- **Average Crash-Free**: X.X%
- **Peak Performance**: App start Xms (best day)
- **User Feedback**: X issues filed, Y resolved
- **Overall Trend**: 📈 Improving / 📊 Stable / 📉 Concerning

## Key Achievements
- [Major fixes or improvements]
- [Performance optimizations]
- [User experience enhancements]

## Areas of Concern
- [Issues requiring attention]
- [Performance regressions]
- [User experience problems]

## Next Week Focus
- [Priority fixes for RC3]
- [Performance optimizations]
- [User experience improvements]
```

---

## 🎯 **RC3 Release Gates**

### **Health-Based Release Criteria**
- **Crash-Free Sessions**: ≥99% sustained for 48 hours
- **Performance Budgets**: All operations within targets
- **Critical Issues**: Zero P0 bugs from pilot feedback
- **User Satisfaction**: Positive feedback from pilot cohort

### **Monitoring Requirements**
- **Dashboard Review**: Daily health checks completed
- **Trend Analysis**: No negative performance trends
- **User Feedback**: All critical issues addressed
- **Regression Testing**: No functionality lost from RC2

---

**This dashboard provides real-time visibility into RC2 health and guides data-driven decisions for RC3 release readiness.** 📊
