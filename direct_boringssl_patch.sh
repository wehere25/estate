#!/bin/bash

echo "=== DIRECT BORINGSSL iOS SIMULATOR FIX ==="
echo "This script will directly patch BoringSSL files to solve the -G flag issue"

# Project paths
PROJECT_DIR=$(pwd)
IOS_DIR="${PROJECT_DIR}/ios"
PODS_DIR="${IOS_DIR}/Pods"
BORINGSSL_DIR="${PODS_DIR}/BoringSSL-GRPC"

# Phase 1: Clean important parts without full clean
echo "1. Cleaning specific build artifacts..."
rm -rf "${IOS_DIR}/build"
rm -rf "${IOS_DIR}/.symlinks"
rm -rf "${IOS_DIR}/Pods/BoringSSL-GRPC"
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products

# Phase 2: Update project settings
echo "2. Creating simulator-specific xcconfig with explicit architectures..."
cat > "${IOS_DIR}/boringssl_fix.xcconfig" << 'EOL'
// Special settings for BoringSSL simulator builds
EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64=arm64 arm64e
EXCLUDED_ARCHS=$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))

// Remove all instances of -G flag for simulator builds
OTHER_CFLAGS=-DOPENSSL_NO_ASM
OTHER_CPLUSPLUSFLAGS=-DOPENSSL_NO_ASM
GCC_PREPROCESSOR_DEFINITIONS=COCOAPODS=1 OPENSSL_NO_ASM=1 BORINGSSL_PREFIX=GRPC POD_CONFIGURATION_$(CONFIGURATION:upper)=1
EOL

# Phase 3: Modify Podfile to have explicit BoringSSL handling
echo "3. Creating a more targeted Podfile..."
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

  flutter_install_all_ios_pods File.dirname(File.realpath(__FILE__))
  
  # Explicitly handle BoringSSL to prevent -G flag issues
  pod 'BoringSSL-GRPC', :modular_headers => true
  
  target 'RunnerTests' do
    inherit! :search_paths
  end
end

post_install do |installer|
  # Add special config file to fix BoringSSL simulator issues
  puts "Adding BoringSSL fix to xcconfig files..."
  config_file_path = File.expand_path('boringssl_fix.xcconfig')
  
  Dir.glob("#{installer.sandbox.root}/Target Support Files/BoringSSL-GRPC/*.xcconfig").each do |config_file|
    unless File.read(config_file).include?('#include "boringssl_fix.xcconfig"')
      File.open(config_file, 'a') do |file|
        file.puts ""
        file.puts '#include "../../../../../../boringssl_fix.xcconfig"'
      end
    end
  end
  
  # First do Flutter's standard pod settings
  flutter_additional_ios_build_settings(installer)
  
  # Then apply custom fixes
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      # Ensure iOS 14.0 deployment target for all pods
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
      # For simulator builds, ensure correct architectures
      config.build_settings['ONLY_ACTIVE_ARCH'] = 'NO'
      
      # Special handling for BoringSSL-GRPC
      if target.name == 'BoringSSL-GRPC'
        puts "Applying special fixes to BoringSSL-GRPC target in #{config.name} configuration"
        
        # Replace any compiler flags containing -G with safer versions
        safe_cflags = '-DOPENSSL_NO_ASM -fno-objc-arc'
        config.build_settings['OTHER_CFLAGS'] = safe_cflags
        config.build_settings['OTHER_CPLUSPLUSFLAGS'] = safe_cflags
        
        # Prevent -G from being added through definitions
        config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'COCOAPODS=1', 'OPENSSL_NO_ASM=1', 'BORINGSSL_PREFIX=GRPC']
        
        # Add other settings to help with the build
        config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      end
      
      # For all targets, remove any -G flags
      ['OTHER_CFLAGS', 'OTHER_LDFLAGS', 'OTHER_SWIFT_FLAGS', 'OTHER_CPLUSPLUSFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].is_a?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag == '-G' }
        elsif config.build_settings[flag_key].is_a?(String) && config.build_settings[flag_key].include?('-G')
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\b/, '')
        end
      end
      
      # iOS compatibility settings
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'YES'
    end
  end
  
  # Direct fix for Xcode project files
  puts "Directly patching Xcode project files to remove -G flags..."
  
  # Directly patch project.pbxproj
  project_path = installer.pods_project.path
  project_pbxproj = File.join(project_path, 'project.pbxproj')
  if File.exist?(project_pbxproj)
    content = File.read(project_pbxproj)
    modified_content = content.gsub(/(\s|\")(-G)(\s|\")/, '\1\3')
    modified_content = modified_content.gsub(/"\-G"/, '""')
    
    if content != modified_content
      puts "Fixed -G flags in #{project_pbxproj}"
      File.write(project_pbxproj, modified_content)
    end
  end
  
  # Also directly patch any C/C++ source files with -G flags
  boringssl_dir = File.join(installer.sandbox.root, "BoringSSL-GRPC")
  if Dir.exist?(boringssl_dir)
    Dir.glob("#{boringssl_dir}/**/*.{c,cc,cpp,h,m,mm}").each do |file|
      begin
        content = File.read(file)
        if content.include?('-G')
          modified = content.gsub(/-G\b/, '')
          if content != modified
            puts "Fixed -G flag in #{File.basename(file)}"
            File.write(file, modified)
          end
        end
      rescue => e
        puts "Error processing file #{file}: #{e.message}"
      end
    end
  end
end
EOL

# Phase 4: Update Flutter configuration 
echo "4. Getting fresh Flutter dependencies..."
flutter pub get

# Phase 5: Install Pods with the new configuration
echo "5. Running pod install with explicit cleanup..."
cd "${IOS_DIR}" && pod install --repo-update

# Phase 6: Direct post-install patching (this is crucial)
echo "6. Direct post-install patching of generated files..."
if [ -d "${PODS_DIR}" ]; then
  echo "Patching Pods directory files..."
  
  # Remove -G flags from xcconfig files 
  find "${PODS_DIR}" -name "*.xcconfig" -type f -exec sed -i '' -E 's/-G[[:space:]]/ /g' {} \;
  find "${PODS_DIR}" -name "*.xcconfig" -type f -exec sed -i '' -E 's/[[:space:]]-G/ /g' {} \;
  find "${PODS_DIR}" -name "*.xcconfig" -type f -exec sed -i '' -E 's/-G$//g' {} \;
  
  # Fix references in BoringSSL specific files
  if [ -d "${BORINGSSL_DIR}" ]; then
    echo "Patching BoringSSL-GRPC files directly..."
    
    # Patch the podspec
    find "${BORINGSSL_DIR}" -name "*.podspec" -type f -exec sed -i '' 's/-G//g' {} \;
    
    # Patch CMake files
    find "${BORINGSSL_DIR}" -name "CMakeLists.txt" -type f -exec sed -i '' 's/-G//g' {} \;
    find "${BORINGSSL_DIR}" -name "*.cmake" -type f -exec sed -i '' 's/-G//g' {} \;
    
    # Check config files
    find "${BORINGSSL_DIR}" -name "config*.h" -type f -exec sed -i '' 's/-G//g' {} \;
    
    # Direct patch of the arch.h file which often contains the -G flag
    ARCH_H_FILES=$(find "${BORINGSSL_DIR}" -name "arch.h")
    for file in $ARCH_H_FILES; do
      echo "Checking $file for -G flags..."
      if grep -q -- "-G" "$file"; then
        echo "Patching $file to remove -G flag..."
        sed -i '' 's/-G//g' "$file"
      fi
    done
  fi
  
  # Patch xcconfig references in Pods project
  PODS_XCCONFIG_DIR="${PODS_DIR}/Target Support Files"
  if [ -d "${PODS_XCCONFIG_DIR}" ]; then
    echo "Ensuring boringssl_fix.xcconfig is included in all relevant files..."
    find "${PODS_XCCONFIG_DIR}" -name "BoringSSL-GRPC*.xcconfig" -type f | while read xcconfig; do
      if ! grep -q "boringssl_fix.xcconfig" "$xcconfig"; then
        echo "Adding boringssl_fix inclusion to $(basename "$xcconfig")..."
        echo "" >> "$xcconfig"
        echo '#include "../../../../../../boringssl_fix.xcconfig"' >> "$xcconfig"
      fi
    done
  fi
  
  # Patch the main project.pbxproj
  PBXPROJ_FILE="${PODS_DIR}/Pods.xcodeproj/project.pbxproj"
  if [ -f "${PBXPROJ_FILE}" ]; then
    echo "Final patch of project.pbxproj..."
    sed -i '' 's/\"-G\"/\"\"/g' "${PBXPROJ_FILE}"
    sed -i '' 's/ -G / /g' "${PBXPROJ_FILE}"
    sed -i '' 's/,-G,/,/g' "${PBXPROJ_FILE}"
  fi
fi

echo ""
echo "=== Setup Complete! ==="
echo "Now try running your app with:"
echo "cd ${PROJECT_DIR} && flutter run -d \"iPhone 16 Plus\""