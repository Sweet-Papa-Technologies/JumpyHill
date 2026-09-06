#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
[[ -d build/ios/TREADFALL.xcodeproj ]] || tools/export.sh iOS "${1:-0.1.0}"
# The 4.7.2 official template declares both simulator architectures but its
# archive is x86_64. Build its actual architecture; device archive is arm64.
ARCH="$(xcrun lipo -info build/ios/TREADFALL.xcframework/ios-arm64_x86_64-simulator/libgodot.a)"
case "$ARCH" in *'is architecture: x86_64'*) SIM_ARCH=x86_64 ;; *) SIM_ARCH=arm64 ;; esac
xcodebuild -project build/ios/TREADFALL.xcodeproj -scheme TREADFALL \
  -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' \
  -derivedDataPath build/ios-derived-final CODE_SIGNING_ALLOWED=NO \
  ARCHS="$SIM_ARCH" ONLY_ACTIVE_ARCH=YES build
printf '\nBuilt: build/ios-derived-final/Build/Products/Debug-iphonesimulator/TREADFALL.app\n'
printf 'Install using: xcrun simctl install <device-id> <app-path>\n'
