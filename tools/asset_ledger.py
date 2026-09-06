#!/usr/bin/env python3
"""Fail closed on untracked assets, unexpected sources, or disallowed licenses."""
from pathlib import Path
import re
ledger = Path('ASSETS.md').read_text()
rows = {}
for line in ledger.splitlines():
    if not line.startswith('| `assets/'): continue
    cells = [c.strip() for c in line.split('|')[1:-1]]
    rows[cells[0].strip('`')] = cells
files = {str(p) for p in Path('assets').rglob('*') if p.is_file() and p.suffix != '.import'}
assert files == set(rows), f'Ledger mismatch: missing={files-set(rows)}, stale={set(rows)-files}'
for path, cells in rows.items():
    original = cells[1] == 'Original work in this repository'
    assert cells[3] in ({'Apache-2.0'} if original else {'CC0', 'CC-BY-3.0', 'CC-BY-4.0', 'OFL-1.1', 'ISC'}), (path, 'license')
    assert original or cells[1].startswith(('https://kenney.nl/', 'https://github.com/google/fonts/', 'https://quaternius.com/', 'https://polyhaven.com/', 'https://ambientcg.com/', 'https://lucide.dev/')), (path, 'source')
print(f'Asset ledger PASS: {len(files)} source files')
