#!/bin/bash

echo "=== SIMPLIFIED BORINGSSL iOS SIMULATOR FIX ==="
echo "This script will fix the -G flag issue with a direct approach"

# Project paths
PROJECT_DIR=$(pwd)
IOS_DIR="${PROJECT_DIR}/ios"
PODS_DIR="${IOS_DIR}/Pods"

# Step 1: Clean critical files
echo "1. Cleaning critical build files..."
rm -rf "${IOS_DIR}/build"
rm -rf "${IOS_DIR}/.symlinks"
rm -rf "${IOS_DIR}/Pods/BoringSSL-GRPC"
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*/Build/Products

# Step 2: Get Flutter dependencies
echo "2. Getting Flutter dependencies..."
flutter pub get

# Step 3: Backup original Podfile
echo "3. Backing up original Podfile..."
if [ -f "${IOS_DIR}/Podfile" ]; then
  cp "${IOS_DIR}/Podfile" "${IOS_DIR}/Podfile.backup"
fi

# Step 4: Run pod install first to generate files
echo "4. Running initial pod installation..."
cd "${IOS_DIR}" && pod install

# Step 5: Create a patch script that will check all installed pods for -G flags
echo "5. Creating patch script to directly modify all files with -G flags..."
cat > "${IOS_DIR}/patch_g_flags.rb" << 'EOL'
#!/usr/bin/env ruby

# Paths to search for files
pod_dir = File.expand_path('../Pods', __FILE__)
build_dir = File.expand_path('../build', __FILE__)

# List of file extensions to check for text-based files
text_extensions = %w[.c .cpp .cc .cxx .h .hpp .m .mm .swift .podspec .pbxproj .xcconfig .cmake]

# Count of fixed files
files_fixed = 0

def fix_file(file_path)
  if !File.file?(file_path) || File.binary?(file_path)
    return false
  end
  
  original_content = File.read(file_path)
  # Only modify if it contains the -G flag
  if original_content.include?('-G')
    # Apply multiple replacements to catch different -G flag variations
    modified_content = original_content.gsub(/ -G /, ' ')
                                     .gsub(/ -G,/, ',')
                                     .gsub(/,-G /, ',')
                                     .gsub(/,-G,/, ',')
                                     .gsub(/"-G"/, '""')
                                     .gsub(/ -G$/, '')
                                     .gsub(/^-G /, '')
    
    # Only write if we actually made changes
    if modified_content != original_content
      File.write(file_path, modified_content)
      puts "Fixed -G flag in #{file_path}"
      return true
    end
  end
  false
end

# Special handler for BoringSSL-GRPC xcconfig files
Dir.glob("#{pod_dir}/Target Support Files/BoringSSL-GRPC/*.xcconfig").each do |config_file|
  contents = File.read(config_file)
  
  # Remove any -G flags in the OTHER_CFLAGS
  if contents.include?('OTHER_CFLAGS')
    new_contents = contents.gsub(/OTHER_CFLAGS = (.*)-G(.*)/, 'OTHER_CFLAGS = \1\2')
                         .gsub(/OTHER_CFLAGS = (.*) -G /, 'OTHER_CFLAGS = \1 ')
                         .gsub(/OTHER_CFLAGS = (.*) -G$/, 'OTHER_CFLAGS = \1')
    if new_contents != contents
      File.write(config_file, new_contents)
      puts "Fixed -G flag in #{config_file}"
      files_fixed += 1
    end
  end
  
  # Also apply for OTHER_CPLUSPLUSFLAGS
  if contents.include?('OTHER_CPLUSPLUSFLAGS')
    new_contents = contents.gsub(/OTHER_CPLUSPLUSFLAGS = (.*)-G(.*)/, 'OTHER_CPLUSPLUSFLAGS = \1\2')
                         .gsub(/OTHER_CPLUSPLUSFLAGS = (.*) -G /, 'OTHER_CPLUSPLUSFLAGS = \1 ')
                         .gsub(/OTHER_CPLUSPLUSFLAGS = (.*) -G$/, 'OTHER_CPLUSPLUSFLAGS = \1')
    if new_contents != contents
      File.write(config_file, new_contents)
      puts "Fixed -G flag in #{config_file}"
      files_fixed += 1
    end
  end
  
  # Add safe compiler flags
  if !contents.include?('-DOPENSSL_NO_ASM')
    new_contents = contents + "\nOTHER_CFLAGS = $(inherited) -DOPENSSL_NO_ASM\n"
    File.write(config_file, new_contents)
    puts "Added safe compiler flags to #{config_file}"
    files_fixed += 1
  end
end

# Process the main project.pbxproj file 
pbxproj_path = "#{pod_dir}/Pods.xcodeproj/project.pbxproj"
if File.exist?(pbxproj_path)
  if fix_file(pbxproj_path)
    files_fixed += 1
  end
end

# Search all other files in pods directory for -G flags
Dir.glob("#{pod_dir}/**/*").each do |file_path|
  next unless File.file?(file_path) 
  next if File.binary?(file_path)
  next unless text_extensions.any? { |ext| file_path.end_with?(ext) }
  
  if fix_file(file_path)
    files_fixed += 1
  end
end

puts "Total files fixed: #{files_fixed}"
EOL

# Make the patch script executable
chmod +x "${IOS_DIR}/patch_g_flags.rb"

# Step 6: Run the patch script
echo "6. Running patch script to fix all -G flags..."
cd "${IOS_DIR}" && ruby patch_g_flags.rb

# Step 7: Create a safe simulator configuration file
echo "7. Creating special simulator configuration file..."
cat > "${IOS_DIR}/BoringSSLSimulator.xcconfig" << 'EOL'
// Special settings for BoringSSL on iOS simulator
OTHER_CFLAGS = -DOPENSSL_NO_ASM
OTHER_CPLUSPLUSFLAGS = -DOPENSSL_NO_ASM
GCC_PREPROCESSOR_DEFINITIONS = $(inherited) COCOAPODS=1 OPENSSL_NO_ASM=1

// Architecture settings for simulator
EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64 = arm64 arm64e
EXCLUDED_ARCHS = $(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))
EOL

# Step 8: Add our simulator config to BoringSSL config files
echo "8. Patching BoringSSL config files..."
BORINGSSL_XCCONFIG_DIR="${PODS_DIR}/Target Support Files/BoringSSL-GRPC"
if [ -d "${BORINGSSL_XCCONFIG_DIR}" ]; then
  for config_file in "${BORINGSSL_XCCONFIG_DIR}"/*.xcconfig; do
    echo "" >> "$config_file"
    echo '#include "../../BoringSSLSimulator.xcconfig"' >> "$config_file"
    echo "Patched $config_file"
  done
fi

# Step 9: Run pod install again to apply changes
echo "9. Running final pod install..."
cd "${IOS_DIR}" && pod install

echo ""
echo "=== Setup Complete! ==="
echo "Now try running your app with:"
echo "cd ${PROJECT_DIR} && flutter run -d \"iPhone 16 Plus\""