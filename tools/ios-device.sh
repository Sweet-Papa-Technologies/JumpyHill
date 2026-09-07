#!/usr/bin/env bash
# Compile for physical iPhones; signing and device deployment are separate.
set -euo pipefail
cd "$(dirname "$0")/.."
SDK_VERSION="$(xcrun --sdk iphoneos --show-sdk-version)"
python3 - "$SDK_VERSION" <<'PY'
import sys
version=tuple(map(int,sys.argv[1].split('.')[:2]))
if version < (26,1):
    sys.exit('The pinned Godot arm64 template was built with iOS SDK 26.1. Select Xcode 26.1+ before building for physical iPhones. Simulator builds can still use tools/ios-simulator.sh.')
PY
tools/export.sh iOS "${1:-0.4.0}"
xcodebuild -project build/ios/TREADFALL.xcodeproj -scheme TREADFALL \
  -configuration Release -sdk iphoneos -destination 'generic/platform=iOS' \
  -derivedDataPath build/ios-device CODE_SIGNING_ALLOWED=NO \
  ARCHS=arm64 ONLY_ACTIVE_ARCH=YES build
