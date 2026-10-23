# P11 — the wall, gates and linear gardens

2026-10-23. **Ready for a practical L3 build after P10's rail interface is
settled.** Preserve the existing implementation checkout and earlier packages.
This is a design brief, not certification that the wall is built.

## 1. Read first and ownership

Read AGENTS.md, CLAUDE.md and moy_build_roadmap.md. Then:

- `city.md` §6c for the railway-wall history and precedents; §§8b/8b.1 for
  City Hall, the West Gate and their existing circulation.
- `tools/city_layout.py`: WALL, WALL.kit, ARCH, ARCH.front/front_guard,
  WEST_GATE, GREEN and PLATFORMS; generate CityPlan, never edit it by hand.
- P10 brief and handoff: track/vehicle/platform interfaces and Watch operation.
- Existing `_add_wall`, `_add_wall_transit`, gate/hall construction in
  `scripts/moy_city_bake_builder.gd`, lifts/escalators and collision policy.
- `docs/drawings/moy_wall_gardens_3d.html`: complete dedicated model, its
  parts/joins tables, ground/upper/bastion/gate/section/night views.
  Local downloadable HTML; external hosting pending.

P11 owns the wall shell, four gates' architectural completion, seven watch
posts, watch route, Rim Corridor/Rim Walk landscape, guards and searchlights.
P10 owns track geometry, rolling stock, timetable, platforms, boarding and
station operation. Coordinate once; do not build two sets of platforms.
P7 remains the only Crossing architecture authority. P12 owns broader city
paving/Deck dressing. P13 owns detailed occupied gate interiors. P14 owns
Watch/resident schedules. P15 owns exterior works/NMEs. P18 owns the five-bay
venue interior and nights; P11 preserves its closed exterior shells only.

Snapshot local source, generated plan, bake and evidence before integrating
planner main. Do not replace the locally built city with this planning clone's
248-pack bake. Regenerate and genuinely bake the actual implementation.

## 2. Design intent: a railway wall with a High Line landscape

The railway came first; infilling its outer arches made it a defensive wall.
Keep the old viaduct readable on the inhabited city face: real recessed
vaults, pale structural piers, warm shade, seats and occasional closed stores.
The desert face remains calm pale ceramic over concrete/earth. No crenellated
castle, military theme park or new fantasy pagoda roof language.

**User,2026-10-23: use the High Line's interesting pathways and integrated
park landscaping.** This is a path-and-planting composition, not a row of
identical potted shrubs. A continuous mineral path weaves between long garden
fingers; planting drifts tighten/relax beside seats and views; the architecture
and gardens make places to pause. Narrow upper links lead to broader planted
bastion terraces. Offer city-facing quiet niches below and desert views above.

Use Moy's water-appropriate palette: desert grasses, agave/aloe, restrained
bougainvillea/coral vine at supported rooted locations. Existing tree sites
stay fixed; do not put new trees/deep soil over narrow wall caps or fill rail
clearance with meadow. No tropical lawn blanket, green sausage shapes,
unrooted floating foliage or exposed decorative irrigation pipes.

Precedents and application:

| Reference | Use here |
|---|---|
| New York High Line | path woven through planted fingers, quiet seats, framed views, broader garden pauses |
| Xi'an wall / mamian bastions | scale, continuous circuit, outward viewing posts |
| Tokyo railway arches | real shaded recesses and inhabited inner face |
| Jiayuguan gates | inherited three-tier corner-tower hierarchy, expressed in pale tile and flat steel |
| Moy's Singapore greenery | rooted climbers and terrace beds integrated into structure |

No printed words, letters, numerals or new mechanic messages. Gate identity
comes from its silhouette and approach: City Hall arch east, twin towers west,
existing smaller tiered gatehouses north/south. No named new Watch NPCs.

## 3. Locked layout and explicit wall section

Circle centre(-560,0), centreline radius209.5; wall12m high×12m thick.
Inner/outer faces203.5/215.5 radius. Keep all four gate sites, footprints and
clear passages, seven post sites, Line House allocation, works/turbines and
114 current canonical arch centres. Earlier prose's112 arches is historical;
use WALL.arch_s. Do not move streets, building sites or the wall to fit details.

WALL.kit section coordinates: **u tangent, v outward from wall centreline,
y above Moy datum**. Runtime world y=datum−60 plus these levels.

| Section element | v / level |
|---|---|
| Wall envelope | v−6..+6; top12 |
| Two track centres | −3.9 and−0.5; rail13.2 |
| Rail-side watch guard | v1.125; height1.1 above walk |
| Upper clear promenade | v1.225..4.825; width3.6; walking level12 |
| Shallow planted edge | v4.85..5.3; trough height.45 |
| Outer parapet | v5.3..6; height1.2 |
| Ground Rim Walk | radius197..203; ground level0 |

**Coordinate correction:** WALL.track_axis=−2.2 is the **midpoint** of the two
tracks, not lane0. The old runtime computes lane0 at−2.2 and lane1 at+1.2;
that shifts the railway1.7m outward and consumes the watch walk. P10/P11 must
use midpoint±track_spacing/2 consistently for rails, cars, platform radii and
clearance. This restores the existing plan section; it does not move the
locked city axis or silently change track spacing. Record the integrated
implementation baseline before applying it; do not overwrite newer correct work.

Nominal car half-width1.325 gives outer car edgev.825, .30 to guard centre;
inner car edge−5.225 remains inside the city-side guard. Use actual body/pocket
swept envelopes, curve overhang and collision margins from P10 at gate platforms.
Never solve a clearance conflict by narrowing the promenade without recording it.

### Station transitions, not a low underpass

The upper path is12, platforms14.2. A path beneath a platform underside13.9
would offer only1.9m headroom: **do not build that underpass**. Before each
station, a2.4m clear ramp rises2.2m over22m (1:10), joining the existing outer
platform's rear circulation zone. It begins42m along the wall from gate
centre and reaches the40m platform end at20m. Mirror at the other end.
Keep the platform's normal3m width and at least1.5m clear circulation behind
the boarding strip; the watch route shares this station space, not a live track.
No private rail crossing, gap jump or guard across the arriving path.

Follow exact curved wall/platform geometry in production, not tangent blocks
from the preview. Supports and all gate/hall walls must clear the ramp sweep
and2.4m vertical headroom. At East/West use the existing train-hall openings
and platform circulation; retain P1's open east wall band serving the outer
platform. Update the ramp guard endpoints to meet real platform guards once,
with P10. Keep existing accessible lifts/escalators, not a new route system.

## 4. Ground Rim Corridor and planted route

Rim Walk and Rim Corridor describe this same connected ground circuit beside
the wall in P11; do not invent a second road outside it. The existing6m
annulus197..203 remains the allocation. WALL.kit.section.ground_path gives
a3.2m clear path with centre radius200+.6sin(9θ), contained inside that annulus.
Its changing margins form .6–1.8m planted fingers, gravel pockets and clear
threshold aprons. Use shared curves for paving and beds, not jagged sample boxes.

Keep radial street/gate mouths fully paved and open: interrupt beds within
at least the street/passage width plus approach clearance. Existing service
access, stairs/lifts, building doors, emergency gaps and reserved P18 entrance
receive connected level aprons. Do not blindly pave/plant the sine curve
across a doorway or retained tree. Local small edge refinements may follow
existing sites while keeping3.2m clear; do not move the annulus.

Alternate long grass drifts with low succulents and mineral edges. Seat niches
sit inside selected arch recesses, facing the city; no bench or planter in the
clear path. Existing shade trees are retained, never invented new sites.
No new chess/vendor/café interactions, commercial tenancies or census changes.
Use current simple foliage builders with a few coherent clumps per bed.

## 5. Viaduct bays and wall construction

WALL.kit.parts/joins specify39 part families and15 joins, the complete visible construction vocabulary.
Gate-panel/diagrid rows are reusable templates dimensioned by the exact
ARCH/WEST_GATE footprints, hall arcs, levels and structural nodes, not1m
replacement facade pieces. Each entry records shape, half-sizes, centre, repetition, collision and bearing
or cut plane. Keep this as a design reference, not a manufacturing spreadsheet.

Typical9m bay:6.5m span,5.5m crown, spring2.25; n3.4 superellipse arch.
The inner5m depth is a real recessed vault with level floor0; outer7m remains
filled structural mass. Show pale arch rims and warmer old brick/concrete
soffits, restrained tile joint rhythm outside, cap and drainage. No black
rectangle pasted over a full-depth collision wall. Piers/cap bear above the
vault; shared radial planes close adjacent bays. Curved runs use actual shared
vertices, no gaps hidden behind overlapping eggs.

Selected recesses stay empty/shaded or hold a wall-backed seat/light. Some
closed storage shutters supply variation, without fake doors players can enter.
P18's five bays retain old soot/darker shutters and one subtle light at the
middle threshold; no club/bar/ring/rave interior or event system now. Do not
fill the future connected volume with irreversible structure or shift its door.

The desert face is solid. No through-vault holes, climb-only shortcuts required,
new defence weapons, forcefield or arbitrary player exclusion. Gates stand open.

## 6. Watch walk and seven garden bastions

Continuous top walk12,3.6m clear between rail guard and planted parapet edge.
Troughs are shallow .45m wide; ground/path and viewing pauses carry the richer
High Line composition. Keep plant height low beside views and foliage away
from trains. Continuous guards are swept profiles with shared curve vertices,
not bead chains. Guard collision stops falling into trains/desert; never
close a real route throat with a rail or invisible wall.

Each existing post:20m along×10m outward, top14. Cut a real inner roof notch
for two open-air10m ramp flights,12→13→14,1:10,2.4m clear. The exact local
flight endpoints/width/landings are in WALL.kit.post_access. Flights sit side
by side atv8.2/10.8, joined by1.8m end landings; a level throat connects the
wall walk to the lower flight, the upper landing to the outer roof terrace.
The roof/base must be notched to the same sweep; do not bury the ramp in the
solid14m bastion. No bridge across live rail tracks. Protect all open notch
edges, with2.4m headroom above routes and guards open at joins.

On the outer terrace keep the2.4m path atv12..14.4, low planting in
v14.6..15.6, and the light at u−8,v15.1. Place the bench between beds,
clear of this path. Planted islands, a bench and the clear route form a
small garden pause. Low soil/plant loads are carried by the roof, drainage
back into service system. Keep the searchlight view/sweep and route clear.
Support massive bastions to terrain, never suspend them on tiny columns.

A searchlight per bastion: mounted gimballed housing, outward lens and a slow
night-only desert sweep, restrained beam/falloff. Its housing/lens/beam turn
together; no sweep into the city/cabin windows, blinding flood or combat damage.
Use existing clock/light patterns and modest distance culling; shadowed lights
only where useful nearby, not seven permanent costly long-range shadow maps.
Night beam is decorative/nonphysical, substantial housing has collision.
Watch figures/schedules remain P14; a functioning light doesn't require a new NPC.

## 7. Gate architecture

**North/South:** retain44m gatehouses,24m depth including outward projection,
10×8m clear street opening, two inherited three-tier corner towers. Shared
wall deck remains12; support train/platform levels above it rather than letting
a14.5m full gate block intersect the railway. Tier bases14.5, pitch3.2,
widths7/5.6/4.2, thin flat steel roofs. Show real bearing and one small hollow
bronze bell hung under the first-tier roof, no floating clapper or extra cap.
Station/lift/ramp circulation and buffers stay as P10's integrated interchange.

**East:** City Hall is the Meridian Arch. Retain the legs, lower bridge32..42,
upper bridge58..72,12m cityward cantilever, front City Steps, Rostrum14.2,
scissors, galleries, lifts and existing Watch-private core. Existing ARCH
and ARCH.front dimensions/voids are authoritative. Finish ceramic-clad frame,
glass and simple structural diagrid, cut at real train halls/doors. Never fill
the high-line train hall or cover the exterior access with a solid glass box.
No redesign of Timekeeper, mayor/council story or P13 occupied interior program.

**West:** retain twin footprints, bridge32..42 and tower tops44. Preserve
Wall Line hall12..21 and the public open loggias/scissor/lift routes to14.2/37.
Complete the existing community roof garden on the bridge with bounded beds,
seats and guards, keeping arrival zones clear. Do not interpret a garden roof
as permission to fill railway space underneath, or invent a high-line siding
outside the locked track envelope.

Line House belongs to P10; P11 only closes its wall/support/guard/landscape joins.
Existing outside works stay separate, fenced and independently accessed.

## 8. Model and preview limits

The dedicated model shows real arch recesses, weaving ground path, upper
section, bastion ramp notch/planting, inherited gate masses/hall curves and
night sweep, with the actual exported hero. All sites and sizes are true-scale.
Context blocks are not new buildings. Technical sections omit wall faces.

Some gate circulation and platform surfaces are simplified construction
studies; ARCH.front/front_guard and the existing precise gate/station plans
remain binding. Production uses curved platform/ramp/guard joins, proper
terrain support, thickness, collision and doorway voids. Do not copy a
schematic plane, unguarded preview edge or opaque neighbour block as game art.
No new substitute Crossing model appears here. External hosting is pending.

## 9. Practical checks and report

Build one real wall/vault bay and one planted path segment, then one complete
bastion/access route, then repeat, then finish gate interfaces. Ohio/Snowhio
sophistication; no universal traversal matrix, new climbing system, detailed
room certification or P2 optimisation detour.

- Plan generation/schedule/section containment checks; required repository
  checks, genuine integrated bake and freshness, relevant city validator.
- Walk one ordinary Rim segment, seated vault and gate mouth; verify real
 5m recess, flush thresholds,3.2m route, visible/collision agreement and no
 plant/seat in it. Check P18 threshold remains connected/shut.
- Follow the upper circuit through a representative station transition and
  one complete bastion ramp/terrace. Check12→14.2 approaches,12→14 post ramps,
  2.4m headroom, real cutouts, guard joins, no rail crossing or blocked mouth.
- At all four gates inspect street passage, outer platform connection and
  existing lift/escalator arrival. Check preserved East hall opening and
  West garden/high-line separation. Sample curved train sweep beside guards.
- Day/night clock check:7 outward lights, shared housing/beam movement,
  no city sweep, physical housing/decorative beam and sensible shadow policy.
- Normal-resolution screenshots: city-side path at eye level, real vault,
  upper walk/train separation, planted bastion, night outward view, each gate
  silhouette plus one gate platform join. Inspect images; don't just save them.

Write `docs/diagnostics/<date>-moy-P11.md`: preserved implementation baseline,
actual bake provenance, key section/access measurements, walkthrough and
lighting results, screenshots, material defects and minor polish separately.
Stop for review before P12. Don't report planning preview as runtime evidence.

## Decisions

- 2026-10-23: user requested P11 next; explicitly reaffirmed High Line pathways
  and integrated park landscaping as a preferred reference.
- Keep all locked sites/levels. Richer planting is concentrated on ground
  circuit and wide bastions/gate gardens; upper connecting path stays clear.
- Explicit midpoint convention restores planned train section. P10 owns
  integrated rail/platform correction; P11 provides shell/guard/path clearance.
- Station approach ramps replace any unsafe low-headroom path under platforms.
- Keep gates open, ordinary public traversal possible, Watch/NME/event systems
  in their existing later scopes. No new named people or printed game text.
