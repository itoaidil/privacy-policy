#!/bin/bash

# OTP Testing Guide for Travel Booking App
# Run this to test OTP registration flow

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📱 OTP Email Verification - Testing Guide"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Check if emulator is running
EMULATOR=$(adb devices | grep "emulator-5554" | awk '{print $1}')

if [ -z "$EMULATOR" ]; then
    echo "❌ Emulator not running!"
    echo ""
    echo "Please start emulator first:"
    echo "  flutter emulators"
    echo "  flutter emulators --launch <emulator_name>"
    echo ""
    exit 1
fi

echo "✅ Emulator detected: $EMULATOR"
echo ""

# Change to app directory
cd "$(dirname "$0")"
echo "📂 Current directory: $(pwd)"
echo ""

# Check if pubspec.yaml exists
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ pubspec.yaml not found!"
    echo "Please run this script from travel_booking_app directory"
    exit 1
fi

echo "✅ pubspec.yaml found"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
flutter pub get > /dev/null 2>&1
echo "✅ Dependencies installed"
echo ""

# Run app
echo "🚀 Starting Travel Booking App..."
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 TEST STEPS:"
echo ""
echo "1️⃣  Tap 'Belum punya akun? Daftar'"
echo ""
echo "2️⃣  Fill registration form:"
echo "   - Nama: Test User $(date +%s)"
echo "   - Email: test$(date +%s)@example.com"
echo "   - Phone: 0812$(date +%s | cut -c 6-13)"
echo "   - Password: password123"
echo ""
echo "3️⃣  Tap 'Daftar' button"
echo ""
echo "4️⃣  You should see OTP Verification Screen"
echo ""
echo "5️⃣  Check Railway logs for OTP code:"
echo "   Open new terminal and run:"
echo "   railway logs --tail 50 | grep 'OTP Code'"
echo ""
echo "6️⃣  Enter the 6-digit OTP code in app"
echo ""
echo "7️⃣  Tap 'Verifikasi' button"
echo ""
echo "8️⃣  You should be auto-logged in to HomeScreen"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Press Enter to start the app..."
read

flutter run -d emulator-5554
