# TreadFall 0.5.0 (15) mobile beta

September 7, 2026. Both platforms use `com.sweetpapa.treadfall`.

## Current status

**iOS:** Apple accepted the signed IPA with zero warnings, then processed build
`974bf6f1-8ba0-44b5-b2f1-4e3142ad1a36` as `VALID`. It is assigned to the internal
**TreadFall Playtest** group. The authorized tester has been invited and membership verified; build state
is **`IN_BETA_TESTING`**. Accept the email invitation to install with TestFlight. External beta review and production release have not been submitted.
The build expires December 6, 2026.

[Open TreadFall TestFlight](https://appstoreconnect.apple.com/apps/6809527457/testflight/ios).

**Android:** Google Play saved version code **15** to the closed **alpha** track
with status **draft**. The signed bundle, English listing, release notes, icon,
feature graphic and three native Android screenshots are saved. Activation was
attempted; Google returned: `Only releases with status draft may be created on draft app.`
This draft is **not available to testers**.

In [Play Console](https://play.google.com/console/), open TreadFall, complete the
required Dashboard app setup and declarations, configure the closed track's
eligible testers/countries, and send the first alpha release for review. These
Console-only steps cannot be completed through the publisher service-account API.
The saved release is ready to review; do not upload the same version again.

## Build and validation evidence

- Gameplay: full `tools/test.sh --full` pass, including 16,665 actual-physics rolls.
  Every sampled course/seed has a solution; zero trials remain unfinished at the
  test-only 120-second observation horizon. Regular-course mean clear rate 22.0%.
  One of 160 default course/seed rolls clears, so the difficulty check allows a
  rare legitimate bank instead of relying on a hidden deadline to reject it.
- Regression: real level 3 bank route clears after 41.47 simulation seconds.
  Slow motion at 0.1 m/s continues beyond two minutes; a stationary spinning tire
  becomes BLOCKED; retry resets the motion detector.
- Android: SPT upload-key signed AAB and APK, arm64, API 36. Exported-game tests
  passed both cameras, goal, pause/resume, retry, settings and daily mode on
  Pixel 9 Pro XL API 36 emulator. A separate normal-release touch test exercised
  angle dragging, view switching and a successful roll. Emulator p95 frame time
  19.03 ms; this does not establish physical-device performance.
- iOS: unsigned device archive built with Xcode 26.3 / iOS 26.2 SDK, then signed
  locally using the existing Apple Distribution identity. Apple validation and
  upload both reported zero warnings. [Successful cloud run](https://github.com/Sweet-Papa-Technologies/JumpyHill/actions/runs/34145028547)
  also passed the exported game on an iOS 26 iPhone simulator. The official
  simulator library is x86_64; its software OpenGL rendering is reduced and its
  71.82 ms p95 is not representative of an iPhone. Physical-device play remains.
- The refreshed local `build/macos/TREADFALL.app` passed packaged gameplay tests.
  It uses an ad hoc local-testing signature, not a new notarized distribution.

Checksums and exact store IDs: [release-05.json](verification/release-05.json).

## Screenshots

All captures are actual game rendering, without mock phone frames or promotional
claims superimposed on gameplay. The source viewport capture helper preserves
native resolution independently of the Mac window's physical size.

- App Store: four 1290×2796 iPhone and two 2064×2752 iPad captures. Uploaded asset
  states were independently verified `COMPLETE`, without delivery errors.
- Play: three 1344×2992 captures taken directly with `adb screencap` from the signed
  Android release: first-person aim, course view, and the cleared result screen.
- Play icon: 512×512 rendering of the game's original vector icon.
- Play feature graphic: 1024×500 actual title/course rendering.

Files: `build/store/screenshots/`. Capture source: `tools/store/screenshots.gd`.
Upload receipts and logs: `build/store/`. These ignored local artifacts contain
no printed private keys or authentication tokens.

## Releasing another beta

The helpers are adapted from the existing FoFo Tetro Cubes release setup in
`~/code/suduko/scripts/release`. Signing keys remain local.

```sh
# Android: explicit, monotonically increasing version code.
TREADFALL_BUILD_NUMBER=16 TREADFALL_VERSION=0.5.1 python3 tools/store/build-android.py
node tools/store/play.mjs                              # inspect only
node tools/store/play.mjs --upload build/android/TREADFALL-store.aab
# --draft saves a reviewable draft if the app remains uninitialized in Console.
# --activate activates the single existing alpha draft after Console setup.

# iOS: GitHub builds without private signing keys; download the archive locally.
gh workflow run ios-beta.yml -f version=0.5.1 -f build=16
python3 tools/store/sign-ios.py PATH/TO/TREADFALL.xcarchive
# Validate and upload using altool plus existing App Store Connect credentials.
node tools/store/testflight.mjs                        # inspect only
node tools/store/testflight.mjs --build APPLE_BUILD_ID # assign a processed build
```

Android signing reads `~/code/SPT`, alias `spt`, and its existing Android Studio
Keychain password entries. Publisher credentials default to
`~/secrets/fofo-play-publisher.json`. Apple API helpers use the existing local
`.p8` key used for Tetro Cubes; paths/IDs support environment overrides. Private
key files, profiles and generated artifacts are excluded from git.
