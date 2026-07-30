#!/bin/bash
# SnapPrint Production Build Script
# Usage: ./build_production.sh <API_URL> <RAZORPAY_LIVE_KEY>
# Example: ./build_production.sh https://api.snapprint.in rzp_live_xxxxx

set -e

API_URL="${1:-https://api.snapprint.in}"
RAZORPAY_KEY="${2:-}"

if [[ "$API_URL" == *"localhost"* || "$API_URL" == *"10.0.2.2"* ]]; then
  echo "ERROR: Production API URL cannot point to a local development host."
  exit 1
fi

if [[ -z "$RAZORPAY_KEY" || "$RAZORPAY_KEY" == *"REPLACE_ME"* || "$RAZORPAY_KEY" == rzp_test_* ]]; then
  echo "ERROR: Pass a live Razorpay key, e.g. ./build_production.sh https://api.snapprint.in rzp_live_xxxxx"
  exit 1
fi

echo "========================================"
echo "  SnapPrint Production Build"
echo "  API: $API_URL"
echo "  Razorpay: $RAZORPAY_KEY"
echo "========================================"

cd snap_print

echo "→ Cleaning previous build..."
flutter clean

echo "→ Getting dependencies..."
flutter pub get

echo "→ Running analyzer..."
flutter analyze --no-fatal-infos

echo "→ Building release AAB..."
flutter build appbundle \
  --release \
  --obfuscate \
  --split-debug-info=../build/debug-symbols/ \
  --dart-define=SNAPPRINT_API_URL="$API_URL" \
  --dart-define=RAZORPAY_KEY_ID="$RAZORPAY_KEY"

echo ""
echo "✅ AAB built at: build/app/outputs/bundle/release/app-release.aab"
echo ""
echo "Next steps:"
echo "  1. Upload AAB to Google Play Console → Production"
echo "  2. Upload build/debug-symbols/ to Play Console for deobfuscated crash reports"
