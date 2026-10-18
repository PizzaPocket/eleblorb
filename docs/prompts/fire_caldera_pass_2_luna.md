Implement Fire Caldera build pass 2 in this repository. Read AGENTS.md,
CLAUDE.md, then docs/architecture/fire_caldera_pass_2.md and its linked design
sections, loading diagnostic and 3D model. The brief is the implementation
checklist; execute it, rather than writing another plan. It supersedes the
older walkways/Heartworks starter prompt.

Work through the brief in order, leaving a working checkpoint at each stage:

1. Fix loading: cache coarse vertices after river/configuration setup, skip
   zero-weight coarse sampling, bake static architecture/roof CSG offline,
   then subdivide remaining construction through the loading queue. Record
   comparable before/after times; a queued monolithic build still freezes.
   Invalidate cached heights when terrain configuration changes, including
   the new corridor grading and ground cuts. Keep collision and resolution.
2. Fix the shared walkway builder: slope-only flight decks, owned-level
   exclusion, ground cuts/retaining edges, outward winding, materials and
   exact guard openings. Then implement the gate, funicular, Renewal ramps,
   Oren's connections and building repairs from the brief.
3. Implement the three real lava volumes and migrate immersion, surface,
   camera and ambience queries. Preserve the existing shared mobility and
   surface-escape fixes for every playable rig. The terrain already exposes
   get_lava_surface_height_at(point); reconcile that with the brief's name
   get_lava_surface_at rather than maintaining two different calculations.

Read all outlines, holes, deck profiles, guard lines, cuts and datums from
scripts/fire_caldera_walkways_plan.gd and fire_caldera_heartworks_plan.gd.
Do not infer them again from screenshots or hand-edit these generated files.
Change the Python authoring tools and regenerate only if a data correction
is necessary. Apply the plan-to-world transform once. Use the model to check
appearance and junctions. Data wins over prose; report contradictions.

Extend tools/validate_fire_plan.tscn and fire_caldera_world_probe.tscn for the
new data and actual collision. Check both playable rigs, all public routes,
funicular docking/carrying, roof/lift exits, clearance and lava-to-air
transitions. A stationary support ray does not establish a successful ride.
Keep timing, automated checks and physically verified play separate in
docs/diagnostics/2026-10-18-fire-caldera-pass-2.md (or the execution date).

Continue through the checklist without asking for approval after each
stage. If interrupted, record completed/remaining steps and exact commands
so work can resume. Do not redesign the settlement, touch Moy, revert local
movement fixes, export build/web, commit or push unless explicitly asked.
