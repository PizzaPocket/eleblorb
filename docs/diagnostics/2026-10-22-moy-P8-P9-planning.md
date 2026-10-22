# Moy P8/P9 integrated planning — 2026-10-22

Status: both packages ready for one implementation pass, not built in game.
User requested the park and playground together. The handoff targets a
practical playable L2/L3 milestone; final L4/performance remains tracked.

## Design coverage

- One model: `docs/drawings/moy_park_playground_3d.html`, with overview, ground
  plan, pond, dry garden, tea terrace/section, playground, track, lawn and net
  views. Net/3m hoop detail uses the actual game-exported hero, copied unchanged
  from the existing figure export. Neighbour/station context can be toggled.
- P8 checked schedule:40 parts/12 joins. P9:30 parts/12 joins. Both briefs
  include source tables of shapes, half-sizes, exponents, collision and joins.
- New2.4m quarter paths join the two existing6m civic walks, tea public door,
  pond-boardwalk ends, lawn/lodge and the playground's west tabletop crossing.
  Plan checks confirm a connected paved network and clear tree trunks.
- The low2.4m pond boardwalk follows the actual pond profile, with guards,
  supported girders/piers and level entry/exit. Source waterline stays-0.3m;
  the six recorded bank/bed levels stay unchanged. Real shade trees replace
  obsolete roadmap wind-tree wording; no new steel tree sculptures.
- Six timber parasols, three chess groups, six benches, tea public room and
  lodge shell keep their existing footprints and private-program reservations.
  Furniture locations were revised away from paths and the pump-track rim.
- Playground retains0.55 horizontal scale, fixed20/16/14/12m tower heights,
  source radii,3m open hoops and2.2m track width. Shared ground entry, towers,
  common9m bridges, Lookout ramp, sagged net, three slides, perches, dunes,
  bounce court and a small recirculated splash pad are coordinated in one kit.
  Ramp inner grade27.71°; checked slide paths stay inside the track. Net plan
  patches cut the four tower envelopes. These are planning constraints, not
  measured game-controller passes.

## Verification

- `city_layout.py --json`: passed,22 streets/47 buildings/133 lots/9 courts;
  full parts/joins checks and park-specific assertions pass.
- Export comparison with previous HEAD: all existing city plan data unchanged
  after removing only `park.kit` and `park.playground.kit`. No relocated
  street, station, tree, pond, building or existing play tower.
- New model and seven existing drawing pages load in Chromium without script
  errors. Ten main views and the human-scale detail were rendered; useful
  ground/pond/playground/interior reference images were visually inspected.
- Bake completes successfully. Freshness check:248 packs current. Canonical
  runtime scenes were retained after generated resource-ID churn; runtime
  geometry is unchanged because the new kit data is not consumed yet. New
  helper source is included in bake hashing. Known headless shutdown warnings
  do not constitute a geometry/controller pass.
- Required quick checks and scoped city-plan validation run before push.

## Explicit implementation work still owed

Correct the actual face-down park paving; build real pond/ground sockets,
shared water/depth integration and ordinary route collision. Verify ramp
headroom and deck apertures, bridge mouths, net footing/cuts, slide and tower
clearances, open tube mouths/run-outs, track/tabletop contact and guard gaps.
Model sampling, previews and a schematic station context are not production
geometry. Allow local slide phase/net-cut/guard refinements inside the locked
play site to remove actual clashes. Do not copy a preview overlap into game.

Use existing shared movement and village builders; no new power/cloth/chess/
scoring framework. Report genuine ordinary-route and representative small-rig
walkthroughs. No exhaustive all-power/all-surface certification is claimed or
required for the practical milestone. Minor polish can remain; major holes,
blockers or broken geometry cannot. One combined implementation diagnostic
will record completed groups and actual remaining failures.

Local HTML/reference images are committed; external model publication remains
pending because this chat has no artifact publisher. No new lore introduced.
