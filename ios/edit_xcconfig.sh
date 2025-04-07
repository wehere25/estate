#!/bin/bash
# Find all xcconfig files and remove the -G flag
find . -name "*.xcconfig" -exec sed -i '' 's/-G//g' {} \;
