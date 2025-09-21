#!/bin/bash

# Enhanced Coverage Gate Script with Component Thresholds
# Enforces different coverage requirements for critical vs non-critical components

set -e

# Configuration
OVERALL_MIN_COVERAGE=${OVERALL_MIN_COVERAGE:-20}  # Soft threshold (warn only)
CRITICAL_MIN_COVERAGE=${CRITICAL_MIN_COVERAGE:-30}  # Hard threshold (fail)
COVERAGE_FILE="coverage/lcov.info"
REPORT_FILE="coverage/coverage_report_enhanced.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
NC='\033[0m' # No Color

echo "🎯 Enhanced Coverage Gate Analysis"
echo "=================================================="
echo "📊 Overall Minimum: ${OVERALL_MIN_COVERAGE}% (soft warning)"
echo "🔒 Critical Minimum: ${CRITICAL_MIN_COVERAGE}% (hard requirement)"
echo ""

# Check if coverage file exists
if [ ! -f "$COVERAGE_FILE" ]; then
    echo -e "${RED}❌ Coverage file not found: $COVERAGE_FILE${NC}"
    echo "Please run 'flutter test --coverage' first"
    exit 1
fi

# Create coverage directory if it doesn't exist
mkdir -p coverage

# Function to get coverage for specific path pattern
get_path_coverage() {
    local path_pattern="$1"
    local description="$2"
    local is_critical="${3:-false}"
    
    # Count files matching pattern
    local matching_files=$(grep "^SF:" "$COVERAGE_FILE" | grep "$path_pattern" | wc -l | tr -d ' ')
    
    if [ "$matching_files" -gt 0 ]; then
        # Extract sections for matching files and calculate coverage
        local temp_file=$(mktemp)
        grep -A 100 "^SF:.*$path_pattern" "$COVERAGE_FILE" | grep -E "^(SF:|LF:|LH:|end_of_record)" > "$temp_file"
        
        local total_lines=$(grep "^LF:" "$temp_file" | cut -d: -f2 | awk '{sum += $1} END {print sum+0}')
        local hit_lines=$(grep "^LH:" "$temp_file" | cut -d: -f2 | awk '{sum += $1} END {print sum+0}')
        
        rm "$temp_file"
        
        local percentage=0
        if [ "$total_lines" -gt 0 ]; then
            percentage=$((hit_lines * 100 / total_lines))
        fi
        
        # Determine threshold and status
        local threshold=$OVERALL_MIN_COVERAGE
        local status_symbol="📊"
        local requirement="soft"
        
        if [ "$is_critical" = "true" ]; then
            threshold=$CRITICAL_MIN_COVERAGE
            status_symbol="🔒"
            requirement="critical"
        fi
        
        printf "%s %-35s %3d/%3d lines (%2d%%)" "$status_symbol" "$description" "$hit_lines" "$total_lines" "$percentage"
        
        if [ "$percentage" -ge "$threshold" ]; then
            echo -e " ${GREEN}✅${NC}"
            return 0
        else
            if [ "$is_critical" = "true" ]; then
                echo -e " ${RED}❌ CRITICAL${NC}"
                return 2  # Critical failure
            else
                echo -e " ${YELLOW}⚠️ WARNING${NC}"
                return 1  # Warning only
            fi
        fi
    else
        printf "%s %-35s %3d/%3d lines (%2d%%)" "📂" "$description" "0" "0" "0"
        echo -e " ${YELLOW}⚠️ No files found${NC}"
        return 1
    fi
}

# Extract overall coverage
extract_overall_coverage() {
    local lines_found=$(grep -c "^LF:" "$COVERAGE_FILE" 2>/dev/null || echo "0")
    local lines_hit=$(grep -c "^LH:" "$COVERAGE_FILE" 2>/dev/null || echo "0")
    
    if [ "$lines_found" -gt 0 ]; then
        local total_lines=$(grep "^LF:" "$COVERAGE_FILE" | cut -d: -f2 | awk '{sum += $1} END {print sum}')
        local hit_lines=$(grep "^LH:" "$COVERAGE_FILE" | cut -d: -f2 | awk '{sum += $1} END {print sum}')
        
        local percentage=0
        if [ "$total_lines" -gt 0 ]; then
            percentage=$((hit_lines * 100 / total_lines))
        fi
        
        echo "$percentage $hit_lines $total_lines"
    else
        echo "0 0 0"
    fi
}

# Track failures
critical_failures=0
warnings=0

# Analyze critical components (hard requirements)
echo -e "${PURPLE}🔒 CRITICAL COMPONENTS (≥${CRITICAL_MIN_COVERAGE}% required):${NC}"
get_path_coverage "lib/core/auth" "Core Authentication" true || { [ $? -eq 2 ] && critical_failures=$((critical_failures + 1)) || warnings=$((warnings + 1)); }
get_path_coverage "lib/features/admin/users" "User Management" true || { [ $? -eq 2 ] && critical_failures=$((critical_failures + 1)) || warnings=$((warnings + 1)); }
get_path_coverage "lib/features/enquiries" "Enquiry Management" true || { [ $? -eq 2 ] && critical_failures=$((critical_failures + 1)) || warnings=$((warnings + 1)); }

echo ""
echo -e "${BLUE}📊 STANDARD COMPONENTS (≥${OVERALL_MIN_COVERAGE}% recommended):${NC}"
get_path_coverage "lib/core/export" "CSV Export System" false || warnings=$((warnings + 1))
get_path_coverage "lib/core/services" "Core Services" false || warnings=$((warnings + 1))
get_path_coverage "lib/features/settings" "Settings System" false || warnings=$((warnings + 1))
get_path_coverage "lib/features/dashboard" "Dashboard" false || warnings=$((warnings + 1))
get_path_coverage "lib/shared" "Shared Components" false || warnings=$((warnings + 1))

# Calculate overall coverage
echo ""
echo "=================================================="
read overall_percent overall_hit overall_total <<< $(extract_overall_coverage)

printf "🎯 %-35s %3d/%3d lines (%2d%%)" "Overall Project Coverage" "$overall_hit" "$overall_total" "$overall_percent"

if [ "$overall_percent" -ge "$OVERALL_MIN_COVERAGE" ]; then
    echo -e " ${GREEN}✅${NC}"
    overall_pass=true
else
    echo -e " ${YELLOW}⚠️ Below recommended${NC}"
    overall_pass=false
    warnings=$((warnings + 1))
fi

echo ""
echo "=================================================="

# Generate enhanced report
{
    echo "# Enhanced Coverage Report - $(date)"
    echo ""
    echo "## Executive Summary"
    echo "- **Overall Coverage**: ${overall_percent}% (${overall_hit}/${overall_total} lines)"
    echo "- **Critical Failures**: ${critical_failures} components below ${CRITICAL_MIN_COVERAGE}%"
    echo "- **Warnings**: ${warnings} components below recommended thresholds"
    echo "- **Files Analyzed**: $(grep -c "^SF:" "$COVERAGE_FILE")"
    echo ""
    echo "## Coverage Thresholds"
    echo "| Component Type | Threshold | Enforcement |"
    echo "|----------------|-----------|-------------|"
    echo "| Critical Security | ≥${CRITICAL_MIN_COVERAGE}% | Hard Fail |"
    echo "| Standard Components | ≥${OVERALL_MIN_COVERAGE}% | Soft Warning |"
    echo ""
    echo "## Component Analysis"
    echo "| Component | Type | Coverage | Status | Priority |"
    echo "|-----------|------|----------|--------|----------|"
} > "$REPORT_FILE"

# Add component details to report
{
    get_path_coverage "lib/core/auth" "Core Authentication" true >/dev/null 2>&1 && echo "| Core Authentication | Critical | ✅ Pass | Good | - |" || echo "| Core Authentication | Critical | ❌ Fail | **URGENT** | P0 |"
    get_path_coverage "lib/features/admin/users" "User Management" true >/dev/null 2>&1 && echo "| User Management | Critical | ✅ Pass | Good | - |" || echo "| User Management | Critical | ❌ Fail | **URGENT** | P0 |"
    get_path_coverage "lib/features/enquiries" "Enquiry Management" true >/dev/null 2>&1 && echo "| Enquiry Management | Critical | ✅ Pass | Good | - |" || echo "| Enquiry Management | Critical | ❌ Fail | **URGENT** | P0 |"
    get_path_coverage "lib/core/export" "CSV Export System" false >/dev/null 2>&1 && echo "| CSV Export System | Standard | ✅ Pass | Good | - |" || echo "| CSV Export System | Standard | ⚠️ Warning | Improve | P1 |"
    get_path_coverage "lib/features/settings" "Settings System" false >/dev/null 2>&1 && echo "| Settings System | Standard | ✅ Pass | Good | - |" || echo "| Settings System | Standard | ⚠️ Warning | Improve | P2 |"
    get_path_coverage "lib/shared" "Shared Components" false >/dev/null 2>&1 && echo "| Shared Components | Standard | ✅ Pass | Good | - |" || echo "| Shared Components | Standard | ⚠️ Warning | Improve | P2 |"
} >> "$REPORT_FILE"

{
    echo ""
    echo "## Action Items"
    if [ "$critical_failures" -gt 0 ]; then
        echo "### 🚨 CRITICAL (Must Fix)"
        echo "- **User Management** coverage is below 30% - add unit tests for role validation"
        echo "- **Authentication** coverage needs improvement - test role guards thoroughly"
        echo "- **Enquiry Management** requires more test coverage - focus on CRUD operations"
        echo ""
    fi
    
    if [ "$warnings" -gt 0 ]; then
        echo "### ⚠️ WARNINGS (Recommended)"
        echo "- Add tests for uncovered service methods"
        echo "- Improve widget test coverage for complex components"
        echo "- Focus on error handling and edge case testing"
        echo ""
    fi
    
    if [ "$critical_failures" -eq 0 ] && [ "$warnings" -eq 0 ]; then
        echo "### ✅ ALL REQUIREMENTS MET"
        echo "- All critical components meet security coverage requirements"
        echo "- Overall coverage is healthy and well-distributed"
        echo "- Continue maintaining high test quality"
        echo ""
    fi
    
    echo "## Next Steps"
    echo "1. **Priority Focus**: Address critical failures first"
    echo "2. **Test Strategy**: Add unit tests for business logic and error paths"
    echo "3. **Monitoring**: Track coverage trends over time"
    echo "4. **Quality**: Ensure tests are meaningful, not just coverage padding"
    echo ""
    echo "Generated by: tools/coverage_gate_enhanced.sh v2.0"
    echo "Report saved: $REPORT_FILE"
} >> "$REPORT_FILE"

# Print summary for CI output
echo -e "${BLUE}📋 Enhanced Coverage Summary:${NC}"
echo "• Overall: ${overall_percent}% (${overall_hit}/${overall_total} lines)"
echo "• Critical Failures: ${critical_failures}/3 components"
echo "• Warnings: ${warnings} components below recommended"
echo "• Report: $REPORT_FILE"

# Final result
if [ "$critical_failures" -eq 0 ]; then
    if [ "$warnings" -eq 0 ]; then
        echo ""
        echo -e "${GREEN}🎉 COVERAGE GATE PASSED!${NC}"
        echo -e "   All components meet requirements"
    else
        echo ""
        echo -e "${YELLOW}⚠️ COVERAGE GATE PASSED WITH WARNINGS${NC}"
        echo -e "   Critical components OK, but ${warnings} warnings"
    fi
    exit 0
else
    echo ""
    echo -e "${RED}❌ COVERAGE GATE FAILED!${NC}"
    echo -e "   ${critical_failures} critical component(s) below ${CRITICAL_MIN_COVERAGE}%"
    echo ""
    echo -e "${YELLOW}💡 Priority Actions:${NC}"
    echo "   1. Add unit tests for User Management (currently 22%)"
    echo "   2. Improve Authentication test coverage"
    echo "   3. Focus on security-critical code paths"
    exit 1
fi
