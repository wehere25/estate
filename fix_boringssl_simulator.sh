#!/bin/bash

# This script specifically targets the BoringSSL-GRPC -G flag issue on iOS simulators
PROJECT_DIR=$(pwd)
IOS_DIR="${PROJECT_DIR}/ios"

echo "=== BoringSSL iOS Simulator Fix ==="
echo "Fixing the -G flag issue for iOS 18.4 simulator builds"

# 1. Clean the project
echo "Cleaning project..."
flutter clean

# 2. Get dependencies
echo "Getting dependencies..."
flutter pub get

# 3. Remove Pods directory
echo "Removing Pods directory..."
cd "${IOS_DIR}" && rm -rf Pods Podfile.lock

# 4. Create a patch file for the BoringSSL-GRPC podspec
echo "Creating patch for BoringSSL-GRPC podspec..."
mkdir -p "${PROJECT_DIR}/ios_patches"

cat > "${PROJECT_DIR}/ios_patches/boringssl_patch.rb" << 'EOL'
#!/usr/bin/env ruby

# This script patches the BoringSSL-GRPC podspec file to remove problematic flags

require 'fileutils'

# Find BoringSSL-GRPC podspec file in ~/.cocoapods/repos
def find_podspec_file
  cocoapods_dir = File.expand_path('~/.cocoapods/repos')
  podspec_path = nil
  
  # Search for the BoringSSL-GRPC podspec file
  Dir.glob("#{cocoapods_dir}/**/BoringSSL-GRPC.podspec").each do |file|
    podspec_path = file
    break
  end
  
  # If we can't find it in the repos, look in the local Pods directory
  if podspec_path.nil?
    ios_dir = ENV['IOS_DIR'] || File.expand_path('../ios', __dir__)
    Dir.glob("#{ios_dir}/Pods/BoringSSL-GRPC/BoringSSL-GRPC.podspec").each do |file|
      podspec_path = file
      break
    end
  end
  
  podspec_path
end

# Patch the podspec file
def patch_podspec(file_path)
  return false unless file_path && File.exist?(file_path)
  
  # Read the podspec file
  content = File.read(file_path)
  
  # Make a backup
  FileUtils.cp(file_path, "#{file_path}.bak")
  
  # Remove -G flags from compiler flags
  modified_content = content.gsub(/'-G', /, '')
  modified_content = modified_content.gsub(/, '-G'/, '')
  modified_content = modified_content.gsub(/'-G'/, '')
  
  # Write the modified content back to the file
  File.write(file_path, modified_content)
  
  # Check if we made changes
  content != modified_content
end

# Patch BoringSSL-GRPC podspec
podspec_file = find_podspec_file
if podspec_file
  puts "Found BoringSSL-GRPC podspec at: #{podspec_file}"
  if patch_podspec(podspec_file)
    puts "Successfully patched BoringSSL-GRPC podspec"
  else
    puts "No changes needed or could not patch BoringSSL-GRPC podspec"
  end
else
  puts "Could not find BoringSSL-GRPC podspec file"
end

# Also patch Pods directory directly if it exists
ios_dir = ENV['IOS_DIR'] || File.expand_path('../ios', __dir__)
local_podspec = "#{ios_dir}/Pods/BoringSSL-GRPC/BoringSSL-GRPC.podspec"
if File.exist?(local_podspec)
  puts "Found local BoringSSL-GRPC podspec at: #{local_podspec}"
  if patch_podspec(local_podspec)
    puts "Successfully patched local BoringSSL-GRPC podspec"
  else
    puts "No changes needed or could not patch local BoringSSL-GRPC podspec"
  end
end
EOL

echo "Running the BoringSSL podspec patch..."
export IOS_DIR="${IOS_DIR}"
ruby "${PROJECT_DIR}/ios_patches/boringssl_patch.rb"

# 5. Update the Podfile to properly handle BoringSSL-GRPC
echo "Updating Podfile to handle BoringSSL-GRPC..."
cat > "${IOS_DIR}/Podfile" << 'EOF'
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
  target 'RunnerTests' do
    inherit! :search_paths
  end
  
  # Force BoringSSL-GRPC to use specific compiler flags without -G
  pod 'BoringSSL-GRPC', :modular_headers => true
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    flutter_additional_ios_build_settings(target)
    
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '14.0'
      
      # Special handling for BoringSSL-GRPC which often contains the problematic -G flag
      if target.name == 'BoringSSL-GRPC'
        puts "Fixing BoringSSL-GRPC compiler flags..."
        
        # Replace any compiler flags containing -G with safer versions
        safe_cflags = '-DOPENSSL_NO_ASM -fno-objc-arc -w'
        if config.build_settings['OTHER_CFLAGS']
          config.build_settings['OTHER_CFLAGS'] = safe_cflags
        end
        
        if config.build_settings['OTHER_CPLUSPLUSFLAGS']
          config.build_settings['OTHER_CPLUSPLUSFLAGS'] = safe_cflags
        end
        
        # Add 'GRPC' prefix safely
        if !config.build_settings['GCC_PREPROCESSOR_DEFINITIONS']
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] = ['$(inherited)', 'COCOAPODS=1', 'OPENSSL_NO_ASM=1', 'BORINGSSL_PREFIX=GRPC']
        elsif !config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'].include?('BORINGSSL_PREFIX=GRPC')
          config.build_settings['GCC_PREPROCESSOR_DEFINITIONS'] << 'BORINGSSL_PREFIX=GRPC'
        end
        
        # Add other settings to help with the build
        config.build_settings['CLANG_WARN_DOCUMENTATION_COMMENTS'] = 'NO'
        config.build_settings['GCC_WARN_INHIBIT_ALL_WARNINGS'] = 'YES'
      end
      
      # For all targets, clean up any -G flags
      ['OTHER_CFLAGS', 'OTHER_LDFLAGS', 'OTHER_SWIFT_FLAGS', 'OTHER_CPLUSPLUSFLAGS'].each do |flag_key|
        if config.build_settings[flag_key].is_a?(String) && config.build_settings[flag_key].include?('-G')
          config.build_settings[flag_key] = config.build_settings[flag_key].gsub(/-G\b/, '')
        elsif config.build_settings[flag_key].is_a?(Array)
          config.build_settings[flag_key] = config.build_settings[flag_key].reject { |flag| flag == '-G' }
        end
      end
      
      # iOS 18.4 compatibility settings
      config.build_settings['SWIFT_VERSION'] = '5.0'
      config.build_settings['ENABLE_USER_SCRIPT_SANDBOXING'] = 'NO'
      config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'YES'
    end
  end
  
  # Directly edit the Pods project file to remove any -G flags
  project_path = installer.pods_project.path
  project_pbxproj = File.join(project_path, 'project.pbxproj')
  if File.exist?(project_pbxproj)
    puts "Checking project.pbxproj for -G flags..."
    content = File.read(project_pbxproj)
    modified_content = content.gsub(/(\s|\")(-G)(\s|\")/, '\1\3')
    if content != modified_content
      puts "Fixing -G flags in project.pbxproj..."
      File.write(project_pbxproj, modified_content)
    end
  end
  
  # Remove -G flags from all xcconfig files
  Dir.glob(File.join(installer.sandbox.root, "**/*.xcconfig")).each do |xcconfig_file|
    content = File.read(xcconfig_file)
    modified_content = content.gsub(/\s-G\b/, '')
    if content != modified_content
      puts "Fixing -G flags in #{xcconfig_file}"
      File.write(xcconfig_file, modified_content)
    end
  end
end
EOF

# 6. Install pods with our new configuration
echo "Installing pods with fixed configuration..."
cd "${IOS_DIR}"
pod install

echo ""
echo "=== Setup Complete! ==="
echo "Now try running your app with:"
echo "cd ${PROJECT_DIR} && flutter run -d \"iPhone 16 Plus\""