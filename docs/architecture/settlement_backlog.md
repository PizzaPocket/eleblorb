# Settlement design and implementation queue

This queue applies the repository's architecture, interior-design and
landscaping process to one settlement at a time. A later settlement does not
enter construction until the earlier one has an authored plan, a coherent
style charter, and a completed traversal audit. This prevents corrections in
one village from becoming another set of isolated props in the next.

## Shared completion gates

Every settlement pass follows the same order.

1. Inventory the actual terrain, buildings, props, residents, dialogue and
   gameplay anchors already present. Preserve intentional story beats.
2. Write the population and economy first. Every residence, workplace, boat,
   yard and public building belongs to a named person or a defined communal
   use. Record new canon in `docs/world_bible.md`.
3. Author the circulation network before moving buildings. Roads, bridges,
   docks, ramps and paths connect real origins and destinations without
   crossings through structures.
4. Approve the cultural style charter and a building program for each type.
   Massing, roof, wall, opening, chimney and material rules precede decoration.
5. Put the plan in one data source consumed by both the generator and its
   validator. Do not distribute placement constants among unrelated scripts.
6. Build architecture, then interiors, then landscape. Substantial visible
   geometry receives collision as it is authored.
7. Walk every route at player, Blorbus and mount scale. Check doors, ramps,
   upper floors, bridges, counters, beds and exterior props from eye level.
7a. Write the trade ledger (who makes, gathers, carries and sells every item
   on every stall and shelf) in the plan file before stocking or furnishing.
   The validator fails any stall item with no source. The inventory tells the
   village's story.
8. Give named residents schedules and dialogue only after their homes and work
   are stable. Dialogue receives a final `no-ai-slop` pass and remains
   character-specific, diegetic and free of mechanic instructions.

## 1. Ohio, starting village

Status: validated and visually audited (2026-10-04). The guarded validator reports
0 FAIL and 2 WARN (Vey house to storehouse 2.9 m, Sallow cottage to drying shed
2.9 m, both usable maintenance passages). Eye-level and cutaway renders confirm
the arrival sightline, inn front and upper plan, meeting house and archive,
bakehouse rear store, overlook paving, and both large-house ramp heads. The upper
floors of every two-storey house are now furnished (beds for the household, chest,
washstand, rug, peg rail, lamp; `upper_beds` in `OhioPlan`). Remaining: the user's
in-engine walkthrough, then a walked play-test with the human and Blorbus (doors,
locked-room sequence, ramps). See `docs/handoff_ohio_village.md`.

## 2. Snow Village, Ice Kingdom

Status (2026-10-04): rebuilt. The single plan is `scripts/snow_plan.gd`; the
laft log module is `scripts/log_house.gd`; hearths are `scripts/nordic_hearth.gd`;
programmes, interiors and the inn's rest function are in `scripts/snow_buildings.gd`,
`scripts/snow_interiors.gd` and `scripts/ice_kingdom_village.gd`. The validator
(`VILLAGE=snow tools/check_village_layout.sh`) passes with 0 failures. The bunny
run's end and the chair lift's lower station moved onto the village pad.
Schedules, dialogue and the landscape pass are done. Remaining: visual check of
the snow banks, eye-level audit of every interior, a walked play-test, and snow-cap
tuning. See `docs/handoff_snow_village.md`; the detailed working document is
`docs/architecture/snow_village.md`.

The pass begins by mapping the sheltered common yard, lift base, mountain-rescue
route, lake road and forest service edge together. The village must work as the
base of a ski mountain and as a year-round cold-climate home. The chair lift,
three pistes and village circulation are one terrain problem, not independent
set pieces.

Required building programs:

- Astrid Snowrest's inn, with a mudroom, drying room, vaulted common room,
  kitchen, pantry, guest wing, party room and an accessible indoor dry toilet.
- Elin's rescue and meeting hall beside the lift base.
- Niko's lift workshop and compact home.
- Anja's forest-edge home, wood yard and communal firewood store.
- Mara and Solveig's combined textile workshop, shop and home.
- Tomas and Soren's lakeside-edge home and separated icehouse.
- Ivar and Freya's household, smokehouse and net shed, distinct from the day
  shelter at the fishing hole.
- The communal bathhouse and washhouse.

The architecture remains continuous laft log construction with true gaps in
the courses at doors and windows, steep snow-bearing roofs, deep eaves, warm
vestibules and gable-end chimney masses. Houses are not cell grids with capped
log fragments. Snow banks, windbreak pines, wood stacks and hardy service plots
follow climate and work rather than filling empty space.

## 3. Crossroads Fishing Village

Status: design brief and fifteen-person census approved (2026-10-06);
dimensioned civic layout in review (`docs/architecture/fishing_village_layout.md`).
No construction has begun. The current implementation is
a dock strip with seven generic huts, six decorative boats and one merchant.
The approved direction is an original, cosmopolitan lake community whose
primary built precedent is the working fishbone layout of George Town's Clan
Jetties in Penang, sited against two steep limestone islets after Ko Panyi,
without importing either community's clan, ethnic or religious identity. See
`docs/architecture/fishing_village.md` and `docs/handoff_fishing_village.md`.

Settled:

- Fifteen named residents in five households: Venn (landing house, shop and
  boatyard), Aran (pearl house and mussel yard), Vale (fishing house and
  processing edge), Mor (guest houseboat and cargo landing) and Sen (clinic,
  school room and shell workshop). The census replaces the single generic Lake
  Diver, who becomes Nara Venn.
- Every structure, boat and stall item has an owner and trade source in the
  brief. Pearls are ordinary cultivated valuables.
- The Mor houseboat is the rest point at 10 Tokoins.

Next work:

- Review and approve the layout plan: Anvil Rock and Heron Rock, their shelves,
  footprints, routes, boat lanes, berths, swim exits and the portal's move to
  Heron Rock.
- Add the islets and shelves to the lake terrain.
- Author `FishingVillagePlan` as the only source for structures, the public
  jetty spine and return route, household and work spurs, gangways, boat lanes
  and berths, swim exits, trade and schedules.
- Add a fishing-village mode to `tools/validate_village.gd` before populating
  the plan, including the three-swim-exit and foot-height ramp checks.
- Then build circulation and swim exits, the architectural kit proofs, the
  village, interiors, water work and landscape, and finally schedules and
  dialogue.

Open:

- Whether working boats become rideable in this pass or remain scheduled
  environmental traffic until vehicle boarding is generalized.
- How the player reaches the village: today a 205 m swim from the west shore.
  Options are swimming only, a west-shore landing with Ivo's ferry, or a long
  public jetty from the shore.

## 4. Fire Kingdom Caldera City

Status: concept planning and proposed named census complete (2026-10-05). The
current implementation is eight generic homes around an 8.4-metre-wide
decorative lava fountain. The proposed direction replaces it with a terraced
city around a broad natural magma reservoir, with a second public district
beneath the lava that opens after the Lava Helm is obtained. See
`docs/architecture/fire_caldera_city.md` and `docs/handoff_fire_kingdom.md`.

Planning priorities:

- Confirm the lava people's physiology: thermal energy sustains them, while
  rocks, minerals, and metals supply bodily matter and an analogue to flavor.
- Review the proposed fourteen-person register across the Aro, Iren, Kel, Vara,
  Oren, and Nahl households. It combines compatible roles so science, vent
  stewardship, forging, glasswork, mineral work, education, care, government,
  and the occasional guest house do not each require a separate NPC.
- Build a three-band plan: dry visitor and market ring, inhabited working
  terraces, then the reservoir and submerged civic and industrial district.
- Establish advanced volcanic-modern architecture using continuous dark shells,
  large structural glass, integrated lava services, and a restrained layer of
  Gaudí-informed forged metalwork. It grows from the caldera without becoming
  a rustic forge village or importing classical architecture.
- Use clear and smoky glazing for daylight and views, then concentrate stained
  mineral colors and colored or polished metal finishes at thresholds,
  clerestories, screens, rails, instruments, and landmarks. Dark basalt is the
  visual ground, not the entire palette.
- Program an armory and weapon forge, an elemental-gem and mineral dealer, and
  a mineral delicacy maker with a complete source-and-production chain.
- Treat the guest house as a minor service opened for rare visitors, not the
  center of a developed tourism or inter-kingdom trade economy.
- Design the kingdom-gate approach and the city threshold as one route. The
  threshold belongs at the near reservoir bank, framed by open metal-and-glass
  pylons and restrained welcome flames rather than a defensive wall.
- Replace oversized braziers with a coherent, lightweight family of controlled
  glass-enclosed flame fixtures; retain large flames only where danger or
  industrial work justifies them.
- Preserve Lava Slide's helm story and make the newly safe reservoir itself the
  environmental reveal. Do not explain the route through mechanic text.
- Reuse the canonical lava surface, immersion, sound, effects, and under-lava
  systems. Author higher-resolution local geology rather than enlarging the
  current decorative fountain.

## 5. Chinese Village

Status: audit complete and population approved (2026-10-04); see
`chinese_village.md` and `docs/handoff_chinese_village.md`. The households,
history, Ohio trade link and the innkeeper 林静 are canon. The layout re-fit,
courtyard charter and palace restructure await approval. No building moves
until then. Queue: Ohio walkthrough first, then the layout re-fit.

Planning priorities:

- Treat the island and bridge network as the town plan. Give every island a
  role, establish bridge hierarchy and desire lines, and ensure paired bridge
  landings share elevation and clearance. The inn must occupy an intentional
  guest-facing island or street position and must not overlap another use.
- Inventory the Emperor, farmer, Chef, Chen, children and existing villagers.
  Assign each named resident a household, work, daily route and relationship to
  the palace economy. Add residents only where a real civic, agricultural,
  craft, market or service role requires them.
- Write and approve a Chinese courtyard and hall charter before rebuilding.
  Ordinary homes use restrained white walls, stone plinths, grey or green tile,
  red structural timber and appropriate gable roofs. Imperial yellow and the
  highest roof hierarchy remain exclusive to the palace.
- Re-plan the palace as an axial complex with public audience, controlled
  service circulation, private or administrative rooms, terraces and working
  ramps. The Royal Kitchen needs a believable delivery route and a clear,
  generous battle floor while remaining connected to the story's palace flow.
- Design a royal Chinese garden as a sequence of framed views, stone paths,
  planting, water and sheltered pauses rather than scattered decorative props.
- Rebuild bamboo as clumping living groves: culms of varied age and diameter
  rise mostly vertical from shared clusters, with nodes and leaf sprays high on
  branching stems. Groves need paths, edges and purposeful clearings. They must
  not read as a regular scaffold or a grid of identical poles.
- Validate every residence, palace level, kitchen entrance, island edge and
  bridge for player, Blorbus and mount traversal before revising dialogue.
