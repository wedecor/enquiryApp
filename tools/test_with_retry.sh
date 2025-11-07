#!/bin/bash

# Test with Retry Script - Handles flaky tests gracefully
# Retries failed tests and quarantines persistently failing tests

set -e

# Configuration
MAX_ATTEMPTS=${MAX_ATTEMPTS:-2}
QUARANTINE_FILE="test_quarantine.txt"
TEST_OUTPUT="test_results.txt"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🧪 Running Tests with Retry Logic"
echo "=================================================="
echo "📊 Max Attempts: $MAX_ATTEMPTS"
echo "📋 Quarantine File: $QUARANTINE_FILE"
echo ""

# Function to run tests and capture output
run_tests() {
    local attempt=$1
    echo -e "${BLUE}🔄 Test Attempt $attempt/$MAX_ATTEMPTS${NC}"
    
    if flutter test --reporter expanded > "$TEST_OUTPUT" 2>&1; then
        echo -e "${GREEN}✅ Tests passed on attempt $attempt${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️ Tests failed on attempt $attempt${NC}"
        return 1
    fi
}

# Function to extract failed test names
extract_failed_tests() {
    if [ -f "$TEST_OUTPUT" ]; then
        # Extract failed test file paths from Flutter test output
        grep -E "FAILED|EXCEPTION|Error:" "$TEST_OUTPUT" | \
        grep -oE "test/[^:]*\.dart" | \
        sort -u > failed_tests.tmp || touch failed_tests.tmp
        
        if [ -s failed_tests.tmp ]; then
            echo -e "${RED}📋 Failed Tests:${NC}"
            cat failed_tests.tmp
            return 0
        else
            echo "📋 No specific failed tests identified"
            return 1
        fi
    fi
}

# Function to update quarantine list
update_quarantine() {
    local failed_tests_file="failed_tests.tmp"
    
    if [ -f "$failed_tests_file" ] && [ -s "$failed_tests_file" ]; then
        echo -e "${YELLOW}📝 Updating quarantine list...${NC}"
        
        # Create quarantine file if it doesn't exist
        touch "$QUARANTINE_FILE"
        
        # Add failed tests to quarantine with timestamp
        while IFS= read -r test_file; do
            if ! grep -q "$test_file" "$QUARANTINE_FILE"; then
                echo "$(date '+%Y-%m-%d %H:%M:%S') - $test_file" >> "$QUARANTINE_FILE"
                echo "  ➕ Added to quarantine: $test_file"
            else
                echo "  🔄 Already in quarantine: $test_file"
            fi
        done < "$failed_tests_file"
        
        # Clean up temp file
        rm -f "$failed_tests_file"
    fi
}

# Function to run quarantined tests (non-blocking)
run_quarantined_tests() {
    if [ -f "$QUARANTINE_FILE" ] && [ -s "$QUARANTINE_FILE" ]; then
        echo ""
        echo -e "${YELLOW}🚧 Running Quarantined Tests (non-blocking):${NC}"
        
        # Extract unique test files from quarantine
        local quarantined_tests=$(cut -d' ' -f3- "$QUARANTINE_FILE" | sort -u)
        
        if [ ! -z "$quarantined_tests" ]; then
            echo "$quarantined_tests" | while IFS= read -r test_file; do
                if [ -f "$test_file" ]; then
                    echo "  🧪 Testing: $test_file"
                    if flutter test "$test_file" >/dev/null 2>&1; then
                        echo -e "    ${GREEN}✅ Now passing - consider removing from quarantine${NC}"
                    else
                        echo -e "    ${RED}❌ Still failing${NC}"
                    fi
                else
                    echo -e "    ${YELLOW}⚠️ File not found - may have been deleted${NC}"
                fi
            done
        fi
    else
        echo -e "${GREEN}✅ No tests in quarantine${NC}"
    fi
}

# Main test execution
success=false

for attempt in $(seq 1 $MAX_ATTEMPTS); do
    if run_tests "$attempt"; then
        success=true
        break
    else
        if [ "$attempt" -lt "$MAX_ATTEMPTS" ]; then
            echo -e "${YELLOW}🔄 Retrying tests...${NC}"
            sleep 2
        fi
    fi
done

# Handle results
if [ "$success" = true ]; then
    echo ""
    echo -e "${GREEN}🎉 TEST SUITE PASSED!${NC}"
    
    # Run quarantined tests to check if they're now passing
    run_quarantined_tests
    
    # Display test summary
    if [ -f "$TEST_OUTPUT" ]; then
        TOTAL_TESTS=$(grep -c "^[0-9][0-9]:[0-9][0-9] +" "$TEST_OUTPUT" | tail -1 || echo "0")
        echo "📊 Total Tests: $TOTAL_TESTS"
    fi
    
    exit 0
else
    echo ""
    echo -e "${RED}❌ TEST SUITE FAILED AFTER $MAX_ATTEMPTS ATTEMPTS${NC}"
    
    # Extract and quarantine failed tests
    extract_failed_tests
    update_quarantine
    
    # Show test output for debugging
    echo ""
    echo -e "${RED}📋 Test Output (last 50 lines):${NC}"
    tail -n 50 "$TEST_OUTPUT" || echo "No test output available"
    
    # Provide guidance
    echo ""
    echo -e "${YELLOW}💡 Troubleshooting Steps:${NC}"
    echo "1. Check quarantine file: $QUARANTINE_FILE"
    echo "2. Run specific failed tests locally"
    echo "3. Review test output above for error patterns"
    echo "4. Consider if tests need Firebase emulator setup"
    
    exit 1
fi
