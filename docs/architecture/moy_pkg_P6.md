# Package P6: Downtown's podiums and three tower exteriors

2026-10-19. **Revision 2: ready; site/base checks passed; supersedes the original 23-tower handoff.**
Read `moy_build_roadmap.md` first. This is a binding L2 brief, not another
massing pass. The plan-data schedule and this brief supersede the scope draft.

- **Area:** 10 consolidated mid-rise sites replacing source lots 110–132, Windspire 12, north tower
  14 and south tower 15, with their recorded public ground and connections.
- **Target:** L2: distinctive architecture, physical ledges and usable public
  routes. Simple planting/colour makes the design legible; final dressing is later.
- **Depends on:** P0 checks and existing shared lifts/collision; integrate
  P3/P4 correctness fixes and P5 sequentially before touching shared builders.
- **Binding data:** `CityPlan.DOWNTOWN` (47 part templates, 16 joins), plus
  existing `LOTS`, `TOWER_SITE`, `COURT_WAYS`, `DECK`, heights and crowns.
- **Model:** `docs/drawings/moy_downtown_3d.html`, overview, tower, street,
  garden and wind-gap views; separate podium/member section beside game hero.
  Local model, publication pending. It is a design reference, not a collision
  or lift demonstration. Never copy its preview tessellation into production.
- **Exclude:** BLOCK's tower/story (P17), Grand Hotel changes, office/flat
  interiors, new NPC schedules/dialogue and city-wide optimization.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, roadmap, architecture skill and the Downtown
   charter in `docs/style_charters.md`.
2. `city.md` section 7's Downtown; section 7c's Windspire/north/south tower
   descriptions; section 6's Deck/vertical circulation. Earlier approximate
   storey counts do not override the checked heights below.
3. `tools/city_layout.py`: `DOWNTOWN`, owner list, parts, joins and checks;
   `lots`, `STOREY`, `HEIGHTS`, `CROWNS`, `FORMS`, `TOWER_SITE`, `COURT_WAYS`.
4. Shared `SuperEgg`, `OpeningTrim`, `SolidModel`, `CollisionPolicy`, lift
   builders and `scripts/moy_city_bake_builder.gd`; streaming in city generator.
5. P3/P4 first-build reviews, especially reversed winding and passage plinths.

## 2. People, hierarchy and boundaries

Mid-rises hold workplaces or private homes above shaded public bases.
Workers and deliveries enter from streets, pass through public colonnades and
use only the planned Deck connections. No invented tenants or private rooms.
Priya, Elizabeth and Venn's Windspire offices stay sealed. Theo's north-tower
studio stays sealed. Tanglewire and the south flats stay sealed.

Public P6 circulation is deliberately limited: streets and courts, tower
forecourts and colonnades, the existing hotel-to-Windspire connection, a plain
Windspire express-lift landing and observation deck, and the north sky garden.
These are plain L2 public shells, without office furnishing or new services.
Keep existing vendors/interactions functional if present; no speculative doors.

BLOCK's neighbour is ordinary P6 mid-rise fabric, but its approach geometry
serves P17. Preserve its footprint, height and six-metre separation. Do not
change BLOCK's tower or silently block its court while building that neighbour.

## 3. Authorized site revision and exact coverage

The user authorized merging sliver plots, separating tall shafts and replacing
the all-open pillar bases. This is an intentional P6 plan change, not an
implementation exception to the locked layout. Roads, landmark sites, court
polygons, estate, hotel and P17 story/geometry remain unchanged.

`DOWNTOWN.sites` is now the building schedule. `DOWNTOWN.owners` and original
`LOTS[110:133]` retain source/provenance and cross-package IDs only. They are
not 23 buildings to implement. Replace those original proxies once each,
then build the ten sites below. Never build both the old owners and new sites.
Source lots have one and only one new site; their polygon union is its podium.
Do not fill a bounding rectangle across a court or garden at an L-shaped site.

| Site | Source lots | Shaft world rect (x0,z0,x1,z1) | Roof above datum |
|---|---|---|---:|
| North garden | 110,114 | −480,−166,−466,−145 | 86.4 |
| Capsule neighbours | 111,112,113 | −439,−119,−410,−105 | 93.6 |
| Wind garden edge | 115,116 | −425,−95,−394,−83 | 93.6 |
| East pavilion | 117,118 | −385.5,−55,−373.5,−41 | 57.6 |
| BLOCK approach | 119,120 | −443,38,−413,58 | 122.4 |
| Court east | 121,122,127 | −405,41,−376,55 | 86.4 |
| Market west | 123,124 | −479,81,−441,95 | 108 |
| Market east | 125,126 | −433,81,−394,95 | 108 |
| South garden edge | 128,129,130 | −439,105,−410,119 | 108 |
| South garden | 131,132 | −480,145,−466,166 | 86.4 |

Small strips are absorbed into podiums/low pavilions or terraces. None keeps
an independent tall shaft. Shortest shaft dimension is at least 12 m.
Shafts have at least 8 m between each other and the four landmark shafts,
except the deliberately preserved six-metre P17 approach gap to BLOCK.
These are game-design clearances, not a claim of regulatory compliance.
Podiums may join at property boundaries; tall windowed facades do not touch.
Existing public courts remain outside podium unions. Roof terraces use the
space between podium edges and shafts, with proper guards and openings.

Court 8's 2.4 × 3 m passage remains in source lot119, world (−436,38) to
(−436,58). Cut that exact clear volume through podium walls and every
collider, including base infill. Primary piers are explicitly placed outside
it. `BLOCK_TOWER.inside.approach` retains its existing strip as the climb
interface: wall x=−443, location z=55, roof +122.4. The enlarged P6 site
absorbs lot120 to its east without moving that six-metre climb interface.

## 4. Podiums, load paths and facade kit

### 4.1 Structure is primary, not decorative

Each mid-rise has a continuous core from embedded foundation to roof: 6 ×
8 m, or 4 × 6 m at the 12 m-wide east pavilion shaft. Use the
per-site `core` value. Major piers are 1.4 m square, aligned vertically through
the shaft and podium into the foundations. `sites.grid` and `.piers` give
actual positions; maximum primary spacing is 7.2 m. Do not replace these
members with the 0.36 m facade piers or glass mullions.

Podium roof top +6.5, slab 0.24, underside +6.26. Primary transfer girders
are 0.8 m wide × 1.2 m deep, from +5.06 to +6.26, seated on the piers and
joined into the core. Their individual supported spans must not exceed the
checked grid spacing, even when the rendered beam is a continuous run.
Keep support positions through upper floors; do not move them to rescue
window patterns. Clip/cap shared bearing faces, and coordinate core openings
with the structure. Terrace extensions need their own supported beams,
secondary piers or cantilever detail; an unsupported slab over a garden is
not a new foundation strategy.

These dimensions establish an architectural load path for the game, not a
real structural-engineering calculation. The model must visibly communicate
core → floors/girders → aligned piers/walls → embedded base.

### 4.2 Inhabited bases and selected public openings

Podiums have substantial 0.4 m wall enclosures, recessed sealed storefronts
and service cores, interrupted by selected entrances, lobbies and the court
passage. They are not completely open floors ringed with small posts.
Public entries are at least 2.4 × 2.8 m clear, with 2 m level landings.
Court passage keeps its own 3 m clear head. P6 builds closed shop/service
shells, not furnished or staffed interiors. Do not invent vendors or tenants.
The core and primary frame support the building independently of storefronts.

Foundation embeds at least 0.5 m below surveyed terrain. Source rectangles
are land ownership/provenance; merged external walls follow the union outline
and coordinate joints between adjoining podiums. A joined podium wall may be
opaque/party wall; no sealed window faces another wall at zero clearance.

### 4.3 Upper facades and roofs

Use the 3.6 m storey rhythm and explicit new heights. The first upper
interval runs from podium +6.5 to +10.8, then +14.4, +18.0 and so on
to the recorded roof; do not finish with a 0.7 m miniature storey. Fit nominal 3.6 m bays
to each **shaft** frontage. Sealed backing is 0.6 m behind its shaft outline;
0.36 m facade piers and 0.24 m heads are secondary shading members, distinct
from the primary 1.4 m frame. Glazing up to 2.4 m high, width bay−0.65 m
(minimum 0.5); one rounded cutter drives opening, glazing and trim.

Three recorded families remain: single piers, paired piers and recessed bays.
Pale ceramic, jade/terracotta/cobalt reveals; no printed characters. Roofs
and terraces have 1.2 m guards and physical landing surfaces. Connect only
existing Deck doors/routes. Do not invent lifts to every mid-rise roof.

## 5. Windspire — building 12

### Form and structure

Shaft rect (−424,−74)–(−396,−46), top +262; crown +280. Rounded triangular
plan, maximum radius 13.8 m, turning 90° from ground to shaft top. For each
of three triangle vertices, trim 20% toward its neighbours, then join those
points with a quadratic rounded corner through the vertex. The section stays
inside the existing 28 m envelope at every sampled height. Interpolate the
same profile through the full height; do not stack unrelated rotated blocks.

Three open wind slots start +72, +144, +216; each 7.2 m clear. A 4 × 6 m
continuous core and three 1.2 m corner mega-columns carry the upper shaft.
Columns follow the twist continuously; 3.6 m transfer zones immediately below
and above each opening contain perimeter beams and core braces. Keep the
west–east air passages beside the core open. No whole-shaft collider across
these slots. Prove supports and bearing surfaces in close-ups.

Terracotta fins, 0.24 × 0.6 m section, follow every third sample of the
27-point rounded triangle profile. Use clipped segments with shared end
planes. Stop facade fins at slot boundaries. Pale fritted glass is recessed
behind the fins; transfer structure belongs to the pale structural family.
Each slot has a visible rotor: 1.1 m hub, three rounded blades 0.36 × 4.4 ×
0.6, centres 1.8 m from hub, centred at local z = −7.5 m, oriented in a vertical plane normal to west wind.
Keep the full swept volume off core, columns, ledges and public routes.
Reuse shared rotation; no new wind mechanic. Do not pretend model motion is
implemented: the planning model shows static blades.

### Public route and crown

Use the existing hotel-side pavilion and bridge rectangles from `TOWER_SITE`.
Their walk surface is +6.5 and meets the hotel's mezzanine threshold. Do not
modify the hotel to hide a gap. Express lift: shared cabin clear 2 × 2.4 m,
shaft 2.8 × 3.2 m, stops ground, +6.5 and observation +258.4 only. Place it
within the continuous core; real landing/shaft cutouts, doors and 2 m clear
landings, shared controls usable by all playable rigs. Other levels are
private and have no false open landing doors.

Observation deck at +258.4: continuous guarded perimeter, 1.2 m parapet,
clear circulation at least 2 m outside the core. The shaft above it ends
+262; open steel crown rises to +274 and its vertical-axis spire to +280.
Cap/seat crown posts into shaft structure. Provide a plain accessible view
space; no office interiors, text signs or new NPCs. Wind gaps are exterior
climbing/maintenance ledges, not additional lift destinations in P6.

## 6. North tower — building 14

Shaft rect (−477,−134)–(−449,−108), roof envelope +175. 45 equal levels:
storey = 175/45. Continuous 6 × 8 m core; capsules begin +7.777778, leaving
open ground. Capsules have 6.4 m width, 3.5 m height and depths cycling
6, 7.5, 9 m. For level j (2–44), side s (0–3), bay b (0–1), depth index
is `(j+s+b)%3`, colour index `(j+s+b)%4` in jade/gold/coral/cobalt.
Use two opposite faces per level, alternating the face pair every level:
keep side s only when `s%2 == j%2`. This prevents adjacent face capsules
from intersecting at the corners. Two bays per active face, tangential centres ±3.35. Radial inner face is 4 m
from core centre; rotate this module by 90° per side. At levels above 40,
omit modules where `(j+s+b)%3==0` for the uneven crown. No module may
exceed the checked shaft bounds; retained nominal roof datum stays +175.

Every capsule seats on a flat-capped socket connected to the core. Socket
tangential centre is ±2.5 m, section 0.48 × 0.6 m; it spans from core
centre to radial 4.6 m, buried into the capsule seat. Capsule
shells use SuperEgg exponent 5.5, with recessed sealed rounded studio glazing
from the same cutter. Roofs are landable: collision follows the visible top,
without invisible protruding box corners. Do not round or shrink the socket
until the capsule appears to float. Keep colour changes deterministic.

Sky garden: floor +85.555556 (22 storeys), upper slab top +93.333333
(24 storeys). Omit capsules throughout that interval. Garden plate 27 × 25 m
inside the shaft; core and four 0.6 m columns at local (±6,±6) support the
upper structure. 1.2 m guards, planters set back from a 2 m clear circulation
ring and a real shared lift from ground to garden. Same clear car/shaft as
Windspire; use a separate shaft inside this core, real openings only at
served levels. No studio interiors. Open makers' yard, shaded workshop/cafe
shells and north/east planted strips retain their recorded site boundaries.

## 7. South tower — building 15

Shaft rect (−477,110)–(−451,136), roof +150. Forty levels at 3.75 m.
First balcony slab +7.5, underside +7.26; two-storey colonnade on 1.4 m
aligned primary piers on the recorded 5.333 m grid. A continuous 6 × 8 m
core runs from foundation to roof; 0.8 × 1.2 m girders sit beneath the first
balcony slab, bottom +6.06/top +7.26. These replace the former four small
corner posts. Retain the core and frame through the upper housing. Inner sealed facade is a 20 m-wide superellipse of exponent 5.5,
not a square whose corners poke through the balconies.

For level j, angle a, use radial half-span
`r = 13 − 1.4*(0.5 + 0.5*sin(3*a + 0.43*j))`.
Profile point is `(r*spow(cos(a),2/5.5), r*spow(sin(a),2/5.5))`.
Sample at least 64 around each floor; production resolution must keep the
silhouette smooth. Balcony slab 0.24, guard 1.2 follows the same outline.
Minimum base radial difference from inner facade is 1.6 m; keep circulation
clear of screens/planters and measure actual normal clearances at tight bends.
Screens sit behind that route. All profiles remain inside the 26 m envelope.

Terraces +142.5, +146.25, +150. For j>37 multiply balcony profile by
`1−0.07*(j−37)`. Inner facade steps to 17 m between +142.5/+146.25 and
14 m between +146.25/+150; it must not project through the stepped terraces.
Pale sand ceramic slabs, recessed dark glazing, terracotta screens and planted
terraces. No apartment or Tanglewire interiors. Ground colonnade opens to
recorded gardens/pergola; nursery and residents' room are closed shells.
Pergola top +3.6; posts seat under its lattice. No new private lift route.

## 8. Parts, joins and formation

`DOWNTOWN.parts` and `.joins` are binding, not optional illustrations. The
model displays all 47 part-template definitions and 16 join rules. The build
report accounts for each part with implemented owner(s), geometry/collision
builder and screenshot, or a precise blocked reason. Account for each join
with its shared planes and a close-up. No generic box proxy counts as a part.

Symbolic half-sizes are evaluated per instance: W/D are the relevant shaft or merged podium width/depth; run/segmentL/L are measured between join planes; clearH is the
owner's clear storey; bay is the fitted facade bay; windowW is bay−0.65 with
0.5 minimum; profileW/D are that level's profile bounds; privateH/housingH
are the recorded sealed vertical intervals; shaftW/rise are the assigned
lift dimensions/served span; coreW/coreD are per-site core dimensions; height is the new shaft roof;
southH is 150 m;
span is between structural bearing planes; shared_radius/height come from NatureProps; roofTop is the assigned pavilion/pergola top.
All are metres. Signs in formulas refer to world-local coordinates.

Use production `SuperEgg.build_part`, `build_clipped_mesh` or
`build_clipped_part`, exact-axis handling and game exponent convention.
Structural exponent 5.5; soft furniture/blades 3; round hubs 2. No exponent
below 2, pinched poles, stretched sphere approximations or rounded seams.
Clipped members are cut from their parent and capped at shared planes, not
independently shortened. For long profile curves use consistent sections and
mitred/bisector joins; no floating end caps or crossing duplicate colliders.
Visible window trim is a ring, not a solid plate across its opening.

Floors and sealed infill may use boxes only for flush bearing/closure, with
the recorded justification. Walls use punched solids. Distinguish public
voids from sealed private interiors; no double-sided material can repair
wrong winding. Vegetation uses the shared NatureProps kit; physical trunks,
planters and benches, decorative leaf tips explicitly declared. No new
plant species, fictional institutions or characters are introduced by P6.

## 9. Collision and route acceptance

Survey terrain at footprint corners and entries; foundation embeds at least
0.5 m below the lowest adjacent ground. Exclude terrain under authored
floors. One collision owner per surface; no hovering, overlapping walkable
planes or thin skirts hiding a mismatch. All substantial geometry is solid
or landing under CollisionPolicy; trim/inlays alone are decorative.

Test CW and CCW rectangle and concave fixtures, then representative baked
mid-rise/tower meshes. Godot's visible front follows `(c−a).cross(b−a)`.
Roof/floor fronts point up and exterior wall fronts point outward. Compare
with authored normals; inspect with default back-face culling. Do not flip
normals alone, use double-sided materials, or add hidden cap boxes as fixes.

Walk with the actual hero and Xiao Hou Zi: street/podium routes; court-8
passage both ways; hotel bridge through Windspire lift to observation deck
and back; north ground to garden and back; south garden through colonnade.
Check lift doors, headroom, cabin clearance, guards at openings and safe
landings for both rigs. A raycast or mocked controller is not route proof.
Show representative capsule and dune-balcony landings with shared powers;
no character-specific traversal patch. Deliberately dropping off an exposed
climbing ledge is different from an inescapable trap inside architectural seams.

## 10. Required checks and report

- Run plan generator with checks; regenerate CityPlan and drawing embeddings.
- Re-bake Moy, check bake freshness and run the city layout validator and
  relevant shared quick checks. Preserve existing working packages.
- P0 audits before/after: exactly matched downtown bounds, starts/settings,
  with owner-level classification. No new solid leaks, closed routes,
  reversed surfaces or unexplained reach/trap regressions. Separate old debt.
- Run matched street, vertical and observation/garden camera routes; record
  frame-time distributions, collision/node counts, resources and visual
  density. Diagnose material regressions; do not strip required geometry or
  collision to optimize. P16 remains the whole-city optimization package.
- Two unload/re-entry cycles: active and pending tile requests settle, no
  unexplained retained requests or increasing retained owner counts. Fix
  ownership/cancellation; no enlarged timeout to disguise failure.

Write `docs/diagnostics/<date>-moy-P6.md`: exact owner reconciliation; all
47 parts and 16 joins; geometry/winding/collision evidence; actual two-rig
route results; before/after audits; performance and unload data; limitations.
Separate implemented, verified, failed and unrun. Partial work stays partial.

Required screenshots: city skyline with all three towers; each tower's full
silhouette; shaded mid-rise street at eye height; narrow infill bay; lot119
passage at both ends; Windspire wind-gap structure and observation landing;
north capsule socket, garden bearing and lift landing; south balcony/guard
section and colonnade; isolated structural member ends beside the hero;
day and dusk. Use a readable camera, never an occluding wall as route proof.

## 11. Planning evidence and handoff

See `docs/diagnostics/2026-10-19-moy-P6-planning-r2.md` for passed planning
checks, reference images and explicit runtime checks still owed by the build.

Build prompt: Pull latest main. Read AGENTS.md, CLAUDE.md and the Moy
roadmap. After earlier district fixes integrate, implement P6 from this brief
and the Downtown model, accounting for all 47 parts and 16 joins. Preserve
the authorized revision-2 layout and other packages. Run the specified checks and write the
P6 implementation diagnostic with actual hero/Xiao route evidence. Commit
and push; report any incomplete item explicitly.

## Decisions log

- Revision 1, 2026-10-19: retained 23 source plots as independent tall
  buildings, with a 42-part/14-join schedule. Superseded after user review
  of thin slivers, touching tall facades and the little-post base model.
- Revision 2, user-authorized 2026-10-19: consolidate into ten sites;
  minimum shaft width 12 m and mutual gap 8 m. Preserve the six-metre P17
  interface. Continuous cores, 1.4 m aligned piers and deep girders replace
  the misleading base model, including the south tower's former small posts.
  Current binding schedule: 47 part templates, 16 joins. All prior P6 build
  prompts must be read against revision 2, not the withdrawn first layout.
