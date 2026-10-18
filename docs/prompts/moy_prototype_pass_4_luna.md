Implement Moy prototype pass 4 in this repository. Read AGENTS.md, CLAUDE.md,
then the current docs/architecture/moy_prototype_pass_4.md in full. Follow
pass 3 and earlier briefs only where pass 4 retains them. Read the city.md
sections and 3D model views it names; keep the Grand Hotel's detailed model
and its existing implementation. Execute the pass, rather than planning it
again.

Use CityPlan data directly through the existing Moy bake builder and runtime
systems. Never hand-edit scripts/city_plan.gd or reconstruct dimensions from
the model. Correct data through tools/city_layout.py if necessary. Report
contradictions; retain the brief's explicit 7.5 cm platform-gap override.

Preflight on 2026-10-18: the Python layout checks completed, but regenerating
on this machine changed WALL, OLD_TOWN and OLD_HOUSES polygon serialization
and some vertices, with a Shapely distance warning. The pulled generated
plan was restored. Check the geometry-tool versions and report these
differences before accepting a regenerated plan; do not treat them as an
approved layout change.

Complete in working stages:

1. Civic Plaza, the westward hotel skybridge and City Hall's front: exact
   scissor bands, steps, landings, guards and lift stops.
2. Moving handrails and closed escalator sections, including solid soffits;
   clear the helix bands and every tower ways_out entry using the authored
   eight ribs and hoop heights.
3. The lattice glass dome, actual open clock eyes, bell and Clock Room:
   arrivals, wells and extended lifts. The latest revision REMOVES the eye
   escalators and landings. Only flying/gliding reaches the eyes' sills.
4. The reed pond: shared VillageWorks.water_material(), real basin/banks,
   collision hazard metadata and matching terrain/liquid queries. Its
   surface is 0.3 m below park ground, not above it. Remove the bespoke
   pond shader and update bake signature inputs accordingly.

The cloud pull on 2026-10-18 changed city_plan.gd and city_layout.py, so
tools/check_moy_bake.py currently reports a stale bake. Rebuild using
tools/bake_moy_city.tscn after implementation; inspect Godot output for
SCRIPT ERROR even if exit status is zero. Do not edit manifest hashes to
pretend old geometry is current. Local compatibility fixes already handle
optional dome ribs and the 47-building/22-street counts; preserve them or
replace them with the complete implementation. Counts alone do not prove
pass 4 was built.

Run tools/city_layout.py, check_moy_bake.py, validate_city_plan.tscn and
validate_moy_runtime.tscn. Verify actual arrival/loading in Moy QA and New
Game, plus named tall-building presence. Retain spatial streaming and
offline static construction. Measure with moy_performance_probe.tscn using
a real renderer; headless timing is not FPS. Test both playable rigs on the
brief's routes, rides, landings, undersides, clock eyes and pond. Recheck
the retained clock-face tests. Report passed/failed/not physically verified
in a dated pass-4 diagnostic, with performance and bake freshness results.

Continue through all stages without asking for approval between them. If
interrupted, leave an exact resume checklist. Keep this thread on Moy;
preserve the shared movement/vine fixes and leave Fire's lava migration to
its own thread. Do not export build/web, commit or push unless asked.
