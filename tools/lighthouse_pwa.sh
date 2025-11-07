#!/bin/bash

# Lighthouse PWA Audit Script
# Builds web app and runs comprehensive Lighthouse audit

set -e

TIMESTAMP=$(date +%F_%H-%M)
REPORT_DIR="build/lighthouse"
PORT=3000

echo "🔍 Lighthouse PWA Audit - We Decor Enquiries"
echo "⏰ Timestamp: $TIMESTAMP"

# Create report directory
mkdir -p "$REPORT_DIR"

# Check prerequisites
echo "🔧 Checking prerequisites..."

if ! command -v npx &> /dev/null; then
    echo "❌ npx not found. Install Node.js and npm."
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo "❌ Flutter not found. Install Flutter SDK."
    exit 1
fi

# Build web app
echo "🏗️ Building web app for production..."
flutter build web --release \
  --dart-define=APP_ENV=prod \
  --dart-define=ENABLE_ANALYTICS=false \
  --dart-define=ENABLE_CRASHLYTICS=false \
  --dart-define=ENABLE_PERFORMANCE=false

echo "✅ Web build completed"

# Kill any existing servers on the port
echo "🧹 Cleaning up existing servers..."
lsof -ti:$PORT | xargs kill -9 2>/dev/null || true

# Start HTTP server
echo "🌐 Starting HTTP server on port $PORT..."
npx http-server build/web -p $PORT -c-1 -o --cors &
SERVER_PID=$!

# Wait for server to start
echo "⏳ Waiting for server to start..."
sleep 3

# Check if server is running
if ! curl -s "http://localhost:$PORT" > /dev/null; then
    echo "❌ Server failed to start"
    kill $SERVER_PID 2>/dev/null || true
    exit 1
fi

echo "✅ Server running at http://localhost:$PORT"

# Run Lighthouse audit
echo "🔍 Running Lighthouse audit..."
echo "📊 This may take 2-3 minutes..."

REPORT_FILE="$REPORT_DIR/lighthouse-report-$TIMESTAMP.html"
JSON_REPORT="$REPORT_DIR/lighthouse-report-$TIMESTAMP.json"

# Run comprehensive Lighthouse audit
npx lighthouse "http://localhost:$PORT" \
  --output html \
  --output json \
  --output-path "$REPORT_FILE" \
  --chrome-flags="--no-sandbox --headless --disable-gpu" \
  --form-factor=mobile \
  --throttling-method=simulate \
  --quiet || {
    echo "⚠️ Lighthouse audit failed, trying with different flags..."
    
    # Fallback with simpler flags
    npx lighthouse "http://localhost:$PORT" \
      --output html \
      --output-path "$REPORT_FILE" \
      --chrome-flags="--no-sandbox" \
      --quiet || {
        echo "❌ Lighthouse audit failed completely"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    }
}

# Also save JSON report
npx lighthouse "http://localhost:$PORT" \
  --output json \
  --output-path "$JSON_REPORT" \
  --chrome-flags="--no-sandbox --headless --disable-gpu" \
  --quiet 2>/dev/null || echo "⚠️ JSON report generation failed"

# Stop the server
echo "🛑 Stopping HTTP server..."
kill $SERVER_PID 2>/dev/null || true

# Parse Lighthouse scores from JSON (if available)
if [ -f "$JSON_REPORT" ]; then
    echo "📊 Lighthouse Scores:"
    
    # Extract scores using basic tools (no jq dependency)
    PERFORMANCE=$(grep -o '"performance":[0-9.]*' "$JSON_REPORT" | cut -d: -f2 | head -1)
    ACCESSIBILITY=$(grep -o '"accessibility":[0-9.]*' "$JSON_REPORT" | cut -d: -f2 | head -1)
    BEST_PRACTICES=$(grep -o '"best-practices":[0-9.]*' "$JSON_REPORT" | cut -d: -f2 | head -1)
    SEO=$(grep -o '"seo":[0-9.]*' "$JSON_REPORT" | cut -d: -f2 | head -1)
    
    echo "  🚀 Performance: ${PERFORMANCE:-N/A}"
    echo "  ♿ Accessibility: ${ACCESSIBILITY:-N/A}"
    echo "  ✅ Best Practices: ${BEST_PRACTICES:-N/A}"
    echo "  🔍 SEO: ${SEO:-N/A}"
    
    # Check if scores meet targets (≥90)
    if [ -n "$PERFORMANCE" ] && [ -n "$ACCESSIBILITY" ] && [ -n "$BEST_PRACTICES" ] && [ -n "$SEO" ]; then
        PERF_OK=$(echo "$PERFORMANCE >= 0.9" | bc -l 2>/dev/null || echo "0")
        A11Y_OK=$(echo "$ACCESSIBILITY >= 0.9" | bc -l 2>/dev/null || echo "0")
        BP_OK=$(echo "$BEST_PRACTICES >= 0.9" | bc -l 2>/dev/null || echo "0")
        SEO_OK=$(echo "$SEO >= 0.9" | bc -l 2>/dev/null || echo "0")
        
        if [ "$PERF_OK" = "1" ] && [ "$A11Y_OK" = "1" ] && [ "$BP_OK" = "1" ] && [ "$SEO_OK" = "1" ]; then
            echo "✅ All Lighthouse scores meet targets (≥90)"
        else
            echo "⚠️ Some scores below target (≥90)"
        fi
    fi
fi

echo ""
echo "✅ Lighthouse audit completed!"
echo "📁 Reports saved:"
echo "  📊 HTML Report: $REPORT_FILE"
[ -f "$JSON_REPORT" ] && echo "  📋 JSON Report: $JSON_REPORT"

echo ""
echo "📋 Next steps:"
echo "1. Open HTML report in browser to view detailed results"
echo "2. Address any issues with scores below 90"
echo "3. Re-run audit after optimizations"
echo "4. Include report in QA documentation"

# Copy latest report to release folder for easy access
cp "$REPORT_FILE" "release/internal-rc1/lighthouse-report.html" 2>/dev/null || true

echo ""
echo "🔗 Quick view: file://$(pwd)/$REPORT_FILE"
