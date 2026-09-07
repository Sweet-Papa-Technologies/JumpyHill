#!/usr/bin/env python3
"""Verify packaged bytes, repairing the observed Godot 4.7.2 empty-Mach-O export."""
import sys, zipfile, os
from pathlib import Path
path = Path(sys.argv[1])
if sys.argv[2] == 'macOS':
    executable = 'TREADFALL.app/Contents/MacOS/TREADFALL'
    with zipfile.ZipFile(path) as z:
        entries = [(i, z.read(i.filename)) for i in z.infolist()]
    binary = next(data for i, data in entries if i.filename == executable)
    if len(binary) == 0:
        with zipfile.ZipFile('.tools/templates/macos.zip') as template:
            binary = template.read('macos_template.app/Contents/MacOS/godot_macos_release.universal')
        assert len(binary) > 1_000_000 and binary[:4] in (b'\xca\xfe\xba\xbe', b'\xcf\xfa\xed\xfe'), 'Invalid official template executable'
        with zipfile.ZipFile(str(path)+'.tmp', 'w', zipfile.ZIP_DEFLATED) as z:
            for info, data in entries:
                if info.filename == executable:
                    data = binary
                    info.external_attr = 0o100755 << 16
                z.writestr(info, data)
        os.replace(str(path)+'.tmp', path)
        print('Replaced empty exported Mach-O with byte-identical official universal release template.')
    with zipfile.ZipFile(path) as z:
        assert z.getinfo(executable).file_size > 1_000_000
        assert z.getinfo('TREADFALL.app/Contents/Resources/TREADFALL.pck').file_size > 100_000
        z.extractall(path.parent)
    os.chmod(path.parent / executable, 0o755)
    print('macOS package byte verification PASS')

elif sys.argv[2] == 'Windows':
    with path.open('rb') as f:
        assert f.read(2) == b'MZ', 'Missing Windows executable header'
        f.seek(60)
        offset = int.from_bytes(f.read(4), 'little')
        f.seek(offset)
        assert f.read(4) == b'PE\0\0', 'Invalid PE header'
    assert path.stat().st_size > 1_000_000
    print('Windows package byte verification PASS (execution/signing needs Windows)')


elif sys.argv[2] == 'Android':
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        assert 'AndroidManifest.xml' in names and 'classes.dex' in names
        assert any(n.startswith('lib/arm64-v8a/') and n.endswith('.so') for n in names)
        assert any(n.startswith('assets/') for n in names)
    assert path.stat().st_size > 1_000_000
    print('Android arm64 package byte verification PASS (signing and execution are separate checks)')
