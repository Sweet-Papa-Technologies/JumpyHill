#!/usr/bin/env bash
# Builds installable local-test APKs; never uploads to a store.
set -euo pipefail
cd "$(dirname "$0")/.."
ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
JAVA_HOME="${JAVA_HOME:-$(/usr/libexec/java_home -v 17)}"
export JAVA_HOME
BUILD_TOOLS="${ANDROID_BUILD_TOOLS:-$ANDROID_SDK_ROOT/build-tools/35.0.0}"
tools/export.sh Android "${1:-0.4.0}"
KEYSTORE="$PWD/.tools/android-test.keystore"
if [[ ! -f "$KEYSTORE" ]]; then
  "$JAVA_HOME/bin/keytool" -genkeypair -keystore "$KEYSTORE" -storepass android -keypass android \
    -alias treadfall-test -dname 'CN=TREADFALL Local Testing' -keyalg RSA -keysize 2048 -validity 3650
fi
# The automation APK has identical game/engine bytes; only launch arguments differ.
python3 tools/android_playtest_apk.py build/android/TREADFALL.apk build/android/TREADFALL-playtest-unaligned.apk
"$BUILD_TOOLS/zipalign" -f -P 16 4 build/android/TREADFALL-playtest-unaligned.apk build/android/TREADFALL-playtest.apk
for apk in build/android/TREADFALL.apk build/android/TREADFALL-playtest.apk; do
  "$BUILD_TOOLS/apksigner" sign --ks "$KEYSTORE" --ks-key-alias treadfall-test --ks-pass pass:android --key-pass pass:android "$apk"
  "$BUILD_TOOLS/apksigner" verify "$apk"
  "$BUILD_TOOLS/zipalign" -c -P 16 4 "$apk"
done
python3 - <<'PY'
import hashlib,json
from pathlib import Path
p=Path('build/android/TREADFALL.manifest.json');m=json.loads(p.read_text())
m.update(signed=True,signing='Local test key; not a Play Store release key',sha256=hashlib.sha256(Path('build/android/TREADFALL.apk').read_bytes()).hexdigest())
p.write_text(json.dumps(m,indent=2)+'\n')
PY
printf 'Android signed local-test APKs verified. Install TREADFALL.apk for normal play.\n'
