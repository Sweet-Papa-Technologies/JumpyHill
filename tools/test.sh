#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
python3 tools/asset_ledger.py
tools/godot --headless --editor --import --quit > build/test-import.log 2>&1
run_checked() {
  local log="$1"; shift
  tools/godot --headless --fixed-fps 120 --script tests/run.gd -- --test "$@" > "$log" 2>&1
  cat "$log"
  if rg -q 'SCRIPT ERROR|ERROR:|TESTS .* FAIL' "$log"; then exit 1; fi
}
run_checked build/unit.log
for i in 1 2 3; do run_checked "build/determinism-$i.log" --determinism; done
python3 - <<'PY'
from pathlib import Path
results=[]
for i in range(1,4):
 results.append(next(x for x in Path(f'build/determinism-{i}.log').read_text().splitlines() if x.startswith('DETERMINISM_RESULT ')))
assert len(set(results))==1, 'Cross-process determinism failed'
print('Cross-process determinism PASS: 3 processes × 20 rolls')
PY
if [[ "${1:-}" == --full ]]; then run_checked build/solver-full.log --solver; fi
