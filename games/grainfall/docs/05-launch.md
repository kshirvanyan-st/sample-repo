# 05 — Launch checklist: Grainfall 1.0

Everything in the repository is ready to build. This list covers what has to happen in Apple's
portals and on real devices, in order.

## 1. Identity & signing
- [ ] Pick the studio reverse-DNS prefix and replace `com.yourstudio` in:
  - `App/project.yml` (`bundleIdPrefix`, `PRODUCT_BUNDLE_IDENTIFIER`)
  - `App/Sources/Services/StoreService.swift` (`fullGameID`)
  - `App/Grainfall.storekit` (`productID`)
- [ ] Register the App ID with the **Game Center** and **In-App Purchase** capabilities.
- [ ] Set `DEVELOPMENT_TEAM` in `project.yml`, or pass it to `xcodebuild`.

## 2. App Store Connect — app record
- [ ] New app "Grainfall: Pixel Pour Puzzle", primary language English (U.S.).
- [ ] Category: Games → Puzzle, secondary Casual. Age rating questionnaire: no objectionable
      content, so the rating is **4+**.
- [ ] App Privacy: **Data Not Collected**. This matches `PrivacyInfo.xcprivacy`: no SDKs, no
      tracking, progress stored on device only.
- [ ] Export compliance: answered by `ITSAppUsesNonExemptEncryption = NO` in Info.plist.
- [ ] Upload the metadata in `AppStore/metadata/` (fastlane `deliver` layout) and the
      screenshots in `AppStore/screenshots/` (6.9" set; App Store Connect scales it for
      smaller iPhones).
- [ ] Support, marketing and privacy URLs. Placeholders are in `metadata/en-US/*_url.txt`.

## 3. In-App Purchase (see 04-monetization.md)
- [ ] Non-consumable `com.<studio>.grainfall.fullgame`, "Full Game", price $4.99, Family
      Sharing **on**.
- [ ] Price schedule: $2.99 for the first 14 days after release, then $4.99.
- [ ] Review screenshot of the paywall plus review notes ("Unlocks chapters 3–6. Restore in
      Settings and on the paywall.").
- [ ] Enrol in the App Store Small Business Program (15% commission).

## 4. Game Center
Create these in App Store Connect → Game Center. The IDs must match `GameCenter.swift`.

| Type | ID | Details |
|---|---|---|
| Leaderboard (classic, high score, integer) | `grainfall.total_stars` | "Total Stars", max 180 |
| Achievement ×6 | `grainfall.chapter{1…6}.complete` | "Chapter N complete", reported as % progress |
| Achievement ×6 | `grainfall.chapter{1…6}.perfect` | "All stars in chapter N", hidden until earned |

## 5. Builds
- [ ] `cd App && xcodegen && xcodebuild -scheme Grainfall -configuration Release archive`
      (or Xcode → Product → Archive), then upload.
- [ ] Bump `CURRENT_PROJECT_VERSION` in `project.yml` for every upload.
- [ ] CI (`.github/workflows/grainfall.yml`) must be green: core tests, all 60 levels
      validated, and the iOS build.

## 6. Device QA (before TestFlight external)
- [ ] 60 fps on the oldest supported device (iPhone XS/11). Check the Metal frame time in
      Instruments.
- [ ] First launch drops into 1-1 with the tutorial hand. Finishing 2-10 opens the paywall.
- [ ] Sandbox purchase, Restore, Ask to Buy (pending state), refund (entitlement revoked on
      next launch).
- [ ] Silent switch mutes audio (ambient session), and the player's own music keeps playing.
- [ ] VoiceOver walk-through of the menus; Dynamic Type at the largest sizes in Settings.
- [ ] All 7 languages: launch with each locale and check that no strings are truncated.
- [ ] Game Center sign-in prompt appears once; achievement banners show.

## 7. Release
- [ ] TestFlight: 2 weeks with 100–200 external testers. Targets: crash-free ≥ 99.5%,
      D1 ≥ 35% (App Store Connect metrics).
- [ ] Submit the featuring nomination (App Store Connect → Featuring) 6–8 weeks before the
      release date.
- [ ] Phased release on, so problems can be paused.
- [ ] Launch-day content: three 15-second pour clips (record the Simulator, or use
      `grainfall-sim render` frame sequences).
