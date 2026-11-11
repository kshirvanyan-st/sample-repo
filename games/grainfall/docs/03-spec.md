# 03 — Technical specification: Grainfall

Implements `02-prd.md`. Requirement IDs (`R-x`) are referenced from tests and code comments.

## 1. Architecture

```
┌──────────────────────────── iOS app (App/) ────────────────────────────┐
│ SwiftUI shell: Title · LevelSelect · Game HUD · Results · Paywall · Settings │
│        │                                   ▲                         │
│        ▼                                   │ snapshot (HUD state)    │
│ GameController  ── fixed 60 Hz step ──►  GrainfallCore.World         │
│   ▲ touch → PlayerAction                   │ rgba pixel buffer       │
│   │                                        ▼                         │
│ Engine adapter (Engine/): GridView (MTKView) + PixelRenderer (Metal) │
│ Services: ProgressStore (JSON file) · StoreService (StoreKit 2) · Haptics │
└──────────────────────────────────────────────────────────────────────────┘
┌──────── GrainfallCore (Swift package, no Apple-only APIs) ────────┐
│ Material · Grid · RNG · Simulation · Level/LevelLoader · World    │
│ Scoring · Progress · LevelCatalog · Replay   (+ levels/*.json)     │
└────────────────────────────────────────────────────────────────────┘
grainfall-sim (CLI): validates levels, runs solutions, renders PNG snapshots
```

- **GrainfallCore** is pure Swift (Foundation only). It builds and tests on Linux CI and macOS,
  and holds all game rules. It has no knowledge of rendering, time or touches.
- **App** owns the platform side: the frame clock, touch input, the Metal draw, and
  persistence/StoreKit.
- **R-ARCH-1:** game logic in the app target is forbidden. If a rule needs to be tested, it goes
  in Core.

### 1.1 Engine integration
The studio Metal engine (the one used for *bulkhead* and *matchday*) wasn't available when this
spec was written. The app therefore includes a minimal engine layer in `App/Sources/Engine/`,
behind a narrow seam that maps directly onto a typical engine's renderer and input modules:

| Seam | Grainfall needs | Built-in implementation |
|---|---|---|
| `PixelSurface` | Upload a `w×h` RGBA8 buffer each frame; draw it letterboxed with nearest-neighbour sampling | `PixelRenderer` (MTKView delegate, 1 texture, 1 triangle-strip draw) |
| Frame clock | Callback per display frame with a timestamp | `MTKView` draw loop → `GameController.tick(now:)` |
| Pointer input | Touch began/moved/ended in view points | `GridMTKView` touch overrides |
| View→grid mapping | Inverse of the letterbox transform | `Letterbox` (pure struct, unit-testable) |

To move onto the studio engine, implement `PixelSurface` with the engine's sprite/texture path,
drive `GameController.tick` from the engine's frame callback, and forward its pointer events.
Core doesn't change.

## 2. Simulation (GrainfallCore)

### 2.1 Grid
- Fixed size **128 × 240** cells (`Grid.width/height`), with y = 0 at the top.
- Structure of arrays, indexed `i = y * width + x`:
  - `mat: [Material]` (UInt8 raw value)
  - `shade: [UInt8]` — a 0…3 colour variant rolled when the cell is created, for the grainy look
  - `life: [UInt8]` — remaining lifetime for steam and fire
  - `stamp: [UInt8]` — tick stamp of the cell's last move, which stops a cell from being processed twice in one tick
  - `gate: [UInt8]` — gate id for gate cells (0 = none)
- Everything outside the grid acts as wall.

### 2.2 Determinism (R-SIM-1)
- Fixed timestep: **1 tick = 1/60 s**. The app runs `n = floor(accumulated / dt)` ticks per
  frame, clamped to 4 so a slow frame can't spiral.
- All randomness comes from `RNG` (SplitMix64) seeded by the level's `seed`. There are no other
  random sources and no dictionary-order dependence.
- Player actions are applied **between ticks** and recorded as `(tick, action)`. Replaying the
  same actions on the same level produces the same grid bit for bit (tested).

### 2.3 Update order
Each tick:
1. Spouts emit (§2.6).
2. Cells update **bottom row to top**. The horizontal scan direction alternates every tick so
   flow has no left/right bias. A cell whose `stamp == tick` is skipped.
3. Cups collect (§2.7).
4. Win, fail and stuck states are evaluated (§2.8).

### 2.4 Movement classes
| Class | Materials | Rule (stop at first success) |
|---|---|---|
| static | wall, dirt, stone, plant, gate | doesn't move |
| powder | sand | ↓; then ↙/↘ (random order) |
| liquid | water (spread 5), lava (spread 1, moves on 50% of ticks) | ↓; ↙/↘; then slide sideways up to *spread* cells in a random direction, through empty space only |
| gas | steam | ↑; ↖/↗; sideways 1. `life` counts down → empty |
| fire | fire | stays in place (flickers via colour); `life` counts down → empty |

A move into a target cell is allowed if the target is empty, or if the target is a fluid (liquid
or gas) with **lower density** than the mover. In that case the two cells swap. Density:
gas 0 < water 2 < sand 3 = lava 3. So sand sinks through water and water sinks through steam,
while lava and sand don't swap.

### 2.5 Reactions (checked against the 4 neighbours after movement)
| Cell | Neighbour | Result | p per tick |
|---|---|---|---|
| lava | water | lava → stone, water → steam | 1.0 |
| lava | plant | plant → fire | 0.5 |
| fire | plant | plant → fire | 0.15 |
| fire | water | fire → empty, water → steam | 1.0 |
| plant | water | water → plant | 0.004 |

Fire's initial `life` is 20–40 ticks and steam's is 60–120 ticks.

### 2.6 Spouts
`{x, y, material, rate, total, width, delay}`. After `delay` ticks (the PRD's 1 s read time is
the default of 60), a spout places up to `rate` cells per tick into random empty cells of row `y`
within `[x - width/2, x + width/2]`, until `total` cells have been emitted. HUD shows the
remaining amount.

### 2.7 Cups (goals)
`{x, y, w, h, accepts, required, forbids[]}`. After movement, every cell inside the rect is
checked:
- `accepts` → counted. `collected` is the number of accepted cells **currently inside** the
  rect. Grains stay put, so the player watches the cup fill up, which is the payoff.
- A material in `forbids` → the cup is **ruined** (`World.status = .failed(.contaminated)`).
- Anything else is left alone (it can clog the cup, which is part of the puzzle).

A level's cup rect must start empty of its accepted material, and must be able to hold
`required` cells. The renderer tints empty cup cells with the accepted material's colour.

### 2.8 Status
`playing → won` when `collected ≥ required` for every cup.
`playing → failed(.contaminated)` as in §2.7.
`stuck` (a flag, **not** a terminal state): every spout is exhausted and no cup's best
`collected` has grown for **600 ticks**. Spout output, a dig that clears at least one cell, an
opened gate, or cup progress resets the counter.
Once the status is terminal, the world stops ticking.

### 2.9 Player actions (R-INPUT-1)
- `dig(from: Point, to: Point)`: walks the segment in steps of 1 cell and clears **dirt** within
  radius 4 of each step. Each cleared cell costs 1 from `digBudget`. Digging stops when the
  budget reaches 0. Total cells dug is tracked as `dug`.
- `openGate(at: Point)`: finds the nearest gate cell within radius 6 and removes every cell
  with that gate's id.
- The app chooses between the two on touch-down: if `world.gateID(near:)` returns a gate, the
  touch is a gate tap; otherwise it's a dig stroke.

### 2.10 Scoring (R-SCORE-1)
`stars(dug) = 3 if dug ≤ par3; 2 if dug ≤ par2; else 1` (only on a win).
`par3`/`par2` are set per level. CI asserts that the reference solution earns 3 stars.

## 3. Level format

JSON files under `Sources/GrainfallCore/Resources/levels/`, with the chapter list in `chapters.json`.

```jsonc
{
  "id": "1-1", "name": "First Dig", "seed": 11,
  "digBudget": 2000, "par": [300, 600],          // par3, par2
  "hint": "Drag to dig a path",                  // optional, shown once
  "shapes": [                                     // painted in order onto an empty grid
    {"op": "rect",   "m": "dirt", "x": 0, "y": 120, "w": 128, "h": 40},
    {"op": "circle", "m": "empty", "cx": 64, "cy": 140, "r": 8},
    {"op": "line",   "m": "wall", "x0": 0, "y0": 60, "x1": 50, "y1": 90, "t": 3},
    {"op": "cup",    "x": 44, "y": 200, "w": 40, "h": 30, "t": 3},   // U of wall
    {"op": "gate",   "id": 1, "x": 30, "y": 100, "w": 20, "h": 3}
  ],
  "spouts": [{"x": 64, "y": 4, "m": "sand", "rate": 3, "total": 900, "width": 8, "delay": 60}],
  "cups":   [{"x": 47, "y": 200, "w": 34, "h": 27, "accepts": "sand", "required": 500, "forbids": []}],
  "solution": [{"t": 0, "dig": [64, 118, 64, 162]}, {"t": 30, "gate": [40, 101]}],
  "traps": [[{"t": 0, "dig": [64, 40, 64, 200]}]]   // wrong approaches that must NOT win
}
```

`dig` is a polyline `[x0, y0, x1, y1, …]` and expands to one action per segment. `spouts` may
be omitted when a level starts with pre-filled hoppers behind gates.

Validation (`LevelLoader.validate`) rejects: unknown materials or ops; shapes, spouts or cups out
of bounds; a cup that needs more than the level provides (matching spout totals plus painted
cells; lava counts toward stone); a cup too small for `required`; duplicate gate ids; par3 > par2.

**CI content checks (R-LVL-1…4), for every level:**
1. It loads and passes validation.
2. With **no input**, it doesn't reach `won` within 3600 ticks, so the level needs the player.
3. With its `solution` replayed, it reaches `won` within 3600 ticks and earns 3 stars, and
   `par2 ≤ digBudget`.
4. None of its `traps` (scripted wrong approaches, e.g. digging straight through the lava
   pocket) wins. This proves the puzzle's idea is actually required.

Par convention: par3 = 1.5× and par2 = 2.5× the reference solution's dig cost, with
`digBudget` = 3×. Human strokes are messier than scripted lines.

## 4. Rendering (App, Metal)
- Core produces the frame: `World.render(into: inout [UInt32])` writes RGBA8 using a
  `Palette` (4 shades per material, plus background and cup tints). It's shared with the CLI's
  PNG output, so screenshots in CI match the device.
- `PixelRenderer`:
  - One `MTLTexture` of 128×240 `.rgba8Unorm`, updated each frame with `replace(region:)`
    (123 KB, well within budget).
  - The pipeline draws a 4-vertex triangle strip. The viewport is set to the letterbox rect
    (aspect fit, integer-ish scale not required). The fragment shader samples with `nearest` and
    adds a subtle vignette.
  - The clear colour matches the palette background, so letterbox bars blend in.
- **Budget (R-PERF-1):** simulation ≤ 2 ms per tick and frame CPU ≤ 6 ms on iPhone 11.
  The grid is 30,720 cells, so one tick is roughly 30k branchy operations.

## 5. App structure
| File | Responsibility |
|---|---|
| `GrainfallApp.swift` | `@main`, injects `AppModel` |
| `AppModel.swift` | Navigation state, progress, catalog, purchase state |
| `Views/TitleView` | Logo, Play (continues at first unfinished level), Levels, Settings |
| `Views/LevelSelectView` | Chapters × levels grid, stars, locks, paywall entry |
| `Views/GameScreen` | Metal view + HUD (cup counters, dig meter, pause/restart), hint overlay |
| `Views/ResultOverlay` | Win (stars, next, replay) / fail (reason, retry) |
| `Views/PaywallView` | Full Game pitch, Buy, Restore |
| `Views/SettingsView` | Haptics toggle, Restore Purchases, credits, version |
| `Game/GameController` | Owns `World`, fixed-step clock, input → `PlayerAction`, publishes HUD snapshot ≤ 10×/s |
| `Engine/PixelSurface`, `Engine/PixelRenderer`, `Engine/GridMTKView`, `Engine/Shaders.metal` | §1.1 (the `Letterbox` math lives in Core so it's unit-tested) |
| `ProgressStore` (Core) | Persistence (§6) |
| `Services/StoreService` | StoreKit 2: product load, purchase, restore, `Transaction.updates` listener, entitlement check on launch |
| `Services/Haptics` | Throttled `UIImpactFeedbackGenerator` / `UINotificationFeedbackGenerator` |

## 6. Persistence
`PlayerProgress` (Codable, in Core): `[levelID: bestStars]`, `settings.haptics`, `schemaVersion = 1`.
Stored as JSON in `Application Support/progress.json` and written atomically after every result
or settings change. A corrupt file is moved aside and replaced with a fresh `PlayerProgress`, so the
app never crashes on bad data (R-SAVE-1).
Unlock rules (`PlayerProgress.isUnlocked(level:in:catalog, fullGame:)`):
- The first level of chapter 1 is always unlocked.
- Within a chapter, level *n* unlocks when level *n−1* has ≥ 1 star.
- The first level of chapter *k* unlocks when every level of chapter *k−1* has ≥ 1 star, **and**
  chapter *k* is free or `fullGame` is true.

Purchase entitlement isn't persisted by us. StoreKit 2 `Transaction.currentEntitlements` is the
source of truth on each launch.

## 7. Monetization implementation
- Product: `com.<studio>.grainfall.fullgame`, non-consumable, Family Sharing on.
- `chapters.json` marks each chapter with `"free": true|false`.
- `Grainfall.storekit` configuration file for local and Simulator testing.

## 8. Build, test, CI
- `swift test -c release -Xswiftc -enable-testing` at the repo root builds and tests Core and
  the CLI. This runs on Linux and macOS. Use release mode: the unoptimised simulation is about
  50× slower.
- `swift run -c release grainfall-sim validate` runs the R-LVL checks with a readable report.
  `render <id> <tick> out.png [--solve]`, `render-trap`, `trace` and `sheet` (every level in one
  PNG) are for level authoring and store art.
- iOS: `App/project.yml` is an XcodeGen spec. Run `cd App && xcodegen && open Grainfall.xcodeproj`.
  The app target depends on the local `GrainfallCore` package.
- GitHub Actions:
  - `core` job: `swift test` on ubuntu, then `grainfall-sim validate`, then upload a level sheet PNG.
  - `ios` job: macOS, `xcodegen`, then `xcodebuild -scheme Grainfall -destination 'generic/platform=iOS Simulator' build`.
- Release: archive with Xcode or Fastlane `gym`, upload to TestFlight. Signing is set up in the
  team's App Store Connect account (out of scope here).

## 9. Test plan
| Area | Tests |
|---|---|
| Materials | Sand falls and piles; water levels out; sand sinks through water; lava + water → stone; fire burns plant; steam rises and fades |
| Determinism | Same seed and actions → identical grid hash; different seed → different hash |
| Actions | Dig clears only dirt, respects radius and budget; gate opens whole gate by id |
| Cups | Collect accepted material; forbidden material fails the level; stuck flag after 600 idle ticks |
| Levels | R-LVL-1…4 for every level in the catalog |
| Letterbox | Aspect fit on tall and wide views; touch → cell round trip |
| Progress | Unlock rules, paywall gating, best stars kept, JSON round trip, corrupt-file recovery |
| App (manual / XCUITest later) | 60 fps on device, haptics, IAP purchase and restore in sandbox |
