# Grainfall

A pixel-physics puzzle game for iPhone. Every grain of sand, drop of water and blob of lava is
simulated. Dig through dirt and pull gates to pour the right material into each cup.

![All 12 vertical-slice levels, mid-solution](docs/levels.png)

| Doc | |
|---|---|
| [`docs/01-ideation.md`](docs/01-ideation.md) | Top 5 concepts, weighted scoring, why Grainfall |
| [`docs/02-prd.md`](docs/02-prd.md) | Product requirements: audience, loop, content, monetization, App Store compliance |
| [`docs/03-spec.md`](docs/03-spec.md) | Technical spec: simulation rules, level format, rendering, persistence, CI |

## Layout

```
Package.swift                 Swift package: GrainfallCore + grainfall-sim (builds on Linux and macOS)
Sources/GrainfallCore/        Engine-agnostic game logic: materials, simulation, levels, scoring, save data
  Resources/levels/           chapters.json + one JSON per level (with reference solution and traps)
Sources/grainfall-sim/        CLI: validate levels, trace, render PNG frames and level sheets
Tests/GrainfallCoreTests/     33 XCTest cases: materials, determinism, actions, cups, levels, progress
App/                          iOS app (XcodeGen): SwiftUI shell, Metal renderer, StoreKit 2, haptics
  project.yml                 → `xcodegen` generates Grainfall.xcodeproj
  Sources/Engine/             PixelSurface seam + Metal PixelRenderer, touch view, shaders
  Sources/Game/               GameController: fixed 60 Hz step, input → actions, HUD
  Sources/Views/              Title (live demo), level select, game HUD, results, paywall, settings
  Grainfall.storekit          Local StoreKit config for the Full Game IAP
tools/make_icon.py            Regenerates the pixel-art app icon
```

## Build & test

Core and levels (Linux or macOS, Swift 5.9+):

```sh
swift test -c release -Xswiftc -enable-testing     # release: the debug simulation is ~50× slower
swift run -c release grainfall-sim validate        # every level: needs input, solvable at 3★, traps hold
swift run -c release grainfall-sim render 3-1 400 out.png --solve
swift run -c release grainfall-sim sheet docs/levels.png --scale 2
```

iOS app (macOS, Xcode 16+):

```sh
brew install xcodegen
cd App && xcodegen && open Grainfall.xcodeproj
```

Run the `Grainfall` scheme. It uses `Grainfall.storekit`, so the Full Game purchase works in the
Simulator without App Store Connect.

## Authoring a level

1. Add `Sources/GrainfallCore/Resources/levels/<id>.json` (format in spec §3) and list it in `chapters.json`.
2. Iterate with `grainfall-sim render <id> <tick> out.png [--solve]` and `trace <id> --solve`.
3. Add a `solution` (scripted digs/gate taps) and at least one `trap` for the obvious wrong idea.
4. Set `par` to [1.5×, 2.5×] of the solution's dig cost and `digBudget` to 3×. `validate` prints the cost.

## Engine integration

The studio Metal engine (bulkhead/matchday) wasn't available when this was built, so `App/Sources/Engine`
has a minimal Metal layer behind the `PixelSurface` seam: one texture upload and one draw per
frame. To move onto the studio engine, implement that seam with its sprite/texture path, call
`GameController.frame(now:)` from its frame callback, and forward its pointer events to
`GameController.touch`. `GrainfallCore` doesn't change.

## Before App Store submission

- [ ] Replace `com.yourstudio` (bundle ID, IAP product ID in `StoreService` and `Grainfall.storekit`) and set `DEVELOPMENT_TEAM`.
- [ ] Create the non-consumable `…fullgame` IAP in App Store Connect (Family Sharing on), with a review screenshot of the paywall.
- [ ] App Privacy: *Data Not Collected* (matches `PrivacyInfo.xcprivacy`). Age rating 4+.
- [ ] Final icon art, 6.9" and 6.5" screenshots (`grainfall-sim render` gives pixel-exact frames), App Preview video.
- [ ] Device pass: 60 fps on iPhone 11, haptics, purchase and restore in the sandbox, TestFlight beta.

## Status: vertical slice (PRD milestone M1)

Done: simulation with 10 materials and reactions; 12 levels in 3 chapters, all CI-verified;
Metal renderer; touch digging and gates; HUD; stars and progress; paywall and restore; settings;
haptics; title-screen live demo; privacy manifest; icon placeholder.

Not done yet (M2+): audio, localization, the remaining 48 levels, final art, XCUITests,
Game Center. The iOS target hasn't been compiled yet: it was written on Linux, where only the core
package and CLI could be built. The `ios` CI job is the first compile, so expect to fix a few
small Xcode issues on the first run.
