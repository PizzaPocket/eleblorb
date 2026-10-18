# Fire Caldera pass 2 implementation diagnostic — 18 October 2026

## Result

Implemented the loading, walkways, gate, funicular, roof-bake, and Heartworks
changes in `docs/architecture/fire_caldera_pass_2.md`. The generated plan files
were read as the source of outlines, holes, profiles, guard runs, cut levels,
and lava volumes; they were not edited. Shared movement support remains in
place for Player and Xiao Hou Zi. Moy and `build/web` were not part of this
implementation.

## Loading measurements

The before values are the single headless baseline run recorded in
`2026-10-18-fire-kingdom-loading.md`; the after value is one measured headless
run of the final live terrain/village build probe on Godot 4.7.1. Both measure
from process launch/scene request to the first observed process frame. The
after probe builds the same terrain, village, walkways and Heartworks through
the loading queue before the first frame. This is a development comparison,
not a graphical or cold-cache benchmark.

| Measure | Before | After |
| --- | ---: | ---: |
| Scene request to first process-frame observation | 114.16 s | 5.09 s |

The after measurement is a single run. It has no per-stage timing split, so it
should not be read as a release startup guarantee. The headless run reports a
macOS certificate-store warning and dummy-renderer resource cleanup warnings
on exit; the probe itself exits successfully.

## Automated checks

- `tools/validate_fire_plan.tscn`: passed, 0 failures. It checks generated
  levels, flight profiles, plan ownership, cuts/material data, volume data,
  and authored walkable-surface overlaps.
- `tools/fire_caldera_world_probe.tscn`: passed, 0 failures. All eight surface
  flights and eight Heartworks flights retain collision at sampled authored
  profile points for both playable rigs; level junctions, the Renewal tongue,
  Heartworks volumes, swimming transitions, funicular station platforms,
  arclength motion, and carrying both rigs were checked.
- Funicular corridor sampled ground-envelope maximum error: **0.0008 m** over
  the 109 generated profile samples. Each comparison uses the generated
  cross-track bed-width ground envelope.
- `tools/bake_fire_caldera.tscn`: passed; baked 11 keyed roof assemblies and
  wrote the source-signature manifest. Runtime falls back to CSG and reports
  stale/missing signature data.

These are automated scene and physics queries. They do not establish that a
person can traverse the routes comfortably, board the cars through the visual
doors, or inspect skylight appearance in the rendered game. No physical
playtesting or graphical visual inspection was performed in this pass.

## Remaining plan-data gap

The pass-2 brief requests cutting refuge pads to their underside and adding a
retaining edge around their outer ends. In the generated walkways plan,
`SITE.refuges` has each pad's ID, bearing, center, and ground height, but no
pad outline, underside/cut datum, or retaining path. The Python authoring
source contains construction parameters, but rebuilding those geometries in
the runtime would infer plan geometry rather than read it from the generated
plan. Those refuge cuts and retaining edges therefore remain unimplemented
until the plan authoring output includes those fields. No other generated plan
data was recalculated or edited to work around this omission.
