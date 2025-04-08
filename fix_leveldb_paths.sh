#!/bin/bash

echo "=== LEVELDB INCLUDE PATH FIX ==="
echo "This script will fix the leveldb include path issue"

# Find the LevelDB source directory
LEVELDB_DIR="/Users/hashi/Desktop/projects/RealState/rsapp/ios/Pods/leveldb-library"

if [ ! -d "$LEVELDB_DIR" ]; then
  echo "Error: LevelDB directory not found at $LEVELDB_DIR"
  exit 1
fi

echo "1. Fixing include paths in LevelDB C++ files..."

# Create a new directory for modified include paths
mkdir -p "$LEVELDB_DIR/include/leveldb-library/db"
mkdir -p "$LEVELDB_DIR/include/leveldb-library/table"
mkdir -p "$LEVELDB_DIR/include/leveldb-library/util"
mkdir -p "$LEVELDB_DIR/include/leveldb-library/port"

# Copy header files to new locations
cp "$LEVELDB_DIR/db/"*.h "$LEVELDB_DIR/include/leveldb-library/db/"
cp "$LEVELDB_DIR/table/"*.h "$LEVELDB_DIR/include/leveldb-library/table/"
cp "$LEVELDB_DIR/util/"*.h "$LEVELDB_DIR/include/leveldb-library/util/"
cp "$LEVELDB_DIR/port/"*.h "$LEVELDB_DIR/include/leveldb-library/port/"

# Fix the version_edit.cc file
VERSION_EDIT_CC="$LEVELDB_DIR/db/version_edit.cc"
if [ -f "$VERSION_EDIT_CC" ]; then
  echo "2. Modifying the problematic version_edit.cc file..."
  cp "$VERSION_EDIT_CC" "${VERSION_EDIT_CC}.backup"
  
  # Change the includes to use the full path
  sed -i '' 's|#include "db/version_edit.h"|#include "leveldb-library/db/version_edit.h"|g' "$VERSION_EDIT_CC"
  sed -i '' 's|#include "db/version_set.h"|#include "leveldb-library/db/version_set.h"|g' "$VERSION_EDIT_CC"
  sed -i '' 's|#include "util/coding.h"|#include "leveldb-library/util/coding.h"|g' "$VERSION_EDIT_CC"
fi

# Fix other files with similar include patterns
echo "3. Fixing includes in other LevelDB files..."
find "$LEVELDB_DIR" -name "*.cc" -o -name "*.h" -o -name "*.c" | while read -r file; do
  if [ -f "$file" ]; then
    sed -i '' 's|#include "db/|#include "leveldb-library/db/|g' "$file"
    sed -i '' 's|#include "table/|#include "leveldb-library/table/|g' "$file"
    sed -i '' 's|#include "util/|#include "leveldb-library/util/|g' "$file"
    sed -i '' 's|#include "port/|#include "leveldb-library/port/|g' "$file"
  fi
done

# Update the Xcode project HEADER_SEARCH_PATHS
echo "4. Creating xcconfig file for LevelDB header paths..."
LEVELDB_XCCONFIG="/Users/hashi/Desktop/projects/RealState/rsapp/ios/leveldb_paths.xcconfig"
cat > "$LEVELDB_XCCONFIG" << EOL
// LevelDB Header search paths
HEADER_SEARCH_PATHS = \$(inherited) "\$(PODS_ROOT)/leveldb-library/include" "\$(PODS_ROOT)/leveldb-library"
EOL

# Apply the fix in the Podfile
echo "5. Updating Podfile to include our LevelDB fix..."
PODFILE="/Users/hashi/Desktop/projects/RealState/rsapp/ios/Podfile"
if [ -f "$PODFILE" ]; then
  cp "$PODFILE" "${PODFILE}.bak.leveldb"
  
  # Add leveldb-library specific configuration
  cat > "$PODFILE.new" << EOL
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
  
  # Special configuration for leveldb-library
  pod 'leveldb-library', :modular_headers => true

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
      
      # Special handling for leveldb-library
      elsif target.name == 'leveldb-library'
        puts "Applying leveldb-library fixes in #{config.name} configuration"
        
        # Add header search paths
        config.build_settings['HEADER_SEARCH_PATHS'] = ['$(inherited)', '${PODS_ROOT}/leveldb-library', '${PODS_ROOT}/leveldb-library/include']
        
        # Disable some warnings for leveldb
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
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
end
EOL
  
  # Replace the old Podfile with the new one
  mv "$PODFILE.new" "$PODFILE"
fi

echo "6. Running pod install with clean cache..."
cd "$(dirname "$PODFILE")" && pod cache clean --all && pod install

echo ""
echo "=== Fix completed! ==="
echo "Now try running: cd /Users/hashi/Desktop/projects/RealState/rsapp && flutter run -d \"iPhone 16 Plus\""