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
