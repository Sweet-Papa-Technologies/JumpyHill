#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
PRESET="${1:-macOS}"
VERSION="${2:-0.1.0}"
[[ "$VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || { echo 'Version must be x.y.z' >&2; exit 1; }
EXPECTED="$(cat .godot-version)"
ACTUAL="$(tools/godot --version)"
[[ "$ACTUAL" == "$EXPECTED.stable."* ]] || { echo "Editor mismatch: $ACTUAL, need $EXPECTED" >&2; exit 1; }
BUILD_NUMBER="$(git rev-list --count HEAD)"
export TREADFALL_SOURCE_DIRTY="$(git status --porcelain)"
export TREADFALL_BUILD_NUMBER="$BUILD_NUMBER" TREADFALL_VERSION="$VERSION"
python3 tools/asset_ledger.py
case "$PRESET" in
  macOS) DEST="build/macos/TREADFALL.zip" ;;
  iOS) DEST="build/ios/TREADFALL.zip" ;;
  Windows) DEST="build/windows/TREADFALL.exe" ;;
  Android) DEST="build/android/TREADFALL.apk" ;;
  *) echo 'Preset must be macOS, iOS, Windows, or Android' >&2; exit 1 ;;
esac
mkdir -p "$(dirname "$DEST")"
# Godot reads version fields from presets; restore them after export, including failures.
PRESETS_BACKUP="$(mktemp)"
cp export_presets.cfg "$PRESETS_BACKUP"
trap 'cp "$PRESETS_BACKUP" export_presets.cfg; rm -f "$PRESETS_BACKUP"' EXIT
python3 - <<'PY'
import os,re
from pathlib import Path
p=Path('export_presets.cfg');s=p.read_text()
s=re.sub(r'application/short_version="[^"]*"',f'application/short_version="{os.environ["TREADFALL_VERSION"]}"',s)
s=re.sub(r'application/version="[^"]*"',f'application/version="{os.environ["TREADFALL_BUILD_NUMBER"]}"',s)
p.write_text(s)
PY
tools/godot --headless --editor --import --quit
tools/godot --headless --export-release "$PRESET" "$DEST"
python3 tools/verify_export.py "$DEST" "$PRESET"
python3 - "$DEST" "$PRESET" "$VERSION" "$BUILD_NUMBER" "$ACTUAL" <<'PY'
import sys,json,hashlib,subprocess,os
from pathlib import Path
p=Path(sys.argv[1]);manifest=dict(preset=sys.argv[2],version=sys.argv[3],build=int(sys.argv[4]),engine=sys.argv[5],commit=subprocess.check_output(['git','rev-parse','HEAD'],text=True).strip(),signed=False,dirty=bool(os.environ.get('TREADFALL_SOURCE_DIRTY', '').strip()))
if p.exists():manifest['sha256']=hashlib.sha256(p.read_bytes()).hexdigest()
p.with_suffix('.manifest.json').write_text(json.dumps(manifest,indent=2)+'\n')
PY
