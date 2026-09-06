# Implementation decisions

- Pinned Godot 4.7.2, the stable patch available at kickoff. Engine binaries live in ignored `.tools`; assets and all game logic are vendored in the project.
- Chose a cylinder collider with a torus/tread visual. Wheel stabilization and lean use torque/force, with no position-based steering. A 16-second failed-roll cutoff keeps retries quick when an obstacle stalls the tire.
- Jolt contact caches changed repeated results in a reused space. Each AIM reset recreates the physics space while retaining meshes. A full-game retry test includes slow motion; the physics harness isolates each repeat and checks 1e-4 position precision.
- Resolve the spec's goal/post contradiction in favor of §5: crossing inside the gate after grazing a post clears with a 50-point penalty; a ricochet or crossing outside the tire-clearance interval misses.
- The guide uses actual collision queries with a reduced integration model. It is deliberately labelled an approximation in technical docs and is not used as evidence of course solvability. Full cloned-world prediction remains a gap.
- Original synthesized music avoids importing unverified music licenses. Four compositions each have synchronized base, melodic, and percussion stems; style crossfades the latter two. Kenney supplies impact and rolling textures.
- Current content is parameterized procedural terrain with three physical channels. All 33 courses pass the full sampled solver. It is a playable content draft, not a claim that the richer feature vocabulary or M1 human feel gate is complete.
- Headless tests use a dependency-free SceneTree assertion harness so all tests execute the production scripts without an addon. Test wrappers reject script errors as well as nonzero exits.
- macOS export verification found a zero-byte executable despite Godot's success exit. The build verifier restores the unchanged binary from the pinned official export template, validates its format and size, and then the app is launched and signed.
- The supplied iOS simulator archive contains x86_64 code despite its dual-architecture XCFramework metadata. The local simulator script builds x86_64 and was verified under Rosetta. No claim is made about an arm64 simulator build.

## 0.2 playtest response

Player feedback showed the broad 60% solver ceiling hid an obvious default winning lane. Regular courses now require zero default-launch clears across five seeds, at least one solution per seed, and a maximum 30% broad-grid clear rate. The tutorial keeps a gentler ceiling. Shallow terrain contours retain physical banking without the old strong gutter funnel; the center boost moved to a side route. A center barricade and staggered obstacles require launch/lean choices and optional nudge corrections.

Moving sweepers and shuttles use AnimatableBody3D, driven from physics time instead of the render loop. Their marked sweep areas show their reach, and their phases reset each retry. Moving visuals are excluded recursively from static mesh batching. Lean force applies while grounded, the axle banks to the selected angle, and there is no automatic forward force to push a blocked tire out of trouble.

The preview is explicitly a 0.65-second launch aid; it never supplies steering to the real tire and stops at a blocking face. Its reduced contact model is still not a full rigid-body pre-roll.

At termination the body freezes and the camera captures a bounded, immutable focus. The short orbit settles instead of chasing a body falling past the end of the hill. BLOCKED results offer route advice rather than reporting misleading distance from a finish never reached.

The visual additions are original repository geometry and shaders, extending the existing Kenney CC0 props: layered cliffs, ground grain, planted shoulders, warning stripes, biome landmarks and finish pavilions. No additional downloads or asset licenses are needed.

The result-freeze regression exposed alternating retry positions from pending forces retained by the old tire body. AIM now recreates just the small tire body before the fresh-world reset; course meshes and colliders are retained. Tests cover a route that reaches moving hazards and clears, rather than stopping at the first barrier. Slow motion remains enabled.
