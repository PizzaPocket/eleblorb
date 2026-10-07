# Handoff: Fire Kingdom Caldera City

**Progress (2026-10-07).** The plan, live caldera ground, reservoir, all nine
surface foundations, and the finished guest house exist and validate.

- `scripts/fire_caldera_plan.gd` (`FireCalderaPlan`): the approved layout as
  data. `VILLAGE=fire tools/check_village_layout.sh` runs
  `tools/validate_fire_plan.tscn` (also in the pre-push hook); `--svg=path`
  draws the plan.
- `scripts/fire_caldera_ground.gd` (`FireCalderaGround`): the city's own
  ground: reservoir basin and bank, immersion shelves, terraces rising 7
  percent outward and toward the far wall. The plot survey and foundation
  ledger are computed from it and checked by the validator (five socket
  plinths, four stepped podiums; floors flush with their front landings,
  uphill backs in retaining sockets of 1.2 to 2.4 m, no blank base). It is now
  built by `fire_kingdom_terrain.gd` in the plan's rotated world frame. The
  coarse terrain omits its triangles and collider beneath the city; the fine
  mesh's outer band samples the coarse wall exactly (measured seam error 0 m).
- `scripts/socket_plinth.gd` (`SocketPlinth`): the tapered, embedded basalt
  plinth with its control joint, floor-level reveal and continuous uphill
  retaining wall; the ground leaves its collider out under it.
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
  a richer interior pass (display cells' stock, assay tools, Savi's stations),
  register its lava beds with the terrain, tune the bricks' milkiness in sun,
  and a way onto the flat roof if it is to be a terrace.
- Next buildings by the brief: Renewal terrace, Kel, Vara, Civic (with the
  terrarium), Iren, Aro, the arrival pylons and the cove bridge. Each gets
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

Pause here for the user's next in-game walkthrough. Do not begin another
building until its stylistic notes have been folded into the shared kit.
After approval, build the remaining briefs plot by plot, beginning with the
arrival forecourt and paired welcome pylons, then Nahl hall and Eris's suite.

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
- `scripts/fire_kingdom_village.gd` places eight generic homes, eight generic
  lava residents, eight braziers, a 4.2-metre-radius lava fountain, the guest
  inn, and Lava Slide.
- `VillageInn.create()` currently receives `Ember Rest` in the innkeeper-name
  position. The replacement plan needs a named guestkeeper and a distinct inn
  name.
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
