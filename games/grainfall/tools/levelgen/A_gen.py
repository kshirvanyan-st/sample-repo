#!/usr/bin/env python3
# Level authoring script for 1-5..1-10 and 2-5..2-10. Writes <id>.json + chapters.json here.
import json, sys
L = {}

def rect(m, x, y, w, h): return {"op": "rect", "m": m, "x": x, "y": y, "w": w, "h": h}
def circ(m, cx, cy, r): return {"op": "circle", "m": m, "cx": cx, "cy": cy, "r": r}
def line(m, x0, y0, x1, y1, t=3): return {"op": "line", "m": m, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "t": t}
def cupw(x, y, w, h, t=3): return {"op": "cup", "x": x, "y": y, "w": w, "h": h, "t": t}
def gate(i, x, y, w, h): return {"op": "gate", "id": i, "x": x, "y": y, "w": w, "h": h}
def spout(x, y, m, rate, total, width=6, delay=60): return {"x": x, "y": y, "m": m, "rate": rate, "total": total, "width": width, "delay": delay}
def cup(x, y, w, h, m, req, forbids=(), t=3):
    # (wall shape, goal rect) for a U cup with walls of thickness t
    return cupw(x, y, w, h, t), {"x": x + t, "y": y, "w": w - 2 * t, "h": h - t, "accepts": m, "required": req, "forbids": list(forbids)}
def dig(t, *pts): return {"t": t, "dig": list(pts)}
def tap(t, x, y): return {"t": t, "gate": [x, y]}

def level(i, name, seed, shapes, spouts, cups, solution, traps=(), hint=None, budget=8000, extra=None):
    d = {"id": i, "name": name, "seed": seed, "digBudget": budget, "par": [9999, 9999]}
    if hint: d["hint"] = hint
    d["shapes"] = shapes
    if spouts: d["spouts"] = spouts
    d["cups"] = cups
    d["solution"] = solution
    if traps: d["traps"] = list(traps)
    if extra: d.update(extra)
    L[i] = d

# ---------------- Chapter 1: First Grains ----------------
c, g = cup(6, 200, 44, 38, "sand", 400)
level("1-5", "Zigzag", 105,
      [rect("dirt", 0, 60, 128, 130), rect("wall", 0, 108, 60, 4), rect("wall", 46, 150, 82, 4), c],
      [spout(20, 6, "sand", 3, 900)], [g],
      [dig(0, 20, 56, 66, 111, 66, 130, 36, 166, 30, 192)],
      traps=[[dig(0, 20, 56, 20, 192)]])

c, g = cup(34, 196, 60, 42, "sand", 700)
level("1-6", "Bucket Brigade", 106,
      [cupw(6, 14, 50, 44), rect("sand", 9, 40, 44, 15), gate(1, 22, 55, 18, 3),
       cupw(72, 14, 50, 44), rect("sand", 75, 40, 44, 15), gate(2, 88, 55, 18, 3),
       rect("dirt", 0, 90, 128, 90), c],
      [], [g],
      [tap(0, 31, 56), tap(0, 97, 56), dig(0, 31, 86, 56, 184), dig(0, 97, 86, 72, 184)],
      traps=[[tap(0, 31, 56), dig(0, 31, 86, 56, 184), dig(0, 97, 86, 72, 184)],
             [tap(0, 97, 56), dig(0, 31, 86, 56, 184), dig(0, 97, 86, 72, 184)]],
      hint="One hopper isn't enough")

cl, gl = cup(2, 196, 40, 40, "sand", 180)
cc, gc = cup(44, 196, 40, 40, "sand", 380)
cr, gr = cup(86, 196, 40, 40, "sand", 180)
level("1-7", "Three Cups", 107,
      [line("wall", 30, 48, 40, 38, 2), line("wall", 40, 38, 50, 48, 2),
       line("wall", 78, 48, 88, 38, 2), line("wall", 88, 38, 98, 48, 2),
       rect("dirt", 0, 56, 128, 124), cl, cc, cr],
      [spout(40, 6, "sand", 3, 650), spout(88, 6, "sand", 3, 650)], [gl, gc, gr],
      [dig(0, 29, 52, 22, 186), dig(0, 51, 52, 58, 186), dig(0, 77, 52, 70, 186), dig(0, 99, 52, 106, 186)],
      traps=[[dig(0, 29, 52, 22, 186), dig(0, 51, 52, 58, 186), dig(0, 99, 52, 106, 186)]])

c, g = cup(80, 204, 44, 34, "sand", 400)
level("1-8", "Caves", 108,
      [rect("dirt", 0, 40, 128, 160), circ("empty", 30, 76, 16), circ("empty", 52, 118, 17),
       circ("empty", 80, 162, 17), c],
      [spout(30, 6, "sand", 3, 1000)], [g],
      [dig(0, 30, 36, 30, 62), dig(0, 34, 90, 42, 104), dig(0, 58, 132, 70, 148), dig(0, 84, 176, 98, 206)],
      traps=[[dig(0, 30, 36, 100, 206)]],
      hint="Dig is limited. Use the caves.", budget=900, extra={"lockBudget": True})

c, g = cup(56, 196, 48, 40, "sand", 450)
level("1-9", "Shutters", 109,
      [cupw(44, 10, 40, 40), rect("sand", 47, 20, 34, 27), gate(1, 54, 47, 20, 3),
       gate(2, 30, 80, 34, 3), gate(3, 64, 80, 34, 3),
       cupw(20, 100, 44, 40), line("wall", 110, 100, 84, 130, 3),
       rect("dirt", 60, 150, 50, 22), c],
      [], [g],
      [tap(0, 64, 48), tap(0, 90, 81), dig(0, 82, 146, 80, 176)],
      traps=[[tap(0, 64, 48), tap(0, 40, 81), tap(0, 90, 81), dig(0, 82, 146, 80, 176)]])

c1, g1 = cup(4, 200, 38, 38, "sand", 300)
c2, g2 = cup(45, 200, 38, 38, "sand", 300)
c3, g3 = cup(86, 200, 38, 38, "sand", 300)
level("1-10", "Grand Pour", 110,
      [cupw(4, 8, 120, 40), rect("sand", 7, 22, 114, 23),
       gate(1, 16, 45, 14, 3), gate(2, 57, 45, 14, 3), gate(3, 98, 45, 14, 3),
       rect("dirt", 0, 70, 128, 120),
       rect("wall", 8, 100, 26, 4), rect("wall", 50, 130, 26, 4), rect("wall", 92, 160, 26, 4), c1, c2, c3],
      [], [g1, g2, g3],
      [tap(0, 23, 46), tap(0, 64, 46), tap(0, 105, 46),
       dig(0, 23, 66, 23, 80, 40, 96, 40, 112, 24, 138, 24, 204),
       dig(0, 64, 66, 64, 110, 82, 128, 82, 144, 66, 170, 64, 204),
       dig(0, 105, 66, 105, 140, 122, 157, 122, 174, 106, 200, 106, 204)],
      traps=[[tap(0, 23, 46), tap(0, 64, 46), tap(0, 105, 46),
              dig(0, 23, 66, 23, 204), dig(0, 64, 66, 64, 204), dig(0, 105, 66, 105, 204)]])

# ---------------- Chapter 2: Flow ----------------
c, g = cup(84, 200, 40, 38, "water", 500)
level("2-5", "Waterslide", 205,
      [rect("wall", 0, 70, 128, 3), rect("dirt", 106, 56, 9, 17),
       rect("wall", 0, 120, 128, 3), gate(1, 8, 120, 16, 3),
       rect("wall", 0, 170, 128, 3), rect("dirt", 106, 156, 9, 17), c],
      [spout(12, 6, "water", 4, 1000)], [g],
      [dig(0, 110, 58, 110, 74), tap(0, 15, 121), dig(0, 110, 158, 110, 174)],
      traps=[[dig(0, 110, 58, 110, 74), dig(0, 110, 158, 110, 174)]])

cl, gl = cup(4, 200, 40, 38, "water", 350)
cr, gr = cup(84, 200, 40, 38, "water", 350)
level("2-6", "Twin Pots", 206,
      [line("wall", 54, 40, 64, 32, 2), line("wall", 64, 32, 74, 40, 2),
       rect("dirt", 0, 50, 64, 62), rect("wall", 12, 110, 52, 3),
       gate(1, 64, 60, 64, 3), rect("dirt", 64, 90, 64, 60), cl, cr],
      [spout(64, 6, "water", 4, 1300)], [gl, gr],
      [dig(0, 52, 46, 52, 106, 6, 106, 6, 116), tap(0, 90, 61), dig(0, 96, 86, 102, 154)],
      traps=[[dig(0, 52, 46, 52, 106, 6, 106, 6, 116)], [tap(0, 90, 61), dig(0, 96, 86, 102, 154)]])

cd, gd = cupw(2, 200, 44, 38), None
cw, gw = cup(82, 200, 42, 38, "water", 650, ["sand"])
level("2-7", "Down the Drain", 207,
      [cupw(70, 14, 52, 44), rect("water", 73, 18, 46, 37), gate(1, 92, 55, 10, 3),
       line("wall", 14, 56, 54, 110, 3), line("wall", 114, 56, 74, 110, 3),
       rect("dirt", 30, 112, 68, 80), cd, rect("drain", 5, 232, 38, 3), cw],
      [spout(64, 6, "sand", 3, 300, delay=0)], [gw],
      [dig(0, 64, 108, 64, 140, 28, 192), tap(400, 97, 56), dig(400, 64, 140, 100, 192)],
      traps=[[dig(0, 64, 108, 64, 140, 28, 192), tap(0, 97, 56), dig(0, 64, 140, 100, 192)],
             [tap(0, 97, 56), dig(400, 64, 108, 64, 140, 100, 192)]],
      hint="Drains swallow anything. Get rid of the sand first.")

c, g = cup(34, 200, 46, 38, "water", 850)
level("2-8", "Lock Chain", 208,
      [cupw(4, 10, 56, 40), rect("water", 7, 18, 50, 29), gate(1, 20, 47, 24, 3),
       rect("wall", 0, 80, 90, 3), gate(2, 6, 80, 16, 3), gate(3, 66, 80, 20, 3), rect("wall", 90, 60, 3, 23),
       rect("wall", 0, 121, 32, 2), rect("drain", 2, 118, 28, 3),
       rect("wall", 40, 130, 88, 3), gate(4, 44, 130, 18, 3), gate(5, 106, 130, 18, 3), rect("wall", 37, 110, 3, 23),
       rect("wall", 96, 173, 32, 2), rect("drain", 98, 170, 30, 3),
       rect("dirt", 30, 150, 50, 30), c],
      [], [g],
      [tap(0, 32, 48), tap(0, 76, 81), tap(0, 53, 131), dig(0, 53, 146, 56, 184)],
      traps=[[tap(0, 32, 48), tap(0, 14, 81), tap(0, 76, 81), tap(0, 53, 131), dig(0, 53, 146, 56, 184)],
             [tap(0, 32, 48), tap(0, 76, 81), tap(0, 53, 131), tap(0, 115, 131), dig(0, 53, 146, 56, 184)]])

c, g = cup(4, 200, 44, 38, "water", 500, ["sand"])
level("2-9", "Muddy Waters", 209,
      [rect("dirt", 0, 60, 128, 130), circ("sand", 50, 130, 12), circ("sand", 100, 100, 9), c],
      [spout(100, 6, "water", 4, 1100)], [g],
      [dig(0, 100, 56, 116, 72, 116, 150, 20, 150, 20, 204)],
      traps=[[dig(0, 100, 56, 100, 150, 20, 150, 20, 204)],
             [dig(0, 100, 56, 116, 72, 116, 138, 20, 138, 20, 204)]])

cl, gl = cup(4, 200, 40, 38, "water", 400, ["sand"])
cr, gr = cup(84, 200, 40, 38, "water", 400, ["sand"])
level("2-10", "Waterworks", 210,
      [line("wall", 54, 40, 64, 32, 2), line("wall", 64, 32, 74, 40, 2),
       rect("dirt", 0, 56, 128, 134), rect("drain", 96, 120, 16, 6),
       rect("wall", 0, 110, 56, 3), gate(1, 20, 110, 16, 3), rect("wall", 70, 140, 40, 4), cl, cr],
      [spout(64, 6, "water", 4, 1400), spout(100, 6, "sand", 3, 900, delay=0)], [gl, gr],
      [dig(0, 100, 52, 104, 118), dig(0, 53, 52, 40, 106, 28, 106), tap(0, 28, 111), dig(0, 28, 116, 24, 204),
       dig(0, 75, 52, 66, 136, 66, 160, 104, 196, 104, 204)],
      traps=[[dig(0, 53, 52, 40, 106, 28, 106), tap(0, 28, 111), dig(0, 28, 116, 24, 204),
              dig(0, 75, 52, 66, 136, 66, 160, 104, 196, 104, 204)]])

json.dump([{"id": 1, "name": "First Grains", "free": True, "levels": [k for k in L if k.startswith("1-")]},
           {"id": 2, "name": "Flow", "free": True, "levels": [k for k in L if k.startswith("2-")]}],
          open("chapters.json", "w"), indent=2)
for k, v in L.items():
    with open(f"{k}.json", "w") as f:
        f.write(json.dumps(v, indent=None, separators=(", ", ": ")).replace(', "shapes"', ',\n  "shapes"').replace(', "spouts"', ',\n  "spouts"').replace(', "cups"', ',\n  "cups"').replace(', "solution"', ',\n  "solution"').replace(', "traps"', ',\n  "traps"') + "\n")
print("wrote", len(L))
