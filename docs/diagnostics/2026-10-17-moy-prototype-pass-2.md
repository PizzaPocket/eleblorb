# Moy prototype pass 2 diagnostic

2026-10-17. Source implementation and offline bake status after the second
prototype pass. This report records measured checks; it does not claim a
completed hands-on playthrough or rendered performance run.

## Input plan and build

- Latest `main` was fetched before implementation. `HEAD` and `origin/main`
  both resolve to `5dc741d01fcf7887a5be9d852d664438b0f92554`.
- `tools/city_layout.py --json /tmp/moy-plan-final.json` regenerated
  `scripts/city_plan.gd`: 23 streets, 48 buildings, 133 lots, 9 courts. The
  configured Shapely environment prints a runtime warning
  (`invalid value encountered in distance`); it printed no `PROBLEM`.
- The baked prototype contains 57 packs. `tools/check_moy_bake.py` passes for
  23 streets, 48 buildings, 133 lots and 60 old houses.
- The offline builder now reads plan values for the Crossing towers, Deck,
  park planting, station escalators, frames, piers, platforms and timetable.
  Repeated small plants use per-cell MultiMeshes with serialized transforms;
  trees, towers and buildings keep separate collision bodies.
- `tools/validate_city_plan.tscn`: 23 streets, 48 buildings, 133 lots,
  **0 failures**.
- Script/editor scan completed. Godot emitted the host's certificate lookup
  warning and could not save its editor settings outside the workspace; no
  project parse error was reported.

## Runtime validation

`tools/validate_moy_runtime.tscn` ran headless from a fresh process. It
finished with **6 failures**, all reported below.

| Check | Result | Measured evidence |
|---|---|---|
| Plan placement | Pass | 911 records checked within 0.05 m; includes 164 columns, 582 bed segments, 32 trees, 96 plant points, 16 frame/pier points. |
| Main counts | Pass | 57 packs loaded; coverage 23 streets, 48 buildings, 133 lots, 60 old houses; 60 separate old-house bodies and 133 lot bodies. The builder's exact count checks cover 4 towers, 164 Deck columns, 131 parapets, 50 beds, 9 Deck trees, 23 park trees, 62 shrubs, 28 reed clumps, 21 rocks, 6 agave, 104 climber panels, 8 Meridian piers and 8 station access sets. No wind trees, tunnel or flyover were detected. |
| Deck and park surfaces | Pass | 4 Deck ramps, 4 gate openings, pond water at y=-59.6 with 4.35 m depth. |
| Vine and suit handover | Pass | Six vine route searches; human-to-Xiao-Hou-Zi and return with six full-plant slots. |
| Trains and service schedule | Pass, with clearance failures below | 12 consists, 30 independent cars; stop counts Spine 5, Meridian 3, Wall inner 4, Wall outer 4; 8/12 second interchange dwell; simulated one game day at 1x/10x. No train-to-train collision found. |
| Lift | Pass | Crossing lift moved 1.986 m during the runtime sample. |
| Timekeeper | Pass | Hollow hour/minute rings and moving seconds bead at radius 14.1 m. |
| Train clearance | **Fail: 6 overlaps** | See geometry conflicts below. |
| Physical route use | Untested | The runtime validator checks route geometry and moving state, not capsule walking/riding/stepping off every ramp, escalator, tower hand and core flight with both playable characters. |
| Train boarding through doors | Untested | Cars have separate rideable bodies and door apertures; an actual player boarding traversal was not measured. |
| Track-and-platform passage | Untested / incomplete | Core flights are built. The plan acknowledges missing core-to-platform/bridge passage data and calls for straight prototype passages with their dimensions recorded; those passages have not been built in this pass. |

### Geometry conflicts to resolve in plan

The train-envelope validator found these intersections while sampling the
full car envelope:

- **North Gate interchange:** the Spine train overlaps
  `WallLine_Station_North_Gate_Platform_0_5` twice at x=-561.5 and the
  adjacent platform segment `...0_6` at x=-558.5, y=-46.8, z=-200.0.
  The authored Spine and Wall Line interchange is level at rail +13.2, while
  the platform segments occupy the train envelope at the same point. The
  source geometry does not provide a clearance dimension here.
- **Meridian lower bridge:** the Meridian train overlaps
  `MeridianArchLowerBridge` at (-336, -24, -1.5) and at the corresponding
  z=+1.5 samples. `ARCH.lower` spans +32 to +42 while the Meridian rail is
  +36 at the East Gate. These source values put the solid slab through the
  train envelope.

Neither conflict was “fixed” by moving plan geometry or shrinking the train.
The plan needs to specify the intended opening/clearance at these places.

## Activation and performance

The headless runtime log measured pack activation and frame deltas. All 57
packs reached active state; some dense packs materialized over several frames.
Observed activation-frame deltas ranged from 0.48 ms to 150 ms, with the
largest first-frame value 150 ms. During the densest later activation, samples
included 51.9 ms, then 34.0 ms and a run around 20–25 ms. These are headless
diagnostic timings, not rendered GPU frame-time results.

`tools/moy_performance_probe.tscn` and its Crossroads-to-Moy, dense-city,
named-view and two reload-cycle measurements are prepared. The rendered
windowed probe was **not run**, so FPS, p50/p95/p99, draw calls, GPU memory,
and rendered reload behavior remain untested. No performance budget pass is
claimed from the headless timings.

## Other required checks

- `tools/check_power_parity.py`: pass (10 powers across 2 playable characters;
  it notes the existing inline FlightMode duplication).
- `tools/check_body_pose_owner.py`: pass.
- `tools/check_design_language.py`: pass.
- `git diff --check`: pass.

## Acceptance still open

The plan's required physical route traversal, line changes by escalator and
lift, route headroom/junction checks, actual player train boarding, and
rendered performance samples remain untested. The headless runtime test has
the six train-clearance failures above. These results should be resolved or
verified in the next playable QA run; this diagnostic does not mark them as
passes.

## Follow-up geometry correction

After the first walkthrough, the Crossing's vine panels and spiral-hand
landings were found to use the radial bearing for their long axis. That
rotated both by 90 degrees from the tangent direction. The builder now
rotates both to the tangent, keeping the vines around the ribs and each
landing aligned with its incoming/outgoing escalator segment. The offline
bake was regenerated.

Focused runtime geometry checks now report **96/96 hand landings tangent**,
**104/104 climber panels tangent**, and **14/14 East Gate core flights** with
paired lane center spacing of 1.2 m. This verifies orientation and lane
layout, not a real player's full ride-on/step-off traversal. The full runtime
validator still ends with the same six unrelated train-envelope failures at
North Gate and the East Gate lower bridge.
