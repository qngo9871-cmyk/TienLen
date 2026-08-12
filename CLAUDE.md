# Tiến Lên — Vietnamese Card Game

Native SwiftUI iOS app for Tiến Lên (Miền Nam / Southern ruleset), the most widely played
Vietnamese shedding card game. Bundle `com.quyenngo.tienlen`. App #1 of a planned 5-app
Vietnamese-games lineup for the same developer, forked from the sibling app `~/Projects/SamLoc`
(Sâm Lốc, already shipped) — read `~/Projects/SamLoc/CLAUDE.md` for that app's history if useful
background, but **do not assume its ruleset applies here**. The two games share a lot of
structure (4 players, combo-beating shedding, tới trắng instant wins, StoreKit Pro unlock,
true bilingual UI) but the actual game logic genuinely differs in several places — see below.

**Status: 🟡 READY FOR RESUBMISSION — scheduled batch 4, 2026-08-28 (pending Apple's Guideline
5.6 hold clearing 2026-08-18).** The whole developer account (19 apps, this one included) got
hit with a Guideline 5.6 "Developer Code of Conduct — Review Suspended" account-level flag,
almost certainly triggered by submitting ~19 similar template-style apps within an 8-day window
(2026-08-01–2026-08-08). Resubmission is hard-blocked until 2026-08-18 — do not attempt any
App Store Connect submit/review-submission action before then (metadata/screenshot pushes are
fine, per `~/Projects/app-store-rejections/NOTES.md`). ASC state as of this session's metadata
push (2026-08-12): app id `6796833065`, version `1.0.2` (id
`3e15840d-4255-48f1-83fc-420fe8cf4ddf`, state `REJECTED`, still editable). No build attached yet
for 1.0.2 — that step (archive/export/upload via the pipeline below) still needs to happen before
the batch-4 submission on 2026-08-28. Release type: automatic (`AFTER_APPROVAL`).

## Polish pass (2026-08-12)

Second, deeper pre-resubmission pass (first pass was 2026-08-09, see below). Scope: re-verify
the 08-09 fixes are still solid, fix real UI/polish issues, refresh ASO copy. Nothing submitted
to review — metadata/screenshot pushes only, per the resubmission-block rule.

- **Card-back Pro feature re-verified live, with screenshot evidence — genuinely works.** This
  was the highest-stakes check for this app (the 08-09 pass built a feature that had previously
  been sold-but-never-built). Read the source end-to-end
  (`CardBackStyle.swift`/`CardView.swift`/`GameView.swift`/`UpgradeView.swift`): `GameView`'s
  `effectiveBackStyle` correctly falls back to Classic if a Pro style is selected without
  `purchases.isPro`, and `UpgradeView` only renders the picker at all once `purchases.isPro` is
  true — free users have no UI path to a Pro-only back. Then verified live in the simulator, not
  just by reading code: launched with `TL_CAPTURE=upgrade`, confirmed the 3-swatch picker
  (Classic Red / Royal Blue / Jade Bamboo) renders and is selectable; set
  `defaults write com.quyenngo.tienlen cardBackStyle royal` and relaunched with
  `TL_CAPTURE=midgame` — opponents' face-down hands actually rendered the Royal Blue design
  (star icon, blue gradient) instead of the default red/club back. Confirmed genuinely wired,
  not cosmetic-only.
- **Bug found and fixed: `screenshots/final/{en,vi}/04-upgrade.png` were stale**, predating the
  card-back picker (the 08-09 pass flagged this as an open, non-blocking item and never
  recaptured). Recaptured all 10 shots via `capture_shots.py`
  (`TL_DEVICE_UDID=<TienLen-Shots UDID>`); the new `04-upgrade.png` for both locales now shows
  the picker, a genuine differentiator worth showing off. All 10 re-inspected visually — correct
  diacritics, no clipping, no dead-space-below-bottom-control layout bug (checked for the
  recurring class of bug found in other apps this session; not present here).
- **Bug found and fixed: ASC en-US subtitle was in Vietnamese.** `LOCALES["en-US"]["subtitle"]`
  in `asc_push_tienlen.py` was a copy-paste of the `vi` subtitle ("Chơi Tiến Lên Cùng AI"),
  wasting a heavily search-weighted field on the English storefront. Changed to
  "Real Rules, Offline vs AI" (25 chars).
- **ASO refresh**: description/promo copy was already strong (accurate, specific ruleset detail,
  not generic template filler) so left mostly as-is, but neither locale's description or promo
  mentioned the card-back Pro feature even though it's now real — added a bullet to both
  locales' description ("PLAY YOUR WAY" / "CHƠI THEO CÁCH CỦA BẠN") and a clause to both promo
  texts. en-US keywords: dropped "vietnamese card game" and "card game" (redundant with the
  indexed app name "Tiến Lên - Vietnamese Cards"), added "chặt heo,tới trắng" (present in the vi
  keyword list already, high-value diaspora search terms, previously missing from en-US).
- **Two push-script bugs found and fixed in `~/asc-tools/asc_push_tienlen.py`** (committed
  separately in the asc-tools repo):
  1. `find_or_create_version` hardcoded `versionString: "1.0.0"` unconditionally — every push
     would silently force the ASC version back down to 1.0.0 regardless of the app's actual
     local version (already 1.0.1 going into this session, now 1.0.2), which would have desynced
     ASC from the built binary's `CFBundleShortVersionString` at submit time. Replaced with a
     `VERSION_STRING` module constant kept in sync with `project.yml`.
  2. `set_iap_localization` had no error handling, unlike its sibling `create_or_update_iap`
     (which already degrades gracefully) — a locked `IAP_VERSION_UNMODIFIABLE` state (pre-existing
     server-side, not caused by this session) crashed the whole script with an unhandled
     `RuntimeError` before pricing ever ran. Wrapped in the same graceful-degradation pattern.
  3. Also found (informational, not fixed — `find_app_info` only had one candidate `appInfo` to
     choose from this time, so the "picks a locked one instead of REJECTED" failure mode from
     Klotski's script didn't actually manifest here): verified via direct API query that this
     app has exactly one `appInfo`, state `REJECTED`, so no ambiguity risk currently exists.
- **Version bump**: `MARKETING_VERSION` 1.0.1 → **1.0.2**, `CURRENT_PROJECT_VERSION` 3 → **4**.
  Note `project.yml` has both a project-level `settings.base` block and a target-level
  `targets.TienLen.settings.base` block with their own copies of these two keys — XcodeGen's
  target-level settings win, so **both** must be edited or the bump silently no-ops on the built
  binary (the project-level block was already stale/inert from a previous pass). Confirmed via
  `PlistBuddy` against the freshly built `.app`'s `Info.plist`: `CFBundleShortVersionString` =
  1.0.2, `CFBundleVersion` = 4.
- **Rebuilt clean after all changes**: `xcodegen generate` + `xcodebuild clean build` for
  `platform=iOS Simulator,name=iPhone 17` — BUILD SUCCEEDED, zero warnings.
- **Pushed to ASC**: app-level metadata (name/subtitle/privacy URL), categories, version
  1.0.2 + both locales' description/keywords/promo/support URL, all 10 screenshots (order
  verified), app base price (Free), IAP price ($2.99) — all confirmed via a follow-up
  `asc_inspect_listing.py` read-back. IAP name/description localization patch was skipped
  (pre-existing locked state, not something this session broke — the live IAP copy was already
  accurate, mentioning card backs, from the 08-09 pass).
- **No build uploaded this session** — out of scope for this pass (would require the
  archive/export/upload pipeline below, which wasn't run since no submission is happening before
  2026-08-18 anyway). Needs to happen before the 2026-08-28 batch-4 submission.

## 2026-08-09 pre-resubmission quality review

Full local review pass (code/build/test only — nothing touched in ASC, per the resubmission
block). Summary written to `~/Projects/app-store-rejections/reviews/TienLen.md`; full detail
there, short version here:

- **Build**: clean `xcodegen generate` + `xcodebuild build` for iPhone 17 Simulator —
  BUILD SUCCEEDED, no errors, no real warnings.
- **Game logic**: hand-traced the full ruleset (combos, bomb-tier hierarchy, chặt heo,
  cóng/thối heo scoring, both tới trắng detectors) against `Combo.swift`/`AIPlayer.swift`/
  `GameModel.swift` — correct and complete, not a stub. No changes needed here.
- **Real bug found and fixed**: the Pro paywall advertised "Exclusive card back designs,"
  but that feature didn't exist anywhere in the code — `CardView` only ever rendered one
  hardcoded back regardless of purchase state. Also, `HomeView`'s only button that opened
  the paywall sheet was hidden entirely once a user went Pro, so a legitimate purchaser had
  no way back to it. Fixed both: added `Core/CardBackStyle.swift` (Classic Red free, Royal
  Blue + Jade Bamboo Pro-exclusive), wired it into `CardView`/`GameView`, added a picker to
  `UpgradeView`, and changed the Home button to stay visible (relabeled "Card Backs & Pro
  Settings" once owned). Verified live in Simulator: paywall picker renders, selecting Royal
  Blue actually changes opponents' card backs in-game.
- **Localization/onboarding/DEBUG-isPro-gating**: all checked, all fine as previously
  documented — bilingual UI is real (not listing-only), onboarding is real and forced on
  first launch, no double-gating bug pattern present.
- **Version bump**: `MARKETING_VERSION` 1.0.0 → 1.0.1, `CURRENT_PROJECT_VERSION` 2 → 3.
  Confirmed landed correctly in the built `.app`'s `Info.plist` via `PlistBuddy`.
- **Open/optional**: `screenshots/final/{en,vi}/` predate the card-back picker UI change —
  optional reshoot via `capture_shots.py` before the next ASC push, not a blocker. Not run
  this session to avoid touching ASC-adjacent assets or racing sibling apps' capture
  scripts on shared simulators.

## Deploy / resubmit pattern

This machine has no Xcode-signed-in Apple ID account and no pre-installed Distribution
certificate — plain `xcodebuild archive`/`-exportArchive` fails with "No Accounts." Pass
the App Store Connect API key explicitly instead (see
[[feedback_asc_release_and_signing]]):
```
xcodegen generate
xcodebuild -project TienLen.xcodeproj -scheme TienLen -configuration Release \
  -archivePath build/TienLen.xcarchive -destination 'generic/platform=iOS' \
  -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016 \
  archive
xcodebuild -exportArchive -archivePath build/TienLen.xcarchive -exportPath build/export \
  -exportOptionsPlist ExportOptions.plist -allowProvisioningUpdates \
  -authenticationKeyPath /Users/q/.appstoreconnect/private_keys/AuthKey_G85WXB4AF5.p8 \
  -authenticationKeyID G85WXB4AF5 -authenticationKeyIssuerID 2e969722-fc4d-444c-af74-7e0233efd016
xcrun altool --upload-app --type ios -f build/export/TienLen.ipa \
  --apiKey G85WXB4AF5 --apiIssuer 2e969722-fc4d-444c-af74-7e0233efd016
```
After a new build finishes processing (`GET apps/6796833065/builds`, check
`processingState == VALID`), attach it to the version and re-submit:
`asc-tools/asc_push_tienlen.py` / `_review.py` / `_screenshots.py` are all idempotent —
re-run after changing copy. No `asc_submit_tienlen.py` script exists yet; submission was
done via one-off `reviewSubmissions` → `reviewSubmissionItems` → `PATCH submitted=true`
calls (see sibling `asc_submit_woktonight.py` for the reusable pattern to copy if this
needs to be resubmitted).

## What this is

- Standard 52-card deck, 4 players (you + 3 AI), **13 cards dealt each** — uses the entire
  deck exactly, no leftover (Sâm Lốc deals 10 of 52, leaving cards undealt).
- Combo-beating shedding game: singles, pairs, triples, straights (sảnh), four-of-a-kind
  (tứ quý), and pair-straight bombs (đôi thông, 3+ consecutive pairs) — the last shape
  doesn't exist in Sâm Lốc.
- Whoever holds 3♠ leads the first trick (same as Sâm Lốc).
- **"Tới trắng" instant-win detector**, only two kinds (trimmed from Sâm Lốc's five, since
  the other three — same-color, three-triples, five-pairs — are Sâm-Lốc-specific house
  rules, not standard Tiến Lên):
  - Sảnh Rồng (Dragon Straight, ×20 payout) — every rank 3 through Ace represented in the
    dealt 13-card hand (12 distinct ranks, one necessarily duplicated to fill 13 cards; no
    2s at all).
  - Tứ Quý Heo (Four 2s, ×16 payout) — all four 2s dealt to one player.
- 3-tier AI (Easy/Normal/Hard) — Hard uses card-usefulness heuristics, not just legal-move
  selection. `AIPlayer.legalPlays` generates any-suit straights and pair-straight bombs
  (Sâm Lốc's generator only produces same-suit straights).
- StoreKit 2 non-consumable IAP `com.quyenngo.tienlen.pro` ($2.99, matches the SamLoc /
  Klotski / ShogiDo price point — actual App Store price tier is set in the ASC push
  script during the submission step, not in Swift) — unlocks Hard AI + alternate card
  backs. Free tier: Easy + Normal AI, full rules, no ads ever, no gambling mechanics.
- **True bilingual in-app UI** — `Core/Localization.swift` (copied verbatim from SamLoc,
  it's app-agnostic) is a manual bundle-swap `LocalizationManager` that loads
  `en.lproj`/`vi.lproj` `Localizable.strings` at runtime, with a live segmented-control
  language switch on the Home screen. Both locales hand-written, not machine-translated.

## Ruleset differences from Sâm Lốc — read this before touching game logic

Tiến Lên and Sâm Lốc are different games; SamLoc's `CLAUDE.md` warns about this same trap
in the other direction. Concretely, what's different here:

1. **13-card deal from the full 52-card deck** (Sâm Lốc: 10 cards, deck not fully dealt).
2. **Straights (sảnh) are NOT same-suit-only.** `Combo.make` and `AIPlayer.legalPlays`
   accept any suits for a straight — only rank sequence matters (3+ consecutive ranks, no
   2s). Suit is still the tie-break for comparing same-rank singles, it just doesn't gate
   straight legality.
3. **New shape: pair-straight bomb ("đôi thông")** — 3+ consecutive pairs (6+ cards), e.g.
   4♠4♣-5♦5♥-6♠6♣. `ComboShape.pairStraight(length:)`, length = number of pairs.
4. **Bomb hierarchy spans multiple shapes**, not just "four of a kind beats everything."
   Weakest → strongest: 3-pair straight < four-of-a-kind < 4-pair straight < 5-pair
   straight < ... — implemented as `ComboShape.bombTier` (an `Int?`, nil = not a bomb).
   `Combo.beats` compares bomb tier first, then rank within the same tier. A bomb beats
   any non-bomb combo regardless of shape (including cutting a lone 2 on the table —
   "chặt heo"). This is all still strictly in-turn, no out-of-turn interrupts.
5. **No "báo sâm" declare mechanic.** Sâm Lốc's mid-game declare-and-double-or-nothing
   doesn't exist in standard Tiến Lên and was not ported — no `declareSam` /
   `samDeclareAvailable` / `canDeclareSam` anywhere in this codebase, no declare button in
   `GameView`, no "Báo Sâm" strings.
6. **No "can't finish on a lone 2" restriction.** `GameModel.play` has no equivalent of
   Sâm Lốc's `isLoneTwo` finishing check — in Tiến Lên you can legally go out by playing a
   single 2 as your last card. (`Combo.isLoneTwo` doesn't even exist in this codebase;
   it was Sâm-Lốc-specific.)
7. **New "cóng" (skunked) scoring rule.** `Player.hasPlayed` tracks whether a player ever
   laid down a single card during the round. In `GameModel.endRound`, any losing player
   who never played a card gets their penalty **tripled**, stacking multiplicatively on
   top of the existing "thối heo" (unplayed-2s) and held-quad penalties — it does not
   replace them. There's no "declaredSam ×2" multiplier here since báo sâm doesn't exist.

## Structure

- `TienLen/Core/` — `Card.swift` (verbatim reuse from SamLoc — Rank/Suit are unchanged),
  `Combo.swift` (rewritten shape/beats logic, see above), `Player.swift` (dropped
  declaredSam/samFailed, added `hasPlayed`), `AIPlayer.swift` (new straight/pair-straight
  generation), `GameModel.swift` (+ `GameModel+Capture.swift` for the screenshot hook),
  `InstantWin.swift` (trimmed to 2 kinds), `PurchaseManager.swift` (verbatim except
  productID), `Localization.swift` (verbatim, app-agnostic).
- `TienLen/Views/` — `HomeView`, `GameView` (declare-sâm button removed, opponent hand
  row shows up to 13 cards), `CardView`, `RulesView` (sections swapped: "Bombs & Chặt Heo"
  and "Cóng" replace Sâm Lốc's "Lone 2" and "Báo Sâm" sections), `OnboardingView`,
  `UpgradeView` (verbatim — same 3 feature rows: Hard AI / alternate card backs / no ads;
  this is a 4-AI-opponent game like Sâm Lốc, not 1v1, so no "play vs friend" framing).
- `TienLen/{en,vi}.lproj/Localizable.strings` — hand-written bilingual UI strings using
  correct Tiến Lên terminology (sảnh, đôi thông, tứ quý, chặt heo, cóng, thối heo). English
  strings using `%@` for a player name were audited against the known SamLoc grammar trap
  (a name-substitution string that reads wrong when `%@` = "You") — all of them use past
  tense or non-conjugated phrasing, so none break under substitution.
- `capture_shots.py` — adapted from SamLoc's, drives the simulator via
  `TL_CAPTURE`/`TL_LANG` DEBUG launch args (renamed from `SL_CAPTURE`/`SL_LANG`) into
  `screenshots/final/{en,vi}/`. Run and all 10 outputs verified — see "App Store readiness
  pass" below. Supports an optional `TL_DEVICE_UDID` env var to pin a specific simulator
  and avoid racing with sibling projects' capture scripts on the shared default device.
- `make_icon.py` — generates the real app icon (a tilted "3♠" emblem, since 3♠ leads the
  first trick) on SamLoc's exact felt-green gradient. Run — see "App Store readiness pass".
- `project.yml` — XcodeGen, forked from SamLoc's. Bundle `com.quyenngo.tienlen`, team
  `SM99L22Q84`, iOS 16.0 deployment target. Regenerate the `.xcodeproj` with
  `xcodegen generate` after adding/removing files, or just run `./rebuild.sh`.

## Judgment calls made where the spec was underspecified

- **Sảnh Rồng (Dragon Straight) definition**: the task brief's phrasing ("all 13 cards
  form one consecutive run 3→Ace... uses literally every non-2 rank once") is internally
  inconsistent — there are only 12 non-2 ranks (3..A), so 13 cards can't each be a
  distinct rank in that run. Implemented the standard real-world Tiến Lên definition
  instead: all 13 cards are non-2, and all 12 non-2 ranks are represented at least once
  (so exactly one rank is necessarily held twice to reach 13 cards). See
  `InstantWinDetector.isDragonStraight`.
- **Bomb-on-non-2 legality**: the spec's item 6 says bombs beat any non-bomb combo
  "regardless of shape," and separately calls out beating a lone 2 as "chặt heo." I
  implemented the general rule literally (a bomb can be dropped on top of any table combo,
  not just a lone 2) since that's also how the mechanic works in real Tiến Lên and the
  spec doesn't say to restrict it further — "chặt heo" is just the traditional name for
  the lone-2 case specifically.
- **Pair-straight can't include rank 2**, matching plain straights (`isStraightEligible`).
  Not explicitly stated for đôi thông, but consistent with every source describing it as
  built the same way as sảnh.
- **`GameModel+Capture.swift`** wasn't in the prompt's abbreviated Core file list, but
  `capture_shots.py` needs a `captureSetup` hook and "mirror SamLoc's layout exactly" was
  the overarching instruction, so it was kept as a separate extension file like SamLoc's.
- **PurchaseManager env var note**: the task brief asked for PurchaseManager.swift's
  `#if DEBUG` capture-flag env var to be renamed to `TL_CAPTURE`, but SamLoc's actual
  `PurchaseManager.swift` has no such env var (that flag lives in `ContentView.swift`).
  Renamed it there instead (`SL_CAPTURE`/`SL_LANG`/`SL_SKIP_ONBOARDING` →
  `TL_CAPTURE`/`TL_LANG`/`TL_SKIP_ONBOARDING`); PurchaseManager itself only changed its
  `productID`.

## Build

```
xcodegen generate
xcodebuild -project TienLen.xcodeproj -scheme TienLen -destination 'platform=iOS Simulator,name=iPhone 17' build
```
Builds clean, no errors or warnings, verified 2026-07-31 (both incremental and a full
`xcodebuild clean` + rebuild).

## App Store readiness pass (2026-07-31)

- **App icon**: done. `make_icon.py` generates a tilted oversized "3♠" card on the same
  felt-green gradient (`#0a2015` → dark) as SamLoc's icon, written to
  `TienLen/Assets.xcassets/AppIcon.appiconset/AppIcon.png` at 1024×1024. Fixed a real bug
  along the way — `AppIcon.appiconset/Contents.json` was missing the `"filename":
  "AppIcon.png"` key that SamLoc's has, so Xcode would have silently ignored the generated
  PNG even though the file existed on disk.
- **Screenshots**: captured via `capture_shots.py` into `screenshots/final/{en,vi}/`
  (5 shots × 2 languages = 10 total) and every single one visually inspected. First run
  produced badly cross-contaminated screenshots — the `en/01-home` shot showed a different
  app's nav bar ("Bầu Cua Tôm Cá"), `03-instantwin` showed a totally different app's
  onboarding screen ("Xếp Phỏm"), and `04-upgrade` showed yet another sibling app's paywall
  ("Cờ Cá Ngựa Pro"). Root cause: this machine runs several sibling Vietnamese-game
  projects, each with their own `capture_shots.py` driving the *same shared* default
  simulator via bundle-ID launch — a concurrently running sibling script (confirmed via
  `ps aux`, e.g. an `OAnQuan/capture_shots.py` process) raced with this one and TienLen's
  screenshot briefly caught a different app's foreground state. Fixed by adding a
  `TL_DEVICE_UDID` override to `find_device()` in `capture_shots.py` and creating a
  dedicated `TienLen-Shots` simulator (`xcrun simctl create`) so this project's capture
  runs never share a device with another project's. Re-ran clean and all 10 outputs were
  verified: correct Vietnamese diacritics (no mojibake/tofu), correct language per locale,
  no clipping/overlap, no placeholder text, captions/rules text accurate to the actual
  ruleset (mixed-suit sảnh, đôi thông, chặt heo, cóng, Tới Trắng).
- **Legal/privacy site**: live at `https://qngo9871-cmyk.github.io/tienlen-legal/`
  (repo `qngo9871-cmyk/tienlen-legal`, public, GitHub Pages from `main`/`/`), built from
  the `~/Projects/fanorona-legal` template (same CSS/structure) with Tiến Lên-specific
  copy — accurate "How to play" (mixed-suit straights, đôi thông, cóng penalty, no báo sâm,
  no lone-2 restriction) and "Difficulty levels" (Easy/Normal free; Hard AI + exclusive card
  back designs via one-time Pro purchase, matching `PurchaseManager.swift`/`UpgradeView.swift`).

## Not done yet (out of scope for this pass)

- App Store Connect: bundle-ID registration, app record, metadata, pricing, IAP setup,
  screenshots upload, TestFlight/review submission — none of the `asc-tools` scripts exist
  for this app yet (SamLoc's `asc_push_samloc*.py` scripts would need Tiến Lên
  equivalents).
- Device sideload / archive-and-upload haven't been tried; `ExportOptions.plist` is copied
  over from SamLoc (same team ID) and should work once there's something to export.
