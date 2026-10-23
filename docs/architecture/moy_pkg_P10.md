# P10 — the Moy trains and rail service

Design brief, 2026-10-23. **Ready for the next design/build pass after P7–P9.**
Target: practical L3 working rail service; final L4 acceptance with the city.
Do not interpret the historical L4 target as a precision-certification project.

## 1. Area, dependencies and read first

All three services, their rolling stock, boarding interfaces, station finishing
outside P7's complete Crossing, and the Line House. Preserve the locked track
axes, level rails, station sites, buildings and street network.

Read AGENTS.md, CLAUDE.md, moy_build_roadmap.md and
`moy_p7_p8_p9_build_handoff.md` before this brief. Use the **existing implementation
checkout**, with its locally built P3–P6 and subsequent P7–P9 source/bake. Main
is a planning base, not a replacement for that working tree. Save a recovery
checkpoint before merging authoring data. Preserve the actual source and bake
provenance; generate a fresh integrated bake when runtime changes are ready.

Read these targeted sources:

- `city.md` §§6c,6e,6f,6g; the corrections in this brief supersede older passages.
- `tools/city_layout.py`: TRAIN, TRAIN.kit, PLATFORMS, CROSS, WALL.shed,
  TIMETABLE, station access/core definitions. Never hand-edit CityPlan.
- `scripts/moy_ride_train.gd`; train/station/wall construction in
  `scripts/moy_city_bake_builder.gd`; streaming in `scripts/city_generator.gd`.
- P7 brief for station ownership, lifts, platforms, canopy and dome clearances.
- `docs/drawings/moy_train_3d.html`: all/car/boarding/interior/house/network
  views. Single-file planning preview; external hosting pending.

## 2. Character and appearance

One short, friendly tram family; cream glazed ceramic panels over aluminium,
smoky blue-grey panoramic glazing, dark bogies, restrained metal fittings.
Lisbon tram proportions are the size reference; Singapore rail infrastructure
supplies the shaded, planted station vocabulary. These are modern electric
cars, without overhead wires, historic tram ornament or drivers' cabs.

Use the existing muted runtime line colours: Wall ochre `#b7833d`, Spine teal
`#438c8a`, Meridian violet `#79588d`. Cream `#e4d4b4`, glass `#78959e`, metal
`#79858a`. The narrow line band follows the shell and continues on closed
leaves. No full-colour car bodies, printed words, letters or numbers.

For colour-independent recognition repeat an unlettered circle, longitudinal
bar or diamond for Wall/Spine/Meridian respectively, beside station entrances
and on car ends. Keep them small, embossed/inlaid motifs; no new HUD or board.
The Watch train is an ordinary ochre Wall consist with warm lights, not an
armoured train, a new character or a new service colour.

## 3. Binding geometry and SuperEgg schedule

`TRAIN.kit.parts` and `.joins` are the P10 construction schedule (33 part
families,13 joins). They supplement and supersede the older six-part solid
silhouette recipe in TRAIN.parts. The old recipe is retained for compatibility,
not as permission to fill the cabin with a body/glazing/livery egg.

Car coordinates: x along, y above rail, z across. Half-sizes in metres.

- Envelope9.6×2.65×3.6; car pitch10.4,0.8m coupling interval.
- Constant-section hollow central shell, rounded end shoulders with flat
  panoramic end panes. Cross-section n5.5, soft end shoulders n3.4; .08 skin.
  This deliberate refinement gives the aisle its clear ceiling instead of
  squeezing a rectangular cabin inside the older highly curved solid egg.
- Floor top rail+1.0; nominal inside width2.4. Usable full-width length8.6;
  end shoulders may taper beyond it. Ceiling at least2.3 above floor across
  the central1.5m standing aisle. Low side shoulders are over seats, never
  counted as standing headroom. Derive inner/outer sections together.
- Four doorways per car, x±2.4 both sides: clear1.4×2.1, flat sill at1.0.
  This retains the specifically approved train doorway rather than importing
  the larger general building-door standard. Rounded corners must not reduce
  the clear1.4m opening at body height. No threshold lip.
- Each opening has two .7m leaves sliding .72 each along x into shallow
  exterior pockets. Nominal body half-width1.325, pocket envelope≤1.35;
  platform edge1.4 leaves .075m from body, at least .05 from pockets.
  Resolve pane/frame tolerances within this envelope, never widen the car.
- Two short longitudinal seats between the doors, with side-fixed backs,
  leaving1.7m aisle and four unobstructed doorway standing bays. No seat,
  pole or equipment blocks a door. Warm ceiling strip; two grab rails.
- Two bogies, roof battery on four mounts, end lamps only at exposed consist
  ends. Front lamps warm white, trailing red; swap roles on reversal.
- Dark folded articulation sleeve and structural coupler share the real car
  transforms. Ends are sealed panoramic windows: **no walk-through gangway**
  in this pass. No invisible passage or walkable bellows collider.

Production surfaces are actual smooth swept/profile or clipped SuperEgg
construction, with matched cut planes. No stretched tip-to-tip beams, capsules
chained into trim, opaque glass boxes or a closed collision box over the cabin.
The HTML is a sectioned surface preview, not a runtime solid/collision export.
It omits production wall thickness, fittings and support details in places;
use the complete schedule for those. Technical labels stay outside game art.

## 4. Boarding, motion and stopping

Wall:3 cars,30.4m on40m platforms. Spine and Meridian:2 cars,20m on30m platforms.
Car-floor and platform tops:14.2 at Wall/Spine,37 at Meridian. Rail heads13.2
and36. No .4m added car offset. Set **consist midpoint** on the station stop
reference so all doors fit within the platform; do not put the leading car
centre there. Use each track's real platform-side geometry.

Finish one car and one boarding stop first, then the fleet. Doors open only
when stopped at a served platform and only on its platform side. Opening and
closing animation sit inside the existing dwell; do not silently shorten the
usable open interval to nearly zero. A short arrival chime and leaf motion
are enough. No mechanic-explaining messages, tickets or interaction menu.

Walking into the cabin is boarding; walking out is alighting. Keep the existing
shared moving-platform machinery, with interior floor and roof rideability.
No train-specific teleport boarding, snap to seat, new traversal power or
character-only ride controller. Party/NME collision uses the same substantial
surfaces. Check the hero plus a second playable rig, with body-relative sizes
left to the shared controllers. Large forms need not fit a1.4m train door.

Closed doors block; open doors have matching voids. Obstruction reopens/holds
leaves and delays departure. Do not close through a body, crush, damage or
lock a passenger into a disappearing vehicle. Non-platform side stays shut.
Allow departure delay to persist rather than resetting the timetable phase
and teleporting the consist forward. Rejoin cadence at a suitable later stop.

### Physical route ownership and turnback

Every car follows the actual rail route independently. Keep car identities and
positions continuous when reversing: reverse velocity/leading-end role, not
the sign of the car-index offset in a way that swaps cars instantly.

The current `mini(train_index,1)` lane assignment is not an operating plan:
it puts multiple timed shuttles on the same fixed lane, including opposing
trips. Build directional running and **local terminal crossovers** inside the
existing double-track guideway, cityward of the terminal stopping area. Reserve
the crossover and berth before an arriving train enters, then reverse at the
platform to leave on the correct track. No lateral jump between tracks and no
invented link between Spine and Wall. Reuse an appropriate simple block/reserve
mechanism; no new general railway simulation framework.

The exact crossover paths must be authored and checked in CityPlan during
implementation against the actual integrated guideway/supports. Keep them
outside boarding edges and within existing railway envelopes; no platform or
street move. Extend schedule path distances for these small turnouts and use
terminal slack to preserve hourly departures and the Crossing pulse where
feasible. If the locked envelope cannot accommodate safe turnback, report the
specific collision/fit and a small plan amendment instead of certifying a
teleport or allowing head-on overlap. Model network view is the locked route
study, not fabricated turnout geometry.

Moving cars must stay alive while ridden even if their original bake cell
unloads; attach lifetime to current route/player relevance, using existing
streaming machinery. Sample/render once per physics step consistently. No
recreated duplicate consist on cell reload; no disappearing cabin floor.

## 5. Timetable and night service

Use WorldState's game clock, including pause/save/load and clock wrap. The
plan's units are game minutes = real seconds at normal speed; do not assume
wall-clock elapsed seconds when the game is paused or accelerated.

Current nominal plan (derive values from TIMETABLE, don't duplicate constants):

| Service | Day sets | Cars | Circuit | Nominal speed |
|---|---:|---:|---:|---:|
| Spine |3|2|180s|9m/s|
| Meridian |3|2|180s|9m/s|
| Wall inner |3|3|180s|10m/s|
| Wall outer |3|3|180s|10m/s|

Departures every60 real seconds / one game hour,05:00–24:00. Ordinary dwell8s,
interchange12s. Existing terminal turnarounds approximately21.11s Spine and
31.33s Meridian absorb schedule slack. Wall East Gate dwell carries .37s
rounding/slack. Keep derived offsets/pulse rather than hand-adjusting visuals.

From00:00–05:00, **one Wall set each direction**, on the same180s circuit,
so night headway is180s / three game hours. Retain that set's phase at the
transition; do not respace all cars by teleport. No overnight cross-line
passenger departures. Finish in-progress passenger runs to an appropriate
terminal/station; keep a car with an occupant present until safe alighting
or the next service window. This is an orderly drain, not an instant fleet
count toggle. Dawn introduces extra sets at station/route entry states with
clear blocks, without intersecting the Watch train or materializing around
players. Report any delayed service honestly.

**Storage correction:** the lines are physically disconnected. Older text
that sent every shuttle into the wall's shed is withdrawn. P10 uses logical
out-of-service fleet state and terminal layovers for the shuttles; it does
not promise a fully modelled all-fleet yard or invent connecting railway.
Non-Watch Wall sets leave service only through safe unoccupied station/stream
transitions, never pop out in view. If visible physical withdrawal cannot be
staged safely, hold that set out of the circulating timetable in a protected
existing layover and report the limitation; never obstruct the Watch route.
Do not add depot tracks outside the locked footprint to hide this problem.

## 6. Station finish and Line House

At every stop retain the real3m platform, flush floor and1.5m clear boarding
strip. Shade underside3.2m above platform where a building/roof does not already
shade it; slim rear posts every6m, no post between door and platform. One simple
bench per12m of rear edge where clear of access. Rear/end1.1m guards open at
real routes; never put a continuous guard across boarding faces. Unlettered
line motif at entrances, restrained warm lighting, planted edges outside
route and train envelopes. Use actual rooted greenery, no floating green bars.

Check ordinary station access, both gate interchanges and both Meridian ends.
Finish their existing landing/platform interfaces; do not redesign City Hall,
West Gate or the wall. P11 owns those architectural shells; P12 owns broader
street/Deck dressing. P7 alone owns the complete Crossing, including towers,
helix, dome, Clock Room, lifts and platforms: P10 may fit door/boarding details,
not substitute a new station or reinstate obsolete6.5m lift calls.

Line House: existing WALL.shed site232°,60m along×16m outward, outside the
wall. The model uses its real circular-wall coordinates, x tangential,
z outward. Workshop at street datum; retained private Watch guardroom beside
it. Upper maintenance deck14.2, maintenance rail13.2, roof top18.82,6m frame
bays. One illustrative maintenance bay with44m track; not operational entry
track or all-fleet storage. Simple ceramic/aluminium shed; no fake ramped
railway or high-line track secretly entering at wall height.

Protected service door into workshop, benches against rear wall; guardroom
remains private and can be closed. A1.8m internal switchback maintenance ramp
and generous landings join the upper shed; four3.25m rises plus1.2m final rise,
32°, fitted in the west service core. Cut a real guarded floor void through
the upper deck and keep roof bearings/frames out of it. No public through-route
or invented staff/NPC census. Support the upper deck on the lower load-bearing
shell and crossbeams, never leave the whole slab floating on furniture.

## 7. Known baseline defects to replace

Published planner runtime is evidence of starting debt, not a required template:

- Solid whole-body egg plus opaque box window/livery meshes fill the cabin.
- Shell/glazing are lifted .4m; colliders span3.6m across despite2.65m car width,
  floor collider top1.2 rather than1.0, doors sit atz±1.64 outside the plan.
- Door leaves are static visual boxes without working leaf collision/state.
- Scheduled motion returns before service-hour and door state updates.
- Fixed lane assignment and direction-dependent car offsets need turnback work.
- Runtime does not apply the planned night fleet/service window.
- Trains are owned by their initial bake cell, with no demonstrated rider pin.

Verify which remain in the local implementation checkout before changing it.
Do not overwrite unrelated built city packages with this planner's bake.

## 8. Focused acceptance and report

Use existing village collision/build patterns and practical Ohio/Snowhio detail.
No all-powers reachability matrix, manufacturing spreadsheet, repeated cinematic
batch, new rail framework, P2 optimisation or movement retuning project.

1. Validate plan/schedule and required repository checks; genuine integrated
   bake and freshness check after runtime changes, city validator as applicable.
2. Measured proof at one ordinary stop and the Crossing high platform: floor
   matches platform, real doorway void, all doors inside platform ends, both
   side states, obstructed-close hold, no cabin blocker or full-box collision.
3. Ride inside and on roof through a Wall curve; one end-to-end shuttle with
   continuous reversal/coupling and reserved crossover. Check the actual fleet
   over a full cycle for head-on/berth/coupler overlap, not just one train.
4. One transfer at North/South Gate and one at Crossing; one ordinary street
   access route; inspect the other terminal/route class for blocked doors.
5. Check23:59→00:00,04:59→05:00 and save/load at day/night and in a ridden car.
   Test an obstructing/remaining passenger. State actual transition exceptions.
6. Cross a streaming boundary while aboard, leave/return, confirm no duplicate
   consist and persistent collision. Check hero plus one other playable rig.
7. Render normal gameplay-resolution fleet/boarding, cabin, Wall curve,
   Crossing stop, Line House and Watch-night views. Inspect them, don't merely
   generate image files. Parts schedule guides appearance, not exhaustive proof.

Write `docs/diagnostics/<date>-moy-P10.md`: exact implementation baseline and
preserved earlier packages; source/bake freshness; key geometry measurements;
service/lane/door/streaming results; screenshots; remaining material defects
versus minor polish. Stop for review before P11. Do not call planning checks
or this preview a runtime acceptance pass.

## Decisions

- 2026-10-23: user requested P10 design brief after the P7–P9 handoff.
- Retain one car family, cream/material palette, muted existing three liveries,
  short consists, locked tracks/stops and game-clock service.
- Explicit full SuperEgg parts/joins schedule; hollow shell/boarding refinement,
  distinct unlettered line motifs, practical staged build scope.
- Correct impossible shared-depot story: disconnected shuttles lay over on
  their own routes; Line House remains maintenance, not all-fleet storage.
- Night circuit retains physical Watch-set phase; safe occupancy/lifetime
  overrides abrupt fleet toggles. Turnout fit is an explicit early build task,
  not an unseen claim that the schematic network is operational railway.
