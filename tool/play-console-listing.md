# Play Console — Neon 2048 submission packet

Everything needed to click through the Play Console create-new-app flow.
Generated assets are staged at `~/Desktop/neon-2048-play-assets/`. The
release-signed AAB is at `~/Desktop/neon-2048-release.aab`.

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

### Short description (80 char max — uses 62)

```
Tile-merging on a neon grid. Slide, merge, double — to 2048.
```

### Full description (4000 char max)

```
Slide tiles. Match equal values. Double them up. Reach 2048 — and keep going.

Neon 2048 is a focused, single-screen take on the classic 4×4 puzzle, dressed in a neon palette: dim slate-blue 2s climb tile by tile toward a white-hot 2048, with animated slides, merge pops, and a breathing neon grid.

WHAT'S IN THE BOX
• Classic 4×4 2048 mechanics — swipe in any direction to slide and merge.
• Per-value tile palette — tiles glow brighter the further you climb.
• Animated slides, merge pops, and tile spawn effects.
• A breathing neon frame with two light streaks chasing each other around the board.
• Live SCORE and BEST panels. BEST is loaded from device storage and ticks up live.
• Top 10 high-score table, saved on your device.
• Game-over and win overlays with a "keep playing" option past 2048.
• Reset and high-scores buttons reachable any time.
• Haptic feedback on every move.

PRIVATE BY DESIGN
Neon 2048 is fully offline. It does not collect any data, contact any server, or include any advertising or analytics SDKs. Your high-score table never leaves your device.

OPEN SOURCE
Neon 2048 is MIT-licensed. The full source code and build instructions live at
https://github.com/SaltedBlowfish/neon-2048.

CREDITS
Display font: Orbitron by Matt McInerney (SIL Open Font License).

Built by Superstition Labs, LLC — Phoenix, Arizona.
```

---

## Visual assets (all in `~/Desktop/neon-2048-play-assets/`)

| Asset | Spec | File |
|---|---|---|
| App icon | 512×512 PNG, opaque | `icon-512.png` |
| Feature graphic | 1024×500 PNG | `feature-graphic-1024x500.png` |
| Phone screenshot 1 | portrait PNG | `screenshot-1-home.png` |
| Phone screenshot 2 | portrait PNG | `screenshot-2-gameplay.png` |
| Phone screenshot 3 | portrait PNG | `screenshot-3-high-scores.png` |

Play Console requires at least 2 phone screenshots; we have 3.

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
2. **App bundles:** upload `~/Desktop/neon-2048-release.aab`.
3. **Release name:** `1.0.0` (auto from `versionName`).
4. **Release notes (en-US):** `First release.`
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

- **Update flow:** bump `version: 1.0.0+1` in `pubspec.yaml` (the `+1` is
  the versionCode — must increase each release), then rebuild:
  ```bash
  flutter build appbundle --release
  ```
  Upload the new AAB under Release → Production → Create new release.

- **Upload key custody:** the keystore at `~/keystores/neon-2048-upload.jks`
  is the only key you need to keep. If it's ever lost, you can request a
  reset through Play Console (because Google holds the actual signing key).
  Back up `~/keystores/` to your password manager / encrypted storage.
