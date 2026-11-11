#!/usr/bin/env python3
"""Sets "par" and "digBudget" in level JSON from each level's reference solution.

Convention (spec §3): par3 = 1.5×, par2 = 2.5× the solution's dig cost, digBudget = 3×
(min 1000). A level with "lockBudget": true keeps its hand-set digBudget (when the budget is
part of the puzzle) and only gets pars, clamped so par2 ≤ digBudget.

usage: tools/set_pars.py [levelsDir] [--sim path/to/grainfall-sim] [--only 1-5,1-6]
"""
import argparse, json, math, re, subprocess, sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent
ap = argparse.ArgumentParser()
ap.add_argument("dir", nargs="?", default=str(root / "Sources/GrainfallCore/Resources/levels"))
ap.add_argument("--sim", default=str(root / ".build/release/grainfall-sim"))
ap.add_argument("--only", default="")
a = ap.parse_args()
only = set(filter(None, a.only.split(",")))

out = subprocess.run([a.sim, "validate", a.dir], capture_output=True, text=True).stdout
up = lambda v, n: int(math.ceil(v / n) * n)
for line in out.splitlines():
    m = re.match(r"^. (\d+-\d+)\s.*?won@\d+\s+(\d+)\s", line)
    if not m or (only and m.group(1) not in only):
        continue
    lid, dug = m.group(1), int(m.group(2))
    p = Path(a.dir) / f"{lid}.json"
    s = p.read_text()
    level = json.loads(s)
    budget = level["digBudget"] if level.get("lockBudget") else max(up(dug * 3, 100), 1000)
    par3 = min(up(max(dug, 1) * 1.5, 10), budget)
    par2 = min(max(up(max(dug, 1) * 2.5, 10), par3), budget)
    s = re.sub(r'"digBudget":\s*\d+', f'"digBudget": {budget}', s, count=1)
    s = re.sub(r'"par":\s*\[\s*\d+\s*,\s*\d+\s*\]', f'"par": [{par3}, {par2}]', s, count=1)
    p.write_text(s)
    print(f"{lid}: dug {dug} → par [{par3}, {par2}], budget {budget}")
