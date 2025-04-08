#!/bin/bash

echo "=== LEVELDB INCLUDE PATH FIX ==="
echo "This script will fix the leveldb include path issue"

# Project directories
PROJECT_DIR=$(pwd)
IOS_DIR="${PROJECT_DIR}/ios"
PODS_DIR="${IOS_DIR}/Pods"
LEVELDB_DIR="${PODS_DIR}/leveldb-library"

# Step 1: Check if leveldb directory exists
if [ ! -d "${LEVELDB_DIR}" ]; then
  echo "Error: LevelDB directory not found at ${LEVELDB_DIR}"
  exit 1
fi

echo "1. Patching LevelDB include paths..."
find "${LEVELDB_DIR}" -name "*.cc" -o -name "*.h" -o -name "*.c" | while read file; do
  # Replace relative includes with full path includes
  sed -i '' 's|#include "db/|#include "leveldb-library/db/|g' "$file"
  sed -i '' 's|#include "table/|#include "leveldb-library/table/|g' "$file"
  sed -i '' 's|#include "util/|#include "leveldb-library/util/|g' "$file"
  sed -i '' 's|#include "port/|#include "leveldb-library/port/|g' "$file"
  
  echo "  Fixed includes in: $(basename "$file")"
done

# Step 2: Create additional fix for version_edit.cc specifically
VERSION_EDIT_CC="${LEVELDB_DIR}/db/version_edit.cc"
if [ -f "${VERSION_EDIT_CC}" ]; then
  echo "2. Specific fix for version_edit.cc..."
  
  # Create header search paths configuration
  cat > "${IOS_DIR}/leveldb_paths.xcconfig" << 'EOL'
// Special LevelDB Header Search Paths
HEADER_SEARCH_PATHS = $(inherited) "${PODS_ROOT}/leveldb-library/" "${PODS_ROOT}/leveldb-library/include/"
EOL
  
  # Update Podfile to include our fix
  echo "3. Updating Podfile to include LevelDB fix..."
  PODFILE="${IOS_DIR}/Podfile"
  
  # Make a backup of Podfile
  cp "${PODFILE}" "${PODFILE}.bak"
  
  # Add LevelDB specific configuration to the post_install section
  sed -i '' '/target.name == '"'BoringSSL-GRPC'"'/a\\
      # Special handling for leveldb-library\
      elsif target.name == '"'leveldb-library'"'\
        puts "Applying leveldb-library fixes in #{config.name} configuration"\
        \
        # Add header search paths\
        config.build_settings['"'HEADER_SEARCH_PATHS'"'] = ['"'$(inherited)'"', '"'${PODS_ROOT}/leveldb-library/'"', '"'${PODS_ROOT}/leveldb-library/include/'"']\
        \
        # Disable some warnings for leveldb\
        config.build_settings['"'GCC_WARN_INHIBIT_ALL_WARNINGS'"'] = '"'YES'"'
  ' "${PODFILE}"
fi

# Step 3: Run pod install to apply the changes
echo "4. Running pod install to apply changes..."
cd "${IOS_DIR}" && pod install

echo ""
echo "=== Setup Complete! ==="
echo "Now try running your app with:"
echo "cd ${PROJECT_DIR} && flutter run -d \"iPhone 16 Plus\""