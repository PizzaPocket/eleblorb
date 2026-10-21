# Package P5: the North Estate kit and public routes

2026-10-22. **Accepted at practical L2 after sense-check 2026-10-22; P6 may proceed.**
Read `moy_build_roadmap.md` first. Section 13 supersedes the initial palette and any numeral exceptions.

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

## Current build direction — 2026-10-22

Apply the user's practical goal: a nice playable district broadly matching
the supplied model, about as sophisticated as Ohio/Snowhio. Done is better
than perfect. P3/P4 are checkpointed with named streaming/polish follow-ups;
no further P3/P4 precision review is a prerequisite to starting P5.

Keep this brief's actual North Estate design and intended public functions:
all nine identities, real open void decks, public galleries/lifts, twins'
level26 connection, courts/linkways, neighbourhood centre and hawker shell.
Section13's accepted colour/model direction supersedes older redesign requests.
No lettering/numbers, private-flat interiors or new resident simulations.

Use the parts/joins schedule as a design reference, not an exhaustive39/12
certificate. Minor decorative simplifications and normal-camera seams may
remain. Major visual defects, blocked public circulation, lift/support faults
and unintended holes still matter. Not every surface needs access. Test the
intentional public circulation/lifts/bridge with both bodies and representative
stops; do not build a separate all-floor/all-surface test matrix.

Use existing builders/systems and fast representative previews during edits.
Integrate coherent batches; bake and take a few ordinary-resolution useful
views when ready. Run relevant required checks and focused walkthroughs.
No repeated city-wide activation/capture cycles per change, giant audit history,
new test/geometry/controller framework or P2 optimization project. Older
before/after performance/capture/ledger demands are proportionate observations,
not blockers requiring a fresh expensive certification cycle on every batch.

Current concise handoff: `moy_p5_build_handoff.md`. Stop after P5 for a useful
district-level review; no automatic cross-chat fix loop or P6 advancement.

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
repeated service bays, laundry rods on outward faces and distinct unlettered colour/shape identities.
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
  No printed numbers, letters or words on buildings, signs or environmental graphics. Use colour and pictorial motifs only; ids in the plan are internal bookkeeping.
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

Place the sky garden's planted edges on the twins' connecting landings,
inside their existing footprints. Keep the bridge polygon's full 2 m width
clear; do not widen it or consume it with planters. P5 adds no garden footprint.

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

`ESTATE.kit.parts` has **39 part templates**, `joins` **12 joins**.
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


## 11. Design review: colour and block identity

User, 2026-10-19: the first model is too boring and uninspired. Research
colourful real HDB buildings before settling the facade design. The aim is
a cheery, inspirational estate with original architecture, where visual
identity can also help residents find their homes. **This initial design review is superseded by section 13.**

The current pale-wall/teal-band model and `kit.palette` are provisional, not
the final visual direction. Keep the locked precinct/site/height data and
public-route work, but revise the facade grammar before handing it to Luna.

Research questions:
- How do real estates compose colour at building and precinct scales?
- How do relief, shading, galleries, gable ends and entrances give colour
  structure rather than treating it as a uniform coat of paint?
- Which large patterns distinguish a block across a court and at its own
  lift lobby, without needing explanatory text?

Initial direction for discussion, not an approved replacement scheme:
- Distinct dominant palettes and large graphic compositions for each block,
  coordinated within the two precincts. The twins should read as related
  but individually identifiable.
- Repeat each block's identifying shape at its entrance canopy, lift lobby
  and appropriate facade; keep contrasting light/dark
  shapes, so recognition does not depend on colour alone.
- Develop depth with gallery frames, sunshades, end-wall relief and bolder
  entrance forms; do not merely recolour the repeated massing.
- Let the inhabited courts and shared routes read at eye height as well as
  from above. Preserve clear openings, shadows and readable identities at dusk.

Official HDB/National Heritage Board reference access was attempted but denied
by the cloud network policy. Specific host additions have been saved in the
environment configuration draft. No fresh photo research is claimed yet.
Inspect and cite actual references, then present revised model alternatives
before replacing the provisional kit palette and finalising this brief.

## 12. Accepted visual direction and SuperEgg handoff

User, 2026-10-19: the colourful concept direction is accepted for development.
Reference: [colour concept](../drawings/references/moy_north_estate_colour_concept.png).
Coral/cobalt twins share an arch motif; sunflower/cream frames and shaded teal
galleries distinguish the slab blocks; block identity repeats at entrances
through colour and pictorial motifs, with no printed characters. This approves the visual direction, not
every depicted dimension or detail. Existing site/height data still wins.
The old concept illustration contains numbers that are explicitly rejected.
Do not copy them. Plan ids remain internal and must never be printed in-world.

**User clarification:** some elongated forms in the browser model look
pointed or tipped. Those are approximation/sampling artifacts, **not intended
SuperEgg profiles**. Do not copy the browser mesh or the illustration's
geometry into the build. The model is a composition reference; the checked
parts/joins schedule, this clarification, and the game's own builders govern
actual geometry. The detailed colour/feature schedule is now updated in section 13.

| Element | Intended construction | Ends / joins |
|---|---|---|
| Columns, posts, gallery guards, beams and sills | Square-ended structural SuperEggs, normally EPSILON_FLAT = 5.5; dimensions are half-sizes, not a recipe to stretch a coarse sphere | Clip and cap at shared bearing/miter planes; no spikes, pointed tips or rounded gaps at supports |
| Entrance frames, sunshades and canopy edges | Broad softened rectangular members or an authored superellipse profile; visibly full-bodied along the span | Resolve corners from the same opening/section and explicit join planes; no spear-like terminal vertices or intersecting rounded ends |
| Long linkway roofs / bridge canopy | Authored clipped SuperEgg slabs or an appropriate constant-section profile, with sufficient longitudinal and corner sampling | Real planar caps and closed undersides; shared datum and complete matching cut profiles at joints |
| Doors, windows and large arch openings | Superellipse outlines, with glazing and trim derived from one aperture; open route thresholds cut flat | No pinched arch crowns, floating trim, rounded threshold lips or fake openings |
| Floor/ceiling infill and hidden structure | Plain structural slabs/boxes where needed for complete coverage, as already justified by the schedule | One surface owner; no doubled collision or gaps disguised by rounded edges |
| Benches, tables and planters | Rounded SuperEgg members appropriate to their role, supported by the ground and their own legs/bases | No stretched pointed ends; supports must visibly meet the piece they carry |
| Large colour fields and identity motifs | Painted/decal treatments unless the revised schedule explicitly specifies physical relief | Do not turn painted arches into unsupported structural members or invent tapered solids from graphic shapes |

Implementation uses `scripts/superegg.gd`: `SuperEgg.build_part` for complete
forms, and `build_clipped_mesh` / `build_clipped_part` for actual cut-and-capped
solids. Use the engine's `surface_point` parameterisation, exponent convention
and exact-axis handling; do not port the model's low-resolution SphereGeometry
vertex transform or its vertex-clamping shortcut. Epsilon below 2 pinches
profiles and is forbidden here. Increasing squareness alone does not repair
poor sampling of a long member.

Before assembling the district, render a representative long post, beam,
guard, canopy junction and entrance frame at true scale beside the hero.
Inspect side silhouette, both terminal profiles, bearings and underside in
close-up. Require smooth full profiles, properly capped ends and no accidental
needle tips/fans or visible gaps. Then inspect the same pieces at gameplay
distance and confirm their substantial visible volumes have collision.
Include those isolated proofs and their dimensions/exponents/cut planes in
the P5 diagnostic. A faithful copy of a pointed browser artifact is a failure.

## 13. Colour model and binding facade schedule

2026-10-19. The interactive North Estate model now renders the accepted
colour direction from `ESTATE.kit` version 2, rather than leaving it only in
the concept illustration. This section supersedes the first model's uniform
pale/teal palette and every earlier permission to print building numerals.
The original layout, heights, court polygons, bridges and public routes stay
locked. This is planning/model work; P5 game implementation remains for Luna.

**No lettering or numbers in-world.** Buildings, canopies, signs and lift
lobbies use no words, letters, printed numbers or number-shaped motifs. Use
colour, abstract arch/circle/step marks, relief and recognisable entrances.
The browser page's technical labels and the ids below identify plan records;
they are not graphics for the game's buildings. The earlier concept image
is inspiration only; the updated model/data supersede its erroneous numerals
and guessed block identities.

| Internal plan id | Block identity | Primary / secondary | Large motif and frame family |
|---|---|---|---|
| 17 | jade circle | jade / coral | ring on an end-wall field, grouped frames |
| 18 | coral steps | coral / sunflower | broad stepped graphic, grouped frames |
| 19 | jade arch | jade / sunflower | tall arch graphic, grouped frames |
| 20 | coral twin | coral / jade | cream arch on a tall field, paired with 21 |
| 21 | cobalt twin | cobalt / jade | the same arch grammar, contrasting colour |
| 22 | sunflower portals | sunflower / jade | repeated tall cream portal frames |
| 49 | jade portals | jade / sunflower | repeated portal rhythm, distinct from 19's grouped frames |
| 50 | cobalt steps | cobalt / coral | broad stepped graphic, grouped frames |
| 53 | sunflower circle | sunflower / jade | ring field, grouped frames |

Exact colours are `kit.identities[].primary/secondary`; cream structure and
dark glazing are `kit.palette`. Each identity repeats at its real entrance
through the same colour and pictorial motif, not explanatory signs. The
twins remain visibly related while individually recognisable. Courtyard
galleries use secondary colour against the primary housing body.

**Form and placement (`kit.facade`):**
- Recess backing 0.24 m; physical frame relief is 0.18 m deep and entirely
  inside the original footprint. Do not enlarge the locked building to fit it.
- Group frames across four storeys; repeated-portal slabs carry a vertical
  rhythm fitted to pairs of structural bays. Frame section is 0.28 m. Fit
  edge bays instead of leaving a thin sliver or overlapping two profiles.
- The main painted field is 38% of the selected outward face width and 86%
  of the housing height above the void deck. Motif width is 62% of that
  field; the arch stroke is 24% of its own width. The selected face is opposite the public court-facing gallery.
  Coordinate its blind service/identity bay with windows and glazing: no
  opaque paint board over an actual aperture, and no blocking gallery relief.
- Entrance portals are 4.4 m wide, 3.01 m high, section 0.24 m, depth 0.24 m,
  inside the building boundary. Their crown/feet are properly formed, with
  no threshold crossbar. Pictorial identity repeats beside the open passage.
- `identity_motif` is painted/decal work. `facade_frame`, `entrance_frame` and
  `sunshade` are real scheduled solid members with collision. The new
  `facade_recess` and `portal_bearing` joins govern their backing/landings.
  Do not mistake a painted arch for a new opening or a freestanding load path.

Section 12's SuperEgg formation safeguards still apply. The browser model's
long members now use capped constant-section superellipse profiles rather
than the former stretched/coarse sphere shortcut. The game implementation
must still use the actual shared builders and prove the close-up profiles.

**Handoff checks:** compare the final game with the interactive model's
overview, twins, court entrance and cutaway kit views; verify each of the nine
identity records and its entrance repeat. Inspect at noon and dusk, including
contrast/readability without relying on colour alone. Assert that no text or
numeral geometry/textures were introduced. Keep all prior geometry, collision,
passage, lift, streaming and actual-controller checks from this brief.

Actual model screenshots: [overview](../drawings/references/moy_north_estate_colour_model.png)
and [twins](../drawings/references/moy_north_estate_colour_twins.png).
Plan generation passed (nine identities, 39 parts, 12 joins) with all non-kit
layout data unchanged. Browser checks passed for model load, view selection,
section/dusk switches and absence of text textures/meshes; bake freshness
passed at 246 packs. This verifies the design handoff, not P5 gameplay.

The model is saved locally in the repository; artifact publication remains
pending because this chat has no publication tool. No fresh HDB-photo
research or completed P5 runtime build is claimed by this update.

## 14. Construction milestone — 2026-10-22

P5 is built locally for review. See `docs/diagnostics/2026-10-22-moy-P5.md`:
nine housing identities, all gallery/roof stops, open void decks, the twins'
bridge/sky edges, five linkways, shared courts/garden and both civic shells.
Both real controllers passed focused saved-geometry circulation and lift
checks, plus the representative roof and hawker cross-aisle checks.
Full-city runtime validation stopped at cold pack activation (62/400), before
gameplay. Streaming/unload, swing and performance limits are recorded honestly.
Inherited P3/P4 source/bake remain preserved and uncommitted. Stop for review;
no automatic P6 advancement.

## Sense-check — 2026-10-22

Accepted as a practical L2 construction milestone under the current user
criteria. Source/result and all six saved-image hashes match the handoff.
Inspected the housing/void-deck, twin bridge and hawker images, estate builder,
shared-lift extension/landing controls and focused test implementation. The
architecture reads as the planned district; isolated saved-pack views establish
construction, not streamed-city gameplay. The civic image is obstructed and is
not evidence of the centre garden route.

Independently reran the saved-pack civic check before pulling upstream:
12 checks, zero failures; Hero and Xiao walk Square through hawker to Park
Ring, and all 276 landing clearance/support probes pass. Reviewed, rather than
reran, the matching 110-check main and 18-check roof records. Those are real
controllers in headless physics; lift destination/recall callbacks are invoked
by the harness, not a separate human UI walkthrough. Current pre-pull bake
freshness passed at 400 packs. Shared pose/parity/design checks pass.

Known follow-ups remain: full runtime activation times out at 62/400 before
gameplay; remote streaming/unload, rendered frame budgets and a live user
walkthrough are unverified. Minor seams/planting/stall/private-room dressing
are later polish. No all-green runtime or L4 acceptance is claimed. These
limits do not block the user-authorized move to P6.

Recovery and upstream integration: `moy_P5_review_2026-10-22.md`.
