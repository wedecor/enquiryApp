# RC2 Fix List - We Decor Enquiries

**Version**: RC1 (v1.0.1+2) → RC2 (v1.0.1+3)  
**Target Date**: September 21, 2024  
**Status**: 🔄 **IN PROGRESS**

---

## 🚨 **P0 Issues (Critical - Must Fix)**

**Current Status**: ✅ **0 P0 Issues Identified**

No critical bugs found in RC1 that block core functionality.

---

## 🔥 **P1 Issues (High Priority - Fix for RC2)**

### **P1-1: Type Error in Enquiry Details Screen**
- **Area**: `area:enquiry`
- **File**: `lib/features/enquiries/presentation/screens/enquiry_details_screen.dart:292`
- **Issue**: `The argument type 'dynamic' can't be assigned to the parameter type 'String?'`
- **Impact**: Potential runtime type errors in enquiry status display
- **Repro**: View enquiry details page, check eventStatus field
- **Fix**: Add proper type casting for `enquiryData['eventStatus']`
- **Owner**: Dev Team
- **ETA**: Immediate
- **Test Plan**: Verify enquiry details page loads without type errors

### **P1-2: Performance Trace API Usage**
- **Area**: `area:performance`
- **File**: `lib/core/perf/perf_traces.dart:70`
- **Issue**: Missing await for Future expression in trace.stop()
- **Impact**: Performance monitoring may not work correctly
- **Repro**: Enable performance monitoring, check Firebase console
- **Fix**: Remove unnecessary await on void methods
- **Owner**: Dev Team  
- **ETA**: Immediate
- **Test Plan**: Verify performance traces appear in Firebase console

### **P1-3: Unused Field Warning**
- **Area**: `area:ui`
- **File**: `lib/shared/widgets/event_type_autocomplete.dart:32`
- **Issue**: `_isInitialized` field is unused but present
- **Impact**: Code quality, potential confusion
- **Repro**: Code review, analyzer warnings
- **Fix**: Either use the field or remove it properly
- **Owner**: Dev Team
- **ETA**: Immediate  
- **Test Plan**: Verify event type autocomplete still functions correctly

---

## 📋 **P2 Issues (Medium Priority - Defer to v1.1)**

### **P2-1: Deprecated API Usage**
- **Area**: `area:ui`
- **Files**: Multiple files using `withOpacity`, `groupValue`, `onChanged`
- **Issue**: Using deprecated Flutter APIs
- **Impact**: Future compatibility warnings
- **Fix**: Update to use `.withValues()` and RadioGroup
- **Owner**: Dev Team
- **ETA**: v1.1 release

### **P2-2: Async Context Usage**
- **Area**: `area:ui`
- **Files**: Multiple files with `use_build_context_synchronously` warnings
- **Issue**: BuildContext used across async gaps
- **Impact**: Potential context issues if widget unmounted
- **Fix**: Add mounted checks or restructure async operations
- **Owner**: Dev Team
- **ETA**: v1.1 release

---

## ✅ **Fixes Implemented**

### **✅ Fixed: Firebase Performance API Compatibility**
- **Issue**: Incorrect API usage for putAttribute and stop methods
- **Fix**: Updated to use synchronous calls as per Firebase Performance SDK
- **Commit**: `34fe651f`
- **Verification**: Performance traces now work correctly

---

## 📊 **Quality Gate Status**

### **Current Status**
| Gate | Status | Details |
|------|--------|---------|
| **flutter analyze** | ⚠️ 1 error | P1-1 type error needs fix |
| **flutter test** | ✅ 105/105 | All unit tests passing |
| **flutter build apk** | ✅ Success | 54.3MB release build |
| **flutter build web** | ✅ Success | PWA builds successfully |

### **RC2 Target Status**
| Gate | Target | Action Required |
|------|--------|-----------------|
| **flutter analyze** | 0 errors | Fix P1-1 type error |
| **flutter test** | 105/105 | Maintain current status |
| **Performance budgets** | ≤2000ms startup | Add trace verification |
| **Lighthouse scores** | ≥90 all metrics | Run manual audit |

---

## 🎯 **RC2 Implementation Plan**

### **Immediate Fixes (Today)**
1. **Fix P1-1**: Type error in enquiry details screen
2. **Fix P1-2**: Performance trace await issue  
3. **Fix P1-3**: Remove or properly use _isInitialized field
4. **Verify**: All quality gates pass

### **Testing & Validation**
1. **Unit Tests**: Ensure all 105 tests still pass
2. **Build Tests**: Verify Android APK and Web PWA build successfully
3. **Manual Testing**: Quick smoke test of core functionality
4. **Performance**: Verify app startup time ≤2000ms

### **RC2 Release**
1. **Version Bump**: 1.0.1+2 → 1.0.1+3
2. **Build & Deploy**: New APK + PWA with fixes
3. **Update Hosting**: Deploy to `/internal/rc2/` and `/pwa/rc2/`
4. **Documentation**: Update release notes with fixes

---

## 📋 **Success Criteria for RC2**

- ✅ **P0 Issues**: 0 (already achieved)
- 🎯 **P1 Issues**: ≤3 (currently 3, will be 0 after fixes)
- 🎯 **Analyzer Errors**: 0 (currently 1, will be 0 after P1-1 fix)
- ✅ **Unit Tests**: 105/105 passing
- ✅ **Builds**: Android + Web successful
- 🎯 **Performance**: Startup ≤2000ms (to be verified)

---

**Next Steps**: Implement P1 fixes, verify quality gates, cut RC2 release
