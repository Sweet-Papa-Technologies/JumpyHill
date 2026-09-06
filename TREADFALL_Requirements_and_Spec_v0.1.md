# TREADFALL — Requirements & Technical Spec v0.1

**Working title:** TREADFALL (rename freely)
**Owner:** Forrester "FoFo" Terry — Sweet Papa Technologies
**Builder:** Astra (AI coder)
**Date:** 2026-09-06
**Status:** Draft for build kickoff

---

## 0. One-liner

You stand at the top of a gorgeous pastel hill. You aim a tire, tilt it a hair, and let go. It rips down the slope, gets funneled through one of many sculpted paths, bounces off pegs and bumpers, catches air, and — if you read the hill right — threads between two goal posts at the bottom. Pinball speed, Jet Set Radio swagger, GameCube-era pastel 3D. 75% skill, 25% luck. One thumb.

---

## 1. Decisions already made (do not relitigate without asking)

| Topic | Decision | Why |
|---|---|---|
| **Engine** | **Godot 4.7.x** (latest stable 4.7 patch at kickoff; MIT license) | Whole project is plain text (`.tscn`, `.gd`, `.tres`, `project.godot`) — an AI coder can author and diff 100% of it without clicking through an editor. Headless CLI export (`godot --headless --export-release`) gives one scripted pipeline for iOS/macOS/Android/Windows. Jolt Physics is built in and the default 3D physics for new projects since 4.6. Native Metal backend on iOS/macOS. Zero licensing exposure. |
| **Why not Unity** | Rejected | Unity Personal is free under $200k and the runtime fee was cancelled, so cost isn't the blocker. The blocker is workflow: Unity is editor-GUI-centric with YAML scene files and GUID-linked metadata that agents handle badly, plus a licensing history that has already burned people once. Godot's text-first project is a much better fit for an agent-driven build. |
| **Why not raw C/C++ (raylib/sokol/SDL3 + Jolt)** | Rejected for v1 | It matches the "C at the core" instinct and FoFo's FloppyJam work, but for a game whose whole pitch is *pretty 3D + juice*, you'd be rebuilding lighting, post-FX, particles, asset import, UI, and four platform packagers before writing any gameplay. Godot *is* the C++ core; escape hatch below. |
| **Language** | **GDScript** for gameplay/UI. **GDExtension (C++)** only for a measured hotspot (unlikely to be needed). | Fewest toolchain surprises on iOS. Static typing (`: int`, `-> void`) required everywhere for perf and readability. No C#/.NET on mobile for v1. |
| **Physics** | Jolt Physics 3D, fixed tick **120 Hz** (`physics/common/physics_ticks_per_second = 120`), physics interpolation on | Tire-on-terrain at speed needs a high tick to not tunnel through pegs and rails. |
| **Renderer** | Godot **Mobile** renderer on *all* platforms (not Forward+) | One look, one shader set, one perf profile. Desktop just runs it faster. |
| **Platform order** | 1) iOS + macOS → 2) Android → 3) Windows | Get feel and content right on two Apple targets sharing one Xcode/signing world, then port. Nothing in v1 may hard-block later platforms (no Apple-only APIs in gameplay code). |
| **Orientation** | **Portrait-first** (9:16 to 9:21). Desktop runs the same portrait-designed courses in a landscape window with the camera pulled back and pastel side-panels/decor filling the margins. | A hill is tall. Portrait means "see the whole course at a glance" actually works on a phone. |
| **Input** | Touch primary. Mouse/trackpad on desktop maps 1:1 to touch. Keyboard/gamepad supported as a bonus, not required. | |
| **Monetization (v1)** | **Premium, one-time purchase. No ads, no IAP, no accounts, no analytics SDKs.** | Simplest possible App Review and privacy label. Open question in §11 if FoFo wants free + cosmetic IAP later. |
| **Assets** | Free-for-commercial-use only, from the whitelisted sources in §8. CC0 preferred; CC-BY allowed with attribution. | |
| **Signing/distribution** | Existing Apple Developer, Google Play Console, and Azure Trusted Signing accounts. Mirror the signing setup already used in `~/code/FoFoPedal`, `~/code/FoFoSoundBooster`, `~/code/FloppyJam`. | Don't invent a new pipeline; copy what already works locally. |

---

## 2. Design pillars

1. **Read the hill, then commit.** The entire course is visible before you roll. Every loss should feel like "I misread it," never "I couldn't see it."
2. **Speed is the reward.** The roll is fast, loud, and over in 8–15 seconds. Momentum, airtime, bumper hits and near-misses all get louder and flashier the better you're doing.
3. **75/25.** Aim + tilt + a well-designed hill decide ~75% of the outcome. Seeded micro-variance (peg jitter, wind gusts, a loose rock) supplies the other 25% and makes replaying the same course fun.
4. **One thumb, zero tutorial text.** If a mechanic needs a paragraph, cut it.
5. **Pastel GameCube.** Flat/low-poly geometry, chunky silhouettes, soft toon lighting, gradient skies, saturated-but-soft palettes. Think *Super Monkey Ball* / *Kirby Air Ride* era, remastered.

---

## 3. Core loop

```
[Course select] → [AIM phase: whole hill visible] → [ROLL phase: chase cam, 8–15s]
      → [RESULT: goal/miss, style score, stars] → [Retry / Next]
```

### 3.1 AIM phase
- Camera: full-course overview, framed so the launch pad is near the top of the screen and the goal posts near the bottom. Slight perspective (not orthographic) so the hill reads as 3D.
- **Aim (left/right):** drag horizontally anywhere on screen. Moves the tire along the launch pad (a curved ledge, ~5 tire-widths wide) and rotates its heading within ±25°. A dotted **short-range guide** (first ~1.5 seconds of predicted travel, computed by a real physics pre-roll, not a fake line) shows where you'll enter the hill. It deliberately does *not* show the whole route.
- **Tilt (lean):** vertical drag / second-finger or a small dial widget sets lean **−15° … +15°**. Lean is a persistent steering bias during the roll: the tire's contact patch is offset, so it drifts toward the lean side and takes curves tighter on that side. This is the "skill ceiling" input.
- **Release:** lift finger / tap "ROLL". Launch speed is fixed per course; gravity does the rest. No power meter in v1 — the hill is the power.

### 3.2 ROLL phase
- Camera: chase cam behind/above the tire, FOV kicks up with speed (e.g. 60°→78°), slight lag + anticipation toward the tire's velocity vector, roll-tilt with the terrain, speed lines at high velocity.
- **Nudge (the pinball element):** the player gets **2 nudges** per roll. Swipe left/right during the roll applies a short lateral impulse (small — enough to save a marginal line, not enough to teleport lanes). A subtle "TILT" lockout triggers if the player spams (3rd nudge = nudges disabled + small style penalty). Nudges are optional; a "Purist" course modifier disables them for bonus stars.
- Terrain funnels the tire into one of several **lanes** (see §4). Splitters, pegs, bumpers, ramps, rails, and gaps create branch points and airtime.
- Style events fire and stack (see §5).
- Slow-mo (0.35× for ~0.4s) on the final approach to the posts if the tire is within a "will it make it" band; snap back to full speed on the result.

### 3.3 RESULT
- **GOAL:** tire passes between posts, any height, without touching a post → cleared. Center-line accuracy and entry speed feed the star rating.
- **POST HIT:** clanging miss. Tire ricochets. Shows how close in tire-widths.
- **WIDE:** tire leaves the goal zone.
- Stars (0–3): ★ clear, ★★ clear with ≥ N style points or ≥ center accuracy, ★★★ both, or clear under Purist modifier.
- Instant retry (same seed) and "new roll" (new seed) buttons. Retry must be < 300 ms from tap to AIM phase.

---

## 4. Course & path system (the heart of it)

### 4.1 Anatomy of a course
- **Launch pad** at top, **goal posts** at bottom, 40–120 m of hill between them.
- The slope is sculpted into a **lane graph**: a set of gutters/ridges/half-pipes that naturally capture a rolling tire. Lanes split (forks around rocks, pachinko peg fields, ramps that launch into one of two landing zones) and merge. 3–7 distinct end-approaches per course, only 1–2 of which actually line up with the posts cleanly; the rest need a lean or a nudge to convert.
- **Feature vocabulary** (each is a reusable scene with a tuned physics material):
  - *Gutter* (captures), *Ridge* (splits), *Half-pipe* (banks — lean matters here), *Peg field* (pachinko luck), *Bumper* (pinball kick + style), *Ramp / Kicker* (airtime, lands into a chosen lane), *Rail* (grind: tire rides a fence top, JSR nod, big style), *Gap* (miss the ramp → fall into a slower lane), *Boost pad* (speed), *Mud / Gravel* (slow, dampens bounce), *Log roll* (rotating, timing luck), *Goal posts* (final gate, sometimes with a swinging/moving gate on hard courses).
- Everything in a course is placed in a `.tscn` from a small library, so courses are cheap to author and diff.

### 4.2 Variability (the 25%)
Each roll gets a **seed** (`uint64`). All randomness in a roll derives from that seed via `RandomNumberGenerator.seed`. Sources:
- Peg field jitter: ±5 cm per peg position.
- Wind gusts: 0–2 gusts per roll, timed windows, lateral force small enough that lean can counter it.
- Loose props: one or two rocks/logs with randomized start rotation.
- Bumper strength ±10%.
- Nothing random ever moves the goal posts or the launch pad.

**Determinism rule:** same build + same platform + same seed + same inputs ⇒ same result. Enforced by a test (§10). Cross-platform bit-determinism is *not* promised (Jolt float differences), so nothing in the game may assume it (no "beat my exact replay" across devices).

### 4.3 Course authoring format
- One folder per course: `courses/<world>/<nn>_<slug>/course.tscn` + `course.tres` (metadata resource: name, world, par style score, launch speed, lean limits, nudge count, star thresholds, seed pool for daily).
- Terrain: authored as a **heightmap PNG + spline gutters** baked into a `MeshInstance3D` + `ConcavePolygonShape3D` (or `HeightMapShape3D` for the base + convex shapes for features) by an editor script (`tools/bake_course.gd`) — run headless. Astra can generate heightmaps procedurally or paint them; both paths must round-trip through the same bake.
- A course is **valid** only if the automated solver (§10.3) finds ≥ 1 aim/tilt combo that clears it with no nudges and ≤ 60% of random aim/tilt combos clear it. (Too easy or impossible both fail CI.)

### 4.4 Content targets
- **v1 (iOS/macOS launch):** 4 worlds × 8 courses = **32 courses** + 1 tutorial hill.
- Worlds (all pastel, all fictional): **Meadow Alps** (green/yellow/sky-blue), **Coral Coast** (cliffs, sea, peach/teal), **Ember Mesa** (desert, rose/orange/violet dusk), **Neon Nightcap** (snowy peak at night with glowing rails and signage — the Jet Set Radio one).
- Difficulty ramps within a world (1–8) and across worlds. Course 8 of each world introduces a moving goal gate or a big rail sequence.
- Stretch (post-v1): Autumn Hollow, Lantern Harbor; user-shared seeds.

---

## 5. Style system (the Jet Set Radio part)

A **style meter** fills during the roll and multiplies the base clear score.

| Event | Points | Notes |
|---|---|---|
| Airtime | 10/0.25s | Scales with height |
| Bumper hit | 25 | Chain multiplier ×1.1 per consecutive |
| Rail grind | 15/0.25s | Balance is automatic; leaving early forfeits |
| Near-miss (pass within 0.3 tire-width of a rock/post) | 30 | Big "!!" pop |
| Clean landing (from ramp into gutter without bounce) | 40 | |
| Top speed hold (≥ 90% max for 1s) | 20 | |
| Nudge save (nudge that changed a MISS prediction to a GOAL) | 50 | Computed by pre-roll predictor |
| Center goal | 100 | Within 0.25 tire-width of centerline |
| Post-graze (clear but touched a post) | −50 | Still a clear |
| TILT lockout | −100 | |

Style pops as chunky wordmarks ("SICK", "GRIND", "AIR", "!!", "NICE") in the pastel UI font, with a graffiti-style stamp animation. Combo counter top-left. The meter's fill level also drives music intensity layers (§7).

---

## 6. Feel & juice checklist (all required, all tunable in one `feel.tres`)

- Tire deforms slightly on impact (squash/stretch shader or bone), leaves tread decals on mud/snow.
- Dust/spray particles keyed to surface type; sparks on rails and bumpers.
- Camera shake (trauma-based, max 0.4) on bumper hits and landings; never on aim phase.
- Hit-stop 40–60 ms on bumpers and post hits.
- Speed lines + subtle radial blur ≥ 80% max speed.
- Screen-edge vignette pulses with combo tier.
- Goal: confetti burst, posts wobble, camera orbits the tire for 1.2s, style tally counts up with tick sounds.
- Miss: tire wobbles to a stop like a dropped coin (tuned rigidbody damping), sad-trombone-free — use a short pastel "bonk" sting.
- Haptics: light tick on aim snaps, medium on bumper, heavy on goal/post (`Input.vibrate_handheld` on mobile; no-op on desktop).
- All transitions ≤ 250 ms. Never block input on an animation.
- 60 fps locked on iPhone 12 / A14-class and M1 Macs at native res; 120 fps optional on ProMotion. Frame-time budget: 16.6 ms, physics ≤ 4 ms, render ≤ 9 ms.

---

## 7. Audio

- **Music:** per-world track with 3–4 stems (base / mid / high / hype). Stems crossfade with style-meter tier. Pinball-y, upbeat, funky/breakbeat for Neon Nightcap. Sourced per §8 (Kevin MacLeod, Pixabay, Kenney, OpenGameArt CC0/CC-BY); if stems aren't available, Astra may split a track into stems via EQ/bandpass in-engine (`AudioEffectFilter`) as an acceptable approximation.
- **SFX:** tire roll loop pitched to speed, surface-specific rolls (grass/gravel/snow/metal rail), bumper "boing", post "clang", ramp "whoosh", peg "tock", goal fanfare, style pops (short vocal-free stings).
- Ducking: music −6 dB on goal fanfare.
- Master/Music/SFX sliders; mute-on-focus-loss.

---

## 8. Asset sources (whitelist)

**Rules:**
1. CC0 preferred. CC-BY 3.0/4.0 accepted **with attribution**. Site-specific "free for commercial use" licenses (Kenney, Pixabay, Mixkit) accepted.
2. **Never** use: CC-BY-NC, CC-BY-ND, CC-BY-SA (avoid share-alike ambiguity in a closed binary), "personal use only", "free for non-commercial", anything ripped from a game, any asset whose license page you can't link.
3. Every imported asset gets a row in `ASSETS.md` (path, source URL, author, license, date pulled) and CC-BY items appear in the in-game credits screen. CI fails if an asset exists on disk without an `ASSETS.md` row.
4. Prefer stylized low-poly over realistic; recolor to the palette via vertex colors / material overrides rather than hunting for exact-color assets.

| Need | Source | License | Notes |
|---|---|---|---|
| 3D props, nature, road/track kits, UI, sounds | **Kenney** — kenney.nl | CC0 | First stop for everything. Nature Kit, Racing Kit, Mini Golf Kit, Platformer Kit, Interface Sounds, Impact Sounds, UI Pack. |
| Low-poly nature/animals/props | **Quaternius** — quaternius.com | CC0 | Ultimate Nature Pack, Stylized Nature, Cars. |
| Additional low-poly models | **Poly Pizza** — poly.pizza | CC0 / CC-BY (filter to CC0) | Searchable aggregator; check license per model. |
| Skies / HDRIs / textures | **Poly Haven** — polyhaven.com | CC0 | Use HDRIs only as lighting reference; skies in-game are gradient shaders. |
| PBR/stylized textures | **ambientCG** — ambientcg.com | CC0 | Grass, gravel, snow, sand, wood. Downsample to 512–1024. |
| Sounds | **Kenney** (above); **freesound.org** filtered to **CC0**; **Mixkit** — mixkit.co | CC0 / Mixkit License | For freesound, only pull assets whose license field reads "Creative Commons 0". |
| Music | **Kevin MacLeod** — incompetech.com (CC-BY 4.0, attribute exactly as his site specifies); **Pixabay Music** — pixabay.com/music (Pixabay License); **OpenGameArt** — opengameart.org (filter CC0 / CC-BY 3.0/4.0) | CC-BY / Pixabay | Look for upbeat electronic, funk, breakbeat, lo-fi with clean loops. |
| Fonts | **Google Fonts** — fonts.google.com | SIL OFL 1.1 | Chunky rounded display font for style pops (e.g. Fredoka, Baloo, Bungee), clean sans for UI (e.g. Nunito, Rubik). |
| Icons | **Kenney** Game Icons; **Lucide** — lucide.dev | CC0 / ISC | |
| Extra models | **Sketchfab** — sketchfab.com filtered to **CC0 only** | CC0 | Only CC0 filter; ignore CC-BY there to avoid attribution sprawl. |

Anything not on this list requires FoFo's OK before import.

---

## 9. Technical spec

### 9.1 Repo layout
```
treadfall/
  project.godot
  README.md            # how to run, export, sign, test
  ASSETS.md            # asset ledger (see §8)
  CREDITS.md
  addons/              # only if strictly needed; vendored, pinned
  src/
    core/              # game state machine, seed/RNG, save, settings
    tire/              # tire scene, physics material, deformation, audio hooks
    course/            # course loader, lane features, bake tools, solver hooks
    camera/            # aim cam, chase cam, result orbit
    style/             # style meter, event detection, combo
    feel/              # shake, hit-stop, particles, haptics, feel.tres
    ui/                # menus, HUD, results, credits
    audio/             # music stem manager, sfx bus
    platform/          # thin per-platform shims (haptics, safe area, store hooks)
  courses/<world>/<nn>_<slug>/
  assets/{models,textures,audio,fonts,ui}/
  tests/               # GUT or gdUnit4 tests + solver/determinism harness
  tools/               # bake_course.gd, solve_course.gd, export.sh, sign_*.sh
  export/              # export_presets.cfg + per-platform notes
  .github/workflows/   # or local scripts if CI runner isn't available
```

### 9.2 State machine
`Boot → Title → CourseSelect → Aim → Roll → Result → (Aim|CourseSelect)` plus `Pause` overlay and `Settings`. Implemented as an explicit enum + `match`, not signals spaghetti. Every state has an `enter/exit/tick` and can be entered directly from the command line for testing (`--course meadow/03 --state roll --seed 42 --aim 0.3 --lean -5`).

### 9.3 Tire
- `RigidBody3D` with a `CylinderShape3D` (or a convex hull of a torus for better edge behavior — test both, pick by feel). Mass ~10 kg, angular damping low, linear damping ~0.05, continuous collision detection **on**.
- Physics material: friction 0.9 rubber-on-grass, bounce 0.35; per-surface overrides via `Area3D` surface volumes.
- Lean: applied as a continuous torque + contact-offset bias each physics tick, clamped; never as a direct velocity write.
- Nudge: `apply_central_impulse(lateral * nudge_strength)` with a 0.5s cooldown and the TILT counter.
- Max speed clamp (per course) so nothing tunnels and the feel stays readable.
- Tire variants (unlockables, v1: 4): *Standard*, *Fat Off-Road* (more grip, less bounce, slower), *Slick* (fast, slides in half-pipes), *Donut Spare* (light, bouncy, chaotic — luck goes up, style goes up). Each is a `.tres` override of the same tire scene.

### 9.4 Short-range guide (aim preview)
- On every aim change (debounced to ~60 Hz), run a **physics pre-roll** in a separate `PhysicsServer3D` space or by stepping a cloned world for 1.5s at 120 Hz. Draw the resulting path as a dotted `ImmediateMesh` line, fading out. Must cost < 2 ms; if it can't, reduce to 1.0s or a coarser 60 Hz step.
- The same predictor, run to completion, powers "nudge save" detection and the CI solver.

### 9.5 Camera
- `AimCamera`: fitted per-course via metadata (position, look-at, FOV) auto-computed from course AABB + safe area; manual override allowed.
- `ChaseCamera`: spring-arm, look-ahead = velocity × 0.25s, FOV = lerp(60, 78, speed/maxspeed), roll follows terrain normal × 0.3, trauma shake.
- `ResultCamera`: 1.2s orbit around tire, then hold.
- All in one `CameraRig` node with a `blend_to(state, duration)` API.

### 9.6 Rendering & look
- Mobile renderer, MSAA 2× on desktop / FXAA on mobile, no SSAO/SSR/SDFGI. One `DirectionalLight3D` with soft shadows (mobile: shadow resolution 2048, one cascade), plus baked `LightmapGI` per course if it's cheap enough — otherwise vertex AO.
- Toon shading via a shared `StandardMaterial3D` set + a small `pastel_toon.gdshader` (2-band ramp + rim light + fresnel highlight). Palette per world lives in a `world_palette.tres` (6 swatches) and props are recolored through it.
- Gradient sky shader (top/horizon/bottom colors + sun disc + a few flat clouds). Distance fog matched to the sky's horizon color.
- Tire tread decals via `Decal` nodes pooled (max 24).
- Target: ≤ 150k triangles per course on screen, ≤ 40 draw calls in the chase view, textures ≤ 1024².

### 9.7 UI
- Portrait HUD: style meter left edge, combo top-left, nudges remaining top-right (two little tire icons), seed + retry bottom on results. Safe-area aware (`DisplayServer.get_display_safe_area`).
- Desktop landscape: same HUD, course letterboxed with pastel decor panels; window resizable, min 720×1280 equivalent.
- Course select: a world "postcard" carousel, courses as pins on the postcard; stars shown; locked courses need ≥ N stars in the previous world (keep the gate low — this is casual).
- Settings: audio sliders, haptics, left-handed layout, reduce motion (disables shake/blur/hit-stop), colorblind-safe post markers (pattern + color), language (en only at v1 but all strings through `tr()`).

### 9.8 Save & data
- Single JSON at `user://save.json`, versioned, atomically written (write temp → rename). Contents: per-course best stars/score/seed, unlocked tires, settings.
- No cloud sync at v1 (Game Center/iCloud Key-Value is a §11 option).

### 9.9 Daily Roll (light live-ops without a server)
- One course + one seed per calendar day, derived deterministically from the date (`hash(YYYY-MM-DD, salt)`) — no network required. Best score stored locally. Shareable result card (screenshot with score, seed, course name) via the OS share sheet.

### 9.10 Platform layer
- `src/platform/Platform.gd` autoload with a tiny interface: `vibrate(kind)`, `share_image(png)`, `open_store_review()`, `safe_area()`. Per-OS implementations chosen at runtime via `OS.get_name()`. Nothing else in the codebase may branch on platform.

### 9.11 Build, export, sign

**Common:** `tools/export.sh <preset> <version>` runs `godot --headless --export-release "<Preset>" <path>`, bumps build numbers from git (`git rev-list --count HEAD`), and writes a build manifest. Export templates must exactly match the editor version; pin the Godot version in `README.md` and a `.godot-version` file.

**macOS (phase 1):** universal binary (arm64 + x86_64), Godot's built-in codesign + notarization using the Developer ID identity already used by FoFoSoundBooster; hardened runtime; entitlements minimal (no network, no camera). Distribute via direct `.dmg` and Mac App Store (App Store build uses the App Store identity + sandbox entitlements).

**iOS (phase 1):** Godot exports an Xcode project; `xcodebuild -archive` + `-exportArchive` with the existing distribution profile; upload to TestFlight via `xcrun altool`/`notarytool` per whatever FoFoPedal already scripts. Min iOS 15. Privacy manifest: no tracking, no required-reason APIs beyond file timestamp/user defaults.

**Android (phase 2):** AAB via Godot's gradle build template, JDK 17, Android SDK, release keystore (back it up — losing it means losing the app identity). Target API per current Play requirements at the time. Test on one low-mid device (e.g. a 2021-era Snapdragon 6xx) for the 60 fps floor.

**Windows (phase 3):** `.exe` + PCK, signed with Azure Trusted Signing exactly as FloppyJam/FoFoPedal do it; Steam-ready but Steam is out of scope.

No platform work is "done" until a signed build installs cleanly on a real device from a fresh script run on a clean checkout.

---

## 10. Verification (what would prove it works)

### 10.1 Unit/integration (gdUnit4 or GUT, run headless in CI)
- State machine transitions; save round-trip; seed→RNG stability; style scoring math; safe-area math.

### 10.2 Determinism test
- Roll course X with seed S and scripted inputs, 20 times in one process and across 3 fresh process launches. Assert identical final position (to 1e-4) and identical style event log. Runs on every commit.

### 10.3 Course solver (CI gate for content)
- For each course: sample aim ∈ [−1,1] × lean ∈ [−15,15] on a 21×7 grid × 5 seeds, run the physics predictor to completion headless, record GOAL/MISS/POST. Fail the build if best-case no-nudge clear rate = 0, or if random clear rate > 60% (too easy), or if any sample exceeds 20s (stuck). Emit a heatmap PNG per course into `build/solver/` so FoFo can eyeball difficulty.

### 10.4 Performance test
- Scripted roll on the heaviest course, capture frame times via `Performance.get_monitor`. Fail if p95 frame time > 16.6 ms on the reference Mac; manual pass on reference iPhone before each TestFlight build.

### 10.5 Asset ledger test
- Every file under `assets/` has an `ASSETS.md` row; every row's license is in the allowed set.

### 10.6 Feel sign-off (human)
- FoFo plays 10 rolls on a phone. Ship criteria: he wants an 11th.

---

## 11. Open questions for FoFo (Astra: proceed with the defaults in bold until answered)

1. Name — **TREADFALL** as working title.
2. Monetization — **premium, no ads/IAP**; or free with cosmetic tire packs?
3. Leaderboards / Game Center — **out of v1**; add in phase 2 with Android?
4. Course count — **32 + tutorial** for launch, or ship 16 and patch?
5. Tire physics shape — **decide by feel in M1**; cylinder vs torus hull.
6. Should the "Purist" no-nudge mode be the default and nudges be the unlock? **Nudges default on.**
7. Any hard "no" on the neon night world (it's the one that leans hardest on the JSR vibe)? **Keep it.**

---

## 12. Milestones

Each milestone ends with a tagged commit, a signed build where applicable, and a short `MILESTONE.md` note stating what was verified and how (not what was written).

| # | Milestone | Done means |
|---|---|---|
| **M0 — Skeleton** (days) | Godot 4.7 project, repo layout, state machine, one gray-box hill, tire rolls, aim + lean + release, chase cam, goal detection, headless export to macOS works. | Solver and determinism tests pass on the gray-box hill. |
| **M1 — Feel lock** | Juice checklist §6 complete, style system §5, nudge + TILT, short-range guide, pastel look on one finished Meadow Alps course, music stems reacting. | FoFo feel sign-off on iPhone via TestFlight + macOS build. Nothing else starts until this passes. |
| **M2 — Content** | 4 worlds × 8 courses, 4 tires, tutorial hill, course select, daily roll, settings, credits, save. | Solver heatmaps reviewed; all courses valid; asset ledger clean. |
| **M3 — iOS + macOS release** | App Store + Mac App Store + notarized DMG. Screenshots, privacy labels, age rating. | Approved and live. |
| **M4 — Android** | AAB signed, 60 fps on reference device, haptics/share shims, Play listing. | Live on Play. |
| **M5 — Windows** | Signed exe, gamepad/keyboard polish, windowed/fullscreen. | Signed build runs on a clean Windows VM. |

---

## 13. Working agreements for Astra

- Read `~/code/FoFoPedal`, `~/code/FoFoSoundBooster`, `~/code/FloppyJam` before touching signing; reuse their scripts and identities, don't reinvent.
- Small, frequent commits with plain-English messages. **Git is ground truth.** Never run `git reset --hard`, `git checkout -- .`, `git clean`, force-push, or any command that discards uncommitted work. If the tree is dirty and you're unsure, stop and ask.
- Deterministic first: any randomness goes through the seeded RNG. Any "magic number" goes in a `.tres` with a comment.
- Count what survived, not what you wrote: milestone notes report what was verified and how, and what was cut.
- If you can't say what would falsify a change, you aren't testing it — add the test or say so explicitly.
- Fight for simplicity: no addons, plugins, or dependencies without a one-line justification in `README.md`. Pin versions.
- Anything not in §8's whitelist stays out of the repo. When in doubt about a license, don't import it.
- When a design call isn't covered here, pick the option that makes the roll faster or the read clearer, note it in `DECISIONS.md`, and keep moving.
