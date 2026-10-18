# Fire Kingdom loading assessment — 18 October 2026

Assessed source commit `54bbf41` on Godot 4.7.1. No gameplay source or generated assets were changed. All instrumentation and experimental changes ran in `/private/tmp/eleblorb-npc-review/proj`, with a separate Godot import cache.

## Finding

Repeated CPU terrain evaluation dominates startup. The new plan-driven walks and Heartworks are comparatively inexpensive to construct. Fire still builds its full terrain and settlement synchronously in `_ready()`; it does not use the staged build queue used by Crossroads. Background resource loading cannot spread those callbacks across frames.

## Measurements

One headless baseline and one controlled height-cache experiment, running the actual `scenes/fire_kingdom.tscn` with its normal children and autoloads. Times are development measurements on this machine, not graphical first-playable-frame or release benchmarks. Resource caches were already imported; OS disk caches were not controlled.

| Stage | Current source | Test-only cached coarse vertices |
| --- | ---: | ---: |
| Scene resource load | 1.76 s | 2.07 s |
| Coarse kingdom terrain mesh/collision | 40.50 s | 2.07 s |
| Fine city ground mesh/collision | 46.52 s | 6.03 s |
| Surface walks/site and foundation construction | 0.50 s | 0.46 s |
| Heartworks builder | 0.40 s | 0.38 s |
| Village `_ready()` including building construction | 4.58 s | 5.22 s |
| Deferred work between scene ready and first process-frame observation | 19.61 s | 2.45 s |
| Scene request to first process-frame observation | **114.16 s** | **18.92 s** |

The cache experiment retains the same terrain resolution, height formula, building builders and collision generation. It memoizes `_vertex(ix, iz, s)` by grid coordinates in the terrain instance, after river centreline preparation; all live callers use the same fixed grid spacing. It demonstrates approximately **83% less startup time** without lowering geometric fidelity. It is an experiment, not a production implementation or a traversal regression pass.

The baseline diagnostic reached all frame observations, then its mesh-count helper called an ArrayMesh-only method on a primitive BoxMesh and stopped; that diagnostic process was terminated. The corrected counting helper completed in the cache run. This counting error occurred after the timing observations and does not affect their values.

Engine-reported static allocations settled around 467 MiB baseline and 469 MiB with the cache. These are not process RSS, peak memory or GPU memory measurements. The resulting cached scene contained 7,217 descendant nodes, 4,572 MeshInstance3D nodes, 1,572 explicit CollisionShape3D nodes and 262 CSGShape3D nodes. ArrayMesh surfaces alone accounted for about 3.29 million triangles; primitive meshes and evaluated CSG are additional geometry. These counts flag follow-up rendering/memory work, but are not draw-call or FPS measurements.

A third test removed the 75 root CSG trees after constructing the cached scene, solely to isolate their deferred cost. The ready-to-first-frame interval fell from 2.45 s to 0.76 s, with static allocations around 419 MiB. This is a diagnostic ablation that removes geometry and some collision, not a proposed playable configuration; it supports treating runtime CSG as a secondary cost. Timing differences are from single runs.

## Why it happens

- `fire_kingdom_terrain.gd:397–406` reconstructs four coarse grid vertices for every interpolated height query. Each vertex reruns noise, volcano shaping and river coverage. `_river_coverage()` scans all eligible segments of the authored river paths.
- The outer 121 × 121 grid repeatedly evaluates those same vertices for mesh positions, finite-difference normals, indices and collision: approximately 364,097 height evaluations for 14,641 unique grid vertices.
- `fire_caldera_ground.gd:186` builds a 513 × 513 fine grid at 0.5 m spacing: 263,169 vertices and 524,288 visual triangles. Each vertex calls the coarse wall-height sampler, adding 1,052,676 coarse vertex evaluations. This happens even where the blend weight gives the coarse wall no influence.
- Fine-ground height/socket sampling alone took 44.25 s baseline, falling to 3.87 s with cached coarse vertices. Building its collision shape took about 1.27 s baseline. Disabling collision is therefore the wrong remedy.
- Deferred vegetation and actor placement also query terrain. The large fall in deferred time with the same cache shows that repeated height work continues beyond the synchronous terrain stage. The baseline deferred interval was not individually attributed to each callback.
- Existing building roofs/skylights still use runtime CSG. Fire has no equivalent of the Chinese Village or Moy persistent architecture bake. The new walkway/Heartworks renderer itself uses direct meshes and combined guard runs; those builders are not the dominant measured startup cost.

## Other scenes

The Fire scene references its own terrain, settlement, actors and shared systems. Its return destination is a string path to `main.tscn`, not a concurrently instantiated Crossroads world. Portal travel changes the current scene. This assessment found no evidence that China, Moy or the other kingdom scenes are being constructed in parallel with Fire. Shared character code and autoload resources are still resident.

## Recommended order

1. **Cache the fixed coarse terrain grid once after river initialization**, then reuse those exact vertices for visuals, normals, fine-ground blending, collision and gameplay height queries. Invalidate on river/terrain configuration changes; do not reuse detached preview sampling before rivers exist. Verify sampled height agreement and surface/support routes for both characters.
2. Avoid evaluating the coarse wall sampler where the fine bowl blend weight is zero. Keep a cached socket outline/bounds lookup. Profile the remaining fine-ground and vegetation work before reducing resolution.
3. Bake deterministic terrain and static architecture offline with source-signature validation, retaining real openings and collision. Reattach doors, lava queries, markers, NPCs and funicular behaviour separately. Fail visibly on missing/stale bakes rather than entering an empty world. Reuse the existing settlement-bake approach.
4. Integrate Fire with the loading queue and subdivide remaining main-thread jobs. Merely placing an unchanged 40-second generator into one queued stage will still freeze that stage.
5. Profile the optimized scene with the actual renderer. Merge repeated static detail by useful spatial/material groups and share materials; evaluate surface versus underground activation and later distance-based loading. Preserve collision ahead of all reachable routes, lava ascent/descent and recovery spawns. No need to redesign the approved layout to solve the measured bottleneck.

A windowed shader/render profile, peak RSS measurement, cold/warm repetitions and full traversal validation remain follow-up work. The CPU-only measurements already establish a large and inexpensive first optimization.

Raw diagnostic logs: `/private/tmp/fire-startup-profile.out`, `/private/tmp/fire-startup-cache.out` and `/private/tmp/fire-startup-no-csg.out`. The completed headless runs emitted dummy-renderer resource cleanup warnings on exit; no clean graphical shutdown or gameplay QA claim is made.
