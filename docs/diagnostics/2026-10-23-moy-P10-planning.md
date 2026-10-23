# P10 planning and handoff — 2026-10-23

Planning readiness only. No P10 game implementation or in-game acceptance
claimed. Base main13f03a3; current builder's P3–P6 and subsequent work remain
in the protected implementation checkout, not this248-pack planning clone.
Read `moy_p7_p8_p9_pull_review_2026-10-22.md` for its recovery checkpoint.

## Delivered

- `docs/architecture/moy_pkg_P10.md`: complete rolling-stock, boarding,
  station/Line House and operating brief; practical L3 build, L4 final.
- `moy_p10_build_handoff.md`: sequential build and prompt, after P7–P9 review.
- TRAIN.kit:33 part families/13 joins, shapes/half-sizes/positions, exponents,
  collision, repeated elements, cut/bearing planes, cabin/palette/service data.
- Reworked existing `moy_train_3d.html`: fleet, car, boarding, cabin section,
  Line House and its section at the actual site, and locked network context.
  Opening/closing controls, exported actual hero, full schedule tables and
  responsive phone layout. No drawn substitute character or printed game text.
- Nine planning drawings embed the current canonical DATA. P7 canonical scene
  embeddings remain identical. Earlier district and park/crossing plans retained.

## Design corrections and limits

Old model incorrectly claimed the Spine joined the Wall and used a solid
silhouette as an interior. New kit supplies a hollow n5.5 standing section,
soft end shoulders and flat panoramic ends, precise floor/door dimensions,
seating and physical leaf movement. Actual production thickness, weld/cut
construction, collision and runtime behaviour remain builder work.

Published runtime has wrong floor/width/door offsets, opaque cabin blockers,
static doors, incomplete service hours, fixed-lane shuttle conflicts,
direction-related car identity jumps and unproven train streaming lifetime.
The brief names these instead of assuming the old preview was operational.

A detailed turnout model is **not** supplied: local terminal crossover paths
must be fitted and checked against actual built guideway before fleet rollout.
The locked route drawing is not proof of those paths. Report a specific small
plan amendment if the envelope fails; no teleporting, fake head-on operation
or invented link between disconnected services. Night storage is a logical
out-of-service fleet, not a physically complete depot yard. Occupied-train
continuity and safe withdrawal override abrupt midnight fleet-count toggles.

The Line House is a true-size maintenance/program section, with a deck void
and switchback route, not a furnished room-level P13 interior. Its exact
support/collision, guards and private-room enclosure need construction.
Crossing architecture remains entirely P7's; network boxes are labelled
technical context, not an alternative station design.

## Checked

- Canonical plan generation exits0:22 streets,47 buildings,133 lots,9 courts.
  Schedule validation and cabin/door/headroom checks pass. Independent JSON
  comparison with13f03a3 proves the only semantic plan addition is TRAIN.kit;
  locked sites/services and earlier kits are unchanged.
- Node syntax check passes. Chromium renders fleet/car/boarding/interior/
  house/house-section/network and390px phone layout without JavaScript errors.
  Both leaf states checked at all doors; exported hero meshes present.
  Inspected saved car, boarding, cabin and maintenance views. External hosting
  remains pending; committed HTML is not a live published viewer.
- P7 embedded canonical-scene parity check passes.
- Genuine headless Godot4.7.2 planning bake exits0,248 packs. It does not consume
  the new kit yet. Canonical existing scenes retained after independent
  comparison of generated ID/name churn and floating-point roundoff only:
  text numeric differences≤2e-6; one packed position buffer≤4.77e-7 with its
  remaining attribute bytes identical. Actual bake-produced manifest retained.
  No fabricated hash update, district source replacement or game build claim.
- Bake freshness passes; city-plan validator0 FAIL. Known headless dummy-renderer
  shutdown/resource-leak warnings remain; they are not new runtime evidence.
- `git diff --check` passes. Required pre-push checks run when publishing.

References: `docs/drawings/references/moy_train_{all,car,boarding,interior,house,
house_section,network,mobile}.png`. Builder must capture actual game views and
focused collision/service/streaming checks in its own dated diagnostic.
