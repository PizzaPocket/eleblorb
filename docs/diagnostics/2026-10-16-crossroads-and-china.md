# Crossroads performance and Chinese Village review, 16 October 2026

The current Chinese Village implementation is the dominant rendering problem in the tested Crossroads starting view. Its architecture also falls substantially short of the approved brief. The layout work is useful, but the runtime buildings are still an intermediate implementation and need correction before decorative polish or further expansion.

This was a diagnostic only. No gameplay source, existing plans, or web-build files were changed. Measurements and test-only alterations ran in `/private/tmp/eleblorb-diagnostic/proj`, isolated from the working project's Godot cache. The reviewed state includes the existing uncommitted China and Fire changes, based on commit `251d414`.

## Measured evidence

Godot 4.7.1, Apple M5, Metal Forward+. Graphics captures were actually 3420 × 1902 despite the launch resolution request. These are development runs on one machine, not release benchmarks. Each rendering condition had eight settling frames followed by two approximately three-second samples. The controlled comparison used the same fixed camera near the starting clearing; the opening animation was skipped in that test only.

| Fixed starting view | FPS | Draw calls per frame |
|---|---:|---:|
| Current world | 2.40–2.43 | 20,612 |
| China hidden, still instantiated | 50.95–54.54 | 893–897 |
| China visible, its geometry shadows disabled | 2.40–2.43 | 20,611–20,613 |
| All world geometry shadows disabled | 2.41–2.42 | 20,532 |

An earlier run using the game's own opening camera also fell to approximately 2–3 FPS and 20,700 draw calls. Physics stayed around 2–3 ms in the controlled runs. This isolates a large rendering/submission cost from distant China; shadows alone do not explain it. It does not isolate render-thread CPU time from GPU time, and no claim is made about their exact split. Frustum culling cannot eliminate distant geometry that remains inside the camera frustum, even if terrain hides it from the player.

The headless construction comparison separates startup and memory from rendering:

| Measurement | Current world | China crop builder bypassed |
|---|---:|---:|
| Time from main-scene resource load start through queued construction | 45.39 s | 35.71 s |
| China construction callback | 14.45 s | 5.14 s |
| Godot static-memory monitor | 2,163 MiB | 1,590 MiB |
| Entire process tree node monitor | 56,200 | 42,573 |
| China subtree nodes | 31,981 | 18,354 |
| China MeshInstance3D nodes | 19,484 | 8,388 |
| China summed mesh-instance triangles | 11,514,598 | 3,382,918 |

The crop bypass saved approximately **573 MiB, 13,627 nodes, 11,096 mesh instances and 9.7 seconds of total construction**. It also omitted three crop-associated terrace boundary pieces; these are included in the difference. This experiment is evidence for batching and reuse, not a proposal to remove the fields.

Triangle totals sum mesh instances before visibility culling; they exclude CSG output meshes and are not triangles drawn per frame. Godot's static-memory monitor is not total process RSS or total GPU memory. Headless and graphical memory figures are not interchangeable. The graphical run reported about 2,342 MiB of rendering memory; hiding China retained that allocation, as expected. The headless world contained 370 live CSG roots and approximately 8,077 explicit CollisionShape3D nodes, in addition to collision owned by CSG. Once construction finished, headless memory remained approximately stable over the short sample. This test does not establish a memory leak.

Evidence and test harnesses are in `wip/diagnostics/2026-10-16-crossroads/`, including `measurements.json`, raw logs and current-source palace/kitchen captures. The captures use midday and disabled geometry shadows to inspect forms; they are not lighting or traversal sign-off. The scripts require the scratch loader's timing instrumentation to reproduce stage timings. For the crop experiment, `_build_field()` returned after its service-pits branch. The original builder was restored before both graphical runs and final validation.

## What loads, and when

`scenes/main.tscn` registers terrain, Ohio, the existing city, the fishing village, China, wilderness and other world objects. `LoadingScreen._drain_build_queue()` executes their substantial construction callbacks sequentially on the main thread, yielding between whole jobs. It does not divide each job into a small frame budget. The corresponding headless callbacks took about 0.5 s for initial terrain, 8.9 s for Ohio, 3.2 s for the city, 4.6 s for fishing, 14.5 s for China and 6.5 s for wilderness. Resource loading, intervening frames and other initialization account for the remainder.

The **Fire Kingdom city is not instantiated alongside Crossroads**. `main.gd` stores destination scene paths as strings; `Portal.destination_scene` is a string, and `KingdomTravel.travel_to()` changes scenes on entry. Crossroads has its own volcano and fire effects. It also reuses the Ocean terrain script for underwater-environment helpers; loading that script is not instantiating the Ocean Kingdom world.

Sky Kingdom is already lazy: its expensive island build happens only when the bird-helm condition first activates it. The city and wilderness have distance-based suspension systems, but keep their geometry allocated after construction. China gates some lantern lights by distance, but has no comparable whole-settlement visibility/activation system in the new builder.

The crop implementation creates a separate stem, head and leaves per plant. `SuperEgg.build_part()` creates fresh geometry and a material each time. The new plan builder does not use MultiMesh or StaticMerge for these repeated parts. The older China script already contains a bamboo MultiMesh helper, so instancing is compatible with the established visual language.

Shared `TownProps` walls construct live Boolean/CSG facades with 96-segment opening cutters and collision during world startup. This is another upfront cost and an obstacle to smooth streaming. `terrain_generator.set_canyon_zone()` also rebuilds the terrain during wilderness generation after the initial terrain build; this is secondary to China's measured cost.

## Immediate work to restore QA

1. **Gate distant China detail by location.** Keep a cheap island/building silhouette at distance and activate the full local settlement near approach. Apply simulation and light activation as well. Hiding the full China root is a proven emergency QA switch for testing elsewhere; it saves rendering work but does not reclaim its memory or startup cost.
2. **Batch repeated vegetation first.** Use shared crop meshes/materials and spatially divided MultiMeshes per field or patch. Use suitable tessellation for small leaves and seed heads. Batch bamboo and repeated static detail too. Dividing batches spatially preserves useful culling; one giant world-wide batch would be a poor substitute. Keep the authored crop distribution and field outlines.
3. **Provide a China-only playable QA scene.** Load its required terrain/hazard adapters, settlement and party without constructing Ohio, fishing, the city and the entire wilderness. This also makes visual comparisons practical. It must exercise real doors, supports and quest state, rather than serve only as a screenshot stage.
4. **Bake deterministic architecture ahead of play.** Preserve the plan-driven authoring process, but cache final meshes, materials and collision as reusable resources. Replace runtime CSG with baked results. Architectural collision remains required; removing substantial collision is not an acceptable optimization.

Godot explicitly recommends replacing final CSG with baked static geometry: [CSGShape3D documentation](https://docs.godotengine.org/en/stable/classes/class_csgshape3d.html). Its [MultiMesh guidance](https://docs.godotengine.org/en/stable/tutorials/performance/using_multimesh.html) explains batching and its culling tradeoffs.

## Scaling to the future city of Moy

Location-based loading is feasible and appropriate. Crossroads can remain one continuous playable world while its detailed content is divided into independently loaded regions.

- Keep world state, quest flags, party ownership and lightweight region/portal anchors persistent. Keep local geometry, collision, residents and dressing in unloadable region containers.
- Use three states: distant proxy; prefetched resources; fully active local content. Unload distant detail when memory must be reclaimed. Visibility and sleep alone retain allocations.
- Load baked resources asynchronously, then instantiate/attach content in bounded main-thread work. Threaded resource loading cannot make a giant procedural `_ready()` callback inexpensive. See [Godot background loading](https://docs.godotengine.org/en/stable/tutorials/io/background_loading.html).
- Choose prefetch distance from measured load time and the fastest supported flight/mount travel. Use a wider unload boundary to avoid repeated loading near an edge. Preserve landing collision ahead of approach and test fast travel, returning through portals and recovery spawns.
- Split Moy by district/block and interiors. A city ten times larger must not be one ten-times-larger startup generator. Keep a coherent distant skyline while loading only nearby detailed streets and rooms.

Acceptance should compare cold/warm startup, first playable frame, sustained frame time, stutters, CPU/RSS and rendering memory at the same cameras. Test approaching and leaving China, returning, fast traversal and story-state restoration. Establish budgets from the resulting baseline before adding the next settlement.

## China against the approved design

**Assessment: meaningful site-layout progress; architectural realization below the approved standard.** This needs correction at the building/section level. More lanterns or surface detail will not recover the planned proportions, roof hierarchy or circulation.

The authored islands, bridge network, compound positions, fields and palace levels are represented in runtime data. Named occupants and story-state hooks also have real implementation. The project itself describes this as an incomplete first runtime pass in `chinese_village.md` section 5. Those advances should be retained.

Three concrete defects explain much of the poor result:

1. **Roof-detail code is skipped for most primary buildings.** In `chinese_village_plan_builder.gd:583–585`, `_build_chinese_roof_details()` is inside `if key == "pen"`. Consequently the main palace halls and primary home shells do not receive that function's eaves, brackets, ridge treatment or lower double-eave planes. Separate shed/inn calls still run. The current palace capture visibly lacks the promised double-eave hierarchy. This also explains why source notes can describe new roof detail that never appears on those buildings.
2. **East/west-facing building footprints are rotated incorrectly.** The generic builder scales a shell to the plan's world-X/world-Z width and depth, then rotates it by 90 degrees. Floor collision sizes and transforms measured in the instantiated world confirm:

   | Building | Planned X × Z | Built X × Z |
   |---|---:|---:|
   | Royal Kitchen | 18 × 12 m | 12 × 18 m |
   | Inner apartments | 14 × 20 m | 20 × 14 m |
   | Dining Hall | 9 × 16 m | 16 × 9 m |

   The drawing's `itemFrame()` distinguishes local dimensions from world extents. The runtime does so for compounds, but not these individual buildings. Door positions, adjacent clearances and furnishing assumptions therefore diverge from the checked plan.
3. **Palace halls inherit domestic proportions.** The Throne Hall is a one-storey `TownProps` shell with a 3.25 m wall/eave datum, whereas the palace brief calls for 8 m to the eaves, seven-by-five bays and a double-eave imperial roof. The model uses its own tall column-and-bracket composition. A roof-family label and vermilion material do not reproduce that architecture. The current render reads as a broad ordinary house on a large podium, rather than the designed hall.

Other incomplete areas include the full architectural garden sequence, accurate moon/octagonal opening construction, rank-specific ceilings and interiors, and complete authored population behavior. Existing source adds some household schedules and civic furnishings, so these should be reviewed individually rather than called wholly absent. The runtime and drawing share placement data but still construct architecture with substantially different algorithms. A true common specification must also own local axes, bay counts, eave/column heights, actual openings, roof sections, terraces and route interfaces.

The structural GDScript validator passed in the scratch copy: 8 islands, 10 bridges, 54 items, 38 openings and 65 paths. That result coexists with the measured footprint errors because the validator checks plan arrays rather than the built building envelopes or traversed surfaces. It does not establish architectural fidelity or playability. The China validator is also absent from the current pre-push hook. The Python geometry generator could not be rerun with the default Python because Shapely was unavailable; no dependencies were installed.

## The service/kitchen ramp

The recent change appears to be the inner-court-to-kitchen descent. **Its purpose is sound and already existed in the approved palace brief.** The inner court is at +5.6 m, the kitchen and service yard at ground level, so a separate service connection is required. Two 2.8 m rises over 4.5 m runs give about 31.9 degrees, within the project's 32-degree convention. There is no need to raise the entire service yard to solve that relationship.

However, the present ramp should not be accepted merely because its plan validator passes:

- The detailed final landing ends at palace-local X=22. The planned kitchen's west wall is X=23. The rotated runtime kitchen's west wall is actually X=26. This leaves about 4 m between the landing's end and the built shell wall, before threshold details.
- The runtime creates thin rotated slabs for flights and landings, without a coordinated architectural support/retaining and guarding solution in that function.
- Other named multi-flight ramps are still represented more simply than the detailed drawing, so route-graph connectivity does not prove their physical section.

Fix the kitchen's coordinate frame first. Then draw and build one measured section from the inner-court surface through all landings to the real west-door threshold, including clear widths, turning room, slab-top datums, support and guards. Verify with physical sweeps and walked checks for the player, Blorbus and a mount. Repairing access against the incorrectly rotated shell would entrench the mismatch.

## Recommended sequence

First restore playable QA through location-based detail activation and vegetation batching. Then correct the palace coordinate/proportion defects and validate one complete representative house and the Throne Hall against the drawing, from matching aerial, approach, interior and eye-level views. Only then propagate the corrected builders through the settlement. Add runtime envelope/door/landing and traversal checks alongside the existing plan checks. Continue with cached region loading before expanding Moy or adding more densely modeled settlements.
