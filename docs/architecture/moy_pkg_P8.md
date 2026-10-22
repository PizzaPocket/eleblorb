# P8 — The park, built together with P9

2026-10-22. **Ready for one combined P8/P9 implementation pass.**

- Area: the locked park rect world(-625,-50) to(-495,50), its four quarters,
  public grounds, pond, six parasols, tea-house public room and park lodge shell.
- Companion: `moy_pkg_P9.md`; one implementation owner and one integrated bake.
- Build goal: a coherent, playable and dressed park at practical Ohio/Snowhio
  sophistication. Reach L2/L3 in this pass; final L4 performance/polish remains
  tracked in the roadmap. Do not turn this into a precision-certification loop.
- Model: `docs/drawings/moy_park_playground_3d.html`, shared with P9. Local
  checked-in model and references; external publication pending.
- Design source: `CityPlan.PARK.kit`,40 part templates/12 joins, plus original
  PARK positions, pond profile and NatureProps proportions. Never hand-edit
  `scripts/city_plan.gd`.

## Read first and ownership

Read AGENTS.md, CLAUDE.md, current roadmap direction, this brief, P9 and the
combined `moy_p8_p9_build_handoff.md`. Then city.md7a/7b and the park paragraphs
only, `tools/moy_park_kit.py`, relevant city_layout.py data, architecture and
landscaping skills, `nature_props.gd`, `village_works.gd`, collision policy,
and `_park_ground_body`/`_add_park` in the Moy bake builder.

P8 owns the connected grounds, small public tea room, parasols, pond crossing,
landscaping and furniture. P9 owns play equipment and its pump track. P7 owns
station towers, ring, lifts, tracks, dome and interior garden. Preserve P7's
geometry/datum and planned exits; connect to its ground landings without
rebuilding the station. P12 owns wider streets/Deck furniture, P10 train operation.
Do not modify P3–P6 buildings or run their historical repair loops.

## People, climate and composition

The park is the city's shared cool ground. Old Fu serves tea and tends the
chess area; Orin's lodge supports park maintenance. The Hos have their existing
chess gathering; the playground's families need shade and sightlines. Keep
existing people/interactions working; no new NPC simulation, chess UI or dialogue.

Use the existing desert palette: dry gravel, agave/boulders and date palms,
ghaf shade trees, flame trees by the tea terrace, the single banyan by the
working reed pond, and the existing small irrigated lawn. Existing source trees
replaced the obsolete steel wind trees; do not restore wind-tree sculptures.
Use shared NatureProps, with layered planting in purposeful clumps and shade
where people sit. Existing tree/trunk positions and the23-tree schedule stay.
Keep tall crowns off the Deck/rail structures. Low edge planting may be omitted
where checked new paths meet it (`excluded_shrubs`), rather than blocking routes.

The charter is Persian four-part garden organization (the two civic walks),
with tropical civic timber parasols as the secondary language and desert play
colour as a small accent. No new ornamental fountain. Colours are in the kit;
no printed letters, words or numbers, including park maps and equipment labels.
Technical page labels and plan IDs are documentation only.

## Ground, routes and quarters

Keep the main east–west and north–south walks6 m wide at their locked positions.
`kit.paths` is one checked connected polygon network: additional2.4 m walks
connect the tea terrace, public east door, dry-garden approach, both boardwalk
abutments, lawn/lodge and the playground's west entry. The route points in
`kit.routes` explain the construction; use the final polygons around sockets.

- Northwest: the existing dry garden is walkable gravel between real boulders,
  palms and agave. Give it a worn approach; do not irrigate it into a second lawn.
- Northeast: preserve the working reed pond, with visible sloping earth/stone
  shelves, reed clumps rooted at shelf level and quiet open water.
- Southwest: six broad timber parasols shade tea and chess, with paths between
  their stems and furniture. Do not put a post through a walking line.
- Southeast: retain the16 ×16 m picnic lawn, lodge and the P9 playground beside
  it. The entry joins the lawn-side path to the track's deliberate level crossing.

Paving is currently face-down in `_park_ground_body`: correct its actual mesh
winding and check both render faces and collision from eye level. Do not hide
it with a second full-area slab. Godot clockwise front normals use
`(c−a).cross(b−a)`; browser triangle order is different. Keep terrain sockets,
park ground, building floors and pond bed to one physical owner per surface.
No invisible flat ground cap across the pond, no duplicated raised turf collider,
no holes around station landings. Grass/gravel dressing rides the one ground.
Use exact land/water/footprint cuts; do not copy the old coarse-grid stair edge.

## Pond section and boardwalk

The source ellipse is centred(-516,-28), radii19/13. Water stays0.3 m below
park datum; bank top is1.15 times those radii. Follow the full source bed:
(1.15,0),(1.0,-0.3),(.86,-.65),(.6,-1.5),(.3,-2.0),(0,-2.1).
Use VillageWorks' shared two-sided translucent water, hazard metadata, actual
surface/depth and existing liquid-query integration. Do not create a new water
shader or collision plane that makes swimming impossible. Keep a usable shallow
exit; swimming is an optional existing-power use, not a new movement system.

The low boardwalk runs(-536,-20) to(-496,-20),2.4 m clear, top+0.18, deck0.18
thick, with timber girders and paired piers at4 m bays to the sampled bed.
Guards1.1 m above the deck along both long edges, open at both level landings.
No guard across a public entrance, no suspended unsupported bridge and no
floating reeds or stones. Water must be visible below and through the banks.
Model water is indicative; actual game depth/shoreline is the verification.

## Tea, chess, parasols and lodge

Building9 retains world(-618,24) to(-604,36), current4 m envelope. Provide a
2 ×2.5 m clear rounded-head east doorway at(-604,30), level public floor,
serving counter, a few tables/stools/cups and a private rear/service partition.
Simple village tea props suffice. Preserve any existing service interaction;
do not add a bespoke shop framework. The historic program includes Kenji's
flat above and Old Fu's private accommodation. This park pass reserves that
private program; it does not invent a habitable flat inside a4 m height or add
an unauthorized storey. Fitout/private accommodation is follow-up scope.

Six parasols stay at `PARK.parasols`: radius4.2, underside4.2, canopy depth0.65.
Their square-round stems and branching arms meet one shallow soft canopy.
No tipped stretched eggs, disconnected beams or multiple rounded caps. Keep
comfortable clearance below each roof. Canopies and substantial furniture are
physical; roof drainage goes to planting, not into doorways.

Three chess groups and six shade/overlook benches follow `kit.chess` and
`kit.benches`; use physical pedestals/legs/stools. Chess is scenery and the
existing social activity, without new game rules or printed board markings.
Carved abstract grid/pieces are fine. Put bins beside seating, not in routes.
Warm low lighting is restrained, shared with existing village fixtures.

Building10 retains(-552,41) to(-542,49),4 m high, with a clear east-facing
service threshold and an obvious simple lodge shell. Keep its private/service
interior sealed this pass. Its footprint must not consume the lawn-side path.

## Shape and construction schedule

Use the full40/12 source schedule below as design guidance. It specifies
SuperEgg/profile/clip shape, half-sizes, exponents and collision for every
piece class. Use existing builders and reasonable simplification; no exhaustive
40-row manufacturing certificate is needed. Major forms, joins, openings and
physical support must match. Structural members use exponent5.5, furniture and
soft ground3, round natural forms2–3. Never use exponents below2 or copy pointed
browser sampling artifacts. Constant-section beams have flat seated/shared cuts.
Box/facet exceptions are only continuous terrain/floor/bearing infill where
rounding would open a seam. Models use approximate NatureProps silhouettes;
production uses the real shared plant builders.

The source part/join tables follow at the end of this brief.

## Finish and focused verification

Build shared ground, water and paths first; play footprints/structures second;
then tea, shade and planting/furniture. Work in coherent batches with quick
local previews, integrating once the park is recognizable. Do not bake the
whole city after each bench or restart P2 optimization.

Run required repository checks, plan validator and current bake freshness.
Walk from the civic axis to tea, across the pond boardwalk, past lawn/lodge
and into the playground. Use ordinary hero movement; check representative
public widths/landings with Xiao Hou Zi as well. Inspect pond swimming/exit
with the existing controller. Do not replace gameplay checks with coordinate
teleports or claim every roof/leaf must be universally reachable.

Take a handful of ordinary-resolution views: integrated aerial, pond at eye
level, tea/chess approach, lawn-to-playground connection, one dry-garden view
and one public interior/threshold view. Report sensible collision, winding,
major holes/blockers and remaining defects. Minor seams and decorative polish
are follow-ups, not automatic rebuild gates. Observe performance proportionately
and flag meaningful regressions; final whole-city budgets remain P2/P16.

One combined diagnostic `docs/diagnostics/<date>-moy-P8-P9.md` covers both
packages: concise implementation/coverage by major groups, actual checks and
walkthrough results, useful images, and explicit incomplete or unverified work.
Do not mark runtime L4 solely from a browser model or planning checks.

## Decisions and handoff

2026-10-22: user explicitly requested P8/P9 together because the park is
integrated. This authorizes one combined construction pass within this area;
retain separate package IDs and schedules for review. No new lore introduced.

Build prompt: Pull latest main and build P8/P9 together from
`moy_p8_p9_build_handoff.md`, both briefs and their shared model. Finish the
connected park at practical village quality, run focused checks, report and push.

Planning evidence: `docs/diagnostics/2026-10-22-moy-P8-P9-planning.md`.

## Source parts reference

Half-sizes in metres; symbolic sizes resolve from the named owner/path.
Shapes use the listed exponents; no cap or rounding may close an opening.

| ID | Shape and half-sizes | Exponent | Collision | Use |
|---|---|---|---|---|
| `ground` | facet · patchW/2 × 0.1 × patchD/2 | cut/facet | landing | earth and terrain excluding pond basin and built sockets |
| `path` | profile · patchW/2 × 0.04 × patchD/2 | 5.5 | landing | connected pale paving, flat top +0.08 |
| `gravel` | profile · patchW/2 × 0.02 × patchD/2 | 5.5 | decorative | dry garden and unwatered soil grounds |
| `lawn` | profile · 8 × 0.02 × 8 | 5.5 | decorative | existing single irrigated picnic lawn, flush edging |
| `bed_edge` | profile · 0.08 × 0.12 × run/2 | 5.5 | solid | low rounded garden edging, no kerb across paths |
| `soil` | profile · W/2 × 0.03 × D/2 | 5.5 | decorative | planted soil surface inside bed edge |
| `rock` | egg · rx × ry × rz | [3.0, 3.0] | solid | existing boulder and bank-stone extents from PARK.rocks |
| `tree_trunk` | egg · R × H/2 × R | [3.0, 3.0] | solid | NatureProps trunk and principal branch dimensions by existing kind/height |
| `tree_canopy` | egg · crownR × crownH/2 × crownR | [3.0, 3.0] | decorative | NatureProps ghaf/flame/palm/banyan crowns, existing positions |
| `shrub` | egg · 0.7 × 0.4 × 0.7 | [3.0, 3.0] | solid | low clumped edge planting, omit at path openings |
| `reed` | profile · 0.035 × H/2 × 0.035 | 2.0 | decorative | shared reed clumps rooted at actual shelf heights |
| `agave` | egg · 0.12 × 0.75 × 0.2 | [3.0, 3.0] | decorative | shared thick natural blades, no pinched tips |
| `pond_bed` | facet · rx × 1.05 × rz | cut/facet | landing | continuous shared source radial shelves; no invisible paving cap |
| `water` | profile · 19 × 0.001 × 13 | 2.0 | open | shared translucent VillageWorks water at -0.3 |
| `board_deck` | profile · 1.2 × 0.09 × bay/2 | 5.5 | landing | 2.4m clear pond boardwalk, top+0.18 |
| `board_pier` | clipped · 0.13 × H/2 × 0.13 | [5.5, 5.5] | solid | low bridge supports to actual bed, no unsupported deck |
| `board_girder` | clipped · 0.12 × 0.16 × run/2 | [5.5, 5.5] | solid | continuous twin timber beams under deck |
| `guard_post` | clipped · 0.045 × 0.55 × 0.045 | [5.5, 5.5] | solid | 1.1m guards at pond bridge edges |
| `guard_rail` | profile · 0.045 × 0.045 × run/2 | 5.5 | solid | continuous rounded-square timber rails |
| `parasol_stem` | clipped · 0.18 × 2.1 × 0.18 | [5.5, 5.5] | solid | six fixed timber parasol columns to canopy bearing |
| `parasol_arm` | clipped · 0.1 × 0.12 × L/2 | [5.5, 5.5] | solid | radial timber branches under roof |
| `parasol_roof` | egg · 4.2 × 0.325 × 4.2 | [3.0, 3.0] | solid | broad shallow rounded canopy, radii4.2 and height0.65 |
| `bench_seat` | egg · 1.1 × 0.09 × 0.3 | [3.0, 3.0] | solid | benches at shade/overlook points |
| `bench_leg` | clipped · 0.12 × 0.2 × 0.22 | [5.5, 5.5] | solid | two ground-bearing bench supports |
| `chess_top` | egg · 0.48 × 0.07 × 0.48 | [3.0, 3.0] | solid | square-round stone chess table with abstract carved grid |
| `chess_base` | egg · 0.16 × 0.36 × 0.16 | [3.0, 3.0] | solid | single pedestal and foot below each tabletop |
| `chess_stool` | egg · 0.22 × 0.22 × 0.22 | [3.0, 3.0] | solid | four stools around each table, kept off walks |
| `chess_piece` | egg · 0.035 × 0.08 × 0.035 | [3.0, 3.0] | decorative | simple carved game pieces; decorative board, no new chess UI |
| `bin` | egg · 0.25 × 0.4 × 0.25 | [3.0, 3.0] | solid | closed refuse/recycling containers beside seating |
| `light` | egg · 0.15 × 0.22 × 0.15 | [3.0, 3.0] | decorative | low path lighting and shaded tea lanterns |
| `tea_plinth` | box · 7 × 0.18 × 6 | cut/facet | landing | building9 socket, one flat floor and level east threshold |
| `tea_wall` | punched · wallW/2 × 1.8 × 0.12 | 5.5 | solid | single walls punched at public door and service windows |
| `tea_roof` | clipped · 7 × 0.14 × 6 | [5.5, 5.5] | solid | existing 14 by12 envelope, flat louvred roof at4m |
| `door_trim` | profile · 1.15 × 1.4 × 0.09 | 5.5 | solid | square-foot rounded-head public opening 2 by2.5m clear |
| `tea_counter` | egg · 1.8 × 0.5 × 0.4 | [3.0, 3.0] | solid | simple serving counter with physical rear service zone |
| `tea_table` | egg · 0.65 × 0.07 × 0.4 | [3.0, 3.0] | solid | shared small tables and stools in public room |
| `tea_cup` | egg · 0.07 × 0.07 × 0.07 | [3.0, 3.0] | decorative | shared village tea props, no printed labels |
| `lodge_shell` | punched · 5 × 2 × 4 | 5.5 | solid | park-lodge existing 10 by8,4m envelope, plain service shell |
| `lodge_door` | profile · 0.75 × 1.25 × 0.09 | 5.5 | solid | east-facing rounded-head service door, actual opening |
| `drain` | profile · 0.12 × 0.06 × run/2 | 5.5 | decorative | shallow runnels and covered drains below path top |

## Source join reference

| ID | Kind | Shared plane / cut | Construction |
|---|---|---|---|
| `ground_cut` | punched | pond bed, tower drums and building sockets | one physical standing surface per location; clockwise up-facing fronts |
| `path_seam` | meet | same ground datum and exact patch boundaries | flush edges, no grass/paving overlaps or path kerbs |
| `pond_bank` | chain | source bed and waterline | bed/ground meet at bank_top1.15; water -0.3; water hazard uses actual depth queries |
| `bridge_bearing` | seated | deck underside and actual bed | piers reach embed below bed; girder tops meet deck underside |
| `bridge_guard` | chain | bridge sides only | guards continuous1.1 above deck, openings at both landings |
| `parasol_bearing` | seated | canopy underside+4.2 | arms seated at common stem; shared roof curve, no loose caps |
| `furniture` | seated | actual floor/ground | legs meet seats and ground; maintain route clearances |
| `plant_root` | seated | surveyed ground and pond shelf | root planting at actual levels; use shared NatureProps, not spikes |
| `tea_socket` | meet | locked building9 footprint and roof4 | walls, floor and roof same envelope; one owner per surface |
| `tea_opening` | punched | east public threshold, rear service partition | one real2 by2.5 opening, clearance2m both sides, no hidden wall collider |
| `lodge_opening` | punched | locked building10 east service threshold | guard private service, no speculative interior or sign text |
| `drainage` | meet | pond shelf and path margins | no open trench across route; splash recirculation separate from pond swimming water |
