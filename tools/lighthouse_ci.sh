#!/bin/bash

# Lighthouse CI Script for Performance and PWA Analysis
# Runs comprehensive audits and generates reports for CI/CD pipeline

set -euo pipefail

# Configuration
URL="${1:-}"
OUTPUT_DIR="${2:-./}"
TIMEOUT="${3:-60}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "🔍 Lighthouse CI Analysis"
echo "=================================================="

# Validate input
if [ -z "$URL" ]; then
    echo -e "${RED}❌ Error: URL is required${NC}"
    echo "Usage: $0 <URL> [output_dir] [timeout]"
    echo "Example: $0 https://example.com ./ 60"
    exit 1
fi

echo "🌐 Target URL: $URL"
echo "📁 Output Directory: $OUTPUT_DIR"
echo "⏱️ Timeout: ${TIMEOUT}s"
echo ""

# Ensure output directory exists
mkdir -p "$OUTPUT_DIR"

# Function to wait for URL to be available
wait_for_url() {
    local url="$1"
    local timeout="$2"
    local elapsed=0
    
    echo -e "${BLUE}⏳ Waiting for URL to be available...${NC}"
    
    while [ $elapsed -lt $timeout ]; do
        if curl -s --head --request GET "$url" | grep "200 OK" > /dev/null; then
            echo -e "${GREEN}✅ URL is available${NC}"
            return 0
        fi
        
        echo "⏳ Waiting... (${elapsed}s/${timeout}s)"
        sleep 5
        elapsed=$((elapsed + 5))
    done
    
    echo -e "${RED}❌ URL not available after ${timeout}s${NC}"
    return 1
}

# Function to run lighthouse audit
run_lighthouse_audit() {
    local url="$1"
    local output_dir="$2"
    
    echo -e "${BLUE}🔍 Running Lighthouse audit...${NC}"
    
    # Install lighthouse if not available
    if ! command -v lighthouse &> /dev/null; then
        echo "📦 Installing Lighthouse..."
        npm install -g lighthouse
    fi
    
    # Run comprehensive audit
    lighthouse "$url" \
        --output html \
        --output json \
        --output-path "$output_dir/lighthouse-report" \
        --chrome-flags="--headless --no-sandbox --disable-dev-shm-usage" \
        --preset=desktop \
        --quiet \
        --no-enable-error-reporting
    
    echo -e "${GREEN}✅ Lighthouse audit completed${NC}"
}

# Function to extract and display scores
extract_scores() {
    local json_file="$1"
    
    if [ ! -f "$json_file" ]; then
        echo -e "${RED}❌ Lighthouse JSON report not found${NC}"
        return 1
    fi
    
    echo -e "${BLUE}📊 Lighthouse Scores:${NC}"
    
    # Extract scores using jq if available, otherwise use grep/sed
    if command -v jq &> /dev/null; then
        local performance=$(jq -r '.categories.performance.score * 100 | floor' "$json_file")
        local accessibility=$(jq -r '.categories.accessibility.score * 100 | floor' "$json_file")
        local best_practices=$(jq -r '.categories["best-practices"].score * 100 | floor' "$json_file")
        local seo=$(jq -r '.categories.seo.score * 100 | floor' "$json_file")
        local pwa=$(jq -r '.categories.pwa.score * 100 | floor' "$json_file" 2>/dev/null || echo "N/A")
    else
        # Fallback parsing without jq
        local performance=$(grep -o '"performance":{"score":[0-9.]*' "$json_file" | grep -o '[0-9.]*' | awk '{print int($1*100)}' || echo "N/A")
        local accessibility=$(grep -o '"accessibility":{"score":[0-9.]*' "$json_file" | grep -o '[0-9.]*' | awk '{print int($1*100)}' || echo "N/A")
        local best_practices=$(grep -o '"best-practices":{"score":[0-9.]*' "$json_file" | grep -o '[0-9.]*' | awk '{print int($1*100)}' || echo "N/A")
        local seo=$(grep -o '"seo":{"score":[0-9.]*' "$json_file" | grep -o '[0-9.]*' | awk '{print int($1*100)}' || echo "N/A")
        local pwa="N/A"
    fi
    
    # Display scores with color coding
    echo "🚀 Performance:    $(format_score $performance)"
    echo "♿ Accessibility:  $(format_score $accessibility)"
    echo "🛡️ Best Practices: $(format_score $best_practices)"
    echo "🔍 SEO:           $(format_score $seo)"
    echo "📱 PWA:           $(format_score $pwa)"
    
    # Calculate overall grade
    if [ "$performance" != "N/A" ] && [ "$accessibility" != "N/A" ]; then
        local avg_score=$(( (performance + accessibility + best_practices + seo) / 4 ))
        echo ""
        echo "📊 Overall Grade: $(format_score $avg_score)"
        
        # Set output for CI
        echo "P${performance} A${accessibility} B${best_practices} S${seo}" > lighthouse_summary.txt
    fi
}

# Function to format score with color
format_score() {
    local score="$1"
    
    if [ "$score" = "N/A" ]; then
        echo -e "${YELLOW}N/A${NC}"
    elif [ "$score" -ge 90 ]; then
        echo -e "${GREEN}${score}%${NC}"
    elif [ "$score" -ge 70 ]; then
        echo -e "${YELLOW}${score}%${NC}"
    else
        echo -e "${RED}${score}%${NC}"
    fi
}

# Function to generate recommendations
generate_recommendations() {
    local json_file="$1"
    local output_file="lighthouse_recommendations.txt"
    
    echo "🔍 Generating Performance Recommendations..." > "$output_file"
    echo "" >> "$output_file"
    
    if command -v jq &> /dev/null && [ -f "$json_file" ]; then
        # Extract key opportunities
        echo "## Top Performance Opportunities:" >> "$output_file"
        jq -r '.audits | to_entries[] | select(.value.score != null and .value.score < 0.9) | select(.value.details.overallSavingsMs > 100) | "- \(.value.title): \(.value.displayValue // "No data")"' "$json_file" | head -5 >> "$output_file" || true
        
        echo "" >> "$output_file"
        echo "## Accessibility Issues:" >> "$output_file"
        jq -r '.audits | to_entries[] | select(.value.score != null and .value.score < 1.0) | select(.key | contains("accessibility") or contains("color-contrast") or contains("tap-targets")) | "- \(.value.title)"' "$json_file" | head -5 >> "$output_file" || true
    else
        echo "## Manual Review Required" >> "$output_file"
        echo "- Install jq for detailed recommendations" >> "$output_file"
        echo "- Review HTML report for specific issues" >> "$output_file"
    fi
    
    echo "📋 Recommendations saved to: $output_file"
}

# Main execution
echo -e "${BLUE}🚀 Starting Lighthouse CI Analysis...${NC}"

# Wait for URL to be available
if ! wait_for_url "$URL" "$TIMEOUT"; then
    echo -e "${RED}❌ URL is not accessible - skipping Lighthouse audit${NC}"
    exit 1
fi

# Run Lighthouse audit
if run_lighthouse_audit "$URL" "$OUTPUT_DIR"; then
    echo ""
    
    # Extract and display scores
    JSON_REPORT="$OUTPUT_DIR/lighthouse-report.json"
    if [ -f "$JSON_REPORT" ]; then
        extract_scores "$JSON_REPORT"
        generate_recommendations "$JSON_REPORT"
    else
        echo -e "${YELLOW}⚠️ JSON report not found - check HTML report${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}🎉 Lighthouse CI completed successfully!${NC}"
    echo "📊 HTML Report: $OUTPUT_DIR/lighthouse-report.html"
    echo "📋 JSON Report: $OUTPUT_DIR/lighthouse-report.json"
    
    exit 0
else
    echo -e "${RED}❌ Lighthouse audit failed${NC}"
    exit 1
fi
