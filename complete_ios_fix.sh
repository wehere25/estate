#!/bin/bash

echo "=== COMPLETE iOS SIMULATOR FIX ==="
echo "This script will fix both BoringSSL -G flag and Flutter header issues"

# Project directories
PROJECT_DIR=$(pwd)
IOS_DIR="${PROJECT_DIR}/ios"
PUB_CACHE="${HOME}/.pub-cache"
SQFLITE_DIR="${PUB_CACHE}/hosted/pub.dev/sqflite_darwin-2.4.2"

# Step 1: Complete cleanup
echo "1. Performing complete cleanup..."
flutter clean
rm -rf build/
rm -rf ios/.symlinks
rm -rf ios/Flutter/Flutter.framework
rm -rf ios/Flutter/Flutter.podspec
rm -rf ios/Flutter/flutter_export_environment.sh
rm -rf ios/Flutter/Generated.xcconfig
rm -rf ios/Pods
rm -rf ios/Podfile.lock
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

# Step 2: Repair Flutter SDK if needed
echo "2. Making sure Flutter SDK is ready..."
flutter precache --ios
flutter doctor -v

# Step 3: Get fresh dependencies
echo "3. Getting fresh dependencies..."
flutter pub get

# Step 4: Create a special xcconfig for Flutter framework search paths
echo "4. Creating Flutter framework path fix..."
cat > "${IOS_DIR}/flutter_paths_fix.xcconfig" << 'EOL'
// Special Flutter Framework search paths
FRAMEWORK_SEARCH_PATHS = $(inherited) "${PODS_ROOT}/../Flutter" "${PODS_XCFRAMEWORKS_BUILD_DIR}/Flutter"
HEADER_SEARCH_PATHS = $(inherited) "${PODS_ROOT}/../Flutter" 

// Fix for Flutter.h not found in plugins
OTHER_LDFLAGS = $(inherited) -framework Flutter
EOL

# Step 5: Create a special patch for sqflite header issues
if [ -d "${SQFLITE_DIR}" ]; then
  echo "5. Patching sqflite_darwin headers..."
  SQFLITE_HEADER_FILE="${SQFLITE_DIR}/darwin/sqflite_darwin/Sources/sqflite_darwin/include/sqflite_darwin/SqfliteImportPublic.h"
  if [ -f "$SQFLITE_HEADER_FILE" ]; then
    # Backup original file
    cp "$SQFLITE_HEADER_FILE" "${SQFLITE_HEADER_FILE}.bak"
    
    # Modify the include path from Flutter/Flutter.h to just Flutter.h
    sed -i '' 's|#import <Flutter/Flutter.h>|// Original: #import <Flutter/Flutter.h>\n#import "Flutter.h"|' "$SQFLITE_HEADER_FILE"
    echo "   Modified sqflite header import path"
  else
    echo "   sqflite header file not found at $SQFLITE_HEADER_FILE"
  fi
else
  echo "5. sqflite_darwin package not found, skipping header patch"
fi

# Step 6: Create a simplified Podfile with our fixes
echo "6. Creating improved Podfile..."
cat > "${IOS_DIR}/Podfile" << 'EOL'
platform :ios, '14.0'

# CocoaPods analytics sends network stats synchronously affecting flutter build latency.
ENV['COCOAPODS_DISABLE_STATS'] = 'true'

project 'Runner', {
  'Debug' => :debug,
  'Profile' => :release,
  'Release' => :release,
}

def flutter_root
  generated_xcode_build_settings_path = File.expand_path(File.join('..', 'Flutter', 'Generated.xcconfig'), __FILE__)
  unless File.exist?(generated_xcode_build_settings_path)
    raise "#{generated_xcode_build_settings_path} must exist. If you're running pod install manually, make sure flutter pub get is executed first"
  end

  File.foreach(generated_xcode_build_settings_path) do |line|
    matches = line.match(/FLUTTER_ROOT\=(.*)/)
    return matches[1].strip if matches
  end
  raise "FLUTTER_ROOT not found in #{generated_xcode_build_settings_path}. Try deleting Generated.xcconfig, then run flutter pub get"
end

require File.expand_path(File.join('packages', 'flutter_tools', 'bin', 'podhelper'), flutter_root)

flutter_ios_podfile_setup

target 'Runner' do
  use_frameworks!
  use_modular_headers!

  # Add special options for BoringSSL to fix -G flag issues
  pod 'BoringSSL-GRPC', :modular_headers => true

  # Install all Flutter pods
  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))

  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  # Fix deployment target for each pod
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
      # Special handling for BoringSSL-GRPC (fix -G flag issues)
      if target.name == 'BoringSSL-GRPC'
        puts "Applying BoringSSL-GRPC fixes in #{config.name} configuration"
        
        # Replace compiler flags
        config.build_settings['OTHER_CFLAGS'] = '-DOPENSSL_NO_ASM -fno-objc-arc'
        config.build_settings['OTHER_CPLUSPLUSFLAGS'] = '-DOPENSSL_NO_ASM -fno-objc-arc'
        
        # Set preprocessor definitions
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'COCOAPODS=1', 'OPENSSL_NO_ASM=1', 'BORINGSSL_PREFIX=GRPC']
      end
      
      # Make sure all pods include the Flutter framework search paths
      if config.build_settings['FRAMEWORK_SEARCH_PATHS']
        unless config.build_settings['FRAMEWORK_SEARCH_PATHS'].include?('${PODS_ROOT}/../Flutter')
          config.build_settings['FRAMEWORK_SEARCH_PATHS'] << '${PODS_ROOT}/../Flutter'
        end
      else
        config.build_settings['FRAMEWORK_SEARCH_PATHS'] = ['$(inherited)', '${PODS_ROOT}/../Flutter', '${PODS_XCFRAMEWORKS_BUILD_DIR}/Flutter']
      end
      
      # Add Flutter to header search paths for all pods
      if config.build_settings['HEADER_SEARCH_PATHS']
        unless config.build_settings['HEADER_SEARCH_PATHS'].include?('${PODS_ROOT}/../Flutter')
          config.build_settings['HEADER_SEARCH_PATHS'] << '${PODS_ROOT}/../Flutter'
        end
      else
        config.build_settings['HEADER_SEARCH_PATHS'] = ['$(inherited)', '${PODS_ROOT}/../Flutter']
      end
    end
  end
  
  # Direct patch of project.pbxproj to fix BoringSSL -G flag issues
  project_path = installer.pods_project.path
  project_pbxproj = File.join(project_path, 'project.pbxproj')
  if File.exist?(project_pbxproj)
    content = File.read(project_pbxproj)
    modified_content = content.gsub(/ -G /, ' ')
                             .gsub(/ -G,/, ',')
                             .gsub(/,-G /, ',')
                             .gsub(/,-G,/, ',')
                             .gsub(/"-G"/, '""')
                             .gsub(/ -G$/, '')
                             .gsub(/^-G /, '')
    
    if content != modified_content
      puts "Fixed -G flags in project.pbxproj"
      File.write(project_pbxproj, modified_content)
    end
  end
  
  # Include flutter_paths_fix.xcconfig in all project configurations
  installer.generated_projects.each do |project|
    project.targets.each do |target|
      target.build_configurations.each do |config|
        # Add custom xcconfig to all targets
        xcconfig_path = File.expand_path('flutter_paths_fix.xcconfig')
        config.base_configuration_reference = project.new_file(xcconfig_path)
      end
    end
  end
end
EOL

# Step 7: Make sure Flutter.framework and Flutter.podspec exist
echo "7. Ensuring Flutter framework files exist..."
mkdir -p "${IOS_DIR}/Flutter"
cd "${PROJECT_DIR}" && flutter precache --ios
cd "${PROJECT_DIR}" && flutter pub get

# Step 8: Run pod install with cleaned cache
echo "8. Running pod install with cleaned cache..."
cd "${IOS_DIR}" && pod cache clean --all
cd "${IOS_DIR}" && pod install --repo-update

echo ""
echo "=== Setup Complete! ==="
echo "Now try running your app with:"
echo "cd ${PROJECT_DIR} && flutter run -d \"iPhone 16 Plus\""