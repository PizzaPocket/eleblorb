# Handoff: Fire Kingdom Caldera City

**Progress (2026-10-08).** The plan, live caldera ground, reservoir, all nine
surface foundations, guest house, Nahl hall, Oren mineral house, Renewal terrace,
Kel foundry, Vara glass studio/home, Civic complex, Iren residence and Aro
thermal works/home exist and validate.

**Settlement-planning pass (2026-10-09).** Civic's architectural redesign is
deferred behind the now-built public-realm revision. `FireCalderaGround` forms
a parabolic inhabited bowl around a second parabolic lava bowl rather than a
deep plunge, flat settlement floor, and second plunge. Its inhabited annulus is
`y = 30 + 18((r-52)/60)^2` from the lava-mouth shoulder to the existing
48 m crater lip; it reaches a 31-degree tangent at the lip, drops decisively
away from rear walls, and leaves the building belt on its lower reach. A separate
`FireCalderaHighline` follows radius 72 as a 4.8 m annular glass deck at world
Y 42.5, with collidable glass guards and continuous bent-pipe top rails. Nahl,
Vara, Civic and Iren dock to
it on thin platforms carried by broad concave-waisted superelliptic service
piers whose glowing seams express lava risers. The inn uses the same pier system
on its own gate platform at world Y 49.5 and local `(22,-98.5)`, reached by a short forecourt
branch rather than a ring-spanning ramp. Oren, Kel and Aro remain natural-grade,
slope-integrated buildings and have been pulled inward under the ring; Oren's
existing roof-terrace lift landing now receives a deliberate Highline dock;
Kel's upper home landing receives a separate curved frontage ribbon. The true
arrival threshold is the full-scale multicolour Tempering Gate on the crater
lip at local `(0,-112)`, and a restrained gallery descends to the ring. The
safe zone reaches beyond the lip.
The lava reservoir mean radius is 52 m. Renewal is no longer a rock ghat: two
public glass byways reach opposite sides of its SuperEgg deck, and a broad guarded glass tongue
slopes into the lava. The obsolete Iren–Civic cross-village bridge is removed.
The title screen's Lava Kingdom debug start binds the Lava Helm to the Fire
head so that study can include molten traversal; ordinary progression is
untouched.

**Terrain palette correction (2026-10-09).** The legacy kingdom terrain and
the fine caldera-city mesh now reference the same shared material resource and
one neutral charcoal-black basalt albedo. The former warm brown terrain and
the city patch's separate terrace/bank/heat tints are removed; lava and its
lighting carry the heat colour. The live-world probe checks material identity,
not only similar RGB values.

**Planetary-ocean exclusion (2026-10-09).** `FireKingdomTerrain` publishes
six visual exclusion footprints: the inhabited caldera, three lava bowls and
two secondary volcanoes. `DayNightCycle` passes those to `PlanetaryOcean` and
its shader discards the world-ocean surface inside each footprint. This keeps
the blue sea from appearing as a false ceiling while swimming down in lava;
the live-world probe verifies all six uniforms.

- `scripts/fire_caldera_plan.gd` (`FireCalderaPlan`): the approved layout as
  data. `VILLAGE=fire tools/check_village_layout.sh` runs
  `tools/validate_fire_plan.tscn` (also in the pre-push hook); `--svg=path`
  draws the plan.
- `scripts/fire_caldera_ground.gd` (`FireCalderaGround`): the city's own
  ground: an annular paraboloid from the 30 m lava-mouth shoulder to the 48 m
  crater lip and a second paraboloid forming the reservoir basin. The plot survey and foundation
  ledger are computed from it and checked by the validator (five Highline
  platforms and four natural-grade foundations). It is now
  built by `fire_kingdom_terrain.gd` in the plan's rotated world frame. The
  coarse terrain omits its triangles and collider beneath the city; the fine
  mesh's outer band samples the coarse wall exactly (measured seam error 0 m).
  The live probe samples each full rear wall and its 1.2 m inspection strip;
  minimum terrain clearance is 0.75 m for ground buildings and at least 2.6 m
  for raised buildings.
- `scripts/socket_plinth.gd` (`SocketPlinth`): the tapered, embedded basalt
  cut-and-fill platform with its control joint and unobstructed floor-level
  reveal. Ordinary foundations have no above-floor perimeter lip; retaining
  work belongs outside an occupied platform at an actual bank cut. The ground
  leaves its collider out beneath the platform.
- `scripts/fire_caldera_highline.gd` (`FireCalderaHighline`): the independent
  level glass deck, its exact walkable collider, collidable glass guards with
  continuous bent-pipe top rails,
  SuperEgg edge members, open junction throats, branching ring supports, and
  the thin docks and supertoroidal service piers for flat-datum buildings.
  Every graded branch is one continuous visual and collision ribbon, rather
  than a chain of slab segments.
  Terrain remains visible and collidable below it.
- `scripts/player.gd` retains grounded locomotion across adjacent authored
  floor seams with a short real-capsule support probe. This prevents a
  one-frame `is_on_floor()` loss between rooms from stopping movement in the
  airborne pose. `tools/player_support_handoff_probe.tscn` covers the seam and
  rejects vertical walls as false support.
- `tools/fire_caldera_proof.tscn`: builds ground, lava and every plinth in
  isolation and checks each socket with physics (0 FAIL); `--shots=dir`
  renders it.

- `FireKingdomTerrain.register_lava_polygon()`: irregular lava surfaces for
  the reservoir, through the same hazard, height and escape queries as the
  circles (`tools/test_lava_polygon.tscn`, 0 FAIL). The live terrain now builds
  and registers the reservoir before the placeholder village initializes.
- The building briefs (`fire_caldera_buildings.md`) were approved by the user
  on 2026-10-07.

- `scripts/caldera_shell.gd` (`CalderaShell`): the kit's first revised shell,
  live as the guest house and isolated in `tools/fire_caldera_proof.tscn`.
  The second walkthrough rejected the domestic window hardware and ribbed
  barrel. The current 15.5 × 12 m pavilion instead has one facade-wide clean
  structural-glass sheet, room-wide side/rear panes, continuous volcanic stone
  and stainless posts large enough to cap the wall ends. A two-degree metal
  slab is Boolean-punched for four fitted glass SuperEgg domes: lounge,
  washroom and one per bedroom. Low stone partitions continue as clean glass
  clerestories to the roof, sharing daylight rather than making ceilinged
  cubicles. Supplies became lounge cabinetry, leaving two 5.5 × 6.25 m guest
  rooms and a 4.5 × 6.25 m washroom. The fitted 2.3 m double door, Eris's
  orientation and fire-free cool program remain. The cobalt/amber entry fin
  now uses a squarer SuperEgg exponent.

- Walkthrough remediation (2026-10-08): guest-house wall heads now derive from
  the roof pitch, and its skylight glass is built from the same Boolean profile
  that punches the roof, following the spaceship glazing precedent. Corner
  forks terminate inward at the two adjoining wall bearings. The forecourt is
  a matching SuperEgg arrival apron rather than a contrasting box.
- Architectural lava now has one construction path
  (`CalderaLavaFixture`): Nahl's molten lobby and lava bed and the Oren/Kel beds
  all use `NatureProps.build_lava_material()` and scaled `LavaSurfaceFX`.
  Small vessels receive small bubbles; the volcanic pools retain full scale.
- Locomotion no longer treats the deliberately lowered terrain inside a
  building socket as a second ground authority. Oren's roof terrace also owns
  a flat collider matching its paving. This addresses threshold hovering and
  repeated roof/conversation-pit hopping at the shared cause.
- Oren's front lobby is 1.7 m clear; the rear threshold and exterior ramp use
  authored platform levels; its home screen is again narrow alternating fins,
  now made as thin squarish glass SuperEgg slabs. Kel's loading door is
  sectional overhead, its public/home doors slide, and interior work passages
  have no leaves to swing into tables or ramps.
- Renewal's unexplained rear glass panes and perimeter retaining lip are gone;
  the promenade meets the deck flush and the descent is an elongated
  superellipse cut rather than a square notch.

- `tools/fire_caldera_world_probe.tscn`: instantiates the real terrain and
  checks the fine ground and reservoir exist, live height and lava queries,
  the exact seam, the basin collider, and the absence of the old coarse floor
  below the city (0 FAIL). `village_aerial_capture.gd -- --village=fire`
  renders the live transition for visual review.

- Walkthrough correction: the fine wall-blended terrain skin now continues in
  a hidden eight-metre apron beyond the coarse triangle cut line, farther than
  a cut triangle can reach, eliminating the rim's blue triangular holes. The
  fine visual mesh is lifted 1 cm above its matching collider to prevent
  boundary depth flicker without changing floor height.

## Built so far (2026-10-07)

- **Guest house** (`FireCalderaBuildings`): live.
- **Nahl tempering hall and Eris's house** (`FireCalderaNahl`): live; pale
  tuff house of care, wrought iron, conversation pit, lava bed.
- **Oren mineral house** (`FireCalderaOren`): live; split level, cast-glass
  brick front and dichroic fins, a first spare furnishing pass. Next for Oren:
  done: richer interior, lava beds registered, bricks toned down, the roof
  terrace reached by a lift from the home's landing (`CalderaLift`).
- **Renewal terrace** (`FireCalderaRenewal`): live; a transparent civic deck
  reached by two Highline byways, with a broad guarded glass immersion tongue,
  half-sunk threshold arch, memory stones and Eris's tempering slab beneath the
  slumped-glass catenary canopy; carried by its own supertoroidal service pier.
- **Kel foundry** (`FireCalderaKel`): live; temper-colour steel facade,
  sawtooth roof, crane over the loading dock, residence on the roof.
- **Vara studio and home** (`FireCalderaVara`): live; separate studio and home
  wings around an open daylight inspection court, with the metal shop closing
  its back. The clean assembly, hot forming, annealing and metal stations are
  furnished; the home has two canonical lava beds and an immersion well. The
  site's first rear-door scheme met the actual uphill cut, so the finished
  building consolidates deliveries at one overhead door on the Kel-facing side.
  Studio, home and both court connections pass the player-capsule proof.
- **Civic complex** (`FireCalderaCivic`): live; a double-height council chamber
  beside exact school/lobby/archive bands and a two-flight public ramp hall.
  Its upper instrument gallery has the city's only plane-clipped observatory
  dome. The sealed Vara-made terrarium is a 6.6 by 5.4 m living-landscape
  centerpiece behind the five council seats, with a full tree, earth, rocks
  and low plants; its shell is also a genuinely clipped and capped SuperEgg.
  Public doors, room passages, both ramp flights, the council void, nested
  upper shell and foundation all pass the player-capsule proof.
- **Iren residence** (`FireCalderaIren`): live; Selka, Aru and Mena's compact
  receiving room and closable molten resting room contain three canonical lava
  beds, a family immersion well and Mena's backlit glass-fragment case. Its
  former private bridge to Civic has been removed; both buildings now use the
  shared Highline rather than spanning the settlement with a redundant route.
- **Aro thermal works and home** (`FireCalderaAro`): live; one low cobalt/teal
  shell separates the 9 m public works band from the 8 m family band, with a
  dedicated outside slider for each and one private service passage. The works
  contains Tovan's five-station valve wall and emergency bell plus Miru and
  Kes's bending, welding and pressure-test shop. The home contains its receiving
  room, sample shelf, three canonical lava beds and shared immersion well. The
  surveyed moderate site uses a stepped embedded podium—not the brief's
  expected steep-site spine—and a protected 2.4 m dry cut carries a railed,
  true-length SuperEgg ramp to a sealed future-L1 bulkhead. All entrances,
  internal passages, ramp samples, clear zones and lava fixtures pass proof.
- Walkthrough follow-through (2026-10-08): Kel's sloped ramp cover and level
  landing cover are clipped on the same junction plane and share the exact
  cut-edge height and width. Their different local positions along rounded
  SuperEgg ends are compensated from the actual section at the cut, so neither
  piece flares wider at the seam. Matching the complete cut profile is now a
  project architecture-skill rule for every joined SuperEgg surface. Oren's
  lift always lists Roof, Home, Ground in that order, and its top canopy clears
  the platform by 2.7 m.
- Foundation/circulation follow-through (2026-10-08): terrain height queries
  now describe terrain only and stay at least 0.75 m below authored floors in
  each building socket; physical floors, ramps, lift decks and the Oren roof
  terrace own their own contact. This removes the competing-height source of
  entry clipping and terrace hopping. The former retaining lip around ordinary
  socket foundations is gone. Oren's service passage is 2.0 m clear, non-secure
  room connections are open arches, the receiving bay has an overhead door,
  and both secure stores use surface sliders (1.4 m stock, 1.6 m gem) instead
  of spending the corridor or lobby on swing arcs. The proof now sweeps a
  player-size capsule through the Fire door routes (0 FAIL).
- The transitional ring of generic houses, generic residents, braziers and
  lava fountain is no longer spawned. The live-world probe asserts that those
  obsolete objects remain absent.
- Recovery now transfers marker position and explicit body heading without
  rotating the Player root. The Fire guest wake marker follows the beds'
  length, so resting no longer lays the player across both beds or desynchronizes
  visual facing from movement and aim.
- Next construction by the brief: the arrival pylons and the cove bridge. Each gets
  its own original idea (see "A culture of original buildings" in the brief).

## Backlog

- **Wall tops against the roof pitch: evaluated 2026-10-07** with the guest
  house and Nahl (renders `guest_wallhead_*`, `nahl_wallhead_*` from the
  proof). The kit's 2-degree slab is pitched about its centre over level wall
  heads, so on the guest house and Nahl's wing the back half of the slab sinks
  up to 0.2 m into the ring beam and stained band, and the front half leaves
  an open wedge up to 0.22 m above the wall head; the sides show both. Nahl's
  raked hall is the one case that matches: its wall heads follow the roof
  (glass wedge, beam on the rake). Options, for the user to choose:
  1. rest every pitched slab on its low wall and fill the side wedge (glass as
     on Nahl's hall, or the band raked) so the head follows the roof;
  2. keep wall heads level and set the slab level, with the fall formed in
     its top surface and a fascia, which reads as a flat roof;
  3. keep the pitch but close the gap with a raked fascia upstand.
  Oren takes option 2 (a walkable roof terrace) meanwhile.

The next isolated construction pass begins with the arrival forecourt and
paired welcome pylons, then the cove bridge. Keep the live-world walkthrough
checks for thresholds, roofs and the three lift stops in the regression pass.

Status: community, civic-system, and architectural brief complete enough for a
dimensioned layout synthesis; the fourteen-person census was approved on
2026-10-06. The outer-wilds regrowth and island-skirt systems
have been implemented, but the caldera city itself has not been reconstructed.
Read
`docs/architecture/fire_caldera_city.md` first.

## Current implementation

- `scripts/fire_kingdom_terrain.gd` owns the volcanic terrain and canonical
  lava queries. The main village caldera has a 72-metre floor radius, a
  112-metre rim radius, and a floor height of -16 metres.
- `scripts/fire_kingdom_village.gd` places Lava Slide and the authored Fire
  buildings and residents. The obsolete generic houses, residents, braziers,
  fountain and placeholder inn are deliberately absent.
- `register_lava_surface()`, the universal lava material and surface effects,
  and the under-lava environment already exist and must remain the only source
  of lava physics and presentation.
- `scripts/volcanic_regrowth.gd` now creates sparse grass colonies and flower
  accents on cooled outer lava using two MultiMeshes. Suitability comes from
  the terrain and excludes active lava buffers, volcanic mouths, the caldera,
  steep faces, the arrival clearing, and submerged coastal ground.
- The terrain skirt reads the Fire Kingdom's configured planetary-ocean level
  and buries every map edge 56 metres below it, rather than depending on an
  independently hard-coded shoreline height.

## Working direction for review

- Replace the tiny fountain with a large, cultivated natural lava reservoir.
- Build the city in terraces around its banks and continue part of the city
  beneath the lava.
- Let the residents' lava physiology determine domestic rooms, work,
  education, medicine, civic life, and industry.
- Make the Fire Kingdom a center of geology, metallurgy, volcanic sculpture,
  structural glass, expensive armor, and high-quality weaponry.
- Use an advanced volcanic-modern style: continuous SuperEgg and superellipse
  masses, large glass panes, integrated molten-heat services, and restrained
  Gaudí-informed forged metalwork rather than rustic stone huts or classical
  architecture.
- Keep the city luminous rather than drab. Most large panes are clear or smoky;
  stained glass in amber, garnet, cobalt, violet, emerald, and mineral teal is
  reserved for clerestories, thresholds, screens, rails, and focal sections.
  One building uses no more than two principal stained colors unless it is a
  landmark. Blackened structure is paired with heat-blued or enameled iron,
  bright stainless precision details, and sparse protected gold or silver inlay
  on surfaces safely removed from open lava.
- Give homes private immersion wells or molten-floor rejuvenation rooms fed by
  an implied concealed lava-duct network.
- Plan two principal visitor-facing merchants: one tied to the armory and
  weapon forge, another tied to elemental gems, rare earths, ores, and mineral
  assay. Add a lava-person delicacy maker to the resident economy, but do not
  present those mineral preparations as edible human items.
- Align the kingdom gate with an open city threshold at the nearest bank of the
  central reservoir. Two organic forged-metal and glass pylons frame a tall
  superellipse of open air, contain narrow controlled welcome flames, and leave
  at least 5 metres clear for the player, party, and mounts.
- Replace the oversized generic braziers and wall flames with the shared fixture
  family in the architecture brief: arrival beacon, low path capsule, branching
  wall light, civic/work light, and submerged mineral marker. Reserve large
  turbulent flames for industrial work, eruptions, and hazards.
- Keep a dry outer visitor network. Use the Lava Helm to open the reservoir and
  submerged district as a second exploration layer.
- Replace fire-word placeholder names and anonymous houses with an exact
  population, household map, and trade ledger before construction.
- Keep the settlement compact: the current target is fourteen permanent
  residents, about eleven adults or elders and three youths or apprentices,
  grouped into six households whose related roles overlap.
- The complete proposed register is now in the architecture brief: the Aro,
  Iren, Kel, Vara, Oren, and Nahl households. Do not restore the placeholder
  Cindra/Basal/Ember-style fire-word names if the register is approved.
- Rebuild the current inn as a small occasional guest house, not an economic
  anchor. Its caretaker has another primary civic role; the building retains a
  functional rest point and only enough program for rare visitors and the
  player's party.
- Do not assume a mature inter-kingdom trade network. Shops first serve local
  craft and the occasional specialist or visitor; external suppliers and
  regular caravans require later lore.

## Next planning task

The coherent, dimensioned civic layout is now drafted in
`docs/architecture/fire_caldera_layout.md`, approved 2026-10-06: its adjacency
matrix, scaled surface plan, dry and molten route networks, utilities,
emergency paths, footprints, access phases and submerged depth bands. Building
architecture briefs come next. It fixes:

1. the arrival axis from the kingdom gate and the paired entrance pylons;
2. the irregular 28-to-32-metre-radius reservoir and its authored banks;
3. the dry outer visitor loop, terraced resident loop, submerged lava network,
   and independent emergency ascent routes;
4. exact footprints, fronts, service sides, and access phases for all six
   household programs, the combined council-school-observatory-archive, thermal
   works, tempering hall and guest house, forge and armory, glass studio,
   mineral house, bridges, and communal immersion spaces;
5. utilities, protected gathering points, schedule anchors, view corridors,
   hazard clearances, and the pre- and post-Lava-Helm reveal sequence.
6. a topographic survey and foundation ledger for every plot: footprint and
   threshold samples, uphill/downhill vector, floor datum, foundation type,
   embed depth, terrain exclusion, exposed height, and route landing levels.

The diagram proposes the submerged district as the city's thermal and
scientific heart: primary manifold, communal renewal chamber, deep observatory
and high-temperature forge, with the archive protecting the volcano's long
record. Final shop stock remains open while the plan reserves the approved
gallery, assay, secure-storage, receiving, and delivery functions.

After layout approval, encode it as the sole `FireCalderaPlan` data source and
add a fire-city mode to the settlement validator. Prototype the localized
caldera bank, one continuous shell with a cut opening, one glass-and-metal
threshold, one sloped-ground socket foundation, and one lava interface in
isolation before constructing the city.
The localized caldera geometry needs more resolution than the kingdom's current
approximately 15-metre terrain sampling. Do not scale up the existing cylinder
fountain or mask the edge with a decorative rim.

## Settlement sequence

The current sequence is Ohio walkthrough closure, remaining Snow Village
visual and walked checks, Fishing Village planning and implementation, Fire
Kingdom planning and implementation, then Chinese Village implementation.
