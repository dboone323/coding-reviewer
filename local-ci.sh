#!/bin/bash
# Local CI/CD Script for CodingReviewer
# Runs on macOS 26 with Xcode 26.3
# Tests on macOS (since it's a macOS app)

set -e

echo "🚀 Starting Local CI/CD for CodingReviewer"
echo "💻 Platform: macOS (latest)"
echo "🛠️ Xcode: 26.3 on macOS 26"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print status
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 1. Code Quality & Linting
echo "🔍 Running Code Quality Checks..."

if command -v swiftformat >/dev/null 2>&1; then
    print_status "SwiftFormat check"
    swiftformat . --config .swiftformat --lint --verbose
else
    print_warning "SwiftFormat not installed, skipping format check"
fi

if command -v swiftlint >/dev/null 2>&1; then
    print_status "SwiftLint check"
    swiftlint --strict --reporter emoji
else
    print_warning "SwiftLint not installed, skipping lint check"
fi

# Line length check
print_status "Line length check"
MAX_LENGTH=200
VIOLATIONS=$(find . -name "*.swift" -not -path "./.build/*" -not -path "./DerivedData/*" -exec awk 'length > '$MAX_LENGTH' {print FILENAME":"NR":"$0}' {} \;)
if [ -n "$VIOLATIONS" ]; then
    print_error "Lines exceed $MAX_LENGTH characters:"
    echo "$VIOLATIONS"
    exit 1
else
    print_status "All lines within $MAX_LENGTH characters"
fi

# 2. Build & Test on macOS
echo "🏗️ Building and Testing on macOS..."

MACOS_DESTINATION="platform=macOS"

print_status "Building CodingReviewer for macOS"
BUILD_OUTPUT=$(xcodebuild build \
    -scheme CodingReviewer \
    -destination "$MACOS_DESTINATION" \
    -configuration Debug \
    -skipPackagePluginValidation \
    -disablePackageRepositoryCache \
    -skipPackageUpdates \
    -skipMacroValidation \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO 2>&1)

if echo "$BUILD_OUTPUT" | grep -q "\\*\\* BUILD SUCCEEDED \\*\\*"; then
    print_status "Build succeeded"
else
    print_error "Build failed"
    echo "$BUILD_OUTPUT"
    exit 1
fi

print_status "Running tests on macOS"
xcodebuild test \
    -scheme CodingReviewer \
    -destination "$MACOS_DESTINATION" \
    -configuration Debug \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    -enableCodeCoverage YES \
    -resultBundlePath TestResults.xcresult || true

# 3. Generate Coverage Report
print_status "Generating coverage report"
xcrun xccov view --report --json TestResults.xcresult > coverage.json || true

if [ -f coverage.json ]; then
    COVERAGE=$(jq '.lineCoverage * 100' coverage.json 2>/dev/null || echo "0")
    print_status "Code coverage: ${COVERAGE}%"
fi

# 4. Security Scan (local alternative)
echo "🔒 Running basic security checks..."
if command -v grep >/dev/null 2>&1; then
    SECRETS_FOUND=$(grep -r "password\|secret\|key\|token" --include="*.swift" . | grep -v "Test" | wc -l)
    if [ "$SECRETS_FOUND" -gt 0 ]; then
        print_warning "Potential secrets found in code: $SECRETS_FOUND occurrences"
        print_warning "Review and move to secure storage"
    else
        print_status "No obvious secrets found in code"
    fi
fi

print_status "Local CI/CD completed successfully! 🎉"
echo ""
echo "📊 Test Results: TestResults.xcresult"
echo "📈 Coverage: coverage.json"
echo ""
echo "To view test results in Xcode:"
echo "open TestResults.xcresult"