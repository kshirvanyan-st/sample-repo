# 02 — PRD: Grainfall

| | |
|---|---|
| Status | Draft v1 |
| Platform | iPhone (iOS 17+), portrait. iPad runs it in compatibility mode at v1. |
| Engine | Studio Metal engine (bulkhead/matchday lineage) — see `03-spec.md` § Engine integration |
| Business model | Free download, one-time "Full Game" in-app purchase, no ads, no tracking |

## 1. Summary
Grainfall is a pixel-physics puzzle game. Every grain of sand, drop of water and blob of lava is
simulated. Spouts pour material; the player **digs through dirt with a finger** and **taps gates
open** to steer the flow into the cup. Materials react with each other: water cools lava into
stone, lava sets plants on fire, fire boils water into steam. Each level is a small machine to
solve, and watching the solution pour into place is the reward.

## 2. Problem & opportunity
- People love satisfying "pour" physics: falling-sand videos get millions of views, and
  *Where's My Water?* proved a dig-to-route puzzle can top the paid charts.
- Today's games in this space are either ad-heavy hypercasual games (shallow and intrusive) or
  open sandboxes (no goals). There is no polished premium **puzzle** game built on rich
  multi-element pixel physics.
- A deterministic cellular simulation lets a small team ship many levels that are verified by
  automated tests.

## 3. Target players
| Persona | Description | What they need |
|---|---|---|
| **Commuter puzzler** (primary) | 25–45, plays 5–15 min sessions, likes *Monument Valley*, *Where's My Water?*, *Two Dots* | Short levels, instant restart, no ads, clear progress |
| **Satisfaction seeker** | 16–30, found it through a TikTok/Reels clip of sand pouring | Gorgeous physics in the first 10 seconds, no tutorial wall |
| **Completionist** | Any age, chases 3 stars everywhere | Star ratings that reward efficient (minimal) digging |

Age rating target: **4+**. Accessible to kids, with no chat, ads or links out of the app.

## 4. Goals & success metrics
| Metric | Target (first 90 days) |
|---|---|
| Store conversion (page view → install) | ≥ 35% |
| D1 / D7 / D30 retention | ≥ 40% / ≥ 15% / ≥ 6% |
| Free → Full Game conversion | ≥ 4% of installs |
| App Store rating | ≥ 4.6 |
| Crash-free sessions | ≥ 99.8% |
| Level 1 completion | ≥ 90% of new players |

We don't put analytics SDKs in v1, so we measure through **App Store Connect App Analytics** and
**Xcode Organizer**. Both are aggregate, opt-in data from Apple and don't affect our "Data Not
Collected" privacy label.

**Non-goals for v1:** multiplayer, user-generated levels, ads, accounts, cloud backend, Android.

## 5. Core gameplay

### 5.1 Core loop
1. A level opens with its spouts paused for one second, so the player can read the board.
2. Spouts start pouring. The player digs and taps gates while material flows.
3. A cup's counter fills as matching grains land in it. When every cup is full, the level is won.
4. The results screen shows 1–3 stars based on how little the player dug. Next level is one tap away.
5. Restart is always one tap and instant. Nothing interrupts the restart flow.

### 5.2 Player verbs
| Verb | Gesture | Rule |
|---|---|---|
| **Dig** | Drag a finger | Removes *dirt* in a small radius along the drag. Each removed cell uses up **dig budget**. Walls, stone and gates can't be dug. |
| **Open gate** | Tap a gate | Removes that gate completely (one-way, like pulling a pin). |
| **Restart** | Button | Instantly resets the level. |
| **Pause** | Button | Freezes the simulation; menu has Resume, Restart, Levels. |

### 5.3 Materials (v1)
| Material | Behaviour | Key interactions |
|---|---|---|
| Empty | — | — |
| Wall | Static, indestructible | — |
| Dirt | Static, **diggable** | — |
| Sand | Powder: falls, slides diagonally, piles up | Sinks through water |
| Water | Liquid: falls, spreads sideways quickly | Cools lava → stone; puts out fire → steam; feeds plants |
| Lava | Heavy, slow liquid | + water → stone (+ steam); ignites plants |
| Stone | Static (formed from lava) | Builds bridges and plugs |
| Steam | Gas: rises, fades | — |
| Plant | Static, grows slowly into touching water | Burns |
| Fire | Short-lived, flickers upward | Spreads through plants; water puts it out |
| Gate | Static until tapped | — |

### 5.4 Goals, failure, scoring
- **Cup** (goal): a marked area that accepts one material and needs N grains of it.
  A cup can also have **forbidden** materials. If one gets in (for example lava into the plant
  pot), the cup is ruined and the level fails at once with a clear reason.
- **Stuck detection:** if every spout is empty and no cup has made progress for 10 seconds, the
  game offers a gentle "Stuck? Try again" prompt. It doesn't end the level by force.
- **Stars:** 3★ for digging at or under the level's 3-star par, 2★ under the 2-star par,
  otherwise 1★. CI checks each level's reference solution against its par.

### 5.5 Progression & content
- Levels are grouped into **chapters** of 10 levels. Each chapter introduces one idea and then
  remixes it.
- Levels unlock in order, and finishing a chapter unlocks the next one (subject to purchase).
- **Launch content:** 6 chapters / 60 levels:
  1. *First Grains* — digging, sand
  2. *Flow* — water, gates
  3. *Hot Stuff* — lava, contamination
  4. *Cool Down* — stone bridges and plugs
  5. *Overgrowth* — plants and fire
  6. *Alchemy* — everything mixed together
- **Post-launch:** a free chapter every 6–8 weeks (new materials: ice, acid, oil, gunpowder)
  to bring lapsed players back and earn App Store featuring.
- **Vertical slice (this repository's first milestone):** 3 chapters × 4 levels = 12 levels,
  covering sand, water, gates, lava, stone and fire.

### 5.6 Monetization
- **Free:** chapters 1–2.
- **Full Game** — non-consumable IAP, tier ≈ $3.99. Unlocks every current and future chapter.
- Paywall appears only when the player taps a locked chapter. It is never shown in the middle of
  a level and never as a pop-up.
- **Restore Purchases** in Settings and on the paywall (required by App Review).
- Family Sharing enabled for the IAP.
- No ads, no consumables, no hint currency in v1. (Hints could come later as a free feature, never sold.)

## 6. Experience requirements
- **Cold start to play:** ≤ 2 s on iPhone 12. First launch drops straight into Level 1, and the
  only tutorial is an animated finger hint ("Drag to dig").
- **Frame rate:** a solid 60 fps simulation on iPhone XS/11 and newer. The display can run at
  120 Hz on ProMotion while the simulation stays at a fixed 60 Hz.
- **Look:** chunky pixel art at about 3 points per cell. Each material has a few shades per pixel
  so piles look grainy. Dark backdrop so the materials stand out.
- **Feel:** light haptics while digging, a firmer tap when a gate opens, success haptics on win.
- **Audio (launch):** soft granular pour loops for each material, gate "clunk", win chime. A mute
  toggle in Settings. The vertical slice ships haptics only.
- **Accessibility:** Dynamic Type in menus, VoiceOver labels on every button, Reduce Motion
  respected in menu transitions, colour-blind-safe material palette (materials differ in
  brightness as well as hue, and cups show their material as an icon).
- **Localization at launch:** EN, plus ES, FR, DE, PT-BR, JA, KO, ZH-Hans, all short UI strings.

## 7. App Store & compliance requirements
- Bundle ID `com.<studio>.grainfall`. Version 1.0 (build numbers from CI).
- **Privacy:** no data collected. Ship `PrivacyInfo.xcprivacy` with no tracking, no collected
  data types and no required-reason APIs. Progress is a JSON file in Application Support, not
  UserDefaults. App Privacy label: *Data Not Collected*.
- **Export compliance:** `ITSAppUsesNonExemptEncryption = NO`.
- App icon 1024 px, launch screen, iPhone 6.9" and 6.5" screenshots, a 15–30 s App Preview
  video showing a pour into a cup.
- Uses only public APIs (Metal, UIKit, SwiftUI, StoreKit 2). No private APIs or dynamic code.
- The game is fully playable offline.

## 8. Release plan
| Milestone | Content | Exit criteria |
|---|---|---|
| M1 Vertical slice | Simulation, renderer, 12 levels, save, IAP stub, haptics | All levels CI-solvable; 60 fps on iPhone 11 |
| M2 Content complete | 60 levels, audio, localization, icon/art pass | Internal playtest: level 1–20 completion ≥ 80% |
| M3 TestFlight beta | 200 external testers | Crash-free ≥ 99.5%, D1 ≥ 35% |
| M4 Launch | App Store submission, preview video, press kit | Approved; featuring nomination submitted via App Store Connect |

## 9. Risks
| Risk | Mitigation |
|---|---|
| Physics feels random → frustration | Fixed-step, seeded simulation; every level has a CI-verified solution with margin |
| Seen as a sandbox clone | Lead marketing with puzzles and reactions, not the sandbox |
| Performance on older devices | 128×240 grid; profile on the oldest supported device each milestone |
| App Review rejection for IAP | Restore button, clear paywall copy, StoreKit configuration tested in TestFlight |
| Engine integration slips | The simulation core is engine-agnostic Swift; rendering sits behind a thin adapter |
