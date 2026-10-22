# P8 — arched bridge, pond containment and lawn revision

2026-10-22. Planning/model revision ready for the combined P8/P9 build.

The user requested a Chinese-garden-style arched pond bridge and questioned
whether the shore extended beyond the park. This also carries through the
requested greener park grounds after the sparse-grass preview.

## Changes and measured bounds

- Confirmed original overflow: centre(-516,-28), radii19/13 and bank factor1.15
  put the east outer shore at-494.15,0.85m beyond the park edge-495.
- Kept centre and depth profile; reduced water x-radius to16.5. Full outer
  bank now has2.025m minimum clearance inside the park. Authoring asserts
  containment in the2m-inset park, not merely containment of the water ellipse.
  Reeds/stones, path cuts, terrain basin and swimming queries use that shape.
- TerrainGenerator's separate hardcoded19m radius now reads CityPlan's radii.
  A focused headless scene probe confirmed16.5m, dry ground outside the revised
  east bank, zero water coverage beyond the new waterline and centre depth2.1m.
- The model uses a gently humped stone bridge referencing the Chinese village
  `bridge_height` and `_build_stone_arch_bridge` construction. Three12m arch
  barrels, two bed-founded piers and bank abutments carry a36m deck. Clear
  width2.4m, structural width2.8, top0.08+1.6*sin(pi*t)^2, crest1.68m and
  maximum grade7.95 degrees. Rails follow the curve1.1m above it. End slopes
  are level; no stair ascent. Bridge/abutment footprint is checked inside park.
- Broad checked lawn patches total6,773.81m², about52% of the entire13,000m²
  park. Dry quarter, pond banks, paths, play surfaces and station rain gardens
  retain their distinct materials. The old picnic lawn remains in this system.
- P8 schedule now41 parts/12 joins; P9 remains30/12. Added a real abutment part
  and replaced timber girders with structural stone arch barrels. Updated
  model, briefs, combined handoff, charter, roadmap and world-bible park note.

## Verification and limits

Plan export and complete parts/joins checks pass. The paved network remains
connected and tree trunks remain clear. Export comparison confirms no unrelated
site/character/building changes: only the P8 kit, pond width and derived shore
planting changed; P9 kit and play geometry are unchanged.

The new model and seven existing pages load without script errors; refreshed
views include the curved bridge and full green-ground plan. Bake completes and
248-pack freshness passes. Updated pond/park-ground/shore-planting packs are
retained; unrelated generated scene-ID churn is discarded. Required pre-push
checks/validators run before publication. Headless shutdown warnings are not
used as evidence of runtime gameplay.

The narrowed pond geometry/query correction is synchronized in source/bake.
The bridge and broad lawn design still await Luna's P8 implementation. Neither
browser renders nor this planning report certify runtime arch collision,
guards, ground sockets, controller routes or full-park L4 completion.
