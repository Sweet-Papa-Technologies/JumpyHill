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


## 0.4 terrain, boundaries and mobile verification

Course previews retain the current music stream. Entering a different world changes its three stems at the existing playback phase. Near-post goal scoring uses the swept center between physical post inner faces: actual Jolt post collisions handle the oriented wheel shape, avoiding the previous incorrect subtraction of the wheel radius from lateral clearance. Post-graze status now requires real contact, and a rebound is allowed to recover before the attempt ends.

Smooth, compact earthworks add two diagonal crests, a trough, an outer bank and a side takeoff. The side gap omits mesh/collider cells; the ground query uses the same cell centers. Existing obstacles are moved out of the excavation. Low drops terminate as GAP and freeze the result. Modifier graphics conform to the terrain; ice changes the actual friction material and restores grip on exit. Boost/spring impulses and gap-landing style remain deterministic physics events.

Glass panels use static colliders and one transparent MultiMesh. Normal impact speed (4.8 m/s) separates banks from shattering. Breaking adds a collision exception only between that wheel and the panel, preserving independence among the simultaneous solver tires. Rendering hides the pane and emits 16 short-lived decorative shards. New tires and restored instance transforms reset both collision and appearance on retry. The full solver required a wider finish approach on Ember 03 for all five seeds.

Android's Vulkan path failed to present on the available emulator; the Android export now selects OpenGL compatibility, which completed the actual game loop. APKs are signed with an explicitly local testing key and alignment/signatures verified. iOS's official template contains only x86_64 simulator code, invoking software GLES through Rosetta. Its simulator-only canvas/3D budget is reduced to make functional playtesting practical; the device path retains normal rendering. iOS playtest launch uses an environment flag because the supplied template does not reliably forward user arguments. Both mobile harnesses avoid writing player progress.
