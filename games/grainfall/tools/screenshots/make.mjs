// App Store screenshots from real simulation frames (6.9" iPhone, 1320×2868).
//   node tools/screenshots/make.mjs [--sim path] [--levels dir] [--out dir]
// Each shot: render the level mid-solution with the CLI (bloom on), then compose it inside a
// mock of the in-game HUD with a marketing caption, and capture with Playwright.
import { execFileSync } from "node:child_process";
import { readFileSync, mkdirSync, existsSync } from "node:fs";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { createRequire } from "node:module";

const require = createRequire(import.meta.url);
const { chromium } = require("playwright");
const here = dirname(fileURLToPath(import.meta.url));
const root = resolve(here, "../..");
const arg = (name, dflt) => { const i = process.argv.indexOf(name); return i > 0 ? process.argv[i + 1] : dflt; };
const sim = arg("--sim", join(root, ".build/release/grainfall-sim"));
const levels = arg("--levels", join(root, "Sources/GrainfallCore/Resources/levels"));
const out = arg("--out", join(root, "AppStore/screenshots/en-US"));
mkdirSync(out, { recursive: true });
const tmp = join(root, "out/shots");
mkdirSync(tmp, { recursive: true });

const shots = JSON.parse(readFileSync(join(here, "shots.json"), "utf8"));
const level = (id) => JSON.parse(readFileSync(join(levels, `${id}.json`), "utf8"));
const colors = { sand: "#F2C46D", water: "#3E8EDE", lava: "#FF5A1F", stone: "#8A8F98", plant: "#4CAF50", steam: "#C9D6E3" };

function solvedTicks(id) {
  const t = execFileSync(sim, ["trace", id, "--solve", "--dir", levels, "--every", "100000"]).toString();
  return Number(/end t=(\d+)/.exec(t)[1]);
}

function page(shot, img, lvl, counts) {
  const cups = lvl.cups.map((c, i) => {
    const got = Math.min(c.required, counts[i] ?? 0);
    const frac = got / c.required;
    return `<div class="chip"><i style="background:${colors[c.accepts] ?? "#fff"}"></i>
      <b><s style="width:${Math.round(frac * 100)}%;background:${colors[c.accepts] ?? "#fff"}"></s></b>
      <span>${got}/${c.required}</span></div>`;
  }).join("");
  return `<!doctype html><html><head><meta charset="utf-8">
<link href="https://fonts.googleapis.com/css2?family=Nunito:wght@800;900&family=Press+Start+2P&display=block" rel="stylesheet">
<style>
  *{box-sizing:border-box;margin:0}
  body{width:1320px;height:2868px;overflow:hidden;font-family:Nunito,DejaVu Sans,sans-serif;
       background:radial-gradient(120% 70% at 50% 0%,#2b2550 0%,#141626 55%,#0b0c14 100%);color:#ecebf2}
  .cap{position:absolute;top:150px;left:0;right:0;text-align:center;padding:0 90px}
  h1{font-size:118px;line-height:1.05;font-weight:900;letter-spacing:-1px}
  h1 em{font-style:normal;color:#F2C46D}
  p{margin-top:34px;font-size:52px;font-weight:800;color:#a4a6bd}
  .phone{position:absolute;left:150px;top:640px;width:1020px;height:2160px;border-radius:120px;
         background:#141626;border:14px solid #2a2d3e;box-shadow:0 60px 140px rgba(0,0,0,.6);overflow:hidden}
  .bar{position:absolute;top:70px;left:44px;right:44px;display:flex;align-items:center;gap:22px}
  .btn{width:88px;height:88px;border-radius:18px;background:rgba(31,33,54,.9);display:grid;place-items:center;
       color:#ecebf2;font-size:44px;font-weight:900}
  .title{flex:1;text-align:center}
  .title small{display:block;font-family:"Press Start 2P",monospace;font-size:22px;color:#a4a6bd}
  .title span{font-size:40px;font-weight:900}
  .chips{position:absolute;top:186px;left:0;right:0;display:flex;justify-content:center;gap:16px}
  .chip{display:flex;align-items:center;gap:12px;background:rgba(31,33,54,.9);border-radius:40px;padding:12px 22px;font-size:26px;font-weight:900}
  .chip i{width:22px;height:22px;border-radius:50%}
  .chip b{width:110px;height:14px;border-radius:7px;background:#2a2d3e;overflow:hidden;display:block}
  .chip s{display:block;height:100%}
  .board{position:absolute;left:30px;top:270px;width:932px;height:1747px;image-rendering:pixelated}
  .meter{position:absolute;bottom:56px;left:70px;right:70px;height:18px;border-radius:9px;background:#2a2d3e}
  .meter s{display:block;height:100%;width:62%;border-radius:9px;background:#845533}
  .hand{position:absolute;font-size:150px;filter:drop-shadow(0 8px 12px rgba(0,0,0,.5))}
</style></head><body>
<div class="cap"><h1>${shot.title}</h1><p>${shot.sub}</p></div>
<div class="phone">
  <div class="bar"><div class="btn">‹</div><div class="title"><small>${lvl.id}</small><span>${lvl.name}</span></div>
    <div class="btn">↻</div><div class="btn">❚❚</div></div>
  <div class="chips">${cups}</div>
  <img class="board" src="data:image/png;base64,${img}">
  ${shot.hand ? `<div class="hand" style="left:${Math.round(30 + 932 * 0.62)}px;top:${Math.round(270 + 1747 * 0.52)}px">👆</div>` : ""}
  <div class="meter"><s></s></div>
</div></body></html>`;
}

const browser = await chromium.launch();
const ctx = await browser.newContext({ viewport: { width: 1320, height: 2868 }, deviceScaleFactor: 1 });
const tab = await ctx.newPage();
let n = 0;
for (const shot of shots) {
  if (!existsSync(join(levels, `${shot.level}.json`))) { console.log(`skip ${shot.level} (no level)`); continue; }
  const lvl = level(shot.level);
  const tick = Math.max(1, Math.round(solvedTicks(shot.level) * shot.at));
  const png = join(tmp, `${shot.level}.png`);
  const log = execFileSync(sim, ["render", shot.level, String(tick), png, "--solve", "--glow", "--scale", "8", "--dir", levels]).toString();
  // "cups ["123/300", "45/300"]" → real counts for the HUD chips.
  const counts = [...log.matchAll(/"(\d+)\/\d+"/g)].map((m) => Number(m[1]));
  const img = readFileSync(png).toString("base64");
  await tab.setContent(page(shot, img, lvl, counts), { waitUntil: "networkidle" });
  await tab.evaluate(() => document.fonts.ready);
  n += 1;
  const file = join(out, `${String(n).padStart(2, "0")}-${shot.level}.png`);
  await tab.screenshot({ path: file });
  console.log(`wrote ${file}`);
}
await browser.close();
