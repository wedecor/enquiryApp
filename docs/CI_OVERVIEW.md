# CI/CD Pipeline Overview

## 🔄 Comprehensive CI/CD with Security & Quality Gates

This document provides an overview of the CI/CD pipeline for We Decor Enquiries, including job descriptions, artifacts, and local reproduction steps.

---

## 📊 Pipeline Architecture

### **Trigger Events**
- **Push**: `main`, `feature/*`, `stabilization/*`, `ops/*`
- **Pull Request**: `main`, `feature/*`, `stabilization/*`, `ops/*`
- **Schedule**: Nightly at 2 AM UTC for maintenance tasks

### **Concurrency Control**
- **Group**: `${{ github.workflow }}-${{ github.ref }}`
- **Cancel in Progress**: `true` (saves CI resources)

---

## 🛠️ CI Jobs Breakdown

### **1. Analyze & Test (`analyze_and_test`)**
**Duration**: ~10-15 minutes  
**Purpose**: Core code quality and test validation

#### **Steps**:
1. **Setup**: Flutter, Java, Node.js with caching
2. **Dependencies**: `flutter pub get`, `npm ci`
3. **Code Generation**: `dart run build_runner build`
4. **Analysis**: `flutter analyze` (must have 0 errors)
5. **Security Scan**: Semgrep static analysis
6. **Tests**: Unit tests with retry logic
7. **Coverage**: Generate and analyze test coverage

#### **Outputs**:
- `coverage_summary`: Overall coverage percentage
- `test_results`: Test execution status

#### **Artifacts**:
- `analysis_report.txt`: Flutter analyzer output
- `coverage_summary.txt`: Detailed coverage breakdown
- `coverage/lcov.info`: Raw coverage data

### **2. Firestore Rules Tests (`firestore_rules_tests`)**
**Duration**: ~5-8 minutes  
**Purpose**: Validate database security rules

#### **Steps**:
1. **Setup**: Node.js with Firebase CLI
2. **Emulator Caching**: Cache Firebase emulators for speed
3. **Dependencies**: `npm ci` in rules-tests directory
4. **Rules Testing**: Jest with stabilized emulator lifecycle

#### **Features**:
- **Isolated Projects**: Unique project ID per test run
- **Proper Cleanup**: `clearFirestoreData` between tests
- **Wait Logic**: `wait-on` ensures emulator readiness
- **Comprehensive Coverage**: 28 security boundary tests

#### **Artifacts**:
- `rules_test_output.json`: Test results and timing

### **3. Build Android Artifacts (`build_android_artifacts`)**
**Duration**: ~8-12 minutes  
**Purpose**: Generate production-ready APK with security

#### **Steps**:
1. **Setup**: Flutter with Android SDK
2. **Cache Restoration**: Restore build dependencies
3. **Release Build**: Obfuscated APK with split debug info
4. **Checksum Generation**: SHA256 for integrity verification

#### **Build Configuration**:
```bash
flutter build apk --release \
  --dart-define=APP_ENV=prod \
  --dart-define=ENABLE_CRASHLYTICS=true \
  --dart-define=ENABLE_PERFORMANCE=true \
  --dart-define=ENABLE_ANALYTICS=false \
  --obfuscate \
  --split-debug-info=build/debug-info/
```

#### **Artifacts**:
- `app-release.apk`: Production Android application
- `SHA256.txt`: Integrity checksum
- **Retention**: 90 days

### **4. Web Preview Deploy (`web_preview_deploy`)**
**Duration**: ~6-10 minutes  
**Purpose**: Deploy PR previews with performance analysis  
**Condition**: Pull requests only

#### **Steps**:
1. **Web Build**: Production web build
2. **Preview Deploy**: Firebase Hosting channels (7-day TTL)
3. **Lighthouse CI**: Performance and accessibility audit

#### **Channel Naming**:
- **Format**: `pr-{number}` or `{branch-name}`
- **Sanitization**: Replace `/` and `_` with `-`, max 63 chars
- **TTL**: 7 days automatic cleanup

#### **Outputs**:
- `preview_url`: Live preview URL
- `lighthouse_score`: Performance score (0-100)

#### **Artifacts**:
- `lighthouse-report.html`: Visual performance report
- `lighthouse-report.json`: Machine-readable results

### **5. Integration Smoke Tests (`integration_smoke_tests`)**
**Duration**: ~5-8 minutes  
**Purpose**: E2E validation of RBAC functionality

#### **Steps**:
1. **Emulator Setup**: Firestore emulator with timeout handling
2. **RBAC Tests**: Staff vs Admin UI behavior validation
3. **Cleanup**: Proper emulator shutdown

#### **Test Coverage**:
- Staff cannot see admin-only UI elements
- Admin can access all features
- CSV export scope validation
- Navigation guard enforcement

#### **Artifacts**:
- `rbac_smoke.log`: Integration test execution log

### **6. Slack Notifications (`slack_notifications`)**
**Duration**: ~1-2 minutes  
**Purpose**: Team communication and status updates  
**Condition**: Always runs (success or failure)

#### **Notification Types**:

##### **Main Branch Success**:
```json
{
  "text": "✅ SUCCESS — main build completed",
  "color": "good",
  "fields": [
    {"title": "Commit", "value": "abc123...", "short": true},
    {"title": "Coverage", "value": "35% overall", "short": true},
    {"title": "APK Checksum", "value": "sha256:...", "short": false}
  ]
}
```

##### **Pull Request Status**:
```json
{
  "text": "✅ SUCCESS — PR #123",
  "color": "good", 
  "fields": [
    {"title": "Branch", "value": "feature/new-feature", "short": true},
    {"title": "Preview", "value": "https://pr-123--project.web.app", "short": true},
    {"title": "Lighthouse", "value": "P85", "short": true}
  ]
}
```

##### **Failure Notification**:
```json
{
  "text": "❌ FAILED — feature/branch @ commit",
  "color": "danger"
}
```

### **7. Nightly Maintenance (`nightly_maintenance`)**
**Duration**: ~15-20 minutes  
**Purpose**: Automated maintenance and monitoring  
**Schedule**: Daily at 2 AM UTC

#### **Tasks**:
1. **Dependency Updates**: Check for outdated packages
2. **Lighthouse CI**: Comprehensive web performance audit
3. **Security Scan**: Full codebase security analysis

#### **Artifacts**:
- `dependency_report.txt`: Outdated packages report
- `nightly-lighthouse.report.html`: Performance analysis
- `security-scan-results.json`: Security findings

---

## 📁 Artifacts & Reports

### **Artifact Retention Policy**
| Artifact Type | Retention | Purpose |
|---------------|-----------|---------|
| **APK + Checksum** | 90 days | Release artifacts |
| **Test Reports** | 30 days | Debugging and analysis |
| **Lighthouse Reports** | 30 days | Performance tracking |
| **Integration Logs** | 14 days | E2E test debugging |
| **Nightly Reports** | 7 days | Maintenance tracking |

### **Artifact Access**
- **GitHub Actions UI**: Download from workflow run page
- **API Access**: GitHub REST API for automated retrieval
- **Slack Integration**: Key artifacts linked in notifications

---

## 🔒 Security & Quality Gates

### **Security Scanning**
- **Semgrep**: Static analysis for security vulnerabilities
- **Secret Detection**: Hardcoded credentials and API keys
- **RBAC Validation**: Admin-only operations properly guarded
- **Dependency Audit**: Known vulnerabilities in packages

### **Quality Gates**
- **Analyzer**: 0 errors required (warnings allowed)
- **Tests**: 100% pass rate required
- **Coverage**: Component-specific thresholds
  - Critical (Auth, User Mgmt, Enquiries): ≥30%
  - Standard (Settings, Dashboard): ≥20%
- **Build**: Successful APK generation required

### **Performance Gates**
- **Lighthouse**: Performance score tracked and reported
- **Bundle Size**: APK size monitoring
- **Build Time**: CI duration tracking

---

## 🚀 Performance Optimizations

### **Caching Strategy**
```yaml
# Dependencies Cache
~/.pub-cache          # Dart packages
.dart_tool            # Build tools
build                 # Build artifacts
node_modules          # Node dependencies
~/.cache/flutter      # Flutter SDK cache

# Emulator Cache
~/.cache/firebase/emulators  # Firebase emulators
```

### **Parallelization**
- **Independent Jobs**: Run analysis, rules tests, and builds in parallel
- **Job Dependencies**: Only necessary dependencies (e.g., tests before deploy)
- **Matrix Builds**: Single platform focus (Ubuntu) for speed

### **Resource Management**
- **Timeouts**: Job-specific timeouts prevent hanging
- **Cleanup**: Proper resource cleanup in all jobs
- **Concurrency**: Cancel in-progress builds for new commits

---

## 🧪 Local Reproduction

### **Run Full Pipeline Locally**
```bash
# 1. Clean and setup
flutter clean && flutter pub get
dart run build_runner build -d

# 2. Analysis and basic tests
flutter analyze --no-fatal-infos
bash tools/test_with_retry.sh

# 3. Enhanced coverage analysis
bash tools/coverage_gate_enhanced.sh

# 4. Firestore rules tests
cd rules-tests && npm ci && npm run ci

# 5. Build verification
flutter build apk --debug
flutter build web --release

# 6. Security scan (requires semgrep)
pip install semgrep
semgrep --config=p/ci --error .

# 7. Lighthouse (requires live URL)
bash tools/lighthouse_ci.sh "https://your-preview-url.com"
```

### **Debug Specific Jobs**

#### **Analyze & Test Issues**:
```bash
# Check analyzer errors
flutter analyze --no-fatal-infos | grep "error •"

# Run tests with verbose output
flutter test --reporter expanded

# Check coverage
flutter test --coverage
bash tools/coverage_gate_enhanced.sh
```

#### **Rules Test Issues**:
```bash
cd rules-tests

# Install dependencies
npm ci

# Start emulator manually
firebase emulators:start --only firestore --project demo-test

# Run tests (in another terminal)
npm test

# Check for port conflicts
lsof -i :8080
```

#### **Build Issues**:
```bash
# Android build
flutter build apk --debug --verbose

# Web build
flutter build web --verbose

# Check for dependency issues
flutter doctor -v
flutter pub deps
```

---

## 🔧 Configuration Management

### **Environment Variables**
| Variable | Purpose | Example |
|----------|---------|---------|
| `FLUTTER_VERSION` | Flutter SDK version | `3.24.3` |
| `JAVA_VERSION` | Java SDK version | `17` |
| `NODE_VERSION` | Node.js version | `18` |
| `FIREBASE_CLI_VERSION` | Firebase CLI version | `13.11.2` |
| `SLACK_WEBHOOK` | Slack notifications | `https://hooks.slack.com/...` |

### **Secrets Management**
- **SLACK_WEBHOOK**: Slack integration (optional)
- **FIREBASE_TOKEN**: Firebase deployment (if needed)
- **GITHUB_TOKEN**: Automatic (for artifacts and API)

### **Feature Flags**
- **Security Scanning**: Can be disabled with `SKIP_SECURITY_SCAN=true`
- **Slack Notifications**: Skipped if `SLACK_WEBHOOK` not set
- **Preview Deploys**: Only on pull requests
- **Nightly Jobs**: Only on schedule trigger

---

## 📈 Monitoring & Metrics

### **Key Performance Indicators**
- **Build Success Rate**: Target >95%
- **Test Pass Rate**: Target 100%
- **Coverage Trend**: Track over time
- **Build Duration**: Monitor for regressions
- **Artifact Size**: Track APK size growth

### **Alert Thresholds**
- **Critical**: Build failures on main branch
- **High**: Coverage drops below critical thresholds
- **Medium**: Performance degradation in Lighthouse
- **Low**: Dependency updates available

### **Dashboards**
- **GitHub Actions**: Built-in workflow monitoring
- **Slack Integration**: Real-time team notifications
- **Artifact Tracking**: Download and usage analytics

---

## 🛠️ Maintenance & Updates

### **Regular Maintenance Tasks**

#### **Weekly**
- Review failed builds and flaky tests
- Check artifact storage usage
- Monitor build performance trends

#### **Monthly**
- Update pinned dependency versions
- Review and update security scan rules
- Optimize cache strategies and job performance

#### **Quarterly**
- Full pipeline review and optimization
- Update documentation and runbooks
- Security audit of CI/CD configuration

### **Troubleshooting Common Issues**

#### **Build Failures**
1. Check dependency cache corruption
2. Verify Flutter/Java/Node versions
3. Review recent code changes for breaking changes
4. Check for Firebase emulator port conflicts

#### **Test Failures**
1. Review quarantine file for known flaky tests
2. Check for timing issues in async tests
3. Verify Firebase emulator setup
4. Run tests locally to reproduce

#### **Deployment Issues**
1. Verify Firebase project permissions
2. Check hosting configuration
3. Review preview channel limits
4. Validate build artifacts

---

## 📞 Support & Escalation

### **CI/CD Issues**
- **Primary**: DevOps Engineer
- **Secondary**: Development Lead
- **Escalation**: Technical Architecture Team

### **Security Alerts**
- **Primary**: Security Team
- **Secondary**: Development Lead
- **Escalation**: Security Officer

### **Performance Issues**
- **Primary**: Performance Engineer
- **Secondary**: Frontend Lead
- **Escalation**: Technical Architecture Team

---

*Last Updated: September 21, 2024*  
*Pipeline Version: 2.0*  
*Next Review: October 21, 2024*
