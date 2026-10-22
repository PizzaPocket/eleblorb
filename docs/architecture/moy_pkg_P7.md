# Package P7: the Crossing to shippable

2026-10-20. **Ready for implementation. Planning model and binding kit complete.**
Read `moy_build_roadmap.md` first. P7 completes the existing station, not a new
station layout. User explicitly requires a parts-and-joins schedule for every
P7 element, including the dome's smooth geometric steel-and-glass construction.

## Current P7–P9 build direction — 2026-10-22

Use `moy_p7_p8_p9_build_handoff.md` in a fresh conversation in the existing
P5/P6 implementation checkout. P7 is first, then P8/P9 together. The integrated
park model now uses the exact same canonical P7 scene as this package's detail
page (`moy_crossing_scene.js`), not a separate low-fidelity station.

Aim for a complete practical L2/L3 built-and-dressed milestone. Preserve all
specified architecture, public circulation, clocks/bell and real close-up frame
quality. The72/19 schedule is design guidance, not an exhaustive certificate.
Focused real-game checks and required repository checks replace the older
per-part/P0/per-view performance and unload matrices as construction gates.
Final L4 remains tracked; never claim an unmeasured performance gate passed.
This direction supersedes older workflow/gate wording below, not the geometry.

- **Area:** the Crossing, its four garden towers, helices, concourse ring,
  cross-bridges, two platform levels, roof, dome, clocks and Clock Room.
- **Long-term target:** L4 locally: correct architecture/collision, finished materials,
  planting/furniture, functioning routes/lifts/clocks/bell, reviewed evidence
  and a measured performance result. A planning-model pass is not game L4.
- **Depends on:** P0 audit suite, accepted P1 work and its P7 carry list;
  integrate shared-builder changes sequentially with the district packages.
- **Binding data:** `CityPlan.CROSSING`, especially `.kit.parts`, `.kit.joins`,
  `.kit.grid`, `.kit.lift_serving` and `.kit.furniture`. Authoring source is
  `tools/city_layout.py` plus `tools/moy_crossing_kit.py`; never hand-edit GDScript.
- **Model:** `docs/drawings/moy_crossing_3d.html`: station, dome, interior,
  eye, platform, ground and section views, with a unioned node detail beside
  the exported game hero. Local page; external artifact publication pending.
- **Exclude:** train rolling stock/timetable work (P10), park redesign (P8),
  giant playground (P9), city-wide optimization (P16), new NPCs or dialogue.
  Preserve existing services and shared traversal/interaction components.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, roadmap, architecture skill and Crossing charter.
2. `city.md` section 6's Crossing and Clock Room, relevant green-infrastructure
   paragraphs and the dome/clock decisions. No need to read unrelated districts.
3. This brief and exact kit/grid in the two authoring sources above.
4. `moy_prototype_pass_4.md` final P1 review/carry list: Crossing lift-call
   reach, 136 overlap and 35 solid findings; roof headroom/overlap ownership.
   These are inherited measurements, not an assertion that all remain current.
5. `scripts/moy_city_bake_builder.gd`: `_add_crossing`, `_add_city_dome`,
   `_add_dome_lattice`, `_add_clock_room`; existing shared lift/escalator code,
   `moy_timekeeper.gd`, collision policy and P0/P2 probe tooling.

## 2. People, character and references

The Crossing is the public interchange and a garden room in the sky.
Passengers use the lawn, ring, helices and platforms; people deliberately
visit the Clock Room, listen to the bell and look through the glass. Kade
maintains it. No invented kiosk merchants, mechanic tutorials or named tenants.

The dome's primary reference is the **Queen Elizabeth II Great Court**:
coherent triangular steel/glass construction, uniform member sections,
flush nodes, and panes coordinated with the frame. **Cloud Forest and Flower
Dome, Singapore** inform the smooth continuity and restrained detailing;
their large arched ribs are not an instruction to add a second cage over this
existing gridshell. These named references guide the design; no claim of a
new live photographic research session or copied engineering is made.

The palette remains white-painted steel, pale timber louvres, clear slightly
cool glass, muted bronze clocks/bell, pale terrazzo and the existing desert
plant palette. No printed letters, words or numerals. Clock ticks, arrows and
the compass pictogram are geometry, not labelled signs.

## 3. Exact coverage and datums

All levels are metres above datum world y=−60. Centre world (−560,0).

| Element | Binding geometry/level |
|---|---|
| Four towers | centres (−547,−13),(−573,−13),(−547,13),(−573,13) |
| Each tower | trunk radius1.2, eight0.44 ribs, recorded drum/hoop positions |
| Two helix hands per tower | inner radius1.4, outer4.0, depth0.9; use hands.profile verbatim |
| Gallery inner clear | at least4.02; inner rail radius4.1, gallery outer5.8 |
| Concourse | +6.5; ring inner24.7/outer32.7, depth1.6, eight planned supports |
| Spine platforms | +14.2; preserve track/boarding envelope |
| Meridian platforms | +37; preserve track/boarding envelope |
| Main roof | underside+41, top/Clock Room floor+41.6 |
| Roof outline | half22, superellipse exponent4, planted rim1.4 |
| Glass drum | half20, exponent4, height17 above floor |
| Cupola | height11, original outer apex+69.6 |
| Clock faces | four cardinal bearings, centres+50.1; ring radii3/5/7/8 |
| Eyes | radius2.85, flat sill+47.7, clear chord3.07, headroom5.25 |
| Clock Room | four existing arrival wells, two platform widenings, four lift lanterns |

No tower, street, track, platform, clock centre or arrival is moved. Use the
recorded ring supports, beam depths, climber sheets and rain gardens. Preserve
the two different helix hands, accumulating angle and flat landing intervals.
Do not generate a generic spiral instead, or repair a route by changing its
rise/run. The shared escalator/helix supports every playable rig.

## 4. Dome framing: repair the actual geometry problem

### 4.1 Current defects to replace

The current `_add_dome_lattice` makes independent six-sided cylinder
instances. It calculates next-angle radii and positions inconsistently, so
neighbouring struts do not reliably meet the same nodes. Its last row
collapses to the pole, producing zero-length members, while the intended
crown radius is nonzero. It also does not cut the lattice at clock eyes.
Do not merely increase the cylinder sides, add spheres to the ends or smooth
normals over disconnected pieces. The user specifically rejected the
segmented appearance close up.

### 4.2 One checked grid, shared by frame and glass

`kit.grid` supplies nodes, unique edges, pane polygons, glass triangles,
closed boundary loops and cap geometry. It is the common geometric source.
The base uses the existing exponent4 rounded-square plan. Drum and elliptical
cupola meet tangentially; row spacing follows meridian arclength. Around each
row, nodes are evenly spaced along the perimeter, not bunched at corners.
Ring counts decrease from72 toward16 at the crown to avoid narrow slivers.
Triangulation connects adjacent rows exactly; no independently derived radii.

The shell cutter is the clock's **outer fixed bezel, radius8 m**, rather
than its inner eye. Glass, lattice and node patches terminate at that outer
rim. A bronze reveal/collar up to0.3 m deep closes the curved-shell to planar
bezel connection, with a recessed continuous gasket. No glass or white bars
remain behind the rotating annuli. The clock assembly occupies this opening;
its inner eye retains its own radius2.85 cutter and flat sill+47.7. These are
two different boundaries. The shell graph has six loops: base, crown and
four outer clock fittings. It is
connected, has no zero-length or duplicate edges, pane-edge valence<=2, and
Euler characteristic−4 before the separate glass cap is applied. Treat a
failed grid check as an authoring defect, not a reason to disable the check.

The cap continues the same meridian and uses the crown loop as its base,
with one apex vertex. No duplicated pole nodes, radiating frame needles or
buried lower half-shell. Keep the outer top+69.6 and existing bell bottom/top.
The actual crown tie is at `grid.crown_y` (about+69.476), not at the apex.

### 4.3 Member section and junctions

White-painted steel: visible face width0.07, radial section depth0.18,
superellipse cross-section exponent5.5. These are constant-section sweeps,
not long full SuperEgg bodies with rounded/pinched ends. A small6 mm weld
fillet can soften concave junctions. The section depth follows the shell's
outward normal; it must not roll arbitrarily from member to member.

At every node, derive a valence-dependent common patch from all incident
profiles. Trim the members at its shared planes and weld the vertices into a
closed continuous surface. No enlarged ball hubs, bead chains, overlapping
loose end caps or material tricks hiding gaps. Combining draw calls does not
weld a node. Use shared cut/profile tools; a planar infill or Boolean union
is justified at the welded node where separate rounded solids would crack.
The enlarged model detail is one unioned six-way patch, not six separate eggs.
Production must prove its actual welded mesh as well as its appearance.

Glass is12 mm nominal, seated0.035 m behind the frame reference surface,
with a recessed22 mm gasket. Panes and seals derive from the same grid
boundaries/cutters. Do not independently shrink triangles until they look
approximately fitted. Glass uses shared material conventions, actual
transparency and correct two-sided optical treatment; this does not excuse
reversed steel or floor faces. Show a grazing-light close-up from inside
and outside at real scale, not just a distant dome silhouette.

These are architectural game dimensions and detailing, not engineering
certification or an exact construction copy of the references.

## 5. Roof, Clock Room, clocks and bell

The structural roof and terrazzo floor must be coordinated as one authored
volume. The terrazzo is a finish, not a second nearly coplanar walkable slab.
Cut all four arrival wells and four lift shafts through every overlapping
roof/floor collision layer. Bridge/galleries use `kit.bridges` and `kit.ring_tongues`: curved shared
annulus cuts, not rectangles through the helix void. Use the128-step circular
boundary consistently. Ring guards open only at the real north/south Deck
walks and inner tower tongues; keep guards elsewhere.

Keep open space/headroom over the Meridian
platforms and all arrival flights. Do not retain the old full roof collider
behind visible well openings. Roof louvres/glass, planted rim and drainage
into trunks remain part of the same section.

Arrival pairs: use recorded foot/head/y, wells, widenings and runoffs. Rounded
well-corner treatment is0.1 m inside the recorded aperture bounds, leaving
full3.2 m flight width clear at discharge. Guards follow three sides and
open exactly where passengers step off. No handrail across a runoff.
The windows' eye sills stay well above ordinary public access: only climbing,
gliding or flight reaches them. Do not reinstate escalators up to an eye.

Each eye keeps its finished clear radius/chord after trim; place the bronze
sleeve outside the cutter. Add the0.6 m-deep flat sill from the same cut at
+47.7. It is a deliberate exposed flying/climbing entry, without a guard
across the opening. No ordinary route is funnelled onto that exposed sill.

Clocks: separate mechanical hour/minute rings and fixed bezels, proper
clearances,48 abstract ticks and distinct magenta arrow markers; no seconds bead
and no numerals. Preserve common centres and shared game-time orientation
on all four faces. Show that rings turn around the hollow eye and never
sweep a bar across it. The model's sample time is illustrative only.

Both markers use the midpoint rose-magenta `#cf4a6b` with restrained
emission. The hour marker has a short broad rectangular base, parallel sides
and a triangular point; the minute marker is a narrower simple triangle.
Use the exact two outlines in `kit.clock_markers`, including their radial
clearances. They must remain identifiable by silhouette without colour.
Do not recolour the bronze rings or bell magenta.

Bell: hollow flared bronze body, clapper, four0.24 ×0.45 m crown arms
and a real0.24 m hanger/yoke. The small crown tie is0.45 m deep with its
top at the grid crown, not a full drum ring/cage;
keep source bottom/top and safe separation from glass. The current silent
placeholder is not L4. Reuse a suitable existing sound or provide a deterministic
procedural bell tone; verify audible output and the actual game-time dawn,
noon and evening patterns from `dome.bell.rings`. No duplicate scheduler,
unintended hourly strikes or catch-up burst after stream reload. Keep all
faces and the bell on the same shared game clock.

## 6. Lifts and all public routes

Use `kit.lift_serving`, with four stops:0,14.2,37,41.6. This agrees with the
existing Clock Room plan and deliberately removes the prototype's unreachable
+6.5 calls. Helices continue to serve the Deck concourse. Do not leave a
button or interaction marker for an unserved level, or simply delete every
call to make the reach audit quiet.

Reuse the shared vertical lift with outer floor2.6 square, clear cabin2 by2.4.
Shaft opening2.8 square, lantern outer3.0 square, oriented with its front
toward the bell/centre. Round the opening corners0.1 m, derive car/guide/door
cuts in that same local frame, and keep the car clear throughout travel.
These explicit P7 fit dimensions supersede a circular-hole approximation
made from the old lift radius. Do not clip a square cabin through a circle.

At served levels, the apron is2.4 m wide, extending1.3 to3.8 m inward from
the lift centre. `toward` and `call` give the direction and physical call
position. Union it into the adjoining platform/floor or clip shared edges
so there is one floor owner. Open guards and gates at actual door planes.
A call must be reachable from that level without boarding the moving car
first. Retain safe car guards/gates while moving, accessible shared controls
and correct party/NME collision; no hero-only workaround.

Required actual-controller routes, **hero and Xiao Hou Zi**:

1. Lawn → all four tower ground entries → both helix hands → every gallery.
2. Concourse ring and cross-bridges → both Spine platforms and both Meridian
   platforms, then back via a different tower. Prove every way-out aperture.
3. All four arrival pairs and widenings → Clock Room floor → public circulation
   around wells/lanterns/bell → another arrival down.
4. Each lift, called and boarded at every served stop in both directions.
5. Representative shared climb/glide/flight → each clock-eye sill → inside
   and back out. Ordinary walking routes do not count as proof of flying access.

Do not substitute raycasts, scripted coordinate teleports or a mock controller
for movement proof. Show source bounds/settings and failures as well as passes.

## 7. Finish, props and landscaping

All72 part templates are in scope. Account for each, including the small
items, rather than treating the dome as the only scheduled kit. Follow
`kit.furniture` for the representative benches, Clock Room planters, public
desk, closed kiosk shells and fountain. `kit.interior_garden` is a park-ground plan, not four ornamental boxes.
About52.7 percent of the usable floor (693 m² of1,317 m², excluding openings)
is green: broad flush lawns with low planted borders. The remaining area is
a connected network of pale paved walks, arrival/lift aprons, seating pockets
and the central compass-rose meeting space. Use the checked polygon edges
and holes directly; do not scatter substitute planters across a bare hall.
Main cross walks are2.8 m wide, the garden loop2.2 m, lift approaches2.6 m.
All actual arrival wells and lift shafts stay open with their guards; paving
connects the discharge landings and cabin doors to the common path network.
Keep grass walkable over the existing physical floor. Bed foliage is decorative,
low and outside path clearances. Keep the existing floor datum and roof depth:
coordinate shallow0.18 m substrate, waterproofing, drainage and root barrier
within the existing roof/floor build-up, not floating above it or piercing it.
No deep-rooted trees in this shallow roof garden. Existing trees stay in their
specified deep planters. Show lawn, garden borders and paving as distinct
materials, with no printed signs, and supply the garden-plan camera view.

The tower green is **coral vine and bougainvillea**, rooted in gallery planters
and trained upward on the stainless support mesh. Add irregular branching
stems, small leaves, occasional muted flowers and pendant tips descending up
to1.4 m from planter rims. `kit.vines` records scale and spacing. Keep visible
gaps between stems/leaves so ribs and mesh remain legible. The source climber
bands retain the intended door/landing gaps. They are planting envelopes,
never solid green panels, hanging fabric, floating blobs or collidable walls.
Root every run in soil or connect it visibly to an established climbing stem.
Show a close-up of one planted gallery and its hanging tips in the diagnostic.

Complete ring beds, shared ghafs,
tower climbers, gallery planters, roof grasses, rain-garden edges and draining
trunks using the existing landscape data and shared NatureProps kit. No new
species or change to the surrounding park layout. Add the scheduled waste bins and restrained warm
fixtures beside the seating/service areas, outside circulation clearances.

Furniture standing surfaces are physical; leaf tips and recessed seals/rose
are explicitly decorative. Preserve2 m main paths and door/runoff clearances.
No picture sign may become a printed word or number. Kiosks are closed service
shells unless an existing service already operates there. No new NPC, dialogue,
mission or invented interaction is required to call the station dressed.

## 8. Binding parts and joins

The plan contains72 part templates and 19 joins. Every visible P7 component
has a shape, symbolic/numeric half-size, exponent where relevant and collision
class. The implementation diagnostic maps every ID to its builder, owner(s),
collision and evidence. Explicitly list blocked or incomplete components;
never count a generic massing proxy or an invisible collider as completion.

| Group | Part IDs |
|---|---|
| Primary structure | `foundation`, `trunk`, `rib`, `hoop`, `mesh_sleeve` |
| Helices and concourse | `helix_tread`, `helix_soffit`, `helix_handrail`, `helix_guard`, `gallery_floor`, `guard`, `way_out`, `spine_head_beam`, `high_head_beam`, `bridge_hanger`, `cross_bridge`, `ring_girder`, `ring_floor`, `ring_support` |
| Lifts and platforms | `lift_guide`, `lift_car`, `lift_landing`, `lift_door`, `call_control`, `lantern_glass`, `platform_floor`, `platform_edge`, `platform_canopy` |
| Roof and arrivals | `roof_structure`, `roof_louvre`, `roof_glass`, `roof_rim`, `gutter`, `clock_floor`, `arrival_widening`, `arrival_tread`, `arrival_soffit`, `arrival_handrail`, `well_guard`, `well_shoe` |
| Dome and clocks | `frame_member`, `frame_node`, `glass_pane`, `pane_seal`, `eye_sleeve`, `eye_sill`, `crown_tie`, `crown_cap`, `bell_hanger`, `bell`, `bell_clapper`, `clock_hour`, `clock_minute`, `clock_bezel`, `clock_arrow`, `clock_tick`, `rose` |
| Furniture and landscape | `bench_seat`, `bench_leg`, `planter`, `soil`, `tree_trunk`, `plant_canopy`, `lawn_surface`, `vine_stem`, `rain_basin`, `desk`, `kiosk_shell`, `kiosk_counter`, `fountain`, `waste_bin`, `light_fixture` |

| Join | Shared planes/geometry |
|---|---|
| `tower_bearing` (seated) | foundation0; spine10.4/12; high30.6/32.6; roof41 |
| `helix_chain` (chain) | every hand.profile angle/height transition |
| `gallery_exit` (meet) | recorded way_out bearing and y |
| `guard_chain` (chain) | explicit route apertures and landing edges |
| `bridge_bearing` (seated) | Deck+6.5; hangers into spine beams |
| `ring_bearing` (seated) | ring top6.5, underside4.9 |
| `lift_landing` (punched) | only stops0/14.2/37/41.6 |
| `platform_join` (meet) | Spine14.2, Meridian37, existing boarding edges |
| `roof_bearing` (seated) | underside41; roof/Clock Room top41.6 |
| `arrival_well` (punched) | existing arrivals.well and y37 to41.6 |
| `grid_node` (chain) | shared node IDs and incident edge tangent/section frames |
| `glass_seat` (seated) | same pane boundaries, inset under frame seats |
| `eye_cut` (punched) | shell cut at outer bezel r8; clock eye r2.85 clipped below sill47.7 |
| `crown_join` (chain) | last nonzero ring radius3 and cap top69.6 |
| `bell_bearing` (seated) | existing bell bottom/top and crown ring |
| `clock_turn` (placed) | four cardinal clock planes, centre50.1 |
| `furniture_bearing` (seated) | actual floor/terrain top |
| `vine_training` (chain) | tower mesh and gallery planter rims; stems rooted in soil, clear access gaps |
| `kiosk_opening` (punched) | rounded shop opening over counter |

Symbolic dimensions: supportW/D = surveyed support base; run/L/span = actual
cut-to-cut path or bearing distance; paneW/H/D = shared pane extents;
landingW/D = the served apron; lanternW = oriented lantern side; floorW/D
= the recorded roof/floor span; W/H/D = the actual fixture/owner dimensions;
node_extent = the union of incident section footprints; sharedR/H and R/H
on plants come from NatureProps. Clipped structural sections use exponent5.5,
soft furniture3, round natural/bell profiles2 as explicitly recorded. Curved
centrelines remain curved; the exponent defines the member section.

Use the game's shared SuperEgg/OpeningTrim/SolidModel builders and exact-axis
handling. Every clipped member has shared end/bearing planes. Floors/closed
infill use boxes only with the recorded flush-join reason; Boolean node
patches and punched walls are deliberate exceptions. No tapering sphere poles,
underside bowls or unclosed surface edges.

## 9. Focused construction checks for the current combined pass

Run relevant required checks, plan validation and a genuine current bake.
Walk the intended ground/ring/platform/Clock Room route, representative lift
stops and arrival wells with real controllers; check the hero and a small rig
at representative clearances. Show the actual frame junction, outer bezel and
open eye up close in Godot, including a useful reverse/inside view. Verify
clock time and bell audio. All substantial geometry needs sensible collision;
all advertised public openings must be open in the actual contact geometry.

Observe meaningful performance/activation regressions and report them. Full
P0 before/after matrices, exhaustive part ledgers and per-view33.3ms/unload
certification are not blockers for this practical construction milestone.
Unverified final L4 remains explicit P2/P16/local follow-up work. No removal
of collision or fake pass through coordinate teleports to improve a report.

## 10. One combined report

Follow `moy_p7_p8_p9_build_handoff.md`: one concise P7/P8/P9 diagnostic with the
starting implementation checkpoint, major coverage, actual functional checks,
ordinary-resolution useful images and explicit remaining issues. Include dome
close-up, Clock Room garden and station-to-park transition evidence. No
spreadsheet certificate or every-surface route matrix. The model is design
reference, not runtime proof. Mark practical built/dressed separately from L4.

## 11. Handoff and decisions

- 2026-10-20: user picked P7 and called out the dome's segmented framing,
  naming the Great Court, Cloud Forest and Flower Dome as references.
- User explicitly required the SuperEgg schedule for everything in P7.
  Bound 72 parts/19 joins and a checked shared grid, plus node/section views.
- Stop list follows the existing Clock Room plan; unserved Deck calls are
  removed. No alteration to streets, tracks or station arrangement.
- Local model and reference images are checked in; external artifact
  publication remains pending because this chat has no publisher.

Build prompt: In the existing P5/P6 implementation checkout, follow
`moy_p7_p8_p9_build_handoff.md`: preserve inherited work, integrate the latest
planning source, build P7 first then P8/P9, run focused checks and report.

- 2026-10-22 revision: outer-bezel glazing fit, distinct magenta marker
  silhouettes and four planned interior garden beds requested by the user.

- 2026-10-22 garden revision: midpoint rose-magenta marker #cf4a6b; majority-green
  interior grounds and explicit rooted/trailing vine construction. Schedule72/19.

Current integrated planning verification: `docs/diagnostics/2026-10-22-moy-P7-P8-P9-handoff-planning.md`.
