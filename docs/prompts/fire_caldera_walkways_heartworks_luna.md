Implement the updated Fire Kingdom walkways and Caldera Heartworks. This is a build task, not another design pass. Use the current generated plans as the implementation baseline despite the briefs' older “proposed for review” labels.

Read AGENTS.md and CLAUDE.md, then these in full:
- docs/architecture/fire_caldera_walkways.md
- docs/architecture/fire_caldera_heartworks.md
- scripts/fire_caldera_walkways_plan.gd
- scripts/fire_caldera_heartworks_plan.gd

Use docs/drawings/fire_caldera_3d.html as the visual reference. Existing buildings remain; replace their circulation system and the obsolete underground scheme.

The essential contract:
- Consume BOTH plans directly. Walkways has LEVELS, FLIGHTS and SITE; Heartworks has LEVELS, FLIGHTS and SECTION. Read every floor outline, hole, railing line, flight profile and width from them. Do not reconstruct rings, offsets, junctions, landings or bridge alignments from the prose or model primitives.
- LEVELS.surface contains polygons with outer and holes: build the joined floor and matching collision, preserving every hole. These surfaces already include their connected porches, bridges and landings; do not overlay another slab for each named component. FLIGHTS.profile includes level approaches as well as slopes; preserve its sampled heights and endpoints instead of redistributing the drop over its total length.
- Plan points are local [x,z]; profiles are [x,world_Y,z]. Use FireCalderaPlan's frame exactly once. Level guards are 2D lines with handrail at datum + 1.09; flight guards are 3D handrail lines ALREADY lifted by 1.09. Do not add that height twice. Heartworks level datums are already world heights, not depths. Respect building-local SITE details in their own frames.
- Never hand-edit the generated plans. Their Python sources are tools/fire_caldera_walkways_layout.py and tools/fire_caldera_heartworks_layout.py, sharing tools/walkway_kit.py. If an actual contradiction blocks construction, report it precisely; do not invent a replacement layout. Sampled plan geometry takes precedence over approximate prose lengths.

Build in this order:
1. Surface walks. Replace fire_caldera_highline.gd's independently derived edges/guards with a reusable plan-driven floor/flight/guard builder. Integrate through fire_kingdom_terrain.gd. Implement the Gate Terrace/plinth, arrival gallery, Highline docks/refuges, Renewal horseshoe stairs, Oren spiral stair, promenade, yards/lanes and working counterbalanced funicular. Apply the documented datum and building-threshold changes together. Retire replaced routes and duplicated porch guards. Use one floor height at every junction; material changes, including the glass Renewal deck within the basalt promenade, must not introduce stacked slabs.
2. Heartworks, using the same builder. Implement the glass dome/open oculus, terraced chamber and supporting colonnades, two crossings, three double-ramp pairs, double helix, Floor, gallery and pool from SECTION and the resolved surfaces/profiles. Remove the superseded rooms, shafts, lifts and their stale validation/census references; preserve residents without inventing replacement underground rooms.
3. Lava and circulation. The one cascade must be actual swimmable/hazardous lava, with Lava Helm descent AND ascent between reservoir and collection pool. There is no dry entrance. Update terrain/liquid queries and vertical clamps as needed: a rendered hole is insufficient if old terrain collision or a height query still seals it or snaps a swimmer above the dome. Keep the surface and chamber functional for both playable characters.

Follow the briefs' glass/steel/basalt family and shared guard dimensions. Use CollisionPolicy for solid floors, stairs, guards, columns, dome and walls. Keep mouths unobstructed and transitions flush; cap exposed edges. Preserve authored curved outlines rather than replacing them with overlapping boxes. Batch static geometry and reuse materials within the existing staged loading system; avoid runtime CSG, per-panel processing or expensive new effects.

Before finishing, run both Python layout generators/checks, migrate tools/validate_fire_plan.gd to the new plans, and run its scene plus tools/player_support_handoff_probe.tscn. Use an isolated Godot copy if the editor is open. Check the real human and Xiao routes in both directions: all flight mouths/door thresholds, funicular boarding and riding, underground ramps/bridges, and Lava Helm entry/return. Capture the built chamber and key surface junctions. Report actual passes, failures and any untested routes; source-plan validation alone does not prove traversal. Do not export web, commit or push unless asked.
