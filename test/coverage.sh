#!/bin/bash

# Test Coverage Script for We Decor Enquiries
# Generates HTML coverage report with threshold enforcement

set -e

echo "🧪 Running tests with coverage..."

# Run tests with coverage
flutter test --coverage

# Check if lcov is available
if ! command -v lcov &> /dev/null; then
    echo "⚠️ lcov not found. Install with:"
    echo "  macOS: brew install lcov"
    echo "  Ubuntu: sudo apt-get install lcov"
    echo "  Windows: Use WSL or install lcov manually"
    exit 1
fi

# Check if genhtml is available
if ! command -v genhtml &> /dev/null; then
    echo "⚠️ genhtml not found. Install lcov package."
    exit 1
fi

# Remove generated files from coverage (they inflate numbers artificially)
echo "🧹 Filtering out generated files..."
lcov --remove coverage/lcov.info \
    '**/*.g.dart' \
    '**/*.freezed.dart' \
    '**/*.gen.dart' \
    '**/*.mocks.dart' \
    '**/firebase_options.dart' \
    -o coverage/lcov_filtered.info

# Generate HTML report
echo "📊 Generating HTML coverage report..."
genhtml coverage/lcov_filtered.info -o coverage/html

# Calculate coverage percentage for core domain logic
echo "📈 Calculating coverage for core domain logic..."
DOMAIN_COVERAGE=$(lcov --summary coverage/lcov_filtered.info 2>/dev/null | grep "lines" | grep -o '[0-9.]*%' | head -1 | sed 's/%//')

echo "📋 Coverage Report Generated:"
echo "  📁 HTML Report: coverage/html/index.html"
echo "  📊 Domain Coverage: ${DOMAIN_COVERAGE}%"

# Set minimum coverage threshold
MIN_COVERAGE=30

# Check if coverage meets threshold
if (( $(echo "$DOMAIN_COVERAGE >= $MIN_COVERAGE" | bc -l) )); then
    echo "✅ Coverage threshold met: ${DOMAIN_COVERAGE}% >= ${MIN_COVERAGE}%"
    exit 0
else
    echo "❌ Coverage below threshold: ${DOMAIN_COVERAGE}% < ${MIN_COVERAGE}%"
    echo "💡 Add more tests to improve coverage"
    exit 1
fi
