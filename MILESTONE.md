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
- macOS universal package bytes checked, exported executable launched, screenshot inspected; Developer ID signature verified with hardened runtime.
- iOS Xcode project compiled, installed and launched on iPhone 16 Pro simulator / iOS 18.6 using the actual x86_64 template architecture. Portrait screenshot inspected. No physical-device installation or haptics/performance claim.

Issues found and fixed during testing: reversed terrain faces, cropped goal framing, inaccessible finish approaches on four hills, retained Jolt contact state breaking retries, duplicate button nodes during rebuild, incorrect viewport coordinates in UI tests, JSON numeric type coercion in the test, corrupted save values, audio shutdown references, and empty executable bytes in a nominally successful Godot ZIP export.

Remaining implementation and release requirements are listed explicitly in `FEATURE_STATUS.md`. In particular, full pre-roll prediction, advanced course features, native mobile sharing and the phone feel gate still need work. No App Store, TestFlight, Play, or Microsoft/Steam release is claimed.
