# P9 — The giant playground, built together with P8

2026-10-22. **Ready: park stage of the sequential P7–P9 handoff.**

- Area: the existing southeast playground centred world(-515,31), inside
  its pump-track outer radius15.4 m. Preserve the locked park/station plan.
- Companion/primary grounds brief: `moy_pkg_P8.md`. One implementation owner,
  shared `moy_park_playground_3d.html`, one integrated final bake/diagnostic.
- Goal: recognizable, playful and usable park equipment at practical village
  sophistication, L2/L3 first milestone. Long-term final L4 remains tracked.
- Source: `CityPlan.PARK.playground.kit`,30 part templates/12 joins, original
  source tower positions/radii/heights and perches. Schedule is design guidance,
  not a30-row certification exercise. No new movement/physics framework.

## Read first and design language

Read AGENTS.md, CLAUDE.md, roadmap current direction, P8 and the combined handoff.
Read city.md7b, `tools/moy_park_kit.py`, original PARK playground data,
CollisionPolicy, shared SuperEgg/profile/opening builders, current shared
traversal/power components and `_add_park`. Do not read historical district
repair audits or widen the task to the station, trains or the whole city.

The playground is one canyon-and-dune landscape with attached play routes,
not unrelated stock equipment. Pale ochre and terracotta tower shells carry
muted teal nets, rose slide surfaces and pale soft ground. It should read as
one recognizable object from the park: four differing heights, spiralling
slides and a net between them. Use natural soft shapes without needle tips.
Monstrum's sculpted landscapes and Hakone's knitted nets guide composition;
Toa Payoh's dragon is a lesson in one strong identity, not a dragon to copy.

No printed text, numerals, route arrows explaining a mechanic or completion
messages. Existing Lily/Kofi/Jammer associations stay; no new residents or
quests. No steel wind-tree structures: the approved real shade trees and
existing P7/high-line structure provide the wider swing context.

## Locked scale and whole-site layout

The approved horizontal size is0.55 of the original56 m design, **while tower
heights remain unscaled**. Do not halve the heights or enlarge the track to
fit old unscaled drawings. World positions/radii are in `kit.towers`:

| Tower | Centre x,z | Top | Radius |
|---|---|---:|---:|
| Lookout | -515,31 |20 |3.08 |
| East satellite | -508.4,27.15 |16 |2.53 |
| West satellite | -522.7,28.8 |14 |2.36 |
| South satellite | -515,38.7 |12 |2.25 |

Pump track inner13.2, outer15.4, clear width2.2. The P8 lawn-side approach
meets it at the west side on a deliberate **level tabletop crossing**. Taper
rollers/bank away from this crossing, keep sightlines open and avoid a kerb,
fence, slide exit or dense planting across the entrance. It is a shared play
space, not a new race/timing system. Parent benches sit outside the track under
the existing ghafs. Protect the P8 lodge/lawn and all park paths.

## Tower structure and ordinary public play route

Replace the four solid tall proxy boxes. Six square-round structural ribs,
bearing bands and sculpted canyon panels support physical9 m bridge decks
and top landings. Keep obvious base openings and clear apertures at each
bridge/slide entry; no invisible full-tower box collider. Make the vertical
faces warm, substantial canyon forms rather than a sparse bundle of poles.

The Lookout has a continuous ramp to the9 m common bridge level: inner radius1,
outer2.75, width1.75, pitch3.3 m per turn. Its steepest inner grade is27.71°.
Maintain at least2 m real headroom, stable walkable collision and guards along
exposed edges. Give the ramp actual clear ground/upper landings. Use one swept
profile with flat matching cuts, not a string of stretched eggs. Punched tower
skin/decks/guards share these route openings.

Three1.6 m wide rope bridges join the Lookout edge to each satellite edge at9 m;
use recorded end points. Their boards/contact surface, supporting ropes,
guards and deck openings meet. Do not bridge centre-to-centre through solid
skins or run a guard across a bridge mouth. All high decks have sensible
edge guards except deliberate open challenge/slide mouths with visible landings.

Upper tops,1.2 m-rise jump leaves,12 m bounce perches and aerial hoops are
optional platforming destinations, not ordinary public promenades. The ordinary
park/court and9 m ramp/bridge route must work. Do not promise every body can
jump the same world-space gap or certify universal access to every surface.
Use existing shared movement; never add a hero-only climbing power or silently
teleport actors to make a route appear proved. If a net-climbing behaviour is
not supported, provide the ordinary route with actual geometry, not a fake
ladder tag or a new framework. Any extra upper-route limitation is reported.

## Nets, slides, dunes, bounce court and splash

The great net is anchored at actual satellite ribs around8 m, sagging toward
6 m, with visible edge ropes, knitted cross strands and a matching standable
contact surface. `kit.net.patches` cuts its plan around all four tower envelopes.
Use these same cuts in strands and collider; anchor trimmed boundaries to real
structure. It must look like open netting and support the feet where it looks
standable. Fine strands are decorative; one simplified net surface supplies
physics. Never fill the vertical gaps with invisible walls or leave an opaque
sheet pretending to be a net. Minor motion is optional, not a new cloth solver.

The16 m satellite has an open-ended hollow tube slide; the Lookout has an open
spiral trough; the wave trough ends on the west dunes. Use `kit.slides` as
coordinated path/composition references. Sweep one continuous section along
each curve, with visible thickness, smooth normals and real supports. The tube
has an open centre and mouths; the trough has a floor and raised sides. Do not
cap a mouth or approximate collision as a solid enclosing cylinder.

Local slide phase, bracket positions, net edges and guard cutouts may be
adjusted inside the existing play envelope to remove clashes and establish
usable entries/run-outs. Preserve tower sites/heights and the overall design.
Do not copy a browser sampling seam or a planning overlap into runtime. In
particular, verify the9 m bridge crossings, net/slide clearance, ramp headroom,
tower-deck apertures and all mouths. Route supports to ribs; long wave-slide
supports reach actual ground. No forest of arbitrary tall support pillars.

Provide smooth, simplified matching collision on slide floors and exits.
Retain ordinary shared controller motion on their slopes; no bespoke automatic
ride/camera script or promised speed boost. The user explicitly excluded both
Snow sandboarding on the dunes and Penguin belly-slide support on these slides.
No new mechanic makes them work. Test one actual descent and report limitations.

Three soft sand mounds, a south rubber bounce court and three12 m perches
follow source locations. Trim dunes around tower feet and the entry where
needed, keeping physical sand/soft-ground surfaces on the terrain. Existing
blorb bounce/super-jump may serve the high perches without movement retuning.
The bounce court does not launch a person automatically as a new mechanic.

The east splash pad has a physical drained floor and low intermittent jets.
Keep its closed recirculation separate from the swimming pond and reclaimed-
water polishing bed. Jets/spray are decorative, not solid rods or a new hazard;
use existing particles/water helpers. An underground drain is not an open
trench across a route. No opulent fountain, new water shader or reward UI.

## Hoops, powers and collision

Eight hoops retain **3 m clear diameter**, with solid0.10 m rims, open centres,
recorded3D heights/bearings and cables to the playground's own real tower ribs.
No mid-air suspended ring with no cable endpoint. Their centres are for
existing flight/crystal-ribbon/hover play. They do not need scoring, triggers,
UI or an exhaustive all-eight route proof this pass. Towers may anchor the
existing vine swing; the P7 southeast tower and east high-line pier remain
unchanged wider anchors. Do not rebuild them or invent steel wind-tree decks.

Every substantial deck, ramp, panel, slide, support, perch, boulder and hoop
rim is physical under CollisionPolicy; intentional landing tops use parkour
policy. Fine ropes, leaves, spray and surface trim may be explicitly decorative.
Ropes carrying an advertised walkable/standable net are accompanied by the
shared surface collider. Match visual voids and guard openings. Segment
contacts are simplified sensibly, not thousands of individual collider beads.

Use the existing shared world-sized features for all playable characters.
Run representative ordinary route checks for hero and Xiao Hou Zi. Optional
power features reuse shared tags/modes and body adapters; do not modify powers
or prove every decorative platform from every character this pass.

## Shape schedule and practical validation

The full30/12 source tables follow. Epsilon5.5 for structural members,3 for
soft forms,2 for circular/round profiles; no exponent below2. Use SuperEggs for
freestanding pieces and constant-section cut/meet sweeps at real joints. Flat
continuous surface infill and the terrain/contact mesh have documented reasons.
The model's natural foliage and net/slide sampling are preview approximations.

Build in the combined sequence from P8: ground/entry first, shared tower/ramp/
bridge forms, nets/slides/perches/hoops, then dress and integrate. Use quick local
previews and existing systems. Do not run a full-city capture/audit after every
part, add a new traversal/geometry framework, or turn this into P2 optimization.

Required checks: repository quick checks, scoped city validator, current bake.
Focused actual-game walkthrough: park entry/tabletop, one track circuit, court,
Lookout ramp to9 m and one bridge, representative net footing, one slide descent,
one optional high route using an existing power. Repeat representative ordinary
widths/contact with Xiao Hou Zi. State failures or unavailable mechanics plainly.

Ordinary-resolution views: integrated P8/P9 aerial, playground eye approach,
bridge/net bearing close-up, track entry and one slide/hoop silhouette. Use one
combined concise P8/P9 diagnostic with major-group coverage and genuine remaining
issues. No30-row manufacturing report, full route matrix or cinematic capture
batch. Minor decorative polish does not hold up the playable milestone; major
geometry, collision, access or visual defects do.

## Handoff

One chat implements both P8 and P9 from `moy_p7_p8_p9_build_handoff.md`. Do not
parallel-edit their shared files or stop after building only four tower proxies.
No new lore introduced; this develops the existing approved playground program.

Planning evidence: `docs/diagnostics/2026-10-22-moy-P8-P9-planning.md`.

## Source parts reference

Half-sizes in metres; symbolic sizes resolve from the named owner/path.
Shapes use the listed exponents; no cap or rounding may close an opening.

| ID | Shape and half-sizes | Exponent | Collision | Use |
|---|---|---|---|---|
| `play_ground` | profile · 13.2 × 0.08 × 13.2 | 5.5 | landing | playground continuous soft ground inside pump track |
| `track` | profile · 15.4 × 0.18 × 15.4 | 2.0 | landing | closed packed-earth annulus with rollers and banked turns |
| `track_edge` | egg · L/2 × 0.2 × 0.35 | [3.0, 3.0] | solid | flush rounded berms, no fence across tabletop entry |
| `dune` | egg · rx × ry × rz | [3.0, 3.0] | solid | three soft SuperEgg sand mounds west of Lookout |
| `bounce_floor` | profile · 3.6 × 0.05 × 2.4 | 5.5 | landing | recessed soft court south of towers |
| `splash_floor` | profile · 2.1 × 0.05 × 3.1 | 5.5 | landing | flat drained splash pad east, physical dry floor |
| `splash_jet` | profile · 0.035 × H/2 × 0.035 | 5.5 | decorative | short intermittent jets, separate decorative water |
| `splash_drain` | profile · 0.14 × 0.025 × 1.2 | 5.5 | decorative | flush grating and closed recirculating sump |
| `tower_foot` | clipped · 0.24 × 0.24 × 0.24 | [5.5, 5.5] | solid | embedded six-foot tower bearings |
| `tower_post` | clipped · 0.16 × H/2 × 0.16 | [5.5, 5.5] | solid | six rounded-square ochre structural ribs per tower |
| `tower_band` | profile · r × 0.14 × r | 5.5 | solid | bearing hoops tying tower ribs at each landing |
| `tower_skin` | punched · panelW/2 × H/2 × 0.12 | 5.5 | solid | sculpted canyon panels, cut at bridge and slide exits |
| `tower_deck` | profile · r × 0.12 × r | 5.5 | landing | top lookout and bridge decks, radius by source tower |
| `tower_guard` | profile · L/2 × 0.55 × 0.07 | 5.5 | solid | guard field with deliberate route/slide openings |
| `lookout_ramp` | profile · outerR × 0.1 × outerR | 5.5 | landing | continuous annular ramp to9m shared bridge level |
| `ramp_rail` | profile · 0.045 × 0.045 × L/2 | 5.5 | solid | continuous rounded handrail along actual ramp edges |
| `jump_leaf` | clipped · 0.9 × 0.12 × 0.65 | [5.5, 5.5] | landing | Lookout optional spiral landing platforms at1.2m rises |
| `bridge_deck` | profile · 0.8 × 0.12 × L/2 | 5.5 | landing | three rope-bridge surfaces at9m,1.6m wide |
| `bridge_rope` | profile · 0.035 × 0.035 × L/2 | 2.0 | solid | sagging support and guard ropes anchored at ribs |
| `net_edge` | profile · 0.045 × 0.045 × L/2 | 2.0 | solid | catenary net support ropes, no loose floating corners |
| `net_strand` | profile · 0.025 × 0.025 × L/2 | 2.0 | decorative | visible knitted-net lattice, close shared cell pattern |
| `net_surface` | profile · W/2 × 0.025 × D/2 | 5.5 | landing | matching standable open-net surface, simplified triangulated collider |
| `slide_shell` | profile · profileW/2 × 0.06 × L/2 | 2.0 | solid | open spiral and wave troughs, tube shell with true hollow centre |
| `slide_support` | clipped · 0.1 × H/2 × 0.1 | [5.5, 5.5] | solid | real slide brackets/posts to tower ribs or ground |
| `slide_exit` | profile · 0.75 × 0.07 × 1.2 | 5.5 | landing | flush run-out onto soft ground, no closed cap at mouth |
| `perch_post` | clipped · 0.18 × 6 × 0.18 | [5.5, 5.5] | solid | three narrow12m perch stems rooted in bounce court |
| `perch_deck` | egg · 0.65 × 0.14 × 0.65 | [3.0, 3.0] | landing | three high bounce perches |
| `hoop_rim` | profile · 1.5 × 1.5 × 0.05 | 2.0 | solid | eight open3m-diameter hoops, wall thickness0.10 |
| `hoop_cable` | profile · 0.02 × 0.02 × L/2 | 2.0 | decorative | suspension cables tied to playground towers only |
| `anchor` | egg · 0.12 × 0.12 × 0.12 | [3.0, 3.0] | solid | visible existing-power swing attachment at real structure |

## Source join reference

| ID | Kind | Shared plane / cut | Construction |
|---|---|---|---|
| `track_ground` | meet | outer15.4 inner13.2; no vertical kerb | closed smooth surface and simplified contact mesh; planned level tabletop entry west |
| `court` | meet | ground top0.08 | flush impact surfaces, no loose boards or hazard cap |
| `tower_bearing` | seated | foot top0, deck9 and source top12/14/16/20 | continuous load path and cut openings; no solid proxy tower collider |
| `ramp_chain` | chain | inner1.0 outer2.75; pitch3.3; ground to9 | same swept profile and end cuts; real2m headroom and connected landings |
| `jump_chain` | seated | source jump spiral,1.2m rises | optional skill route, no stairs or claim of universal reachability |
| `bridge_seat` | meet | three tower-to-Lookout routes at9m | cut correct guard openings; bridge joins deck edge, not tower centre through solid skin |
| `net_anchor` | chain | three satellite anchor points at8m; centre sag to6m | all strands and contact mesh share one catenary surface; visible support corners |
| `slide_cut` | punched | top entry and open exit atground | true hollow tube and open trough; trim intersecting bridge/guard geometry |
| `slide_bearing` | seated | source path brackets at2.5m intervals | no floating slide; supported at real ribs or embedded ground posts |
| `perch_bearing` | seated | perch tops12m | same shared bearing plane, no overlapping rounded caps |
| `hoop_hang` | seated | eight3D centres, source cable anchors | solid rims, open centres; cables end at visible structure, not sky |
| `swing_anchor` | seated | real Lookout and unchanged P7/high-line structures | reuse shared swing tags; no movement retuning or new power framework |

Current integrated planning verification: `docs/diagnostics/2026-10-22-moy-P7-P8-P9-handoff-planning.md`.
