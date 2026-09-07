# Spec coverage and release gates

This repository is a playable alpha. The original requirements remain unchanged. The verified core loop is end to end; the entire launch specification is **not yet complete**.

| Area | Current implementation | Remaining to meet the original spec |
|---|---|---|
| Runtime | Godot 4.7.2, typed GDScript, Jolt 120 Hz, Mobile renderer, explicit state machine | None for the selected engine stack |
| Tire/input | Cylinder rigid body, CCD, rolling torque, neutral-bank gameplay, launch-angle-only input, two nudges/cooldown/TILT, mouse/touch/keyboard, four unlockable variants | Device feel sign-off; contact-patch camber model remains simplified |
| Preview | 0.65-second launch-only dotted path using Jolt motion queries against real collision geometry | Full cloned rigid-body pre-roll and verified <2 ms budget; full predictor-based nudge-save award |
| Hills | 33 individually addressable metadata/scenes; shallow contours, staggered barricades/pegs/bumpers, side ramps/boosts, mud/rails, physical rotating sweepers and traversing blocks, moving final gates; per-seed solver validation | Richer authored lane graphs, actual gap/slow-lane geometry, rotating log feature, integrated edited-heightmap/spline baking |
| Style | Air, bumper chains, near misses, landing, top speed, center, post graze, TILT; score/combo/stars | Rail awards currently entry-based, not continuous balanced grinding; nudge-save event not awarded |
| Presentation | Full-screen gameplay HUD with a dedicated single-angle launch panel; stabilized first-person camera and fitted course-view toggle; four palettes, terraced cliffs, microtextured terrain, cabins/lighthouses/stone arches/orbital sculptures, marked danger zones, 4× MSAA, chase/FOV/shake, short view hit-stop, deterministic-trigger slow motion, dust, pooled tread decals, speed blur/lines/vignette, confetti, squash, goal wobble and bounded result tableau | Full toon/rim shader system, final sound/animation tuning, animated style tally, coin-like miss finish, per-feature reusable editor scenes |
| Progress/menus | World selector, course grid, stars, locks, garage, retry/new seed/next, daily date/seed/best persistence, audio/accessibility settings, credits | Postcard course-pin carousel and richer tutorial gestures; native gamepad bonus support |
| Save/privacy | Versioned atomic JSON, malformed-data recovery, no accounts/ads/analytics; no runtime network dependency | Real-device interruption/storage tests and store privacy review |
| Share/platform | Screenshot postcard saved locally; desktop reveals file; haptics and safe-area adapters | Native iOS/Android share sheets and actual store review IDs; verify physical haptics |
| macOS | Universal app export, package-byte validation, native playtest, Developer ID signing, accepted notarization and stapled DMG; clean-checkout test/export/sign/launch | Second-Mac installation; reference M1 performance sign-off |
| iOS | Xcode export, simulator build/install/launch, portrait inspection | Signed physical-device install, iPhone 12 performance, ten-roll human feel sign-off, TestFlight/App Store metadata/review |
| Android/Windows | Export presets and reused Windows signing script | Android AAB/keystore/SDK validation; signed Windows build on Windows; actual devices and store distribution |

The spec's M1 gate explicitly requires FoFo to play ten rolls on a phone and want an eleventh. No automated test or simulator screenshot substitutes for that. Content here is a tested draft available for that evaluation; M1–M5 are not marked complete.
