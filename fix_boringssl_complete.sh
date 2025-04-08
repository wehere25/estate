#!/bin/bash

echo "=== COMPREHENSIVE BORINGSSL iOS SIMULATOR FIX ==="
echo "This script will completely fix the -G flag issue for iOS simulators"

# Project directories
PROJECT_DIR=$(pwd)
IOS_DIR="${PROJECT_DIR}/ios"
PODS_DIR="${IOS_DIR}/Pods"

echo "1. Performing a deep clean..."
# Clean Flutter
flutter clean
# Remove all build artifacts
rm -rf build/
rm -rf "${IOS_DIR}/build/"
rm -rf "${IOS_DIR}/.symlinks"
rm -rf "${IOS_DIR}/Flutter/Flutter.framework"
rm -rf "${IOS_DIR}/Flutter/Flutter.podspec"
# Clean derived data (this is where Xcode keeps build products)
rm -rf ~/Library/Developer/Xcode/DerivedData/Runner-*

echo "2. Removing all pods..."
rm -rf "${PODS_DIR}"
rm -f "${IOS_DIR}/Podfile.lock"

echo "3. Getting fresh Flutter dependencies..."
flutter pub get

echo "4. Directly patching any remaining xcconfig files..."
find "${IOS_DIR}" -name "*.xcconfig" -type f -exec sed -i '' 's/-G//g' {} \;

echo "5. Creating a simulator settings file with explicit flags..."
cat > "${IOS_DIR}/simulator_settings.xcconfig" << 'EOL'
// Simulator specific settings to avoid the -G flag issue
EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_simulator__NATIVE_ARCH_64_BIT_x86_64=arm64 arm64e
EXCLUDED_ARCHS=$(inherited) $(EXCLUDED_ARCHS__EFFECTIVE_PLATFORM_SUFFIX_$(EFFECTIVE_PLATFORM_SUFFIX)__NATIVE_ARCH_64_BIT_$(NATIVE_ARCH_64_BIT))
OTHER_CFLAGS=-DOPENSSL_NO_ASM
EOL

echo "6. Creating a script to modify xcconfig files..."
cat > "${IOS_DIR}/edit_xcconfig.sh" << 'EOL'
#!/bin/bash

# This script modifies the generated xcconfig files to include our simulator settings

# Find all xcconfig files in the Flutter directory
for config_file in ./Flutter/*.xcconfig; do
  if [ -f "$config_file" ]; then
    echo "Adding simulator settings to $config_file"
    if ! grep -q "#include \"simulator_settings.xcconfig\"" "$config_file"; then
      echo '' >> "$config_file"
      echo '#include "simulator_settings.xcconfig"' >> "$config_file"
    fi
  fi
done
EOL

# Make the script executable
chmod +x "${IOS_DIR}/edit_xcconfig.sh"

echo "7. Running the xcconfig editing script..."
cd "${IOS_DIR}" && ./edit_xcconfig.sh

echo "8. Patching BoringSSL-GRPC podspec files..."
find ~/.cocoapods/repos -name "BoringSSL-GRPC.podspec" -type f -exec sed -i '' 's/-G//g' {} \;

echo "9. Running pod install with explicit cleanup..."
cd "${IOS_DIR}" && pod install --repo-update --clean-install

echo "10. Running precautionary build cleanup..."
cd "${PROJECT_DIR}" && flutter clean

echo "11. Patching after pod install (important)..."
# This is crucial - we need to patch the files that get generated during pod install
if [ -d "${PODS_DIR}" ]; then
  echo "Patching Pods directory files..."
  
  # First, remove any -G flags from xcconfig files in Pods
  find "${PODS_DIR}" -name "*.xcconfig" -type f -exec sed -i '' 's/-G//g' {} \;
  
  # Then patch the project.pbxproj file which may contain -G flags
  PBXPROJ_FILE="${PODS_DIR}/Pods.xcodeproj/project.pbxproj"
  if [ -f "${PBXPROJ_FILE}" ]; then
    echo "Patching Pods project.pbxproj..."
    sed -i '' 's/ -G / /g' "${PBXPROJ_FILE}"
    sed -i '' 's/ -G"/" /g' "${PBXPROJ_FILE}"
    sed -i '' 's/"-G / /g' "${PBXPROJ_FILE}"
    sed -i '' 's/"-G"/"/g' "${PBXPROJ_FILE}"
  fi
  
  # Patch any direct BoringSSL source files that might include -G
  BORINGSSL_DIR="${PODS_DIR}/BoringSSL-GRPC"
  if [ -d "${BORINGSSL_DIR}" ]; then
    echo "Patching BoringSSL-GRPC files..."
    find "${BORINGSSL_DIR}" -name "*.podspec" -type f -exec sed -i '' 's/-G//g' {} \;
    find "${BORINGSSL_DIR}" -name "*.cmake" -type f -exec sed -i '' 's/-G//g' {} \;
    find "${BORINGSSL_DIR}" -name "CMakeLists.txt" -type f -exec sed -i '' 's/-G//g' {} \;
  fi
fi

echo ""
echo "=== Setup Complete! ==="
echo "Now try running your app with:"
echo "cd ${PROJECT_DIR} && flutter run -d \"iPhone 16 Plus\""