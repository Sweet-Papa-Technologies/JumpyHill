#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
tools/export.sh macOS "${1:-0.1.0}"
tools/sign-macos.sh build/macos/TREADFALL.app --dmg
codesign --verify --deep --strict build/macos/TREADFALL.app
spctl --assess --type execute build/macos/TREADFALL.app
xcrun stapler validate build/macos/TREADFALL.app
xcrun stapler validate build/macos/TREADFALL.dmg
ditto -c -k --sequesterRsrc --keepParent build/macos/TREADFALL.app build/macos/TREADFALL-signed.zip
mv build/macos/TREADFALL-signed.zip build/macos/TREADFALL.zip
python3 - <<'PY'
from pathlib import Path
import json,hashlib
p=Path('build/macos/TREADFALL.manifest.json');data=json.loads(p.read_text())
data.update(signed=True,notarized=True,sha256=hashlib.sha256(Path('build/macos/TREADFALL.zip').read_bytes()).hexdigest(),dmg_sha256=hashlib.sha256(Path('build/macos/TREADFALL.dmg').read_bytes()).hexdigest())
p.write_text(json.dumps(data,indent=2)+'\n')
PY
