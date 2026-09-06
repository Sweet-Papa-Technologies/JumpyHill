#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p build
python3 tools/asset_ledger.py
tools/godot --headless --editor --import --quit > build/test-import.log 2>&1
if rg -q "SCRIPT ERROR|ERROR:" build/test-import.log; then cat build/test-import.log; exit 1; fi
run_checked() {
  local log="$1"; shift
  tools/godot --headless --fixed-fps 120 --script tests/run.gd -- --test "$@" > "$log" 2>&1
  cat "$log"
  if rg -q 'SCRIPT ERROR|ERROR:|TESTS .* FAIL' "$log"; then exit 1; fi
}
run_checked build/unit.log
tools/godot --headless --script tests/ui_flow.gd -- --test > build/ui-flow.log 2>&1
cat build/ui-flow.log
if rg -q 'SCRIPT ERROR|ERROR:|UI FLOW FAIL' build/ui-flow.log; then exit 1; fi
tools/godot --headless --fixed-fps 120 --script tests/retry.gd -- --test > build/runtime-retry.log 2>&1
cat build/runtime-retry.log
if rg -q 'SCRIPT ERROR|ERROR:|RUNTIME RETRY FAIL' build/runtime-retry.log; then exit 1; fi
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
