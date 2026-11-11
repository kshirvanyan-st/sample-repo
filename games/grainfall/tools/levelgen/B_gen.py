#!/usr/bin/env python3
"""Level drafts for 3-5..3-10 and 4-1..4-10. Writes JSON next to this file."""
import json
from pathlib import Path

HERE = Path(__file__).parent
LEVELS = []


def rect(m, x, y, w, h): return {"op": "rect", "m": m, "x": x, "y": y, "w": w, "h": h}
def circle(m, cx, cy, r): return {"op": "circle", "m": m, "cx": cx, "cy": cy, "r": r}
def line(m, x0, y0, x1, y1, t=3): return {"op": "line", "m": m, "x0": x0, "y0": y0, "x1": x1, "y1": y1, "t": t}
def cupshape(x, y, w, h, t=3): return {"op": "cup", "x": x, "y": y, "w": w, "h": h, "t": t}
def gate(i, x, y, w, h=3): return {"op": "gate", "id": i, "x": x, "y": y, "w": w, "h": h}
def spout(x, m, total, rate=3, width=6, delay=60, y=6):
    return {"x": x, "y": y, "m": m, "rate": rate, "total": total, "width": width, "delay": delay}
def goal(x, y, w, h, accepts, required, forbids=()):
    return {"x": x, "y": y, "w": w, "h": h, "accepts": accepts, "required": required, "forbids": list(forbids)}
def dig(t, *pts): return {"t": t, "dig": list(pts)}
def tap(t, x, y): return {"t": t, "gate": [x, y]}
def boom(t, x, y): return {"t": t, "blast": [x, y]}


def cup(x, y, w, h, accepts, required, forbids=(), t=3):
    """Cup walls + matching goal rect inside them."""
    return cupshape(x, y, w, h, t), goal(x + t, y, w - 2 * t, h - t, accepts, required, forbids)


def hopper(x, y, w, h, m, fill_h, gate_id, gate_x, gate_w, t=3):
    """Gated container: walls, material filled at the bottom, gate in the floor."""
    return [cupshape(x, y, w, h, t),
            rect(m, x + t, y + h - t - fill_h, w - 2 * t, fill_h),
            gate(gate_id, gate_x, y + h - t, gate_w, t)]


def level(id, name, seed, shapes, spouts, cups, solution, traps=(), hint=None, blasts=0, budget=9999):
    d = {"id": id, "name": name, "seed": seed, "digBudget": budget, "par": [9999, 9999]}
    if blasts:
        d["blasts"] = blasts
    if hint:
        d["hint"] = hint
    d["shapes"] = shapes
    if spouts:
        d["spouts"] = spouts
    d["cups"] = cups
    d["solution"] = solution
    if traps:
        d["traps"] = list(traps)
    LEVELS.append(d)


# ---------------------------------------------------------------- Chapter 3: Hot Stuff

# 3-5 Down the Drain — a ramp dumps lava right beside the water route; feed it to the drain.
c1s, c1g = cup(4, 204, 44, 34, "water", 600, ["lava"])
level("3-5", "Down the Drain", 305,
      [rect("dirt", 0, 60, 128, 130), rect("wall", 52, 30, 3, 30), c1s,
       rect("drain", 86, 232, 38, 4)],
      [spout(32, "water", 1000, rate=3, delay=250), spout(46, "lava", 400, rate=2, width=2, delay=30)],
      [c1g],
      [dig(0, 32, 56, 26, 206), dig(0, 46, 56, 104, 230)],
      traps=[[dig(0, 32, 56, 26, 206)]],
      hint="Drains swallow anything. Feed them the lava.")

# 3-6 Long Way Round — sand must swing around a lava pocket (steep slopes only).
c1s, c1g = cup(76, 204, 46, 34, "sand", 400, ["lava"])
level("3-6", "Long Way Round", 306,
      [rect("dirt", 0, 50, 128, 150), circle("lava", 66, 126, 14), c1s],
      [spout(36, "sand", 900, rate=3)],
      [c1g],
      [dig(0, 36, 46, 36, 150, 98, 212)],
      traps=[[dig(0, 36, 46, 98, 206)]])

# 3-7 Molten Moat — a lava pool sits right over the cup. Drain it first, then dig down.
c1s, c1g = cup(40, 206, 48, 32, "sand", 400, ["lava"])
level("3-7", "Molten Moat", 307,
      [rect("dirt", 0, 70, 128, 130),
       rect("empty", 40, 100, 48, 14), rect("lava", 40, 104, 48, 10),
       line("dirt", 90, 107, 48, 116, 6),
       c1s, rect("drain", 2, 236, 30, 3)],
      [spout(64, "sand", 900, rate=3, delay=300)],
      [c1g],
      [dig(0, 42, 112, 16, 234), dig(900, 64, 112, 64, 208), dig(900, 64, 66, 64, 100)],
      traps=[[dig(0, 64, 66, 64, 208)], [dig(0, 64, 66, 64, 100), dig(30, 64, 112, 64, 208)]],
      hint="Empty the lava into the drain before you dig to the cup.")

# 3-8 Three Ways — sand, water, and a lava spout right between them. Three channels, one drain.
s1, g1 = cup(4, 206, 40, 32, "sand", 300, ["lava", "water"])
s2, g2 = cup(84, 206, 40, 32, "water", 300, ["lava", "sand"])
level("3-8", "Three Ways", 308,
      [rect("dirt", 0, 56, 128, 136), s1, s2, rect("drain", 50, 232, 28, 4)],
      [spout(42, "sand", 650, rate=3, delay=220), spout(64, "lava", 300, rate=1, delay=40),
       spout(86, "water", 650, rate=3, delay=220)],
      [g1, g2],
      [dig(0, 42, 52, 42, 80, 22, 208), dig(0, 86, 52, 86, 80, 106, 208), dig(0, 64, 52, 64, 230)],
      traps=[[dig(0, 42, 52, 42, 80, 22, 208), dig(0, 86, 52, 86, 80, 106, 208)]])

# 3-9 First Things First — lava pools in the funnel. Drain it, then release the sand.
s1, g1 = cup(70, 206, 50, 32, "sand", 450, ["lava"])
level("3-9", "First Things First", 309,
      hopper(72, 12, 50, 44, "sand", 30, 1, 88, 18) + [
          rect("lava", 50, 116, 28, 15),
          line("wall", 0, 96, 50, 130), line("wall", 127, 96, 78, 130),
          rect("dirt", 0, 132, 128, 60), s1, rect("drain", 4, 234, 40, 3)],
      [],
      [g1],
      [dig(0, 64, 134, 24, 232), tap(900, 97, 54), dig(900, 70, 132, 95, 208)],
      traps=[[tap(0, 97, 54), dig(0, 70, 132, 95, 208)], [dig(0, 70, 132, 95, 208)]],
      hint="Order matters.")

# 3-10 Inferno — two pockets, and a lava ramp that drops right beside the sand route.
s1, g1 = cup(4, 206, 42, 32, "sand", 300, ["lava", "water"])
s2, g2 = cup(82, 206, 42, 32, "water", 300, ["lava", "sand"])
level("3-10", "Inferno", 310,
      [line("wall", 64, 40, 42, 58), rect("dirt", 0, 62, 128, 136),
       circle("lava", 24, 120, 10), circle("lava", 104, 140, 10),
       s1, s2, rect("drain", 50, 234, 28, 3)],
      [spout(24, "sand", 700, rate=3, delay=240), spout(64, "lava", 400, rate=3, delay=40),
       spout(104, "water", 700, rate=3, delay=240)],
      [g1, g2],
      [dig(0, 24, 58, 24, 96, 8, 116, 8, 160, 20, 208),
       dig(0, 104, 58, 104, 116, 122, 136, 122, 170, 108, 208),
       dig(0, 38, 60, 64, 232)],
      traps=[[dig(0, 24, 58, 20, 208), dig(0, 104, 58, 108, 208), dig(0, 38, 60, 64, 232)],
             [dig(0, 24, 58, 24, 96, 8, 116, 8, 160, 20, 208),
              dig(0, 104, 58, 104, 116, 122, 136, 122, 170, 108, 208)]])

# ---------------------------------------------------------------- Chapter 4: Cool Down

# 4-1 Stone Soup — fill the cup with stone by pouring lava and water together.
s1, g1 = cup(36, 196, 56, 42, "stone", 50)
level("4-1", "Stone Soup", 401,
      hopper(6, 14, 46, 40, "lava", 10, 1, 20, 18) + hopper(76, 14, 46, 40, "water", 12, 2, 90, 18) + [
          rect("dirt", 0, 80, 128, 100), s1],
      [],
      [g1],
      [tap(0, 29, 52), tap(0, 99, 52), dig(0, 29, 76, 56, 186), dig(0, 99, 76, 72, 186)],
      traps=[[tap(0, 29, 52), dig(0, 29, 76, 56, 186)]],
      hint="Lava + water = stone. Make stone in the cup.")

# 4-2 Simmer — water falls on a lava pool; the crust holds. Dig from the rim, not the bottom.
s1, g1 = cup(78, 206, 44, 32, "water", 400, ["lava"])
level("4-2", "Simmer", 402,
      [rect("dirt", 0, 70, 128, 130),
       rect("empty", 40, 90, 48, 30), rect("lava", 40, 108, 48, 12), s1],
      [spout(64, "water", 1100, rate=4)],
      [g1],
      [dig(0, 64, 66, 64, 88), dig(0, 86, 98, 100, 100, 104, 208)],
      traps=[[dig(0, 64, 66, 64, 88), dig(0, 70, 118, 100, 208)]],
      hint="Water cools lava into a stone crust.")

# 4-3 Blast Off — a stone slab you can't dig. Blast it.
s1, g1 = cup(40, 204, 48, 34, "sand", 400)
level("4-3", "Blast Off", 403,
      [rect("dirt", 0, 70, 128, 50), rect("stone", 0, 120, 128, 10), rect("dirt", 0, 130, 128, 40), s1],
      [spout(64, "sand", 900, rate=3)],
      [g1],
      [dig(0, 64, 66, 64, 118), boom(0, 64, 125), dig(0, 64, 130, 64, 176)],
      traps=[[dig(0, 64, 66, 64, 176)]],
      blasts=1,
      hint="Stone can't be dug. Tap the bomb, then tap the stone.")

# 4-4 Mixing Bowl — sand to its cup, lava and water together into the stone cup.
s1, g1 = cup(4, 204, 44, 34, "sand", 300, ["lava", "water", "stone"])
s2, g2 = cup(74, 196, 50, 42, "stone", 45)
level("4-4", "Mixing Bowl", 404,
      [rect("dirt", 0, 60, 128, 120), s1, s2],
      [spout(24, "sand", 600, rate=3), spout(80, "lava", 260, rate=2, delay=60),
       spout(118, "water", 300, rate=2, delay=60)],
      [g1, g2],
      [dig(0, 24, 56, 26, 206), dig(0, 80, 56, 94, 186), dig(0, 118, 56, 104, 186)],
      traps=[[dig(0, 24, 56, 26, 206), dig(0, 80, 56, 50, 140, 26, 206)]])

# 4-5 Hard Hat — stone floor under the sand, a wall splits the pour, stone guards the good side.
s1, g1 = cup(76, 204, 48, 34, "sand", 170)
level("4-5", "Hard Hat", 405,
      [rect("wall", 40, 14, 3, 46), rect("wall", 85, 14, 3, 46), rect("stone", 40, 54, 48, 6),
       rect("sand", 43, 20, 42, 34),
       rect("wall", 44, 118, 48, 4), rect("dirt", 0, 124, 128, 62), rect("stone", 92, 124, 36, 14), s1],
      [],
      [g1],
      [boom(0, 64, 56), boom(0, 100, 130), dig(0, 100, 136, 100, 206)],
      traps=[[boom(0, 64, 56), dig(0, 100, 124, 100, 206)], [boom(0, 64, 56), dig(0, 40, 124, 40, 200, 80, 210)]],
      blasts=2,
      hint="Each bomb counts. Spend them on stone.")

# 4-6 Dam It — lava will slide down the ramp into the cup. Quench it into a stone dam first.
s1, g1 = cup(54, 196, 52, 42, "sand", 400, ["lava"])
level("4-6", "Dam It", 406,
      [cupshape(4, 14, 44, 40), rect("water", 7, 30, 38, 21), gate(2, 14, 51, 20),
       line("wall", 0, 90, 60, 126),
       cupshape(76, 12, 48, 40), rect("sand", 79, 22, 42, 27), gate(1, 90, 49, 18),
       rect("dirt", 64, 100, 64, 80), s1],
      [spout(40, "lava", 220, rate=2, delay=60, y=60)],
      [g1],
      [tap(0, 24, 52), tap(200, 99, 50), dig(200, 98, 96, 84, 200)],
      traps=[[tap(200, 99, 50), dig(200, 98, 96, 84, 200)]],
      hint="Cool the lava before it reaches the cup.")

# 4-7 Short on Shovels — barely any dig budget; blasts do the heavy lifting.
s1, g1 = cup(40, 206, 48, 32, "water", 450)
level("4-7", "Short on Shovels", 407,
      [rect("dirt", 0, 50, 128, 150), s1],
      [spout(64, "water", 1000, rate=4)],
      [g1],
      [boom(0, 64, 56), boom(0, 64, 70), boom(0, 64, 84), boom(0, 64, 98), dig(0, 64, 104, 64, 202)],
      traps=[[dig(0, 64, 46, 64, 202)]],
      blasts=4, budget=1000)
LEVELS[-1]["lockBudget"] = True

# 4-8 Twin Crusts — water crosses two lava pools on its zig-zag down.
s1, g1 = cup(4, 206, 44, 32, "water", 350, ["lava"])
level("4-8", "Twin Crusts", 408,
      [rect("dirt", 0, 60, 128, 140),
       rect("empty", 70, 72, 46, 26), rect("lava", 70, 88, 46, 10),
       rect("empty", 14, 130, 46, 26), rect("lava", 14, 146, 46, 10), s1],
      [spout(94, "water", 1300, rate=4)],
      [g1],
      [dig(0, 94, 56, 94, 70), dig(0, 72, 82, 58, 128), dig(0, 16, 138, 8, 142, 8, 200, 20, 208)],
      traps=[[dig(0, 94, 56, 94, 70), dig(0, 94, 98, 26, 208)]])

# 4-9 Forge — make stone, keep the sand clean, and blast through the old stone floor.
s1, g1 = cup(4, 206, 46, 32, "sand", 350, ["lava", "water"])
s2, g2 = cup(76, 196, 48, 42, "stone", 45)
level("4-9", "Forge", 409,
      hopper(6, 12, 50, 40, "sand", 26, 1, 22, 18) + hopper(70, 12, 52, 40, "lava", 10, 2, 82, 16) + [
          rect("dirt", 0, 80, 128, 104), rect("stone", 0, 150, 60, 10),
          s1, s2],
      [spout(118, "water", 300, rate=2, delay=100)],
      [g1, g2],
      [tap(0, 31, 50), dig(0, 31, 76, 31, 148), boom(0, 26, 155), dig(0, 26, 160, 27, 208),
       tap(0, 90, 50), dig(0, 90, 76, 96, 188), dig(0, 118, 76, 106, 188)],
      traps=[[tap(0, 31, 50), dig(0, 31, 76, 31, 148), boom(0, 26, 155), dig(0, 26, 160, 27, 208),
              tap(0, 90, 50), dig(0, 90, 76, 40, 150)]],
      blasts=1)

# 4-10 Caldera — a lava lake in the middle; cool it, cross it, blast your way out.
s1, g1 = cup(4, 206, 44, 32, "water", 350, ["lava"])
s2, g2 = cup(80, 206, 44, 32, "sand", 300, ["lava"])
level("4-10", "Caldera", 410,
      [rect("dirt", 0, 56, 128, 144),
       rect("empty", 30, 84, 68, 30), rect("lava", 30, 102, 68, 12),
       rect("stone", 70, 150, 58, 10), s1, s2],
      [spout(64, "water", 1200, rate=4), spout(112, "sand", 700, rate=3, delay=120)],
      [g1, g2],
      [dig(0, 64, 52, 64, 82), dig(0, 34, 94, 20, 100, 14, 150, 22, 208),
       dig(0, 112, 52, 112, 146), boom(0, 108, 155), dig(0, 108, 160, 102, 208)],
      traps=[[dig(0, 64, 52, 64, 82), dig(0, 50, 112, 22, 208)]],
      blasts=1)

for d in LEVELS:
    (HERE / f"{d['id']}.json").write_text(json.dumps(d, indent=1) + "\n")
chapters = [
    {"id": 3, "name": "Hot Stuff", "free": False, "levels": [d["id"] for d in LEVELS if d["id"].startswith("3-")]},
    {"id": 4, "name": "Cool Down", "free": False, "levels": [d["id"] for d in LEVELS if d["id"].startswith("4-")]},
]
(HERE / "chapters.json").write_text(json.dumps(chapters, indent=1) + "\n")
print("wrote", len(LEVELS), "levels")
