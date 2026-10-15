# Fire Caldera City: Civic Layout Plan

Status: approved (2026-10-06). This plan turns the approved city
systems into one coherent surface and submerged layout. It fixes relationships,
route hierarchy, approximate footprints, and implementation constraints. Exact
building architecture follows only after this civic plan is approved.

**Public-realm revision built (2026-10-09).** The reservoir is now a nested
central lava bowl within a shallower inhabited volcanic bowl. Outer circulation
is an independently supported **Caldera Highline**, not terrain grading. The
Civic architecture redesign remains deferred until its Highline dock is
settled.

Read with `fire_caldera_city.md`. That document owns the community, census,
physiology, cultural practices, architectural charter, and individual building
programs. This document owns where those programs meet the caldera.

## 1. Survey frame

The current terrain supplies these fixed facts:

- kingdom gate center: `Vector2(0, -3)`;
- caldera and proposed reservoir center: `Vector2(155, 85)`;
- inhabited bowl radius: approximately 108 m before the coarse wall seam;
- village safe-zone radius: 120 m, protecting the settlement through the true
  crater lip;
- crater rim radius: 112 m and outer volcanic mass radius: 205 m;
- inhabited-bowl vertex elevation: 30 m, following a parabola to the 48 m
  crater lip;
- terrain sampling: approximately 15 m inside the kingdom's current 121-sample
  mesh, too coarse for the final reservoir bank and settlement terraces.

The localized caldera mesh establishes two explicit paraboloids. The inhabited
bowl is `y = 30 + 18(r/112)^2`; inside the organic reservoir outline, a second
parabola meets that surface at the bank and falls to the central lava bed.
There is no flat settlement floor or linear grade band. Ground buildings use
the outer curve; elevated buildings remain separate from it. Buildings are
never lowered afterward merely until they appear to touch.

The plan uses a local coordinate frame centered on the reservoir:

- local `+Y` points inward from the kingdom gate through the reservoir toward
  the far caldera wall;
- local `+X` points right when a visitor stands at the arrival threshold and
  looks into the city;
- local `(0, 0)` maps to world `Vector2(155, 85)`;
- world position is computed from the surveyed gate-to-center basis rather than
  from separately authored rotations.

This frame makes the arrival sequence legible without forcing the city into a
perfectly radial composition.

## 1a. Topography and foundation system

### Caldera Highline

**Fixed:** the people preserve the natural volcanic bowl. The perimeter route
is civic architecture: a level annular deck on sparse branching steel frames,
with the original ground continuing below it. Terrain height, deck height and
building floors remain separate collision systems. The lower reservoir
promenade remains a distinct public realm. The Lava Kingdom debug start equips
the Lava Helm so dry and molten routes can both be inspected.

**Built first fit:** the Highline centre follows radius 72 m, is 4.8 m wide,
and has finished world floor elevation 42.5 m. It widens into SuperEgg docking
platforms only beneath buildings whose entrances share one level. Nahl, Vara,
Civic and Iren are ring-docked Highline buildings; the gate inn is the fifth
raised building, on a matching supported platform beside the true gate rather
than at the far end of a scenic ramp. Oren, Kel and Aro retain split
sections keyed to the natural slope. Renewal is a glass public deck with two
Highline byways landing on opposite sides and one broad immersion tongue. Oren's
roof terrace receives a curved dock at its existing lift landing, and Kel's
upper home receives its own continuous frontage ribbon. The true gate is the
multicolour Tempering Gate on the crater lip at local `(0,-112)` and a curved
arrival gallery descends to the ring. Public overlooks and connectors occur as deliberate stations rather
than making the whole ring broad and land-like.

Every elevated building is carried by a broad concave-waisted superelliptic
service pier. Its upper perimeter follows the building foundation, its buried
foot disappears into the bowl, and inset glowing risers express the lava-power
channels within. These piers replace generic post clusters beneath private
platforms.

**Superseded first fit:** the earlier 30-to-40 m reservoir proposal was replaced
by the built 52 m mean-radius reservoir, the parabolic inhabited bowl, the
Tempering Gate and curved arrival gallery, the guarded Highline, Renewal's two
byways and immersion tongue, and the building-specific docks described above.

**Remaining review:** walk the complete surface network at player, Blorbus and
mount scale; inspect the Tempering Gate, guards, docks, lift stops, thresholds
and night lighting at eye level; then decide the final shop stock and submerged
story encounters before constructing the post-Lava-Helm district.

The lava people have developed a foundation system suited to moving heat,
sloped volcanic rock, and precise modern construction. It is expressed as part
of the architecture rather than hidden as an implementation patch.

### Shared foundation language

- Every building stands on a continuous cast-basalt or refractory-composite
  **socketed plinth** following the same superellipse plan as the mass above.
  The plinth extends below the lowest sampled ground along its perimeter by a
  real embed margin, initially 1.5 m, so no daylight seam can open when the
  terrain slopes or the mesh samples coarsely.
- The localized terrain mesh omits or cuts the ground beneath each authored
  foundation footprint. The foundation and floor provide the sole collision in
  that footprint. Overlapping a second terrain collider beneath the interior is
  forbidden because it causes hovering, snagging, and vertical snapping.
- The uphill side enters a clean bedrock socket or retaining reveal. The
  downhill side exposes the same structural foundation as a tapered basalt
  base, not a thin skirt pasted around the building.
- A narrow recessed metal-and-glass control joint separates the foundation from
  the occupied shell. It accommodates thermal movement and makes the base read
  as intentional advanced construction. Glass never continues below grade.
- Floor datum comes from the building's entrance and route relationship, not
  the average height under its center. The public threshold and its serving
  route meet flush; service doors receive their own level landing.
- Foundations carry concealed thermal branches only where the utility ledger
  requires them. Visitor foundations are cooled and insulated; they never sit
  above the high-temperature forge branch.

### Foundation types by slope

1. **Socket plinth, mild slope:** up to about 1.5 m of elevation change across
   the reserved footprint. One level floor and a tapered embedded base.
2. **Stepped podium, moderate slope:** about 1.5 to 4 m of change. Two or more
   interlocking superellipse foundation terraces step with the ground, with the
   occupied building using a split-level plan only where its program benefits.
3. **Bedrock spine, steep bank:** a thick uphill shear wall keys into rock while
   the downhill side uses broad branching buttresses or a short, visibly
   supported cantilever. It never becomes a field of thin stilts.
4. **Reservoir-edge foundation:** a cooled basalt socket continues below the
   lava surface and ties into the authored bank. The visible edge, collision,
   hazard boundary, and liquid overlap derive from the same section.

An exposed foundation face should generally remain below 3 m. If a building
would need a taller blank base, step the terrain and mass, split the building,
or move the plot. Do not solve it by extruding a featureless wall downward.

### Required plot survey

Before architecture, `FireCalderaPlan` records for every reserved plot:

- terrain height at all footprint corners, edge midpoints, center, every door,
  and each route landing;
- uphill and downhill vectors, total elevation change, and maximum local grade;
- chosen finished-floor datum and any intentional split levels;
- foundation type, bottom elevation, embed depth, retaining faces, and exposed
  downhill height;
- exact terrain exclusion polygon and matching visual and collision footprint;
- public and service landing elevations, drainage or ash-shedding direction,
  thermal-service penetration, and emergency-route connection.

The plan is not ready for a building shell until those fields pass validation.
This survey may move a plot within its reserved envelope, but it may not break
the approved adjacency or route graph.

## 2. Spatial concept

The large irregular reservoir remains visually dominant. Architecture forms a
broken crescent around it, denser near the arrival and industrial side and more
open around the thermal and civic outlooks. Buildings do not complete a rigid
ring and do not occupy a central island.

Three overlapping public realms organize the city:

1. **Dry visitor crescent.** Arrival, guest house, mineral counter, armory
   gallery, civic upper rooms, and reservoir overlooks remain reachable without
   the Lava Helm.
2. **Resident terrace loop.** Household entrances, studios, school, council,
   care, and work routes form a continuous dry loop with several radial links.
3. **Molten lower city.** The primary manifold, communal renewal chamber, deep
   observatory, high-temperature forge, and volcanic archive connect beneath
   the reservoir. Three authored immersion shelves join it to the surface after
   the Lava Helm is acquired.

The city has no generic center plaza. Its civic heart is the relationship
between the reservoir promenade, the council-school-observatory complex on the
far bank, and the communal renewal chamber visible beneath the western water.

## 3. Adjacency matrix

`D` means direct adjacency or a shared threshold. `N` means near on the same
route. `S` means intentionally separated by access, heat, noise, or privacy.

| Program | Arrival | Guest / tempering | Mineral house | Armory / forge | Glass studio | Civic / Iren | Thermal / Aro | Renewal chamber |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Arrival | — | D | D | N | S | view | S | S |
| Guest / tempering | D | — | N | S | S | N | N | D |
| Mineral house | D | N | — | D | N | N | S | S |
| Armory / forge | N | S | D | — | D | N | S | lower link |
| Glass studio | S | S | N | D | — | D | N | view |
| Civic / Iren | view | N | N | N | D | — | D | lower link |
| Thermal / Aro | S | N | S | S | N | D | — | D |
| Renewal chamber | S | D | S | lower link | view | lower link | D | — |

The arrival view to the civic complex is deliberately left open across the
reservoir. No bridge, vendor, or sculpture occupies that sightline.

## 4. Surface districts and footprints

Coordinates and sizes are schematic meters in the local frame. Footprints
include the primary occupied mass but not yet their final canopy or terrace
outline. The later architecture pass must keep eaves, cantilevers, and outdoor
work within the reserved plot envelope.

| Id | Center `(X,Y)` | Primary footprint | Reserved plot | Program and frontage |
|---|---:|---:|---:|---|
| `ARRIVAL` | `(0,-46)` | open 16 x 14 m | 24 x 20 m | Forecourt and paired pylons; arrival axis remains 6 m clear. |
| `NAHL` | `(-38,-28)` | 16 x 12 m | 22 x 18 m | Tempering hall with Eris's suite; public face toward promenade, separate guest entrance toward arrival. |
| `GUEST` | `(-27,-51)` | 15.5 x 12 m | 17 x 14 m | Insulated two-room guest pavilion and rest point; directly visible from arrival, physically separate from treatment rooms. |
| `OREN` | `(30,-34)` | 17 x 12 m | 22 x 17 m | Mineral counter faces arrival crescent; assay, secure store, preparation, and receiving face the outer service route. |
| `KEL` | `(44,-4)` | 19 x 15 m | 24 x 20 m | Surface armory gallery and receiving bay; residence on quiet outer edge; protected descent to deep forge. |
| `VARA` | `(28,37)` | 18 x 14 m | 23 x 19 m | Glass and metal studio with daylight court; clean assembly faces promenade, hot forming and deliveries face Kel. |
| `CIVIC` | `(0,43)` | 24 x 15 m | 30 x 21 m | Combined council, school, archive, and upper observatory; landmark front faces reservoir and arrival view. |
| `IREN` | `(-26,50)` | 12 x 9 m | 16 x 13 m | Household residence connected to, but acoustically distinct from, civic complex. |
| `ARO` | `(-39,22)` | 17 x 13 m | 22 x 18 m | Thermal works and household; public entrance on terrace loop, service descent to primary manifold. |
| `RENEWAL` | `(-43,-4)` | 18 x 14 m | 23 x 19 m | Surface tempering and gathering terrace above the submerged communal chamber; linked to Nahl and Aro without becoming a shortcut through either home. |

**Drawn to scale (2026-10-07).** `scripts/fire_caldera_plan.gd`
(`FireCalderaPlan`) is now the plan; `tools/validate_fire_plan.tscn` checks it
(`--svg=path` draws it). Drawing it changed these numbers, without changing an
adjacency or a route connection:

- Kel `(48.2,-4.4)`, Civic `(0,49)` and Renewal `(-48,-4.5)` move 3 to 6 m
  outward along their own bearing, and Aro to `(-39.4,27)`: their reserved
  envelopes reached into the promenade. The reservoir's lobes toward them
  swell 2 m, not 3.
- Nahl turns 3 degrees round the bank to `(-36.5,-30)`, Vara 8 degrees to
  `(32.9,32.8)` and Aro 5 degrees, so no two reserved envelopes touch and each
  terrace link has 5 m between its neighbours.
- The promenade (R1) follows the bank 4 m out, but keeps within 4.5 m of the
  building fronts where the bank pulls back into a cove (Nahl, Oren). It runs
  from Nahl's south side round to Oren's, broken at the arrival.
- The terrace loop's links (R6 west, R7 east) are radial links through the
  gaps between plots, joining the promenade to the service loop; R5 runs
  straight out to Iren between Civic and Aro. R3 runs from the forecourt to the
  promenade's west end with a short branch to the guest house's door.
- The west emergency spoke (E1) leaves through the Aro–Iren gap at 131 degrees.

The six household programs are therefore not six detached suburban houses.
Each household has a compact private volume joined to the work or civic complex
that explains its daily life. The plot reservations keep private doors away
from public counters and keep receiving routes out of household rooms.

## 5. Surface route ledger

| Route | Width | From and to | Role |
|---|---:|---|---|
| `R0 Arrival axis` | 6 m | kingdom gate approach → pylons → forecourt → reservoir overlook | Primary visitor and party route; no fixtures or channels in clear span. |
| `R1 Reservoir promenade` | 4 m | broken inner crescent joining Nahl, Renewal, Aro, Civic, Vara, Kel, and Oren | Main public route and visual address; follows an irregular 34–38 m bank offset. |
| `R2 Outer service loop` | 3.5 m | guest receiving → Oren receiving → Kel foundry → Vara hot bay → civic records/service → Aro works → Nahl care service | Goods, maintenance, and resident circulation; never requires crossing a shop queue. |
| `R3 Arrival west link` | 4 m | forecourt → guest → Nahl → Renewal | Hospitality and care route. |
| `R4 Arrival east link` | 4 m | forecourt → Oren → Kel | Exchange and material route. |
| `R5 Far civic link` | 4 m | promenade → civic landmark → Iren residence | Public council and learning route with a broad landing. |
| `R6 Thermal link` | 3.5 m | Nahl / Renewal → Aro → civic | Care, heat-system inspection, and council route. |
| `R7 Craft link` | 3.5 m | Oren → Kel → Vara → civic | Materials, finished work, and technical collaboration. |

Routes bend around plots and reservoir shelves. The ring measurements describe
clear corridors, not circular decal paths. Public and service routes may share
a junction but cannot occupy the same narrow threshold.

## 6. Emergency network

Four independent dry ascent spokes prevent the reservoir from trapping the
settlement during a pressure event:

- `E0 Arrival ascent`: forecourt to the existing gate-side caldera ascent;
- `E1 West ascent`: Aro and Civic to a far-west pressure-safe shelf;
- `E2 Far ascent`: Civic and Vara to the far caldera wall;
- `E3 East ascent`: Kel and Oren to an east-side shelf and outer route.

Each is at least 3.5 m clear, stays outside receiving bays, and ends at a real
safe shelf above the reservoir system. No home, school, guest room, or lower
workplace relies on only one escape direction. The localized terrain plan must
shape these slopes deliberately rather than asking paths to climb the current
coarse crater wall.

## 7. Crown reservoir and Heartworks layout

The visible reservoir retains its built irregular approximately 52 m mean
radius. Broad lobes approach Renewal and Civic; dry coves pull away from Aro,
Kel, the arrival sightline and visitor counters. In the Heartworks proposal its
lava becomes a crown annulus around a 17 m radius oculus. The lava mesh still
overlaps its natural outer bank, while the authored solid bank continues below
it. There is no decorative rim, shore strip, cylinder wall or central island.
The inner edge is working architecture: settling baffles, three metered fall
gates and the dry Crown Gallery immediately beneath it.

An 84 m diameter spherical chamber begins beneath that opening. Its six rings
follow the inner shell rather than becoming one flat underwater floor. The
dimensioned section, flow cycle and review questions are in
`fire_caldera_heartworks.md` and the explorable model is
`docs/drawings/fire_caldera_3d.html`.

The six lower programs occupy three of those rings:

| Id | Approximate local position | Depth below surface | Purpose |
|---|---:|---:|---|
| `L0 Renewal chamber` | west / `H1` | 11–17 m | Broad communal immersion beside the Renewal Fall and coming-of-age practice. |
| `L1 Primary manifold` | north-west / `H1` | 11–17 m | Miru and Tovan's thermal distribution, fall controls, and inspection loop. |
| `L2 Deep observatory` | north / `H2` | 23–29 m | Selka's instruments looking across and through the Heartfall. |
| `L3 Fired archive` | north-west / `H2` | 23–29 m | Protected cast and engraved records in the quieter civic sector. |
| `L4 High-temperature forge` | east / `H3` | 35–41 m | Daro, Vesa, and Ruun's hot-work floor beside the Forge Fall and secure lift to Kel. |
| `L5 Experimental materials bay` | north-east / `H3` | 35–41 m | Shared Kel–Vara testing space, separated from clean surface assembly. |

Curved lava passages and shell-following rings join these rooms around, not
through, the falls. Deep inspection and return galleries continue below them.
The lower loop provides two directions out of every occupied chamber.
Vertical material lifts connect the forge to Kel, the experimental bay to Vara,
and the archive to Civic. These are service paths, not substitutes for public
circulation.

Three public immersion shelves reveal the lower city after the Lava Helm:

1. Renewal terrace to `L0`, the gentlest and most social entry.
2. Civic observation landing to `L2`, a deep scientific descent.
3. Kel protected hot-work landing to `L4`, an industrial route kept out of the
   visitor gallery.

The surface dry route remains complete after unlock; lava traversal adds a
second network rather than replacing ordinary circulation.

## 8. Thermal and material infrastructure

- The primary manifold occupies `L1` on the Steward Ring. A buried annular service spine follows
  the western and northern bank beneath the resident terrace, with branches to
  every household immersion room, Renewal, Civic, Vara, Kel, and Nahl.
- Three metered falls divide gravity flow into civic, renewal and industrial
  sectors. A collection basin 69 m below the crown separates return flow, gas,
  mineral load and emergency overflow.
- Three enclosed risers follow the spherical shell back to the crown. Their
  glowing seams and instrument bays express the system without exposing fantasy
  pipes beside public paths.
- A separate high-temperature branch serves `L4` and `L5`; it does not run
  beneath the guest house or imported-provisions cabinet.
- Inspection hatches occur on service terraces beside routes, never in the
  middle of public walking lanes.
- Pressure relief travels outward and uphill toward the west and far emergency
  shelves, away from the arrival forecourt and broad glass fronts.
- Pela's raw material route enters at Oren, continues along `R7` to Kel and
  Vara, and never crosses Nahl's care rooms or the guest sleeping wing.
- Finished weapons and armor travel upward to Kel's surface gallery. Finished
  glass travels from Vara's clean assembly floor, not through the forge.
- Mineral delicacies move from Savi's preparation room to homes, Renewal, and
  communal gatherings; they are never displayed as human provisions.

## 9. Landscape, edge, and public realm

The settlement terraces remain geological rather than planted. Beyond the
caldera and active lava system, however, old cooled rock supports a sparse
pioneer ecology: discontinuous mats of low grass with occasional small flowers,
leaving fresh flows, hot ground, steep faces, routes, and volcanic mouths bare.
This is natural recolonization rather than civic gardening. The city design
uses:

- solid basalt terraces that grow from the caldera wall and meet buildings
  cleanly;
- irregular cooled-lava shelves at outlooks and immersion entries;
- clustered volcanic rock and mineral seams kept outside clear routes;
- a small number of shaped basalt sculptures tied to civic memory;
- colored glass light falling across walking surfaces;
- controlled flame fixtures at thresholds and junctions;
- open reservoir views as intentional empty space.

No living plant is placed anywhere within the caldera. Civic landscape there
is composed from columnar basalt, vesicular boulder groups, obsidian fins,
mineral crusts, controlled vents, fitted paving, forged-and-glass sculpture,
colored mineral light, framed views, and the movement of lava itself. These
elements still follow the landscape rule that each has a job: retaining,
wayfinding, shelter, commemoration, scientific observation, heat management,
or gathering.

There are no generic flower beds, hedge enclosures, timber street furniture, or
decorative exposed pipes inside the city. Every rail guards a real drop. Every
bridge crosses a real bank indentation or service gap. The only dry bridge in the first pass is
a short sculptural span across the narrow eastern reservoir cove between Kel
and Vara; no bridge cuts across the reservoir center or blocks the arrival view.

## 10. Access and reveal phases

### Before the Lava Helm

- `R0` through `R7` form a complete dry visitable network.
- Guest house, mineral counter, armory gallery, civic upper rooms, school,
  promenade, glass clean floor, and reservoir overlooks are usable.
- Lower-city lights and residents are visible through lava and protected glass.
- Immersion shelves read as real resident infrastructure without explanatory
  text. Unsuitable party members gather on authored dry pads.

### After the Lava Helm

- The three immersion shelves connect to the full lower loop.
- The spherical Heartworks, its Steward, Civic, Works, Inspection and Return
  rings, the three separated falls, thermal manifold, renewal chamber, deep
  observatory, fired archive, high-temperature forge, experimental bay and
  collection system become traversable.
- Surface and lower residents use one schedule identity; no duplicate NPCs are
  spawned to populate the submerged district.
- Returning to the surface is possible from all three entries and through at
  least two directions in the lower loop.

### Raised civic tier revision (2026-10-09)

The Highline is now the settlement's upper civic street at world Y 42.5, not a
low shelf behind the buildings. Guest, Nahl, Vara, Civic and Iren stand outside
the ring with their reservoir-facing front doors docked to its outer edge;
Guest occupies the higher gate datum at world Y 49.5.
Their enlarged platforms are private additions to the shared structure and
own their doorway landings; a coloured expansion joint records the boundary.
The ring floor is transparent structural glass with steel mullions and guards,
opened only at authored docks.

Oren, Kel and Aro remain terrain-following buildings below and sit inward
beneath the upper tier. The lava mean radius is 52 m. A long curved
arrival gallery descends from the true south-lip gate. Two curved glass byways
approach Renewal from opposite sides; the renewal deck, guarded immersion
tongue and concave service pier share the Highline's architectural language.
The former bulky rock platform and stepped ghat are retired. The former
diagonal Iren–Civic bridge and its two redundant exterior doors are also
retired: both properties now connect through the shared Highline. Ring and ramp
glass guards own collision, and the first and last ramp bays open at junction
throats rather than placing a railing across the desired path. Guard top rails
are continuous bent pipes along each uninterrupted run, never a visible chain
of short tessellation segments. Each graded deck is likewise one continuous
mesh and collision ribbon; constant-grade profiles and level junction throats
replace the former chain of overlapping slab colliders.

## 11. Implementation contract

After approval, `FireCalderaPlan` becomes the only source for:

- local basis and all district, plot, route, emergency, utility, lower-room,
  landing, gathering, schedule, and gameplay anchors;
- the fourteen residents and six household programs;
- access phase and protected-party behavior;
- shop, inn, Lava Slide, and story anchors;
- non-regression limits and validator inputs.

`fire_kingdom_village.gd` must consume the plan rather than retain a second
offset list. The localized caldera geometry and reservoir are built before
structures. The old eight houses, generic residents, fountain, and braziers are
removed only when their replacements are present and validated.

The fire-city validator must fail:

- plots or reserved envelopes crossing one another, the reservoir, or a route;
- a plot without the required topographic samples, floor datum, foundation
  type, embed depth, terrain exclusion, and threshold elevations;
- exposed daylight beneath a foundation, terrain collision remaining inside a
  building socket, duplicate floor collision, or a threshold that does not meet
  its route flush;
- more than 3 m of blank exposed foundation where a stepped podium, split mass,
  or relocated plot is required;
- an incomplete dry loop or any occupied building with only one emergency
  direction;
- a public or service entrance facing the wrong route;
- fewer than three valid immersion connections after unlock;
- a lower occupied room with only one exit;
- thermal or pressure services beneath the guest wing;
- receiving paths crossing guest, school, care, or gathering rooms;
- a broken arrival-to-civic sightline;
- visible lava, bank, floor, bridge, or terrace geometry disagreeing with its
  collision or canonical hazard query.

## 12. Approval status

### Fixed

- Existing Fire Kingdom gameplay anchors and canonical lava systems remain.
- The crown reservoir and proposed spherical Heartworks, three overlapping
  realms, dry pre-Helm network, and lower post-Helm network define the settlement.
- All fourteen proposed residents receive real home, work, civic, and schedule
  anchors in the plan; no generic filler residents or houses return.
- Arrival remains aligned to the kingdom gate, with a clear view to Civic.

### Proposed

- The precise local coordinates, plot sizes, route hierarchy, lower depth
  bands, four emergency spokes, and short Kel–Vara cove bridge in this document.
- The Heartworks' role as the thermal, scientific, renewal, archival and
  hottest industrial heart of the city; its exact section remains proposed
  until the interactive-model review is complete.

### Open without blocking spatial review

- Final shop inventory and progression gating inside the approved shop
  programs.
- Exact submerged story encounters and rewards.
- Final architectural form of every reserved building envelope: now proposed
  in `fire_caldera_buildings.md` (2026-10-06).

The next gate is review of this civic diagram. Building architecture and
procedural implementation begin only after its relationships and scale are
accepted or revised.
