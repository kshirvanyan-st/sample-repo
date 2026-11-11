# 01 — Ideation: 2D pixel physics puzzle for the App Store

**Goal:** a premium-feeling 2D pixel-art physics puzzle for iPhone, built on our Metal engine.
It should be easy to pick up and look striking in App Store screenshots and short video ads.
It also needs to be small enough for a small team to ship and keep updating.

## How ideas were scored

Each idea is scored 1–5 on six criteria. Weights reflect what drives installs and retention for
a small-studio puzzle game on iOS.

| Criterion | Weight | What it measures |
|---|---|---|
| Hook / ad-ability | 25% | Can a 3-second clip or one screenshot sell it? (CPI driver) |
| Proven demand | 20% | Have comparable games hit 10M+ installs or top-chart ranks? |
| Depth & retention | 20% | Can mechanics combine into 100+ levels without feeling repetitive? |
| Differentiation | 15% | Does it avoid looking like a clone in a saturated sub-genre? |
| Build feasibility | 10% | Fits a pixel-grid simulation on a Metal 2D renderer; small team; ~3 months |
| Monetization fit | 10% | Works with a premium unlock and no ads (simpler privacy, better reviews) |

## Top 5 ideas

### 1. Grainfall — falling-sand routing puzzle
Every pixel is simulated: sand, water, lava, steam, plants and fire. Spouts pour material, and the
player **digs through dirt with a finger** and **taps gates open** to guide the flow into the cup.
Elements react: lava + water → stone, lava + plant → fire, fire + water → steam. Later puzzles use
these reactions. For example, you pour water on lava to build a stone bridge, or burn a vine wall
to open a path.
- **Comps:** *Where's My Water?* (Disney, #1 paid iOS app in 2011, 2B+ plays in the franchise),
  *Sand Balls* and *Pull the Pin* (100M+ hypercasual installs each), *The Powder Toy* /
  *Sandspiel* (viral sandboxes), *Noita* (pixel-physics critical hit).
- **Why it works:** pouring sand and water is satisfying to watch on its own, and that makes it
  strong ad and TikTok material. It has the proven "dig a path" control scheme plus a chemistry
  layer that hypercasual competitors lack.
- **Risk:** the sandbox genre is well known; we stand out through hand-made puzzles, a pixel-art
  look, and reactions as puzzle mechanics.

### 2. Inkbridge — draw-to-solve rigid physics
Draw pixel shapes that turn into rigid bodies (bridges, ramps, wedges) to get a ball to the goal.
- **Comps:** *Brain It On!* (50M+), *Draw Physics*, *Happy Glass* (100M+).
- **Why:** proven, creative, and every solution is different.
- **Risk:** very crowded with near-identical games. Needs a robust rigid-body solver (polygon
  decomposition of drawn strokes), which is a large engine investment that doesn't use our
  pixel-grid strengths.

### 3. Topple — pixel demolition
Place a limited number of charges so a destructible pixel tower collapses into a target zone
without hitting bystanders.
- **Comps:** *Demolition Master*, *Angry Birds* (destruction appeal), *Teardown* (style).
- **Why:** explosions get clicks.
- **Risk:** needs both rigid-body fragments and cellular debris. Outcomes are chaotic, so puzzles
  feel random and replay poorly. Hardest to make deterministic.

### 4. Pinpop — pin-pull color mixing
Pull pins in the right order to release coloured liquids that must mix into a target colour.
- **Comps:** *Pull the Pin* (Popcore, 100M+), *Water Sort* (100M+).
- **Why:** proven, very cheap to build.
- **Risk:** extremely saturated. Shallow, with little skill expression. Usually ad-funded,
  which conflicts with a premium App Store positioning. High clone perception.

### 5. Tiltling — gravity-rotation soft body
Rotate the world to roll a squishy pixel creature through a maze full of hazards.
- **Comps:** *Tilt Maze*, *Gravity Guy*, *Monument Valley* (rotation-as-puzzle).
- **Why:** charming character, good for brand.
- **Risk:** soft-body physics is costly. Motion controls are divisive. Narrower audience.

## Scores

| Idea | Hook (25) | Demand (20) | Depth (20) | Diff. (15) | Build (10) | Money (10) | **Weighted** |
|---|---|---|---|---|---|---|---|
| **1. Grainfall** | 5 | 5 | 5 | 4 | 4 | 4 | **4.65** |
| 2. Inkbridge | 4 | 4 | 4 | 2 | 2 | 3 | 3.40 |
| 3. Topple | 5 | 3 | 3 | 3 | 2 | 3 | 3.40 |
| 4. Pinpop | 3 | 5 | 2 | 1 | 5 | 2 | 3.00 |
| 5. Tiltling | 3 | 2 | 3 | 4 | 2 | 4 | 2.95 |

(Weighted = Σ score × weight; e.g. Grainfall = 5·.25 + 5·.20 + 5·.20 + 4·.15 + 4·.10 + 4·.10.)

## Decision: **Grainfall**

1. **Most likely to attract users.** A pour of sand into a cup is the most thumb-stopping visual
   of the five ideas, and that drives the cheapest installs. The "dig with your finger" control
   needs no tutorial text.
2. **Proven demand, without being a clone.** It mixes the *Where's My Water?* dig mechanic with
   the *Pull the Pin* gate mechanic, both proven at large scale. Element chemistry adds depth those
   games never had.
3. **Fits a pixel-grid engine.** A cellular-automaton simulation on a fixed grid is cheap: 30k
   cells is about 0.3 ms per tick on an A-series chip. The whole frame becomes a single texture
   upload and one draw call in Metal. No rigid-body solver needed.
4. **Deterministic, so content scales.** Seeded simulation and replayable solutions let CI
   prove every level is solvable and check its star thresholds. That lets us ship 100+ levels
   without manual QA on each one.
5. **Clean monetization.** Free first chapters plus a one-time "Full Game" unlock. No ads and no
   tracking, so the App Store privacy label says "Data Not Collected", which helps conversion and
   reviews.

Before launch, check that "Grainfall" is free as an App Store name and trademark. Backup names:
*Siftworks*, *Pourly*, *Grain & Flow*.
