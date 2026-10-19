# Package P5: the North Estate kit and public routes

2026-10-19. Build-session brief. Read `moy_build_roadmap.md` first.

- **Area:** the two North Estate precincts, nine housing blocks, their
  courts and covered links, Estate Square, the neighbourhood centre and the
  hawker centre shell. Keep all existing footprints, turns, heights and routes.
- **Target:** L2, built: recognizable architecture and usable public space.
- **Depends on:** P0's check suite; P3/P4 for adjacent integration, not kit
  implementation. Do not modify their buildings to make estate routes fit.
- **Model:** `docs/drawings/moy_north_estate_3d.html`, including the cutaway
  kit beside the exported hero. Local model; artifact publication pending.
- **Binding data:** `CityPlan.ESTATE.kit`, including `parts` and `joins`.
  The data wins. Never edit `scripts/city_plan.gd` by hand.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, the roadmap.
2. `city.md` section 7d, the North Estate paragraphs in section 7, and
   section 6's estate circulation. The street/precinct layout is locked.
3. `tools/city_layout.py`: numbered building records, `ANGLE`,
   `HEIGHTS`, `ESTATE`, `DECK`; the P5 kit and its checks.
4. `scripts/moy_city_bake_builder.gd`: current massing/estate links,
   `scripts/city_generator.gd` for streaming, and the shared lift and
   collision builders. Reuse working components, not new controller variants.
5. The P5 model. It is a design reference, not evidence that the game is built.

## 2. People, purposes and limits

These are Singapore-influenced public housing precincts, not isolated luxury
towers: pale painted structure, recessed openings, shaded open galleries,
repeated service bays, laundry rods on outward faces and graphic block numerals.
The courts are shared outdoor rooms framed by broad blocks. Do not dress them
as Old Moy tower houses or market shophouses.

- Tomas Wren uses Block 1's lift and void deck for deliveries.
- Siti Rahman lives in Block 2 and works at the hawker centre; keep her route
  to Estate Square and the public market floor open.
- Juno Rell's Block 3 has a realised twentieth-floor public gallery stop.
  Her Housing Board office is in the centre, not a new district building.
- Imani and Kofi use Block 5 and the twins' shared court. No new resident
  schedules/dialogue are required; P14 owns their population pass.
- All flats stay private and sealed. P5 builds no apartment interiors.
- The centre's public circulation, lift, upper gallery and roof garden are
  realised; shop/classroom/office rooms are closed shells at L2.
- The hawker hall is open-sided with a real public floor, clear circulation
  and plain placeholder stall bays. Full food service, equipment, dressing and
  Siti's stall interior are P13f. Preserve any existing vendor service.

## 3. Exact coverage

| Building id | Place | Storeys | Main roof, m above datum | Orientation |
|---|---|---:|---:|---|
| 17 | Block 1 | 28 | 91 | turned −30° |
| 18 | Block 2 | 32 | 104 | turned −30° |
| 19 | Block 3 | 36 | 117 | city grid |
| 20 | Block 4 | 40 | 130 | turned −30° |
| 21 | Block 5 | 40 | 130 | turned −30° |
| 22 | Block 6 | 14 | 46 | city grid |
| 49 | Block 7 | 16 | 52 | city grid |
| 50 | Block 8 | 34 | 110 | city grid |
| 53 | Block 9 | 24 | 78 | turned −30° |
| 23 | Hawker centre | open hall | 6 | city grid |
| 51 | Neighbourhood centre | 2 public storeys + garden | 8 envelope | city grid |

Read actual world corners from the numbered record and angle. No new lots.
The west court, east court polygons, community garden, twins' gate,
sky-bridge polygon, two playground points, two pavilion points and five
linkway polylines come from `ESTATE`; do not redraw them by eye.
P5's precinct play pieces remain modest L2 furniture. P9's giant playground
in the park is a different project.

## 4. The housing kit

### 4.1 Structure and facade

- Foundation top is the public ground datum (world y = −60 where level),
  with surveyed cut/fill and embed to real terrain. No floating corners,
  double ground/floor collision or masking skirts.
- The ground storey is a **real open void deck**: structural columns and a
  small lift core, with public through routes under the block.
  First slab top +3.25, underside +3.01. Columns are 0.55 m square-ended
  SuperEggs, clipped at bearing planes, on a fitted grid no wider than 6.4 m.
  Do not leave a building-sized ground collider inside the void.
- Housing above is solid to the private-flat envelope. Court-facing public
  galleries are 1.8 m clear, inset within the existing footprint; subtract
  them from that solid envelope. Do not add full-width collision behind them.
- Structural module 3.2 m, fitted across each face; floor rhythm 3.25 m.
  Keep recorded roof heights: last-storey clearance is derived, not a reason
  to stretch the tower. Data checks keep it at least 2.4 m after the roof slab.
- Outward faces carry paired recessed windows, square-ended pale frame and
  contrasting sill, shallow warm panels, and grouped slender laundry rods.
  Court-facing galleries carry solid lower guards and sealed private doors.
  Frame openings from the same cutter; no black rectangles pretending to be
  walk-through doorways.
- Materials follow `kit.palette`: warm pale wall, cream structure,
  muted teal guard/bands, ochre inset panels and darker roof/service elements.
  Variation is by existing block identity, not random per-floor colours.
  Block numbers are painted numerals only; no explanatory signs.
- Block 6 and Block 7 retain open street-side shop bays under the housing,
  facing Park Ring/North Street. A shallow sealed shop display may sit behind
  the bay; through void-deck circulation must remain on its court side.

### 4.2 Public galleries, lift and roof

Each block has one public lift core on its court-facing edge. Choose the face
whose outward normal best points at `blocks[].court_point` in plan coordinates;
do not assume world north after rotation. The lift fits inside its existing
footprint: shaft 2.8 × 3.2 m, cabin 2.0 × 2.4 m, clear door 1.5 × 2.4 m,
with at least 2 m clear at each landing. Door/core placement is a deterministic
kit derivation, logged in the diagnostic, not a new footprint.

- Real stop at the void deck, every upper public gallery and the roof.
  Upper landing index i is i × 3.25 m for i=1…storeys−1; roof top is the
  numbered building's recorded height. The ground void is level index 0.
- The lift must transport the real hero and Xiao Hou Zi; validate boarding,
  mid-ride support, exit, recall from another floor and unload retention.
  Reuse the game's moving-support and interaction system.
- Galleries connect the lift to private doors, with continuous 1.2 m guards.
  Each door has a 2 m unobstructed approach along the gallery.
- The roof is reachable, guarded and a usable landing surface, not a thin
  cap over an invisible floor. Planting/services cannot block the lift exit.
- No hidden climbable internal apartment floors, accidental accessible shafts
  or window openings that drop the player into a solid private volume.

### 4.3 Twins' sky route

Use `ESTATE.sky_bridge` and the existing gap between Blocks 4 and 5.
Walking top is **+84.5 m** (26 × 3.25), world y=24.5, with 2 m clear width,
1.2 m side guards and a canopy at +87.5. The ground gate stays open.

Join both bridge ends to level-26 gallery landings. Small in-footprint landing
tongues may connect the locked bridge polygon to each face; derive their ends
from the real rotated faces and show the exact joins in the diagnostic.
No rail across either entrance, overlapping floor collision, floating end,
step, support through the gate below, or cut through an unrelated floor.
Use the lift to reach it from the ground and return through the other twin.

The green portion is a narrow planted edge beside the traversable strip;
do not consume the 2 m route with planters. P5 is not a new garden footprint.

## 5. Courts, linkways and Estate Square

- Implement all five linkway polylines as covered public connections.
  Roof top +3.0 m, slab 0.24 m, width 3.2 m. The underside clears 2.4 m;
  posts remain outside a 1.5 m clear through strip.
- Miter segment ends at the angle bisector at the shared top datum. Roofs
  are continuous and collidable, usable as the planned low roof-run route.
  Cap exposed undersides; no hanging rounded bowl or double intersection.
- At entrances, carry the link to the real landing with the floor at one
  height. Where it crosses streets/lanes, preserve the street route and
  appropriate headroom; do not extend a support into a travel lane.
- Place the two court pavilions/play corners at their existing data points.
  Keep furniture out of through paths: chess tables under shade, benches at
  edges, letterboxes beside cores, simple planted edges and garden beds.
  Do not add fences that seal a courtyard or crowd out a swing gap.
- The community garden remains behind Block 9, on its authored polygon.
  The garden and court lawns can share existing ground materials; never
  place a second walkable plane on top of terrain at the same height.
- Estate Square remains a square. Do not put the centre or hawker hall in it.
  Connect both precincts, North Street, Estate Lane, Park Ring and the Deck.

## 6. The two civic shells

**Neighbourhood centre (51):** two-storey public circulation at +0/+3.25,
roof garden at +6.5, envelope to +8.0. Ground doors face Estate Square;
a real lift reaches the upper public gallery and garden. The existing
`DECK` Neighbourhood centre bridge meets the +6.5 landing, with one floor
owner and a clear guard opening. Private-use room shells carry picture
identity only; no minimart simulation or kindergarten population in P5.

**Hawker centre (23):** open-sided public hall, column line at +4.5 eave,
shallow roof within the +6 envelope. Its section is a ventilated shelter,
not a solid 6 m box. Keep a 2 m public aisle between plain stall footprints,
with at least two open approaches from Estate Square/Park Ring.
Model the roof's ends and underside, and keep support columns clear of the
entrances. P13f provides full stall equipment, detailed seating and service.

## 7. Binding parts and joins

`ESTATE.kit.parts` has **36 part templates**, `joins` **10 joins**.
W/D/face/run/span are fitted dimensions from the existing site or actual route;
the schedule defines half-sizes, exponents, collision and explicit join planes.
Repeat counts come from the block's storeys and fitted face bays, never a
hand-authored alternate building list. Report each template built/deferred
with its reason and instance counts. A part is not optional because absent
from an overview camera.

Structural floor infill may be boxes for flush bearing/coverage. Visible posts,
guards, sills, canopies and furniture use square-ended SuperEggs or clipped
profiles. Derive apertures/glazing/trim from one opening. No intersecting mesh
seams masquerading as joined members. Use `CollisionPolicy` and simplified
box/capsule/convex colliders; substantial visible objects are physical.

Bake new detail offline in local building/block units. No runtime Boolean,
per-floor construction or whole-estate merge. Reuse resources and existing
streaming. Do not preload every estate pack from an always-loaded script.

## 8. Acceptance and screenshots

Before editing, record existing geometry findings and performance at the same
estate views. Preserve P0's committed baseline; use unique P5 output names.
After editing, require:

- Coverage: exactly nine housing blocks plus the two civic shells, five link
  polylines, two pavilions/play points and one twins' sky route; all transforms
  and main roof heights match the plan.
- Real capsule traversal through every void deck, each court exit and each
  link junction, with measured minimum widths/headroom and no collision seams.
- Lift proof at ground, representative intermediate floors, Block 3's floor
  20, both twins' level 26, and every roof; machine-check each stop's clear
  landing and reachability. No trapped shaft or false floor.
- Walk from west court through the twins' ground gate to Library Lane,
  from east court through the 8 m passage to Estate Square, and from the
  square through the centre to the Deck; real hero and Xiao Hou Zi.
- Traverse the twins' bridge both ways, jump onto/off linkway roofs and swing
  between two different blocks' real eligible anchors. Preserve these supports
  during streaming and when controlling another body.
- P0 fixtures and estate-area audit: no new blocking findings attributable to
  P5. Compare by check/location/path; the city baseline already contains debt.
- Quick pose/parity/design checks, plan generation/validator, final bake
  freshness and full runtime validator. Add estate-specific checks to that
  validator or a focused scene; keep focused and full outcomes distinct.
- Rendered before/after performance on the same hardware, resolution and
  renderer at ground court, gallery, sky bridge and roof. Use P2 tools;
  record misses/regressions openly. City-wide optimization and final budgets
  are deferred alongside district replacement, not a gate to finishing P5.
  Loading crashes, unsafe unloading and collision failures remain blockers.

Use P0's screenshot rig, with unique P5 names and real current cameras:
1. both precincts from above, with the turned ring against the city grid;
2. eye-height west court through the twins' gate;
3. Block 6/Park Ring and Block 7/North Street shops and through paths;
4. an occupied void deck and lift entrance, plus a public gallery;
5. level-26 bridge approach from each twin and its underside from the gate;
6. east court passage to Estate Square;
7. centre's garden/Deck connection and hawker hall's open public aisle.
Capture noon and dusk, plus a focused cutaway proving core/floor/guard joins.
Record camera/target/FOV/resolution/clip planes and source hashes.

## 9. Diagnostic and handoff

Write `docs/diagnostics/<date>-moy-P5.md`: each building's actual transforms,
roof/landing levels and counts; each scheduled part/join; public-route
measurements; real controller/lift/swing proof; P0 comparison; exact commands
and exits; screenshots; before/after performance; remaining limitations.
No web export. Follow AGENTS.md and stop after P5 for review.

**Build prompt:** Build Moy package P5 from
`docs/architecture/moy_pkg_P5.md`. Read AGENTS.md, CLAUDE.md and the roadmap
first. Complete its checks, diagnostic and screenshots, then stop for review.
Record performance before/after; defer city-wide optimization.

## 10. Decisions log

- 2026-10-19: P5 keeps section 7d's precincts/sites and raises public exterior
  architecture to L2; flats sealed. Public galleries/lifts/roofs and the
  level-26 sky route are real; full hawker fit-out stays P13f.
- 2026-10-19: dimensions and palette for repeated members are now in
  `ESTATE.kit`, with checked parts/joins. Existing building roof heights win
  over exact storey multiples; no footprint/height change was authorized.
- 2026-10-19: city-wide performance acceptance remains deferred; measure
  before/after, fix local safety failures and report regressions.
- 2026-10-19: model publication is pending because this cloud chat lacks
  artifact publishing tools. The local reference can be reviewed and built
  from without claiming the published artifact is updated.

