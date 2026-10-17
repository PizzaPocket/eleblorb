# Crossroads performance and China architectural remediation

Implemented 2026-10-16 following the diagnostic in
`2026-10-16-crossroads-and-china.md`. This is a source change, not a web release.
Existing unrelated working-tree changes have been retained.

The subsequent fidelity and real-water corrections are recorded in
`2026-10-16-china-fidelity-followup.md`; measurements below describe this
earlier remediation checkpoint.

## Why the model and game diverged

The Three.js model and Godot agreed on much of the settlement placement but
used different building construction code. Generic domestic shells substituted
for the prescribed palace halls. East/west rotation exchanged frontage and
depth; a roof-detail branch accidentally applied only to the animal pen.
Hall bay count, eave height, roof rank, terrace rails and lantern attachment
were not enforced against the reference. These are implementation defects;
superellipse interpretation does not require changing architectural dimensions
or omitting the prescribed members.

`tools/chinese_village_plan.py` now exports palace architectural specifications
alongside the plan and updates the model's embedded data. Godot's dedicated
`chinese_architecture.gd` consumes those specifications. `check_chinese_bake.py`
compares the model's placements, openings, paths, ramps and hall specifications
with the runtime data and checks the baked geometry's source signature.
This prevents data drift; rendered comparisons are still needed because each
renderer constructs its own geometry.

## Implemented construction

- Correct local frontage/depth, seven-bay throne hall and prescribed hall
  heights, double eaves, joined hip/xieshan roofs, red columns, lattice windows,
  painted beams and bracket sets. The upper pavilion floor has headroom.
- Three-tier terrace balustrades, sloped flight rails, inner-court and island
  edge guards, gate base and access ramps, supported pavilion forecourt/mound.
- Three separately entered apartment rooms and permanent partitions; civic
  furnishing changes within that shell.
- Household three-bay facades, 0.45 m plinths, grey hard gables, black doors,
  blue curtains, threshold ramps, drying produce and kang flues.
- Lanterns centered on their supporting posts.

The service descent remains justified by the approved level difference, but
its earlier continuous connection was insufficiently resolved. It now has two
4.5 m flights, an intermediate landing, a top turning platform, ground landing,
guards and masonry support. Its ground end connects to the approach beside the
kitchen's west door. The throne terrace front recess was increased from 2.5 m
to 3.44 m to accommodate a 2.24 m flight plus 1.2 m landing; the model and runtime
were updated together. The garden ramp's level direction was also corrected.

Manchego now samples built support at spawn and while ridden, rather than
snapping to terrain below floating islands. Grounded obstacle sweeps follow
walkable ramp normals while retaining wall collision.

## Memory and loading

China's static construction is baked to compressed meshes and collision in
`assets/generated/chinese_village.scn`. Doors are reconstructed as moving,
interactive objects; civic furnishings, NPCs and inn service remain live.
Crop fields and bamboo use shared meshes and spatial MultiMesh batches.

At ordinary Crossroads spawn, only a cheap China silhouette is built. The
resource prefetches at 510 m, activates at 410 m and unloads beyond 620 m.
Prefetch distance increases for a fast controlled body. The player and active
controlled body both count; recruited companions and quest state survive
unloading. Modal interactions delay unloading and inn recovery ensures the
region exists first. A runtime WeakRef check confirms the PackedScene is
released after unloading.

Fire Kingdom is a separate scene and is not loaded with Crossroads. Other
Crossroads generators still contribute to startup; this pass specifically
removes the measured China bottleneck.

## Measurements

Same development machine, Godot 4.7.1, Metal Forward+, fixed camera, capped
60 FPS. These are development measurements, not a release performance guarantee.
Build time runs from scene resource loading through queued construction.

| Measurement | Before | After |
|---|---:|---:|
| Crossroads build | 52.95 s | 17.89 s |
| Fixed spawn view | about 2.4 FPS | 60 FPS |
| Spawn draw calls | 20,612 | 871–872 |
| Static memory at spawn | 985 MiB | 468 MiB |
| Reported video memory at spawn | 2,342 MiB | 1,446 MiB |

With China active, the measured view ran at 59.3–60 FPS, 3,376 draw calls,
about 638 MiB static and 1,714 MiB video memory. The isolated QA scene built
in 2.57 s and ran at 60 FPS, about 296 MiB static and 624 MiB video memory.
Those measurements preceded the final small landing/support and mount fixes.

**Remaining limitation:** first activation took 1.40 s with a worst frame of
929 ms. Background resource loading does not make PackedScene instantiation
and actor construction incremental. For Moy, split construction into districts
and blocks, budget main-thread activation across frames, prefetch along travel
routes, and establish view-distance, draw-call and memory budgets before adding
the full city. The current whole-settlement activation is not sufficient proof
that a settlement ten times larger will perform acceptably.

## Review and verification

Open `scenes/chinese_village_qa.tscn` and run the current scene (F6). This uses
the real player, terrain, village, Blorbus and Manchego without constructing the
other settlements. Run the main scene to check approach and departure behavior.

Evidence is in `wip/diagnostics/2026-10-16-china-remediation/`, including final
palace, service route, household and inn renders and the measurement logs.
The architecture remains a work in progress: complete garden/inn detail,
interior dressing, story staging and a full human walkthrough remain open in
the settlement backlog. Selected views and automated checks do not certify
every building, bridge or story sequence.

Checks cover plan geometry, built hall dimensions and roof rank, apartment
doors, household bays/plinths, upper pavilion headroom, lantern alignment,
instanced crops, moving doors, physical ramp surfaces, player/Blorbus/Manchego
clearance, ridden flights, mount wall blocking, resource release, recruited
companions, civic-state restoration and threaded activation. Pose ownership,
power parity and design-language checks also pass. The existing FlightMode
duplication notice remains. Ohio and Snow regression results are saved with
the evidence (Ohio: 0 failures, 8 warnings; Snow: 0 failures, 5 warnings).
The player support handoff probe also passes. Headless macOS runs reported a
certificate-store diagnostic, and the standalone plan/support probes reported
two ObjectDB instances at exit; these are retained in the logs. No claim of a
full interactive story QA pass is made.

## Regenerating the cache

1. If changing plan data, run `python3 tools/chinese_village_plan.py` in an
   environment with its Shapely and NumPy dependencies. This updates both the
   runtime constants and the model's embedded data.
2. Close the editor before using the live project, or use the documented
   scratch-copy workflow. Never run concurrent Godot processes. Import the
   scratch project once after adding script classes.
3. Run Godot headlessly with `tools/bake_chinese_village.tscn` as the scene.
   For a scratch build, copy its generated `.scn` and `.scn.sha256` back into
   the live project's `assets/generated/` directory.
4. Run `python3 tools/check_chinese_bake.py`, the China plan validator and
   `tools/validate_chinese_runtime.tscn`; render representative views.

China is included in the pre-push village checks. Do not regenerate the
deprecated web build for these changes.
