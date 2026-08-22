#!/bin/bash
# Copies the correct GoogleService-Info.plist based on the active Xcode build configuration.
# Place this script as a "Run Script" phase in Xcode *before* the "Compile Sources" phase.
#
# Expected file layout:
#   ios/Runner/GoogleService-Info.plist         → Release (production)
#   ios/Runner/GoogleService-Info-Debug.plist   → Debug (development)

set -euo pipefail

RESOURCE_PATH="${SRCROOT}/Runner"
RELEASE_PLIST="${RESOURCE_PATH}/GoogleService-Info.plist"
DEBUG_PLIST="${RESOURCE_PATH}/GoogleService-Info-Debug.plist"
DESTINATION="${BUILT_PRODUCTS_DIR}/${PRODUCT_NAME}.app/GoogleService-Info.plist"

if [[ "${CONFIGURATION}" == *"Debug"* ]]; then
  echo "Installing DEBUG GoogleService-Info.plist from ${DEBUG_PLIST}"
  cp "${DEBUG_PLIST}" "${DESTINATION}"
else
  echo "Installing RELEASE GoogleService-Info.plist from ${RELEASE_PLIST}"
  cp "${RELEASE_PLIST}" "${DESTINATION}"
fi
