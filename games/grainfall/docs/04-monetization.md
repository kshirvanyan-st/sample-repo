# 04 — Monetization plan: Grainfall

Written after the game was built: it reflects the shipped content (60 levels, 6 chapters,
2 free) and the features that already exist (paywall, Restore, Family Sharing, share button,
review prompt, Game Center).

## 1. Principles

1. **Free to start, pay once to finish.** The game is a puzzle box with an end. A one-time unlock
   matches what players expect from a premium-feeling puzzler. Subscriptions and energy timers
   don't fit.
2. **No ads, no tracking, no consumables that affect gameplay.** This protects the 4+ rating, the
   "Data Not Collected" privacy label, review scores, and our chance of being featured by Apple
   editors. Those editors favour games built this way.
3. **Never interrupt play.** The paywall appears only when the player taps a locked chapter or
   finishes the last free level. It never appears mid-level or as a pop-up on launch.
4. **Keep the promise.** "Every future chapter included" is in the paywall copy. Later chapters
   are retention and word-of-mouth tools, not new SKUs.

## 2. Product catalog

### Launch (v1.0) — implemented
| Product | Type | US price | Notes |
|---|---|---|---|
| `…grainfall.fullgame` | Non-consumable | **$4.99** (launch promo $2.99 for 14 days) | Unlocks chapters 3–6 and all future chapters. Family Sharing on. |

**Why $4.99:** comparable premium puzzlers sell at $3.99–$6.99:
- *Monument Valley*: $3.99
- *Mini Metro*: $4.99 full unlock
- *Where's My Water? 2*: chapter packs around $1.99 each
- *Baba Is You*: $6.99

The free part is 20 levels, about 45–60 minutes. That's enough for players to feel the value
and the "one more level" pull before they're asked to pay. The launch promo uses an App Store
price schedule. It creates urgency for launch-week press and featuring, then reverts automatically.

### v1.1 — optional, cosmetic only (planned, not built)
| Product | Type | Price | Notes |
|---|---|---|---|
| Palette Pack (Neon, Handheld, Sunset, Mono) | Non-consumable | $1.99 | Re-skins the palette (`Palette.shades`). Zero gameplay effect. Shown in Settings and once on the results screen after chapter 6. |
| Tip Jar (Small / Medium / Large) | Consumable | $0.99 / $2.99 / $9.99 | "Support a small studio". Each tip adds a name card to the credits screen. Never prompted, only listed in Settings. |

Both are low-pressure extras for players who already love the game. Expect +8–12% revenue on
top of the unlock, without touching the core promise.

### Not recommended
- **Rewarded or interstitial ads.** They break the brand and the privacy label, and they
  depress ratings. The revenue from a puzzle audience of this size wouldn't cover the cost.
- **Paid hints or currency.** Hints are free and unlock after 15 s or one retry. Selling help
  in a puzzle game reads as pay-to-win, and reviewers notice.
- **Subscription.** Nothing recurring to deliver, and churn would be immediate.

### Alternative: Apple Arcade
Grainfall fits Apple Arcade on paper: no ads, no IAP, offline, family-friendly and polished.
Before launch, **pitch it to Arcade**. A deal pays upfront and removes the need for user
acquisition, but it requires exclusivity and removing the IAP. If they decline, launch with the
model above. The build supports both: in an Arcade build, set every chapter in `chapters.json`
to `"free": true` and hide the paywall.

## 3. Pricing by region
- Use App Store Connect's automatic price equalization from the US base price.
- Lower prices by hand where the default is high relative to purchasing power: India, Brazil,
  Indonesia, Türkiye, Vietnam, Philippines (≈ 40–60% of the equalized price). These are
  fast-growing puzzle markets where a lower price lifts conversion more than it costs per sale.
- Review prices after 60 days using the proceeds-per-country report.

## 4. Paywall placement & design (implemented)
| Moment | Behaviour |
|---|---|
| Finishing level 2-10 | **Next level** opens the paywall (via `AppModel.playNext`). It's the natural cliffhanger: the player has just mastered water and sees "Hot Stuff" next. |
| Tapping a locked chapter tile or **Unlock** in level select | Paywall sheet |
| Title screen | Quiet line "2 chapters free". No banner, no badge. |
| Settings | Unlock + Restore Purchases (App Review requirement) |

Paywall content: lava/fire icon, four plain benefit lines ("every chapter", "future chapters",
"no ads, ever", "Family Sharing"), the localized `displayPrice`, Restore, and a pending state for
Ask to Buy. **v1.1 improvement:** show a looping demo of 3-1 at the top, reusing the title
screen's `GameController` demo mode. Watching lava is the best sales pitch the game has.

## 5. Funnel model & targets

| Step | Target | Basis |
|---|---|---|
| Install → finish 1-1 | 90% | PRD; tutorial hand plus one-gesture level |
| → finish chapter 1 (10 levels) | 60% | Casual puzzle norms |
| → finish chapter 2 (sees paywall at 2-10) | 35% | |
| → paywall view (incl. browsing locked chapters) | 40% of installs | |
| → purchase | 12% of paywall viewers ≈ **4.8% of installs** | Premium-unlock puzzlers report 3–8% |

**Revenue per install** ≈ 4.8% × $4.99 × 0.85 (App Store Small Business Program, 15% commission)
≈ **$0.20**, or ≈ $0.22 with v1.1 cosmetics.

**Implication:** paid acquisition only pays back if cost per install stays under about $0.20.
Puzzle cost per install is usually $0.80–$2.50, so **growth must be organic**:

1. **Short-video content:** satisfying pour clips straight from `grainfall-sim render`/screen
   recordings, posted daily to TikTok, Reels and Shorts. This is the main channel for a
   "satisfying physics" game.
2. **App Store featuring:** submit the featuring nomination 6–8 weeks before launch.
   No ads, no tracking, full accessibility labels, Game Center and localization all count with
   editors.
3. **In-App Events:** one per new chapter ("Chapter 7: Ice Age is here").
4. **Product Page Optimization:** A/B test icon variants and first screenshot ("Every grain is
   simulated" vs "Dig. Pour. Solve.").
5. **Custom Product Pages:** one per short-video theme (lava, sand, water) so each video links to
   a page that matches it.
6. **Built-in virality:** the share button on the results screen produces a crisp pixel snapshot
   with "I solved level X of Grainfall with ★★★".
7. **Ratings:** the one-time review prompt fires after a 3-star win once the player has 8+ wins.

**Break-even example.** Assume 3 months of one developer plus art and sound at roughly $45k.
At $0.20–$0.22 per install, that needs ≈ 220k installs. That's realistic with one Apple feature
(typically 50–300k installs in a week) plus steady short-video traffic. Without a feature, plan
on 12–18 months to recoup.

## 6. Measurement (without tracking)
- **App Store Connect:** impressions → page views → installs (conversion), proceeds per
  country, retention cohorts (opt-in data from Apple), and paying users.
- **StoreKit:** purchases, refunds, Ask-to-Buy pending (already handled in `StoreService`).
- **Xcode Organizer:** crashes, hangs, energy.
- In-game funnel (chapter completion, paywall views) is **not** collected in v1, to keep "Data
  Not Collected". If we need it, add a privacy-preserving aggregate SDK (e.g. TelemetryDeck),
  update the privacy label to "Usage Data — not linked to identity", and treat it as a separate
  product decision.

## 7. Roadmap
| When | Content | Monetization |
|---|---|---|
| Launch | 60 levels, 6 chapters | Full Game $4.99, 14-day launch price $2.99 |
| +6 weeks | Chapter 7 (new material: ice) — free for owners | In-App Event; first price review |
| +10 weeks | v1.1 Palette Pack, Tip Jar, paywall demo loop | +8–12% revenue |
| +3 months | Chapter 8 (oil), daily challenge (seeded generator) | Daily challenge drives D30 retention |
| +6 months | iPad layout, Mac (Designed for iPad) | Same SKU, universal purchase |
| Any time | Apple Arcade conversation | Upfront deal; build switch already exists |

## 8. What's implemented vs. to do
- **Implemented:**
  - Full Game IAP via StoreKit 2: purchase, Restore, `Transaction.updates`, entitlement check on
    launch, Family Sharing flag in the StoreKit config
  - free/paid chapters in data, and the paywall
  - 2-10 → paywall flow, share button, review prompt, Game Center
- **To do in App Store Connect:**
  - create the IAP at $4.99 with the launch price schedule
  - enrol in the Small Business Program
  - set regional price overrides
  - create the leaderboard and achievements (IDs in `GameCenter.swift`)
- **v1.1 code:** palettes (a `Palette` variant selected in settings) and Tip Jar products in
  `StoreService`.
