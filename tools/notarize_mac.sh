#!/bin/bash
# Signs, notarizes and zips build/macos/Eleblorbs Demo.app for distribution.
# Prerequisite (one time, in your own terminal; it prompts for the password):
#   xcrun notarytool store-credentials eleblorbs-notary \
#     --apple-id <your Apple ID> --team-id G22BC8W3D6
# Use an app-specific password from appleid.apple.com, not your Apple ID password.
# Re-export the macOS preset first; this script handles everything after that.
set -euo pipefail
cd "$(dirname "$0")/../build/macos"
APP="Eleblorbs Demo.app"
ZIP="Eleblorbs Demo-macOS-universal.zip"
ID="Developer ID Application: Leonard Reese (G22BC8W3D6)"
PROFILE="eleblorbs-notary"

codesign --force --options runtime --timestamp --sign "$ID" "$APP"
codesign --verify --strict --deep "$APP"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
xcrun notarytool submit "$ZIP" --keychain-profile "$PROFILE" --wait
xcrun stapler staple "$APP"
rm -f "$ZIP"
ditto -c -k --sequesterRsrc --keepParent "$APP" "$ZIP"
spctl --assess --type execute --verbose "$APP"
echo "Notarized and stapled: build/macos/$ZIP"
