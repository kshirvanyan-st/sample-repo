#!/usr/bin/env python3
"""Recompresses the CLI's stored (uncompressed) PNGs in place: python3 tools/pngsquash.py a.png b.png ..."""
import struct, sys, zlib

for path in sys.argv[1:]:
    d = open(path, "rb").read()
    pos, chunks = 8, []
    while pos < len(d):
        n = struct.unpack(">I", d[pos:pos + 4])[0]
        chunks.append((d[pos + 4:pos + 8], d[pos + 8:pos + 8 + n]))
        pos += 12 + n
    raw = zlib.decompress(b"".join(x for t, x in chunks if t == b"IDAT"))
    c = lambda t, x: struct.pack(">I", len(x)) + t + x + struct.pack(">I", zlib.crc32(t + x) & 0xFFFFFFFF)
    ihdr = next(x for t, x in chunks if t == b"IHDR")
    open(path, "wb").write(b"\x89PNG\r\n\x1a\n" + c(b"IHDR", ihdr) + c(b"IDAT", zlib.compress(raw, 9)) + c(b"IEND", b""))
