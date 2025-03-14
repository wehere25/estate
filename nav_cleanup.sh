#!/bin/bash

# Define base directory
BASE_DIR="/Users/hashi/Desktop/projects/RealState/rsapp"

# Create a temporary directory for backups (just in case)
BACKUP_DIR="$BASE_DIR/nav_backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "📱 RealState Navigation Cleanup Script"
echo "====================================="
echo "This script will help you clean up redundant navigation bar files."
echo "All removed files will be backed up to: $BACKUP_DIR"
echo ""

# Function to move a file to backup and remove the original
backup_and_remove() {
    local file="$1"
    if [ -f "$file" ]; then
        # Create directory structure in backup
        local rel_path="${file#$BASE_DIR/}"
        local backup_path="$BACKUP_DIR/$(dirname "$rel_path")"
        mkdir -p "$backup_path"
        
        # Copy to backup
        cp "$file" "$backup_path/"
        echo "✅ Backed up: $rel_path"
        
        # Remove original
        rm "$file"
        echo "🗑️ Removed: $rel_path"
    else
        echo "⚠️ File not found: $file"
    fi
}

# List of files that are no longer needed
echo "The following navigation-related files are no longer needed:"
echo ""

# These are the files we identified as no longer needed
FILES_TO_REMOVE=(
    # Old navigation implementations that have been replaced by the new app_navigation.dart
    "$BASE_DIR/lib/core/navigation/navigation_service.dart"
    "$BASE_DIR/lib/core/navigation/route_names.dart"
    "$BASE_DIR/lib/core/navigation/navigation_util.dart"
    # Redundant shell layout that's now consolidated
    "$BASE_DIR/lib/core/navigation/old_shell_layout.dart"
    # Any test files for removed navigation components
    "$BASE_DIR/test/core/navigation/navigation_service_test.dart"
)

# Display files and ask for confirmation
for file in "${FILES_TO_REMOVE[@]}"; do
    if [ -f "$file" ]; then
        echo "- $(basename "$file")"
    fi
done

echo ""
read -p "Do you want to back up and remove these files? (y/n): " confirm

if [ "$confirm" = "y" ] || [ "$confirm" = "Y" ]; then
    echo ""
    echo "Starting cleanup process..."
    
    for file in "${FILES_TO_REMOVE[@]}"; do
        backup_and_remove "$file"
    done
    
    echo ""
    echo "Cleanup complete. Files have been backed up to: $BACKUP_DIR"
else
    echo "Operation cancelled. No files were removed."
fi

echo ""
echo "Additional recommendations:"
echo "1. Update your import statements if needed"
echo "2. Make sure all navigation calls use the new AppNavigation class"
echo "3. Verify that your app still works correctly after this cleanup"
echo ""
echo "If you encounter issues, you can restore the backup files from: $BACKUP_DIR"