# Release Preview System

## 🚀 Firebase Hosting Channels for PR Previews

This document explains how the preview deployment system works, including channel management, TTL policies, and manual cleanup procedures.

---

## 🌐 Preview Channel System

### **Channel Naming Convention**
```
pr-{number}           # For pull requests: pr-123
{branch-name}         # For direct pushes: feature-contact-shortcuts
```

### **Sanitization Rules**
- Replace `/` and `_` with `-`
- Truncate to 63 characters maximum
- Convert to lowercase
- Remove special characters

### **Examples**
| Branch/PR | Channel Name | Preview URL |
|-----------|--------------|-------------|
| `PR #123` | `pr-123` | `https://pr-123--wedecorenquries.web.app` |
| `feature/contact-shortcuts` | `feature-contact-shortcuts` | `https://feature-contact-shortcuts--wedecorenquries.web.app` |
| `ops/ci-hardening-v2` | `ops-ci-hardening-v2` | `https://ops-ci-hardening-v2--wedecorenquries.web.app` |

---

## ⏰ Time-to-Live (TTL) Policies

### **Automatic Cleanup**
- **Default TTL**: 7 days
- **Cleanup Trigger**: Firebase automatically removes expired channels
- **Grace Period**: 24 hours after expiration before deletion

### **Manual Cleanup**
```bash
# List all preview channels
firebase hosting:channel:list

# Delete specific channel
firebase hosting:channel:delete CHANNEL_NAME

# Delete all expired channels
firebase hosting:channel:list --json | \
  jq -r '.[] | select(.expireTime < now) | .name' | \
  xargs -I {} firebase hosting:channel:delete {}
```

### **Channel Limits**
- **Maximum Channels**: 100 per project
- **Storage Limit**: 10GB total across all channels
- **Bandwidth**: Shared with main site

---

## 🔄 Deployment Workflow

### **Automated Deployment (PR)**
1. **Trigger**: Pull request created/updated
2. **Build**: `flutter build web --release`
3. **Deploy**: `firebase hosting:channel:deploy pr-{number}`
4. **Lighthouse**: Performance audit on preview URL
5. **Notification**: Slack message with preview link

### **Manual Deployment**
```bash
# Deploy to custom channel
firebase hosting:channel:deploy my-feature-branch

# Deploy with custom expiration
firebase hosting:channel:deploy my-feature --expires 14d

# Deploy with JSON output for automation
firebase hosting:channel:deploy my-feature --json
```

---

## 📊 Preview Features

### **What's Included in Previews**
- **Full Web App**: Complete PWA functionality
- **Real Firebase**: Connected to production Firebase project
- **Analytics**: Disabled in preview builds
- **Crashlytics**: Enabled for error tracking
- **Performance Monitoring**: Enabled for optimization

### **What's Different from Production**
- **Environment**: `APP_ENV=prod` but different URL
- **Analytics**: Disabled to avoid skewing production data
- **Caching**: Different cache keys due to different domain
- **Service Worker**: Preview-specific registration

---

## 🔍 Lighthouse Integration

### **Automated Audits**
- **Trigger**: Every preview deployment
- **Metrics**: Performance, Accessibility, Best Practices, SEO, PWA
- **Reporting**: HTML report + JSON data
- **Thresholds**: Performance score tracked (no hard limits)

### **Lighthouse Configuration**
```bash
lighthouse $PREVIEW_URL \
  --output html --output json \
  --output-path ./lighthouse-report \
  --chrome-flags="--headless --no-sandbox" \
  --preset=desktop \
  --quiet
```

### **Score Interpretation**
| Score Range | Status | Action Required |
|-------------|--------|-----------------|
| **90-100** | 🟢 Excellent | Maintain quality |
| **70-89** | 🟡 Good | Monitor trends |
| **50-69** | 🟠 Needs Improvement | Optimize |
| **0-49** | 🔴 Poor | Immediate action |

---

## 🛠️ Management & Operations

### **Channel Management**

#### **List Active Channels**
```bash
firebase hosting:channel:list --json | jq -r '.[] | "\(.name) - \(.url) (expires: \(.expireTime))"'
```

#### **Extend Channel TTL**
```bash
# Extend specific channel
firebase hosting:channel:deploy CHANNEL_NAME --expires 14d

# Clone to new channel with extended TTL
firebase hosting:channel:clone SOURCE_CHANNEL NEW_CHANNEL --expires 30d
```

#### **Channel Analytics**
```bash
# Get channel traffic data (requires Firebase CLI extensions)
firebase hosting:channel:list --json | \
  jq -r '.[] | select(.name | startswith("pr-")) | .name' | \
  head -5  # Show recent PR channels
```

### **Storage Management**

#### **Monitor Usage**
```bash
# Check total hosting storage
firebase hosting:sites:list

# Monitor channel storage (approximate)
firebase hosting:channel:list --json | \
  jq '[.[] | {name: .name, size: .deployTime}] | length'
```

#### **Cleanup Strategies**
```bash
# Remove old PR channels (PRs closed >7 days ago)
# This would require GitHub API integration to check PR status

# Remove feature branch channels for merged branches
git branch -r --merged main | \
  grep -v main | \
  sed 's/origin\///' | \
  xargs -I {} firebase hosting:channel:delete {} || true
```

---

## 🔧 Troubleshooting

### **Common Issues**

#### **Deployment Failures**
**Symptoms**: Channel deployment fails with error
**Solutions**:
1. Check Firebase project permissions
2. Verify hosting configuration in `firebase.json`
3. Check for invalid channel names
4. Verify build artifacts exist

#### **Preview Not Loading**
**Symptoms**: Preview URL returns 404 or blank page
**Solutions**:
1. Wait 2-3 minutes for propagation
2. Check if web build completed successfully
3. Verify Firebase hosting configuration
4. Check browser console for errors

#### **Lighthouse Failures**
**Symptoms**: Lighthouse audit fails or times out
**Solutions**:
1. Verify preview URL is accessible
2. Check for JavaScript errors in preview
3. Increase timeout in lighthouse_ci.sh
4. Run lighthouse locally for debugging

#### **Channel Limit Exceeded**
**Symptoms**: "Maximum channels exceeded" error
**Solutions**:
1. List and delete old channels
2. Clean up expired channels manually
3. Review TTL policies
4. Contact Firebase support for limit increase

### **Emergency Procedures**

#### **Delete All Preview Channels**
```bash
# WARNING: This deletes ALL preview channels
firebase hosting:channel:list --json | \
  jq -r '.[].name' | \
  grep -E '^(pr-|feature-|ops-|stabilization-)' | \
  xargs -I {} firebase hosting:channel:delete {} --force
```

#### **Restore from Backup**
```bash
# Deploy main to new channel for emergency access
firebase hosting:channel:deploy emergency-$(date +%Y%m%d)

# Clone existing channel
firebase hosting:channel:clone CHANNEL_NAME emergency-backup
```

---

## 📈 Analytics & Monitoring

### **Preview Usage Metrics**
- **Channel Creation Rate**: Channels per day/week
- **Preview Access**: Unique visitors per preview
- **Lighthouse Scores**: Performance trends over time
- **Build Success Rate**: Preview deployment success rate

### **Performance Tracking**
- **Build Time**: Monitor for CI performance regressions
- **Deployment Time**: Channel creation and propagation speed
- **Lighthouse Trends**: Track performance over time
- **Error Rates**: Monitor preview-specific errors

### **Cost Monitoring**
- **Hosting Bandwidth**: Preview traffic costs
- **Storage Usage**: Channel storage consumption
- **Build Minutes**: CI resource usage
- **Firebase Quotas**: Monitor against project limits

---

## 📋 Best Practices

### **For Developers**
1. **Review Previews**: Always test your changes on preview URL
2. **Check Lighthouse**: Monitor performance impact of changes
3. **Clean Branches**: Delete merged branches to reduce channel clutter
4. **Test Responsively**: Preview on mobile and desktop
5. **Verify PWA**: Test "Add to Home Screen" functionality

### **For Reviewers**
1. **Use Preview Links**: Review functionality on actual preview
2. **Check Performance**: Review Lighthouse scores in PR
3. **Test User Flows**: Verify critical paths work correctly
4. **Cross-browser**: Test on different browsers if needed
5. **Accessibility**: Use screen readers and keyboard navigation

### **For Operations**
1. **Monitor Costs**: Track hosting usage and costs
2. **Clean Regularly**: Remove old channels to free resources
3. **Update Documentation**: Keep procedures current
4. **Monitor Performance**: Track build and deployment times
5. **Security Review**: Regular audit of preview access and data

---

*Last Updated: September 21, 2024*  
*System Version: 2.0*  
*Next Review: October 21, 2024*
