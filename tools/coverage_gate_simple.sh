#!/bin/bash

# Simple Coverage Gate Script for We Decor Enquiries
# Enforces minimum coverage requirements using genhtml for accurate parsing

set -e

# Configuration
MIN_COVERAGE_PERCENT=${MIN_COVERAGE_PERCENT:-30}
COVERAGE_FILE="coverage/lcov.info"

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

# Extract overall coverage using simple parsing
extract_overall_coverage() {
    local lines_found=$(grep -c "^LF:" "$COVERAGE_FILE" 2>/dev/null || echo "0")
    local lines_hit=$(grep -c "^LH:" "$COVERAGE_FILE" 2>/dev/null || echo "0")
    
    if [ "$lines_found" -gt 0 ]; then
        # Sum up all LF (lines found) and LH (lines hit) entries
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

# Get coverage for specific path pattern
get_path_coverage() {
    local path_pattern="$1"
    local description="$2"
    
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
        
        printf "%-40s %3d/%3d lines (%2d%%)" "$description" "$hit_lines" "$total_lines" "$percentage"
        
        if [ "$percentage" -ge "$MIN_COVERAGE_PERCENT" ]; then
            echo -e " ${GREEN}✅${NC}"
            return 0
        else
            echo -e " ${RED}❌${NC}"
            return 1
        fi
    else
        printf "%-40s %3d/%3d lines (%2d%%)" "$description" "0" "0" "0"
        echo -e " ${YELLOW}⚠️ No files found${NC}"
        return 1
    fi
}

# Analyze critical components
echo -e "${BLUE}📊 Analyzing Coverage by Component:${NC}"
echo ""

failed_components=0

# Critical RBAC components
echo -e "${YELLOW}🔐 Security & RBAC Components:${NC}"
get_path_coverage "lib/core/auth" "Core Authentication" || failed_components=$((failed_components + 1))
get_path_coverage "lib/core/export" "CSV Export System" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}👥 User Management:${NC}"
get_path_coverage "lib/features/admin/users" "User Management" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}📋 Enquiry System:${NC}"
get_path_coverage "lib/features/enquiries" "Enquiry Features" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}⚙️ Settings & Configuration:${NC}"
get_path_coverage "lib/features/settings" "Settings System" || failed_components=$((failed_components + 1))

echo ""
echo -e "${YELLOW}🌐 Shared Components:${NC}"
get_path_coverage "lib/shared" "Shared Components" || failed_components=$((failed_components + 1))

# Calculate overall coverage
echo ""
echo "=================================================="
read overall_percent overall_hit overall_total <<< $(extract_overall_coverage)

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

# Generate summary
echo -e "${BLUE}📋 Coverage Summary:${NC}"
echo "• Overall Coverage: ${overall_percent}% (${overall_hit}/${overall_total} lines)"
echo "• Minimum Required: ${MIN_COVERAGE_PERCENT}%"
echo "• Failed Components: ${failed_components}/6"
echo "• Files Analyzed: $(grep -c "^SF:" "$COVERAGE_FILE")"

# Final result
if [ "$overall_percent" -ge "$MIN_COVERAGE_PERCENT" ]; then
    echo ""
    echo -e "${GREEN}🎉 Coverage Gate PASSED!${NC}"
    echo -e "   Overall coverage meets minimum requirement"
    exit 0
else
    echo ""
    echo -e "${RED}❌ Coverage Gate FAILED!${NC}"
    echo -e "   Coverage is below minimum requirement (${MIN_COVERAGE_PERCENT}%)"
    echo ""
    echo -e "${YELLOW}💡 To improve coverage:${NC}"
    echo "   1. Add tests for core/auth/ components"
    echo "   2. Add tests for export/ functionality" 
    echo "   3. Add tests for admin user management"
    echo "   4. Focus on business logic in features/"
    exit 1
fi
