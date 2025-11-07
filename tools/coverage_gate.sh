#!/bin/bash

# Coverage Gate Script for We Decor Enquiries RBAC System
# Enforces minimum coverage requirements for critical security components

set -e

# Configuration
MIN_COVERAGE_PERCENT=${MIN_COVERAGE_PERCENT:-30}
COVERAGE_FILE="coverage/lcov.info"
REPORT_FILE="coverage/coverage_report.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🎯 Coverage Gate Analysis - Minimum Required: ${MIN_COVERAGE_PERCENT}%"
echo "=================================================="

# Check if coverage file exists
if [ ! -f "$COVERAGE_FILE" ]; then
    echo -e "${RED}❌ Coverage file not found: $COVERAGE_FILE${NC}"
    echo "Please run 'flutter test --coverage' first"
    exit 1
fi

# Create coverage directory if it doesn't exist
mkdir -p coverage

# Function to calculate coverage percentage for a path
calculate_coverage() {
    local path_pattern="$1"
    local description="$2"
    
    # Extract lines for the specific path
    local lines_found=$(grep -E "^SF:.*${path_pattern}" "$COVERAGE_FILE" | wc -l | tr -d ' ')
    local lines_hit=0
    local lines_total=0
    
    if [ "$lines_found" -gt 0 ]; then
        # Get all files matching the pattern
        local files=$(grep -E "^SF:.*${path_pattern}" "$COVERAGE_FILE" | sed 's/^SF://')
        
        while IFS= read -r file; do
            if [ -n "$file" ]; then
                # Extract coverage data for this file using grep instead of awk
                local file_section=$(grep -A 1000 "^SF:$file$" "$COVERAGE_FILE" | grep -B 1000 "^end_of_record$" | head -n -1)
                
                # Count hit and total lines
                local file_lines_hit=$(echo "$file_section" | grep -E "^DA:" | grep -v ",0$" | wc -l | tr -d ' ')
                local file_lines_total=$(echo "$file_section" | grep -E "^DA:" | wc -l | tr -d ' ')
                
                lines_hit=$((lines_hit + file_lines_hit))
                lines_total=$((lines_total + file_lines_total))
            fi
        done <<< "$files"
    fi
    
    local percentage=0
    if [ "$lines_total" -gt 0 ]; then
        percentage=$((lines_hit * 100 / lines_total))
    fi
    
    printf "%-40s %3d/%3d lines (%2d%%)" "$description" "$lines_hit" "$lines_total" "$percentage"
    
    if [ "$percentage" -ge "$MIN_COVERAGE_PERCENT" ]; then
        echo -e " ${GREEN}✅${NC}"
        return 0
    else
        echo -e " ${RED}❌${NC}"
        return 1
    fi
}

# Function to get overall coverage
calculate_overall_coverage() {
    local lines_hit=$(grep -E "^DA:" "$COVERAGE_FILE" | grep -v ",0$" | wc -l | tr -d ' ')
    local lines_total=$(grep -E "^DA:" "$COVERAGE_FILE" | wc -l | tr -d ' ')
    
    local percentage=0
    if [ "$lines_total" -gt 0 ]; then
        percentage=$((lines_hit * 100 / lines_total))
    fi
    
    echo "$percentage $lines_hit $lines_total"
}

# Start coverage analysis
echo -e "${BLUE}📊 Analyzing Coverage by Component:${NC}"
echo ""

# Track failures
failed_components=0

# Critical RBAC components
echo -e "${YELLOW}🔐 Security & RBAC Components:${NC}"
calculate_coverage "lib/core/auth/" "Core Authentication" || failed_components=$((failed_components + 1))
calculate_coverage "lib/core/export/" "CSV Export System" || failed_components=$((failed_components + 1))
calculate_coverage "lib/core/services/audit_service.dart" "Audit Service" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}👥 User Management:${NC}"
calculate_coverage "lib/features/admin/users/" "User Management" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}📋 Enquiry System:${NC}"
calculate_coverage "lib/features/enquiries/" "Enquiry Features" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}⚙️ Settings & Configuration:${NC}"
calculate_coverage "lib/features/settings/" "Settings System" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}🌐 Shared Components:${NC}"
calculate_coverage "lib/shared/" "Shared Components" || failed_components=$((failed_components + 1))

# Calculate overall coverage
echo ""
echo "=================================================="
read overall_percent overall_hit overall_total <<< $(calculate_overall_coverage)

printf "%-40s %3d/%3d lines (%2d%%)" "🎯 Overall Project Coverage" "$overall_hit" "$overall_total" "$overall_percent"

if [ "$overall_percent" -ge "$MIN_COVERAGE_PERCENT" ]; then
    echo -e " ${GREEN}✅${NC}"
    overall_pass=true
else
    echo -e " ${RED}❌${NC}"
    overall_pass=false
fi

echo ""
echo "=================================================="

# Generate detailed report
{
    echo "# Coverage Report - $(date)"
    echo ""
    echo "## Summary"
    echo "- Overall Coverage: ${overall_percent}% (${overall_hit}/${overall_total} lines)"
    echo "- Minimum Required: ${MIN_COVERAGE_PERCENT}%"
    echo "- Failed Components: ${failed_components}"
    echo ""
    echo "## Component Breakdown"
    echo "| Component | Coverage | Status |"
    echo "|-----------|----------|--------|"
} > "$REPORT_FILE"

# Add component details to report
{
    calculate_coverage "lib/core/auth/" "Core Authentication" >/dev/null 2>&1 && echo "| Core Authentication | ✅ Pass | Good |" || echo "| Core Authentication | ❌ Fail | Needs Work |"
    calculate_coverage "lib/core/export/" "CSV Export System" >/dev/null 2>&1 && echo "| CSV Export System | ✅ Pass | Good |" || echo "| CSV Export System | ❌ Fail | Needs Work |"
    calculate_coverage "lib/features/admin/users/" "User Management" >/dev/null 2>&1 && echo "| User Management | ✅ Pass | Good |" || echo "| User Management | ❌ Fail | Needs Work |"
    calculate_coverage "lib/features/enquiries/" "Enquiry Features" >/dev/null 2>&1 && echo "| Enquiry Features | ✅ Pass | Good |" || echo "| Enquiry Features | ❌ Fail | Needs Work |"
    calculate_coverage "lib/features/settings/" "Settings System" >/dev/null 2>&1 && echo "| Settings System | ✅ Pass | Good |" || echo "| Settings System | ❌ Fail | Needs Work |"
    calculate_coverage "lib/shared/" "Shared Components" >/dev/null 2>&1 && echo "| Shared Components | ✅ Pass | Good |" || echo "| Shared Components | ❌ Fail | Needs Work |"
} >> "$REPORT_FILE"

{
    echo ""
    echo "## Recommendations"
    if [ "$failed_components" -gt 0 ]; then
        echo "- Focus on improving coverage for failed components"
        echo "- Add unit tests for critical security functions"
        echo "- Ensure all role guard functions are tested"
        echo "- Test CSV export column filtering logic"
    else
        echo "- All components meet minimum coverage requirements ✅"
        echo "- Continue maintaining high test coverage"
        echo "- Consider increasing coverage targets for critical components"
    fi
    echo ""
    echo "Generated by: tools/coverage_gate.sh"
} >> "$REPORT_FILE"

# Final result
echo -e "${BLUE}📋 Coverage Report saved to: ${REPORT_FILE}${NC}"
echo ""

if [ "$overall_pass" = true ] && [ "$failed_components" -eq 0 ]; then
    echo -e "${GREEN}🎉 Coverage Gate PASSED!${NC}"
    echo -e "   Overall coverage (${overall_percent}%) meets minimum requirement (${MIN_COVERAGE_PERCENT}%)"
    echo -e "   All critical components have adequate test coverage"
    exit 0
else
    echo -e "${RED}❌ Coverage Gate FAILED!${NC}"
    if [ "$overall_pass" = false ]; then
        echo -e "   Overall coverage (${overall_percent}%) is below minimum requirement (${MIN_COVERAGE_PERCENT}%)"
    fi
    if [ "$failed_components" -gt 0 ]; then
        echo -e "   ${failed_components} component(s) failed coverage requirements"
    fi
    echo ""
    echo -e "${YELLOW}💡 To improve coverage:${NC}"
    echo "   1. Run: flutter test --coverage"
    echo "   2. Add tests for uncovered code paths"
    echo "   3. Focus on critical security components"
    echo "   4. Re-run this script to verify improvements"
    exit 1
fi
