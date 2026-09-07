#!/usr/bin/env python3
"""Clone an unsigned release APK with only Godot launch arguments changed."""
import struct, sys, zipfile
source, target = sys.argv[1:]
with zipfile.ZipFile(source) as src, zipfile.ZipFile(target, 'w') as dest:
    for entry in src.infolist():
        data = src.read(entry.filename)
        if entry.filename == 'assets/_cl_':
            count, = struct.unpack_from('<I', data)
            # Godot's exported launch arguments are count + length-prefixed UTF-8.
            extra = ['--', '--test', '--playtest', '--aim', '-0.6', '--test-output', 'user://playtest']
            data = struct.pack('<I', count + len(extra)) + data[4:]
            for arg in extra:
                encoded = arg.encode()
                data += struct.pack('<I', len(encoded)) + encoded
        dest.writestr(entry, data)
with zipfile.ZipFile(source) as src, zipfile.ZipFile(target) as dest:
    assert src.namelist() == dest.namelist()
    assert all(src.read(n) == dest.read(n) for n in src.namelist() if n != 'assets/_cl_')
print('Automation APK payload identical; only launch arguments changed')
