#!/bin/bash
# Build script for Travel Booking App releases

set -e

RAILWAY_API="https://travel-api-production-23ae.up.railway.app/api"
LOCAL_API="http://10.0.2.2:3000/api"

echo "🚀 Travel Booking App - Build Script"
echo "===================================="
echo ""

# Check if keystore exists
if [ ! -f "$HOME/upload-keystore.jks" ] && [ ! -f "android/key.properties" ]; then
    echo "⚠️  Warning: No signing keystore found!"
    echo ""
    echo "To create one, run:"
    echo "  keytool -genkeypair -v -keystore ~/upload-keystore.jks -storetype JKS \\"
    echo "    -keyalg RSA -keysize 2048 -validity 10000 -alias upload"
    echo ""
    echo "Then create android/key.properties with:"
    echo "  storePassword=your-password"
    echo "  keyPassword=your-password"
    echo "  keyAlias=upload"
    echo "  storeFile=$HOME/upload-keystore.jks"
    echo ""
    read -p "Continue anyway? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo "Select build type:"
echo "1) Development (local API: $LOCAL_API)"
echo "2) Production (Railway API: $RAILWAY_API)"
echo "3) Custom API URL"
read -p "Choice [1-3]: " choice

API_URL=""
case $choice in
    1)
        API_URL=$LOCAL_API
        echo "📦 Building for DEVELOPMENT"
        ;;
    2)
        API_URL=$RAILWAY_API
        echo "🚀 Building for PRODUCTION"
        ;;
    3)
        read -p "Enter API URL: " API_URL
        echo "🔧 Building with custom API: $API_URL"
        ;;
    *)
        echo "❌ Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "Cleaning previous builds..."
flutter clean

echo "Getting dependencies..."
flutter pub get

echo ""
echo "Building release AAB with API: $API_URL"
echo ""

flutter build appbundle --release \
    --dart-define=API_BASE_URL="$API_URL"

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Build successful!"
    echo ""
    echo "📦 App Bundle: build/app/outputs/bundle/release/app-release.aab"
    echo ""
    echo "Next steps:"
    echo "1. Upload to Google Play Console"
    echo "2. Create release in Internal testing"
    echo "3. Add testers and test"
    echo "4. Promote to Production"
else
    echo ""
    echo "❌ Build failed!"
    exit 1
fi
