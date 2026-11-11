#!/usr/bin/env python3
"""Generates App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png (1024×1024, no alpha).

Pixel-art icon: sand pouring through a dug hole into a cup, drawn on a 32×32 grid and scaled ×32.
Deterministic (seeded), standard library only.
"""
import random, struct, sys, zlib
from pathlib import Path

N, S = 32, 32
rng = random.Random(7)
BG = (0x14, 0x16, 0x26)
SAND = [(0xF2, 0xC4, 0x6D), (0xE8, 0xB8, 0x5E), (0xF7, 0xD1, 0x84), (0xDD, 0xAF, 0x58)]
DIRT = [(0x7A, 0x4E, 0x2D), (0x6E, 0x46, 0x28), (0x84, 0x55, 0x33), (0x73, 0x4A, 0x2A)]
WALL = (0x4A, 0x4E, 0x69)
TINT = (0x3B, 0x36, 0x30)

px = [[BG] * N for _ in range(N)]
# dirt band with a hole
for y in range(10, 16):
    for x in range(N):
        if not (13 <= x <= 18):
            px[y][x] = rng.choice(DIRT)
# cup
for y in range(21, 30):
    for x in range(8, 24):
        wall = x in (8, 23) or y == 29
        px[y][x] = WALL if wall else TINT
# sand pile in the cup (triangle)
for y in range(22, 29):
    half = (y - 21) + 1
    for x in range(16 - half, 16 + half):
        if 9 <= x <= 22:
            px[y][x] = rng.choice(SAND)
# falling stream (sparse, like the game)
for y in range(1, 23):
    for x in range(14, 18):
        if rng.random() < (0.55 if y < 10 else 0.45):
            px[y][x] = rng.choice(SAND)
# spout nozzle
for x in range(13, 19):
    px[0][x] = (0xE0, 0xE1, 0xDD)

raw = bytearray()
for y in range(N * S):
    raw.append(0)
    row = px[y // S]
    for x in range(N * S):
        raw.extend(row[x // S])

def chunk(t, d):
    c = struct.pack(">I", len(d)) + t + d
    return c + struct.pack(">I", zlib.crc32(t + d) & 0xFFFFFFFF)

png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", struct.pack(">IIBBBBB", N * S, N * S, 8, 2, 0, 0, 0)) \
    + chunk(b"IDAT", zlib.compress(bytes(raw), 9)) + chunk(b"IEND", b"")
out = Path(sys.argv[1] if len(sys.argv) > 1 else
           Path(__file__).resolve().parent.parent / "App/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png")
out.write_bytes(png)
print(f"wrote {out} ({len(png)} bytes)")
