#!/usr/bin/env python3
"""Package generated PNG sizes into a standard PNG-backed ICNS container."""
from pathlib import Path
import struct
import sys

source, destination = map(Path, sys.argv[1:])
entries = [
    (b'icp4', 'icon_16x16.png'), (b'ic11', 'icon_16x16@2x.png'),
    (b'icp5', 'icon_32x32.png'), (b'ic12', 'icon_32x32@2x.png'),
    (b'ic07', 'icon_128x128.png'), (b'ic13', 'icon_128x128@2x.png'),
    (b'ic08', 'icon_256x256.png'), (b'ic14', 'icon_256x256@2x.png'),
    (b'ic09', 'icon_512x512.png'), (b'ic10', 'icon_512x512@2x.png'),
]
chunks = []
for kind, name in entries:
    payload = (source / name).read_bytes()
    assert payload.startswith(b'\x89PNG\r\n\x1a\n'), name
    chunks.append(kind + struct.pack('>I', len(payload) + 8) + payload)
body = b''.join(chunks)
destination.write_bytes(b'icns' + struct.pack('>I', len(body) + 8) + body)
