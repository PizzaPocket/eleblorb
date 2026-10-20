# Moy P7 planning verification — 2026-10-20

Status: ready for implementation, targeting local L4. This report verifies
the plan and models; it does not certify the current game implementation.

## Scope and evidence

- Checked plan data binds 70 part templates and 18 joins across the entire
  Crossing, including structure, circulation, glazing, machinery, furniture
  and planting. The brief requires a part-by-part implementation report.
- The dome has 1,964 shared nodes, 4,032 unique members, 2,064 panes and
  2,947 glass triangles. Its graph is connected, with six closed boundary
  loops and Euler characteristic −4. Eye cuts and the open crown use the
  same pane boundaries; there are no zero-length pole members.
- Constant-section frame profiles and one unioned six-way junction are
  modelled beside the game-exported hero. Production junction welding,
  shading and collision still require verification in Godot.
- The P7 page and six existing drawing pages loaded in Chromium without
  script errors. Reference images cover the overview, dome, Clock Room,
  floor, eye, platforms, ground, node detail and section. See
  `docs/drawings/references/moy_crossing_*.png`.
- Derived bridges and ring tongues respect gallery voids. Fixture placement
  checks preserve the public ring route. Lift stops remain the authoritative
  four levels: 0, 14.2, 37 and 41.6 m; the brief removes unserved 6.5 m calls.

## Source findings

The current runtime lattice uses independent six-sided cylinders rather
than welded junctions. Its endpoint calculations mix row angles/radii,
collapse the final row to a pole and omit eye cuts. The glass is generated
separately. P7 requires replacing these paths with the shared checked grid,
constant profiles and flush, trimmed junctions, with close-up game evidence.

## Verification

- Plan generation and parts/joins checks passed. Exported plan data outside
  the new `crossing.kit` is unchanged from the preceding commit.
- Quick checks passed: pose ownership, power parity and design language.
- Bake freshness passed: 246 packs, 47 buildings, 133 lots, 60 old houses
  and 22 streets. The helper is included in bake source hashing.
- City plan validation passed: 22 streets, 47 buildings, 133 lots, zero FAIL.
- Baking produced resource-ID churn in otherwise unchanged runtime scenes;
  canonical scene files were retained with updated source-hash metadata.
  Headless renderer shutdown warnings remain; the bake exited successfully.

## Outstanding implementation proof

Luna must verify actual controller routes, collision and winding, lift
arrivals, clock operation, bell audio, close-up frame shading, matched P0
audit bounds, frame timing and repeated unloads. No runtime L4 pass is
claimed here. The model and references are committed locally; external
artifact publication is pending because this chat has no publisher.
