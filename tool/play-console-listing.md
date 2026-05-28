# Play Console — Neon 2048 submission packet

Everything needed to click through the Play Console create-new-app flow.

- **Generated assets:** `tool/store-assets/` (regenerate with `python3 tool/generate_store_assets.py`).
- **Release-signed AAB:** `build/app/outputs/bundle/release/app-release.aab` (regenerate with `flutter build appbundle --release`).
- **Release-signed APK** (for sideloading): `build/app/outputs/flutter-apk/app-release.apk` (regenerate with `flutter build apk --release`).

---

## App identity

| | |
|---|---|
| **App name** | Neon 2048 |
| **Default language** | English (United States) |
| **Package name (applicationId)** | `com.superstitionlabs.neon2048` |
| **Category** | Game → Puzzle |
| **Developer name** | Superstition Labs, LLC |
| **Privacy policy URL** | https://superstitionlabs.com/privacy |
| **Support email** | hello@superstitionlabs.com |
| **Website** | https://superstitionlabs.com |
| **Source code** | https://github.com/SaltedBlowfish/neon-2048 (MIT) |
| **Contains ads** | No |
| **In-app purchases** | No |

---

## Store listing copy

### Short description (80 char max — uses 76)

```
Two modes — classic 2048 on squares, plus 2187 on a neon hex grid.
```

### Full description (4000 char max)

```
Slide tiles. Match equal values. Reach the target — and keep going.

Neon 2048 ships with two game modes, swapped from a single tap at the top of the screen:

• 2048 — the classic 4×4 square grid. Swipe to slide, equal tiles merge by doubling (2 → 4 → 8 → … → 2048). Cyan tile palette that glows brighter as you climb.
• 2187 — a fresh take on a pointy-top hexagonal grid (19 cells, six swipe directions). Tiles start at 3 and merge by tripling (3 → 9 → 27 → … → 2187). Red tile palette from crimson to hot pink.

Both modes share the focused, single-screen design: animated slides, merge pops, a breathing neon frame, live SCORE and BEST panels, and a top-10 high-score table that's kept separately per mode and saved on your device. Your last-played mode is remembered between launches.

WHAT'S IN THE BOX
• Two game modes (2048 and 2187), each with its own grid shape, merge rule, and tile palette.
• Title-as-toggle: tap the inactive mode to switch — a confirm dialog protects an in-progress game.
• Six-direction swipe input in hex mode resolved through 60° wedges.
• Per-value tile palette — tiles glow brighter the further you climb.
• Animated slides, merge pops, and tile spawn effects.
• A breathing neon frame in the active mode's accent color.
• Live SCORE and BEST panels. BEST is loaded from device storage and ticks up live.
• Top 10 high scores kept per mode.
• Game-over and win overlays with a "keep playing" option past the win value.
• Reset and high-scores buttons reachable any time.
• Haptic feedback on every move.

PRIVATE BY DESIGN
Neon 2048 is fully offline. It does not collect any data, contact any server, or include any advertising or analytics SDKs. Your high-score tables never leave your device.

OPEN SOURCE
Neon 2048 is MIT-licensed. The full source code and build instructions live at
https://github.com/SaltedBlowfish/neon-2048.

CREDITS
Display font: Orbitron by Matt McInerney (SIL Open Font License).

Built by Superstition Labs, LLC — Phoenix, Arizona.
```

---

## Visual assets (all in `tool/store-assets/`)

| Asset | Spec | File |
|---|---|---|
| App icon | 512×512 PNG, opaque | `icon-512.png` |
| Feature graphic | 1024×500 PNG | `feature-graphic-1024x500.png` |
| Phone screenshot 1 | 1350×2400 PNG (9:16) | `screenshot-1-home.png` |
| Phone screenshot 2 | 1350×2400 PNG (9:16) | `screenshot-2-gameplay.png` |
| Phone screenshot 3 | 1350×2400 PNG (9:16) | `screenshot-3-high-scores.png` |
| Phone screenshot 4 | 1080×1920 PNG (9:16) | `screenshot-4-promo.png` |
| Phone screenshot 5 | 1080×1920 PNG (9:16) | `screenshot-5-promo-2187.png` |

All five screenshots are exactly 9:16 and ≥1080 px on the short side, which
satisfies the promotion eligibility rule. Screenshots 1–3 are real emulator
captures (2048 mode) padded with dark bars on the sides to reach 9:16 without
cropping any UI. Screenshot 4 is a synthetic portrait showing the 2048
palette climbing from 2 to 1024. Screenshot 5 is a synthetic portrait of
2187 mode showing the hex board with the red palette from 3 to 729 and the
title-toggle highlighting 2187.

Re-generate any time via `python3 tool/generate_store_assets.py`.

---

## Click-through checklist

> Before you start: make sure the updated privacy policy is live at
> https://superstitionlabs.com/privacy (commit + push the Superstition-Labs
> repo — the GitHub Actions deploy will run on push). Play reviewers fetch
> this URL during review.

### Step 1 — Create the app
1. Open https://play.google.com/console/u/2/developers/5897127230985352456/create-new-app
2. **App name:** `Neon 2048`
3. **Default language:** English (United States)
4. **App or game:** Game
5. **Free or paid:** Free
6. Tick both declarations (Developer Program Policies + US export laws).
7. Click **Create app**.

### Step 2 — Dashboard tasks ("Set up your app")

Open each task and complete it. The Play Console will not let you submit
until every one of these shows a green check.

a) **App access** → "All functionality is available without special access."

b) **Ads** → "No, my app does not contain ads."

c) **Content rating**
   - Email: `hello@superstitionlabs.com`
   - Category: Puzzle game
   - Answer **No** to every violence / sex / drugs / gambling / mature theme question.
   - Expected rating: PEGI 3 / ESRB Everyone / IARC Everyone.

d) **Target audience and content**
   - Target age groups: **13–15, 16–17, 18+** (general teen-and-older).
     - If you want the listing to surface for younger ages, you'll be opted
       into the Designed for Families program with additional declarations.
       Neon 2048 would qualify (no ads, no data) but it's more paperwork.
   - Appeal to children: **No**.

e) **News apps:** No. **f) COVID-19 apps:** No. **g) Government apps:** No.
   **h) Financial features:** None. **i) Health apps:** No.

j) **Data safety**
   - Does your app collect or share any user data? **No**.
   - The Data Safety summary should end up reading **"No data collected"**.
   - For each category (Location, Personal info, Financial info, Health,
     Messages, Photos/Videos, Audio, Files, Calendar, Contacts, App activity,
     Web browsing, App info and performance, Device or other IDs) → answer
     **No** to "Collected" and **No** to "Shared".

k) **Privacy policy** (under App content → Privacy policy)
   - URL: `https://superstitionlabs.com/privacy`

### Step 3 — Main store listing
**Grow → Store presence → Main store listing**
- App name: `Neon 2048`
- Short description: paste from above
- Full description: paste from above
- App icon: upload `icon-512.png`
- Feature graphic: upload `feature-graphic-1024x500.png`
- Phone screenshots: upload all three `screenshot-*.png`
- (Tablet / TV / Wear screenshots: skip — phone-only.)
- Save.

### Step 4 — App releases (Production)
**Release → Production → Create new release**
1. **Play App Signing:** accept the default — Google generates the signing
   key and re-signs your uploads. (Your upload key is the one in
   `~/keystores/neon-2048-upload.jks`. Password in
   `android/key.properties` and `~/keystores/neon-2048-upload.password.txt`.)
2. **App bundles:** upload `build/app/outputs/bundle/release/app-release.aab`.
3. **Release name:** auto from `versionName` in `pubspec.yaml`.
4. **Release notes (en-US):** paste from the per-version "Release notes" section at the bottom of this doc.
5. **Next**, review, then **Save** (don't roll out yet).

### Step 5 — Countries / regions
**Release → Production → Countries** → start with **United States** only.
You can expand later once the first review passes.

### Step 6 — Submit
With every Dashboard checkmark green and the release saved, click
**Send 1 release for review** on the Production page.

First reviews for new apps typically take 1–7 days.

---

## After the first publish

- **Update flow:** bump `version` in `pubspec.yaml` (the `+N` suffix is the
  versionCode — must increase each release), then rebuild:
  ```bash
  flutter build appbundle --release
  ```
  Upload the new AAB under Release → Production → Create new release.

- **Upload key custody:** the keystore at `~/keystores/neon-2048-upload.jks`
  is the only key you need to keep. If it's ever lost, you can request a
  reset through Play Console (because Google holds the actual signing key).
  Back up `~/keystores/` to your password manager / encrypted storage.

---

## Release notes

### v1.0.0 (initial release)

```
First release.
```

### v1.1.0 (adds 2187 hex mode)

```
New "2187" game mode — a pointy-top hexagonal grid (19 cells, six swipe
directions) where tiles start at 3 and merge by tripling. Toggle between
classic 2048 and 2187 from the new title tabs at the top. Each mode keeps
its own top-10 high-score table; your last-played mode is remembered.
```
