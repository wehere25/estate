#!/bin/bash

echo "=== SQFLITE FLUTTER IMPORT FIX ==="
echo "This script will fix the Flutter.h import issue for sqflite_darwin"

# Find the sqflite header file that's causing problems
SQFLITE_HEADER=$(find ~/.pub-cache/hosted/pub.dev/sqflite_darwin-2.4.2 -name "SqfliteImportPublic.h")

if [ -z "$SQFLITE_HEADER" ]; then
  echo "Error: SqfliteImportPublic.h not found in pub cache"
  echo "Searching for alternative locations..."
  SQFLITE_HEADER=$(find ~ -name "SqfliteImportPublic.h" 2>/dev/null)
  
  if [ -z "$SQFLITE_HEADER" ]; then
    echo "Error: Could not find SqfliteImportPublic.h anywhere"
    exit 1
  else
    echo "Found sqflite header at: $SQFLITE_HEADER"
  fi
fi

echo "1. Backing up the original sqflite header..."
cp "$SQFLITE_HEADER" "${SQFLITE_HEADER}.backup"

echo "2. Modifying the include statement..."
sed -i '' 's|#import <Flutter/Flutter.h>|// Modified Flutter import to fix build issues\n#import "Flutter/Flutter.h"\n// Alternative import paths if the above fails\n#import "../../../../../Flutter/Flutter.h"\n#import "../../../../../../Flutter/Flutter.h"|g' "$SQFLITE_HEADER"

echo "3. Creating a symbolic link to Flutter.h in a common location..."
mkdir -p ~/Desktop/projects/RealState/rsapp/ios/Flutter/Flutter.framework/Headers
ln -sf ~/development/flutter/bin/cache/artifacts/engine/ios/Flutter.framework/Headers/Flutter.h ~/Desktop/projects/RealState/rsapp/ios/Flutter/Flutter.framework/Headers/Flutter.h

echo "4. Creating a local Flutter.h file for direct inclusion..."
mkdir -p ~/Desktop/projects/RealState/rsapp/ios/Runner/Flutter
cat > ~/Desktop/projects/RealState/rsapp/ios/Runner/Flutter/Flutter.h << 'EOL'
// Flutter.h - Local copy to fix sqflite import issues

#ifndef FLUTTER_FLUTTER_H_
#define FLUTTER_FLUTTER_H_

#import <Foundation/Foundation.h>

@protocol FlutterBinaryMessenger;
@protocol FlutterPluginRegistrar;
@protocol FlutterPlugin;

@interface FlutterMethodChannel : NSObject
+ (instancetype)methodChannelWithName:(NSString*)name
                      binaryMessenger:(id<FlutterBinaryMessenger>)messenger;
- (void)invokeMethod:(NSString*)method arguments:(id _Nullable)arguments;
- (void)setMethodCallHandler:(id _Nullable)handler;
@end

@interface FlutterEventChannel : NSObject
+ (instancetype)eventChannelWithName:(NSString*)name
                     binaryMessenger:(id<FlutterBinaryMessenger>)messenger;
@end

@protocol FlutterPluginRegistrar
- (id<FlutterBinaryMessenger>)messenger;
- (NSString *)lookupKeyForAsset:(NSString *)asset;
- (NSString *)lookupKeyForAsset:(NSString *)asset fromPackage:(NSString *)package;
@end

@protocol FlutterPlugin <NSObject>
+ (void)registerWithRegistrar:(id<FlutterPluginRegistrar>)registrar;
@end

@interface FlutterResult : NSObject
typedef void (^FlutterResult)(id _Nullable result);
@end

@interface FlutterMethodCall : NSObject
@property(nonatomic, readonly) NSString *method;
@property(nonatomic, readonly) id _Nullable arguments;
@end

#endif  // FLUTTER_FLUTTER_H_
EOL

echo "5. Updating any xcconfig files to include additional search paths..."
SEARCH_PATHS_XCCONFIG=~/Desktop/projects/RealState/rsapp/ios/Flutter/FlutterSearchPaths.xcconfig
cat > "$SEARCH_PATHS_XCCONFIG" << 'EOL'
HEADER_SEARCH_PATHS = $(inherited) "$(SRCROOT)/Flutter" "$(SRCROOT)/Flutter/Flutter.framework/Headers" "$(SRCROOT)/Runner/Flutter" "${PODS_ROOT}/Flutter/Flutter.framework/Headers" "${PODS_ROOT}/../Flutter/Flutter.framework/Headers"
FRAMEWORK_SEARCH_PATHS = $(inherited) "$(SRCROOT)/Flutter" "${PODS_ROOT}/Flutter" "${PODS_ROOT}/../Flutter"
EOL

echo "6. Updating project.pbxproj to include the search paths..."
PROJECT_FILE=~/Desktop/projects/RealState/rsapp/ios/Runner.xcodeproj/project.pbxproj
if [ -f "$PROJECT_FILE" ]; then
  cp "$PROJECT_FILE" "${PROJECT_FILE}.backup"
  sed -i '' 's/HEADER_SEARCH_PATHS = (/HEADER_SEARCH_PATHS = (\n\t\t\t\t\t"$(SRCROOT)\/Flutter\/Flutter.framework\/Headers",\n\t\t\t\t\t"$(SRCROOT)\/Runner\/Flutter",/g' "$PROJECT_FILE"
fi

echo "7. Cleaning build folders..."
rm -rf ~/Desktop/projects/RealState/rsapp/build/ios
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo ""
echo "=== Fix completed! ==="
echo "Now try running: cd ~/Desktop/projects/RealState/rsapp && flutter run -d \"iPhone 16 Plus\""