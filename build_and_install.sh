#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔨 Starting build process..."

# Set JAVA_HOME
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home"

# Navigate to android folder
cd "$(dirname "$0")/android" || exit 1

echo "📦 Building APK with Gradle..."
./gradlew assembleDebug

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Build successful!${NC}"
    
    # Check if APK exists
    APK_PATH="../build/app/outputs/apk/debug/app-debug.apk"
    if [ -f "$APK_PATH" ]; then
        echo -e "${GREEN}✓ APK found${NC}"
        ls -lh "$APK_PATH"
        
        # Copy to SSD_FITRO
        cp "$APK_PATH" /Volumes/SSD_FITRO/travel_booking_app_debug.apk
        echo -e "${GREEN}✓ Copied to /Volumes/SSD_FITRO/travel_booking_app_debug.apk${NC}"
        
        # Install to emulator
        echo "📱 Installing to emulator-5554..."
        adb -s emulator-5554 install -r /Volumes/SSD_FITRO/travel_booking_app_debug.apk
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✓ Successfully installed to emulator!${NC}"
            echo ""
            echo "🎉 All done! Open the app on emulator to see the new 'Hantar Instant' menu."
        else
            echo -e "${RED}✗ Failed to install to emulator${NC}"
            exit 1
        fi
    else
        echo -e "${RED}✗ APK file not found at $APK_PATH${NC}"
        exit 1
    fi
else
    echo -e "${RED}✗ Build failed${NC}"
    exit 1
fi
