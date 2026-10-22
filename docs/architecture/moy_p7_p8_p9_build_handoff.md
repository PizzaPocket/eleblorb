# P7–P9 — Crossing, park and playground: one sequential build

2026-10-22. Start a **fresh builder conversation in the same project checkout
used for the completed P5/P6 work**. One implementation owner: P7 first,
then P8/P9 together, then one integrated review. Do not automatically start P10.

## 1. Preserve the actual built city before integrating this planning work

A new conversation is useful; a fresh clone is not the build baseline.
`moy_P5_review_2026-10-22.md` records accepted P5 implementation as **local,
uncommitted source and bake**, with a recovery snapshot. P3/P4 work is also
protected local implementation. The user reports P6 finished, but the planner's
remote check found no published P6 implementation checkpoint/report on main.
The older `claude/keen-franklin-tyqtng` branch is planning history, not P6.

Before editing:

- Confirm this is the current P6 builder's working tree, or restore its verified
  latest recovery snapshot into a separate checkout. Do not start from the
  planner's248-pack main bake and mistake it for the newer built districts.
- Read current git status and the builder's P6 completion report. Record its
  base commit, modified/untracked implementation files and current bake state.
  Make a verified recovery snapshot of that existing work before integration.
- Preserve P3/P4/P5/P6 source, nonignored new files, public routes and working
  bake. Do not reset, clean, overwrite with upstream generated packs, or broadly
  commit inherited files merely to obtain a clean tree. Keep ownership clear.
- Fetch and carefully integrate the latest planner main (including this handoff,
  model scene, P7 kit, park kit and pond-radius query correction). Merge source
  authoring, regenerate CityPlan; do not choose a generated-data side blindly.
  Preserve any local Crossing zero-area-triangle fix noted in the P5 review.
- If the current build/checkpoint is unavailable, request its checkout or
  recovery snapshot before changing shared builders/bakes. Do not rebuild or
  roll back P3–P6 to make a fresh main clone look complete.

P5 has an accepted practical L2 record. P6 is user-reported finished pending a
source checkpoint here; this handoff is not a new acceptance review of P6.

## 2. Read this small set, then build

Read AGENTS.md, CLAUDE.md, current roadmap direction, `moy_pkg_P7.md`,
`moy_pkg_P8.md`, `moy_pkg_P9.md`, their relevant checked kit data and models.
Use `tools/moy_crossing_kit.py`, `tools/moy_park_kit.py`, relevant city_layout
source and existing shared village builders. Read the architecture/landscaping
skills for shape/collision/ground rules. Do not restart historical district
repair audits, palette research or the old automation loop.

**Current practical construction direction wins over historical certification
gates.** Build a coherent playable model-matching area at Ohio/Snowhio detail.
The complete shape schedules remain design references: P7 72 parts/19 joins,
P8 41/12, P9 30/12. No exhaustive manufacturing ledger, all-surface/all-power
route matrix, repeated full-city capture or new movement/geometry framework.
Minor polish can remain; broken architecture, blocked public circulation,
missing substantial collision and conspicuous unfinished proxies cannot.

## 3. One authoritative Crossing, shown in the integrated park

- **P7 owns the complete station:** towers, ribs, helices, landings, lifts,
  galleries, ring, beams, platform finish, roof/arrival wells, dome/frame/glass,
  clocks, bell, Clock Room and its interior gardens, station planting.
- **P8 owns the surrounding ground:** lawns, dry garden, external park paths,
  pond/arched bridge, parasols, tea public room, lodge shell and furniture.
- **P9 owns playground equipment and its track**, within the existing site.
- P8 paths meet P7's actual landings; grade the small park/station datum
  transition flush. Never solve a connection by replacing P7 with a proxy,
  altering a station level, closing an opening or moving a fixed tower.

The main integrated model is `docs/drawings/moy_park_playground_3d.html`.
It now includes **the complete same P7 geometry** as `moy_crossing_3d.html`.
Both use `docs/drawings/moy_crossing_scene.js`, embedded identically by
`python3 tools/embed_moy_crossing_scene.py`; `--check` detects stale copies.
Both downloaded HTML files remain standalone apart from their existing Three.js
CDN libraries. The old pale primitive/wire Crossing has been removed.

The integrated model provides Crossing/dome/Clock Room/section views as well
as park/play views. Its ground-plan view deliberately hides the Crossing to
expose paths; visibility is not a replacement design. The standalone P7 page
also carries the welded-node close-up. Rough city-overview context is not an
alternative station construction source. Package geometry/data wins over any
preview sampling artifact. Build shared profiles/collision in Godot, not raw
browser triangles or rounded capsule chains.

## 4. P7 first — complete the Crossing before surrounding work

Build its full structural/circulation kit and intended public routes. Correct
wall/roof/helix winding, close real structural undersides and coordinate floor,
roof, arrival and lift cutouts. Use only real lift stops0/14.2/37/41.6; remove
unserved6.5 calls. Physical landings/guards/gates/calls must agree.

Dome: use the checked shared nodes/panes, constant-section white steel and
flush welded junctions. No six-sided loose cylinders, beads, pinched tips,
collapsed crown or bars across clock eyes. Glass/frame fit the **outer r8 clock
bezel**; the inner r2.85 eye and flat sill47.7 stay open. Preserve the nonzero
crown tie and supported bell. Prove the frame visually up close in the game.

Clock faces share game time. The approved marker colour is **#cf4a6b**; the
hour has a broad short rectangular base tapering to a point, the minute is a
slender triangle. Preserve bronze rings/bell and no printed numbers. Finish
real bell audio with existing/procedural assets rather than a silent placeholder.

The Clock Room is an indoor continuation of the park: broad green areas with
paved circulation and clear arrival wells/lift aprons, not four tiny pots.
Retain the planned rooted tower vines with visible branches/leaves/pendant
ends on support mesh, not solid hanging green sheets. Use shared NatureProps.

Make one useful P7 construction checkpoint before P8/P9. Verify the main routes
and actual close-up frame/eye/clock appearance; do not hold this checkpoint
for an exhaustive L4/performance certificate. Report genuine incomplete work.

## 5. Then P8/P9 together — the connected park

Keep the approved broad lawns, existing23 real trees, tea/chess parasols,
private-program reservations and fixed park/play sites. The northwest dry
**rectangle is an allocation/search envelope only**. Replace the old rectangular
`ParkDryGardenGravel` preview with `PARK.kit.dry_garden.footprint`: curved gravel
lobes, grass fingers, planted drifts and a1.8m winding trail around existing
palms/boulders, with a shaded seat. Do not recreate a beige square.

Pond: centre(-516,-28), water radii16.5/13, water-0.3, full bank factor1.15.
The full outer shore is at least2.025m inside the park. Terrain/swimming queries
read the same radii; keep bed/planting/paths synchronized. Preserve shared
translucent water and real swimming/shore exits. No hidden flat ground cap.

Build the Chinese-garden-inspired stone bridge: three actual masonry arches,
two bed-founded piers, bank abutments, gently humped36m deck2.4m clear, curved
1.1m guards and level ends. Reference the Chinese village arch details; no
pagoda roof or stair-only crossing. Paths and all bridge structure stay in park.

Build P9 as one warm canyon/net play landscape, not four tall proxy boxes.
Retain20/16/14/12m tower tops, shared9m bridge/ramp circulation, standable open
net, supported hollow/open slides, perches/hoops, dunes/courts/splash floor and
continuous2.2m pump track. Its west level-tabletop entry meets the park path.
Resolve net/slide/deck/guard openings and headroom locally inside the site.
No new automatic slide, cloth, chess, scoring, quest or traversal system.
Snow sandboarding and Penguin belly-slide support on this equipment are excluded.

## 6. Finish, check and report once as an integrated place

Use quick local previews during coherent construction batches. Bake when a
meaningful batch is ready and at final integration, preserving actual build
provenance. Do not overwrite the newer local P3–P6 bake with planning packs or
change source hashes to pretend a rebuild occurred.

Run required relevant repository checks, current plan validation and bake
freshness. Walk the intentional station/park/play routes with the real hero
and representative small-rig checks. Inspect lift arrivals/Clock Room, one
net/slide contact route, pond bridge/shore, and connections across P7/P8/P9.
No coordinate teleport mock counts as controller movement proof. Optional
high challenge routes need no universal reachability certificate.

Capture a handful of ordinary-resolution images: integrated overview, true
in-game dome/frame close-up, Clock Room garden, station-to-park transition,
organic dry garden, pond bridge and playground/net. Observe meaningful frame/
activation regressions proportionately; whole-city P2/P16 certification is not
this pass. Do not call unmeasured L4 complete.

Write one concise `docs/diagnostics/<date>-moy-P7-P8-P9.md`: starting P5/P6
checkpoint, built major groups, actual checks/walkthroughs, images and explicit
failed/unverified features or minor follow-ups. Preserve inherited work and
commit/publish only deliberately owned changes under the repo rules. Stop for
one combined review before P10.
