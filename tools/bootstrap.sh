#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
VERSION="$(cat .godot-version)"
[[ "$(uname -s)" == Darwin ]] || { echo "Install Godot $VERSION for your OS and set GODOT_BIN; this bootstrap downloads macOS." >&2; exit 1; }
mkdir -p .tools/templates
BASE_URL="https://github.com/godotengine/godot-builds/releases/download/$VERSION-stable"
if [[ ! -x .tools/Godot.app/Contents/MacOS/Godot ]]; then
  curl --fail --location --retry 3 "$BASE_URL/Godot_v$VERSION-stable_macos.universal.zip" -o .tools/godot.zip
  unzip -qo .tools/godot.zip -d .tools
fi
if [[ ! -f .tools/templates/macos.zip ]]; then
  curl --fail --location --retry 3 "$BASE_URL/Godot_v$VERSION-stable_export_templates.tpz" -o .tools/templates.tpz
  unzip -jo .tools/templates.tpz templates/macos.zip templates/ios.zip templates/windows_release_x86_64.exe templates/windows_debug_x86_64.exe templates/android_release.apk templates/version.txt -d .tools/templates
fi
tools/godot --headless --editor --import --quit
