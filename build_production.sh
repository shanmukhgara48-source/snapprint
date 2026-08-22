#!/usr/bin/env bash
# SnapPrint Production Build Script
# Usage: ./build_production.sh <API_URL> <RAZORPAY_LIVE_KEY>
#        SNAPPRINT_API_URL=https://api.snapprint.in RAZORPAY_KEY_ID="$RAZORPAY_LIVE_KEY_ID" ./build_production.sh
# Optional: BUILD_NAME=1.0.0 BUILD_NUMBER=42 ./build_production.sh ...

set -euo pipefail

API_URL="${1:-${SNAPPRINT_API_URL:-}}"
RAZORPAY_KEY="${2:-${RAZORPAY_KEY_ID:-}}"
BUILD_NAME="${BUILD_NAME:-}"
BUILD_NUMBER="${BUILD_NUMBER:-}"

usage() {
  cat <<'EOF'
Usage:
  ./build_production.sh <API_URL> <RAZORPAY_LIVE_KEY>

Example:
  ./build_production.sh https://api.snapprint.in "$RAZORPAY_LIVE_KEY_ID"

Required before running:
  - snap_print/android/key.properties, or KEYSTORE_PATH/KEYSTORE_PASSWORD/KEY_ALIAS/KEY_PASSWORD
  - snap_print/android/app/google-services.json for the production Firebase Android app
EOF
}

if [[ -z "$API_URL" || -z "$RAZORPAY_KEY" ]]; then
  usage
  exit 1
fi

if [[ "$API_URL" != https://* ]]; then
  echo "ERROR: Production API URL must use HTTPS."
  exit 1
fi

if [[ "$API_URL" == *"localhost"* || "$API_URL" == *"127.0.0.1"* || "$API_URL" == *"10.0.2.2"* || "$API_URL" == *"example."* ]]; then
  echo "ERROR: Production API URL cannot point to a local/example host."
  exit 1
fi

if [[ "$RAZORPAY_KEY" != rzp_live_* || "$RAZORPAY_KEY" == *"REPLACE"* || "$RAZORPAY_KEY" == *"placeholder"* || "$RAZORPAY_KEY" == *"xxxxx"* ]]; then
  echo 'ERROR: Pass a real live Razorpay key, e.g. ./build_production.sh https://api.snapprint.in "$RAZORPAY_LIVE_KEY_ID"'
  exit 1
fi

if [[ ! -f "snap_print/android/app/google-services.json" ]]; then
  echo "ERROR: Missing snap_print/android/app/google-services.json."
  exit 1
fi

HAS_KEY_PROPERTIES=false
if [[ -f "snap_print/android/key.properties" ]] &&
  grep -q '^storeFile=' snap_print/android/key.properties &&
  grep -q '^storePassword=' snap_print/android/key.properties &&
  grep -q '^keyAlias=' snap_print/android/key.properties &&
  grep -q '^keyPassword=' snap_print/android/key.properties; then
  HAS_KEY_PROPERTIES=true
fi

HAS_ENV_SIGNING=false
if [[ -n "${KEYSTORE_PATH:-}" && -n "${KEYSTORE_PASSWORD:-}" && -n "${KEY_ALIAS:-}" && -n "${KEY_PASSWORD:-}" ]]; then
  HAS_ENV_SIGNING=true
fi

if [[ "$HAS_KEY_PROPERTIES" != true && "$HAS_ENV_SIGNING" != true ]]; then
  echo "ERROR: Android release signing is not configured."
  echo "Create snap_print/android/key.properties from snap_print/android/key.properties.example,"
  echo "or set KEYSTORE_PATH, KEYSTORE_PASSWORD, KEY_ALIAS, and KEY_PASSWORD in CI."
  exit 1
fi

BUILD_VERSION_ARGS=()
if [[ -n "$BUILD_NAME" ]]; then
  BUILD_VERSION_ARGS+=(--build-name="$BUILD_NAME")
fi
if [[ -n "$BUILD_NUMBER" ]]; then
  BUILD_VERSION_ARGS+=(--build-number="$BUILD_NUMBER")
fi

echo "========================================"
echo "  SnapPrint Production Build"
echo "  API: $API_URL"
echo "  Razorpay: ${RAZORPAY_KEY:0:13}..."
if [[ -n "$BUILD_NAME" || -n "$BUILD_NUMBER" ]]; then
  echo "  Version: ${BUILD_NAME:-pubspec default}+${BUILD_NUMBER:-pubspec default}"
fi
echo "========================================"

cd snap_print

echo "→ Cleaning previous build..."
flutter clean

echo "→ Getting dependencies..."
flutter pub get

echo "→ Running analyzer..."
flutter analyze --no-fatal-infos

echo "→ Running tests..."
flutter test

echo "→ Building release AAB..."
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=../build/debug-symbols/ \
  --dart-define=SNAPPRINT_API_URL="$API_URL" \
  --dart-define=RAZORPAY_KEY_ID="$RAZORPAY_KEY" \
  "${BUILD_VERSION_ARGS[@]}"

echo ""
echo "✅ AAB built at: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Next steps:"
echo "  1. Upload AAB to Google Play Console → Production"
echo "  2. Upload build/debug-symbols/ to Play Console for deobfuscated crash reports"
