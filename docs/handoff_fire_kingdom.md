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
## Remaining work

- The surface city is built and covered by the plan validator, isolated physics
  proof, live-world probe and player-support handoff regression. It still needs
  a human eye-level and walked review in Godot of the Tempering Gate, complete
  Highline, building docks, guest thresholds, Oren's three lift stops and night
  lighting.
- The original inner forecourt pylons and Kel–Vara cove bridge were superseded
  by the built crater-lip Tempering Gate, curved arrival gallery and shared
  Highline. Do not add them as duplicate routes.
- The post-Lava-Helm district remains unbuilt. Its earlier room reservations
  are now organized as the proposed **Caldera Heartworks**: a 34 m oculus into
  an 84 m spherical chamber, six shell-following rings, three controlled lava
  falls, a deep collection basin and three enclosed return risers. Review the
  explorable `docs/drawings/fire_caldera_3d.html` and resolve the decisions in
  `docs/architecture/fire_caldera_heartworks.md` before changing live terrain.
  Final shop stock and Heartworks story encounters also remain decisions for
  the user.
- Keep the automated regressions at 0 failures whenever the walkthrough finds
  a visual, collision or circulation issue.
