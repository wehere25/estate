#!/bin/bash

echo "=== DIRECT FLUTTER HEADER FIX ==="
echo "This script will directly copy Flutter.h to multiple locations"

# Find the sqflite header file that's causing problems
SQFLITE_DIR=$(find ~/.pub-cache/hosted/pub.dev -name "sqflite_darwin" | grep -v .dart_tool)
SQFLITE_HEADER=$(find ~/.pub-cache/hosted/pub.dev -name "SqfliteImportPublic.h")

if [ -z "$SQFLITE_HEADER" ]; then
  echo "Error: SqfliteImportPublic.h not found in pub cache"
  exit 1
fi

echo "Found sqflite header at: $SQFLITE_HEADER"
echo "Sqflite directory: $SQFLITE_DIR"

# Find the actual Flutter.h file
FLUTTER_HEADER=$(find ~/development/flutter -name Flutter.h | grep -E "Flutter.framework/Headers/Flutter.h" | head -1)

if [ -z "$FLUTTER_HEADER" ]; then
  echo "Error: Flutter.h not found in Flutter SDK"
  exit 1
fi

echo "Found Flutter.h at: $FLUTTER_HEADER"

echo "1. Cleaning up previous build artifacts..."
flutter clean
rm -rf ~/Desktop/projects/RealState/rsapp/ios/Pods
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo "2. Creating Flutter directories in all potential locations..."
# Create Flutter directory in Pods
mkdir -p ~/Desktop/projects/RealState/rsapp/ios/Pods/Flutter/Flutter.framework/Headers
# Create Flutter directory where sqflite is looking
SQFLITE_INCLUDE_DIR=$(dirname "$SQFLITE_HEADER")
mkdir -p "$SQFLITE_INCLUDE_DIR/Flutter"
# Create Flutter directory in project
mkdir -p ~/Desktop/projects/RealState/rsapp/ios/Flutter/Flutter.framework/Headers
# Create Flutter directory in Runner
mkdir -p ~/Desktop/projects/RealState/rsapp/ios/Runner/Flutter

echo "3. Copying Flutter.h to multiple locations..."
cp "$FLUTTER_HEADER" ~/Desktop/projects/RealState/rsapp/ios/Pods/Flutter/Flutter.framework/Headers/
cp "$FLUTTER_HEADER" "$SQFLITE_INCLUDE_DIR/Flutter/"
cp "$FLUTTER_HEADER" ~/Desktop/projects/RealState/rsapp/ios/Flutter/Flutter.framework/Headers/
cp "$FLUTTER_HEADER" ~/Desktop/projects/RealState/rsapp/ios/Runner/Flutter/

echo "4. Modifying sqflite header to use direct inclusion..."
sed -i '' 's|#import <Flutter/Flutter.h>|// Modified import for Flutter.h\n#import "Flutter/Flutter.h"|g' "$SQFLITE_HEADER"

echo "5. Creating xcconfig file with header search paths..."
cat > ~/Desktop/projects/RealState/rsapp/ios/Flutter/FlutterHeaders.xcconfig << EOL
// Flutter Header search paths
HEADER_SEARCH_PATHS = \$(inherited) \$(SRCROOT)/Flutter \$(SRCROOT)/Flutter/Flutter.framework/Headers \$(SRCROOT)/Runner/Flutter \$(PODS_ROOT)/Flutter/Flutter.framework/Headers "${SQFLITE_INCLUDE_DIR}"
EOL

echo "6. Getting fresh dependencies and updating Flutter plugins..."
cd ~/Desktop/projects/RealState/rsapp && flutter pub get

echo "7. Running pod install with clean cache..."
cd ~/Desktop/projects/RealState/rsapp/ios && pod cache clean --all && pod install

echo ""
echo "=== Fix completed! ==="
echo "Now try running: cd ~/Desktop/projects/RealState/rsapp && flutter run -d \"iPhone 16 Plus\""