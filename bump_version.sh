#!/bin/bash
FILE="pubspec.yaml"
# Extract the current version (assumes format: version: x.y.z+n)
CURRENT_VERSION=$(grep '^version:' $FILE | awk '{print $2}')
BASE_VERSION=$(echo $CURRENT_VERSION | cut -d'+' -f1)
BUILD_NUMBER=$(echo $CURRENT_VERSION | cut -d'+' -f2)
# Increment the build number
NEW_BUILD_NUMBER=$((BUILD_NUMBER + 1))
NEW_VERSION="${BASE_VERSION}+${NEW_BUILD_NUMBER}"
# Replace the version in pubspec.yaml
sed -i.bak "s/^version: .*/version: ${NEW_VERSION}/" $FILE
rm "${FILE}.bak"
# Stage the updated file
git add $FILE