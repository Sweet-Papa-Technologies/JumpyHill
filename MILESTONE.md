# Terrain and mobile gameplay update — 2026-09-07

## 0.5 beta — patient rolls and mobile submissions

Simplified title/menu labels and removed both hidden roll deadlines. A 12 cm / three-second progress check detects a stuck wheel while slow rolls can continue. The real level 3 regression reaches GOAL at 41 seconds; stationary spinning and 0.1 m/s slow-roll cases pass. Full validation passes: 16,665 angle-only trials, all course/seed combinations solvable, zero unfinished trials at the test-only 120-second horizon. One of 160 default course/seed rolls succeeds; default launching remains unreliable.

SPT-signed Android AAB/APK passed exported-game automation and native touch play. Google saved build 15 in closed alpha as a draft, plus listing artwork. The iOS 26 device archive passed Apple signing/validation/upload; TestFlight build 15 is processed and assigned to TreadFall Playtest. Cloud iOS simulator playtest passed. See [STORE_RELEASE.md](docs/STORE_RELEASE.md) for exact status and remaining user setup.


Version **0.4.0 playable alpha** adds rolling terrain, true side gaps, banked shoulders, terrain-conforming boost/mud/ice/spring pads, glass boundaries with openings, physical banks and impact shattering, transient shards and Kenney glass sounds. The control stays launch-angle-only with first-person/course-view switching.

- Fixed uninterrupted course/world preview music and preserved musical phase when entering a different world. Native audio regression passed.
- Fixed near-post passes: swept center scoring uses physical post inner faces; contact status comes from actual collisions. Both sides passed with three wheel widths; an outside pass still fails.
- New physics integration checks passed: no hidden gap floor, prompt frozen gap miss, successful gap landing, soft/hard glass impacts, independent wall state for parallel solver tires, retry restoration, ice friction/reset and spring impulse. Native rendered shatter/reset check passed, including pane removal and cleanup of all 16 shards.
- Final **16,665 rolls** (33 courses × 101 launch angles × 5 seeds) passed. Every course has a solution for each seed; regular-course mean clear rate **18.29%**, range **3.96–45.74%**, and **0/160** default launches clear. Ember 03's finish approach was widened after the initial sweep found one inaccessible seed. See `docs/verification/angle-only-04.json`.
- Native scripted gameplay completed a three-star GOAL with airtime/landings; pause, retry, both camera views, settings and daily mode passed. UI event tests, 20 complete runtime retries, ten-second result holds and three processes × 20 deterministic physics trials passed.
- Final heaviest-course native Metal benchmark on M4 Pro: **13.404 ms p95 wall frame time**, 41 maximum 3D draw calls, 71,272 visible primitives, 2.452 ms p95 physics monitor. Godot's CPU/process monitor reported 32.587 ms and is retained in the report. This is not a phone or M1 performance certification.
- Android arm64 export, local-test signing, package-byte/signature/16 KB alignment checks and Pixel API 36 emulator gameplay passed. Android uses OpenGL after the emulator's Vulkan presentation failed. iOS compiled and completed the same gameplay flow on iPhone 16 Pro / iOS 18.6 simulator, using the official x86 template's software-rendering fallback. These establish functional mobile execution, not physical-phone haptics/performance or store readiness.
- The asset ledger now covers **30 source files**. New glass sounds came from the already downloaded Kenney CC0 impact archive; terrain, glass and shards are original procedural source geometry/materials.

Final package identifiers/checksums and mobile reports are recorded in `docs/verification/release-04.json` and `mobile-04.json`. Mac app/ZIP and local DMG are ready with an ad hoc local-testing signature; automatic approval review blocked Developer ID signing/notarization pending explicit authorization. Android normal/automation APKs are signed with the local test key. Final iOS simulator gameplay passed. A separate physical-iPhone build failed because the official engine archive was built with SDK 26.1 and this host has SDK 18.5; `docs/verification/ios-device-04.txt` records the linker failure and the new build script reports the requirement early. Android lighting was reduced after touch/visual inspection found washed-out terrain under GLES. Previous sections below are historical.

---

# Version 0.3 — single-control HUD and first-person play

- Gameplay occupies the full window. A dedicated bottom panel contains one launch-angle slider and Roll; bank input and drag-to-release launching are removed. Purist is available before a roll in the pause menu.
- Every attempt starts in a stabilized first-person tire view. Course view / Tire view (keyboard V) switches in AIM or ROLL. The fitted overview uses a wider desktop diagonal and keeps launch and finish clear of the HUD in landscape and portrait.
- Actual GUI-event tests cover the sole angle control, neutral bank, drag without accidental launch, switching views before/during play, pause/resume, retry-to-first-person and visible course endpoints. PASS.
- Native full-flow playtest includes both views, launching, rolling, pause/resume, result/retry and daily challenge. PASS. Landscape and portrait screenshots inspected.
- Angle-only balance: **33 hills × 101 angles × five seeds = 16,665 rolls**, bank fixed to zero. Every hill has a no-nudge solution on every tested seed. Default launch wins **0/160** regular-course/seed samples. Regular-course angle-grid clear rates are **1.39–46.73%**, averaging **17.88%**. This metric samples one adjustable value and is not comparable with the old aim/bank grid. Three finish positions were adjusted to keep their routes solvable without bank input.
- The angle-only ceiling is 50% on regular hills, 80% on the tutorial. The full report is `docs/verification/angle-only-03.json`.
- Existing result-freeze, off-edge presentation and 20-retry determinism checks remain passing. Native first-person benchmark: **13.42 ms p95 wall**, **2.19 ms p95 physics**, **36 visible draw calls**, **58,432 primitives**, Apple M4 Pro. The process monitor reports 17.18 ms; the automated GUI walk reports 27.58 ms p95 frame delta. These are development-machine measurements, not physical-phone guarantees.

Final release: **0.3.0 / build 9**, source `d978c91`. The Mac app and DMG are signed, notarized and stapled; the signed app passed the packaged first-person/overview playtest. `tools/test.sh --full` completed successfully, including all 16,665 angle-only trials. Windows was re-exported and PE-validated (unsigned); the refreshed iOS simulator target compiled successfully. Manifest: `docs/verification/release-03.json`.

Earlier release notes below are historical.

---

# Version 0.2 — playtest feedback addressed

Verified on macOS 15.5 / Apple M4 Pro with Godot 4.7.2, Jolt 120 Hz and Mobile rendering.

- Final course balance: **24,255 actual physics rolls** across 33 courses, 21 aims, seven bank settings and five seeds. Every course has a no-nudge solution on every seed. Regular-course clear rates range from **1.77% to 18.91%**, averaging **6.65%** across the broad grid. This is a solver sampling rate, not a measured player win rate. The tutorial remains easier.
- Default launch: **0 wins in 160 regular-course/seed combinations**, also checked with standalone isolated rolls. The center barricade, shallow contours and side-route boosts remove the old free winning lane.
- The final report combines the full sweep with a 735-roll retest of Coral 06 after widening its finish to preserve a solution on seed 7777. Results: `docs/verification/solver-report.json`.
- Full application: **20 identical planned-route retries**, including a moving sweeper and slow motion; position tolerance 0.0001 with identical events. Creating a fresh tire body on AIM clears pending forces retained by the result freeze. Existing course geometry stays loaded.
- Off-edge result check: the original out-of-bounds endpoint stays in the score record; the frozen tire is presented on the visible shoulder, clear of decorative cliffs. Native screenshot and ten-second stability regression: PASS.
- Native and headless experience checks: deliberate route wins, default launch blocks, moving hazards animate and pause, retry restores hazard phase, launch preview never moves the actual tire, and both result camera/body remain stable for ten seconds. PASS.
- Asset ledger, real mouse/keyboard UI flow, save/style/nudge tests and three fresh processes × 20 physics repeats: PASS.
- Native full menu playtest: pause/resume, daily challenge and retry PASS; retry **2.42 ms**. Portrait and all four world aim views inspected, plus close chase and settled win/miss views.
- Final uncapped heaviest-course benchmark: **13.59 ms p95 wall**, **1.80 ms p95 physics**, **54 visible 3D draw calls**, **59,488 visible primitives**. The separate process monitor reports 28.80 ms and the scripted menu playtest reports 27.87 ms p95 frame delta; these are retained rather than presenting the best metric as a universal frame-rate guarantee. Physical phone performance remains unverified.
- New visual content is original source geometry/materials: terraced cliffs, detailed ground, dense shoulders, world landmarks, hazard stripes/sweep markings, finish pavilions and 4× MSAA. The 28 external/original source asset ledger entries are unchanged.

Final native artifacts: version **0.2.0**, source commit `bdaf089`, build 7. The universal Mac app and DMG are Developer ID signed, accepted by Apple notarization, stapled and validated; Gatekeeper accepts the app. The final signed binary was launched and its corrected off-edge result inspected. Artifact checksums are in `docs/verification/release-02.json`. Windows was re-exported and its PE package validated (unsigned, not executed on Windows). The final iOS simulator app compiled, installed and launched; its screenshot was inspected and the simulator restored to shutdown.

The earlier alpha verification below is historical and its old difficulty/performance figures do not describe 0.2. Remaining full-spec release gates remain in `FEATURE_STATUS.md`.

---

# Build verification — 2026-09-06

Status: **playable alpha / M0 verified; M1 human feel gate still open**. The content draft is available for evaluation. M1–M5 are not claimed complete.

Verified on macOS 15.5, Apple M4 Pro, Godot 4.7.2 (`ed1daf0bf`), native Metal Mobile renderer:

- Real mouse/keyboard events through title, course selection, aim, launch, pause, settings, resume, nudge, retry, world carousel and locked-world controls: PASS.
- Scripted graphical playtest completed a GOAL, displayed 2 stars, retained the same seed on retry, preserved the roll across pause/resume, and opened the date-derived daily challenge. Measured retry: **2.7 ms** in the polished pass.
- Unit/integration checks: catalog of 33 unique courses, seed stability/variation, style/star math, atomic save round trip, malformed-data recovery, best score retention, daily seed, nudge cooldown, TILT and Purist: PASS.
- Physics determinism: **3 fresh processes × 20 repeated rolls**, matching position to 1e-4 and identical event/outcome logs: PASS.
- Actual application determinism: **20 complete retries with slow motion enabled**, using the retained-mesh/fresh-physics-space reset: PASS.
- Course solver: **33 × 21 aims × 7 leans × 5 seeds = 24,255 rolls**. Every hill has a no-nudge solution, no clear rate exceeds 60%, and no sample reaches 20 s: PASS. Detailed per-course results: `docs/verification/solver-report.json`; heatmaps: `build/solver/`.
- Heaviest course, uncapped native graphics: **13.9 ms p95 wall frame time**, **2.24 ms p95 physics monitor**, **40 maximum visible 3D draw calls**, **23,480 maximum visible primitives**. See `docs/verification/performance.json`. Godot's process monitor also reported 23.5 ms; it is recorded, not silently discarded. These measurements establish neither an M1 Mac nor iPhone 12 result, and a separate render-time ≤9 ms gate has not been measured.
- PNG heightfield → reload → mesh + collider bake on Meadow 01: PASS. Edited bakes are an authoring tool, not the current shipped terrain source.
- All **28 source assets** pass the ledger/license whitelist check; generated Godot import records and Finder metadata are excluded.
- macOS universal package bytes checked, exported executable launched, screenshot inspected; Developer ID signature verified with hardened runtime. Apple accepted app and DMG notarization; tickets stapled and validated; Gatekeeper accepted. The shipped DMG was mounted read-only and its app launched successfully; the disk image was then ejected. A fresh isolated checkout independently passed the test suite, exported, signed and launched.
- Windows candidate exported and PE headers validated (110,744,648 bytes); not executed or signed on Windows.
- iOS Xcode project compiled, installed and launched on iPhone 16 Pro simulator / iOS 18.6 using the actual x86_64 template architecture. Portrait screenshot inspected. No physical-device installation or haptics/performance claim.

Issues found and fixed during testing: reversed terrain faces, cropped goal framing, inaccessible finish approaches on four hills, retained Jolt contact state breaking retries, duplicate button nodes during rebuild, incorrect viewport coordinates in UI tests, JSON numeric type coercion in the test, corrupted save values, audio shutdown references, and empty executable bytes in a nominally successful Godot ZIP export.

Remaining implementation and release requirements are listed explicitly in `FEATURE_STATUS.md`. In particular, full pre-roll prediction, advanced course features, native mobile sharing and the phone feel gate still need work. No App Store, TestFlight, Play, or Microsoft/Steam release is claimed.
