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

Status: design brief, fifteen-person census and dimensioned civic layout
approved (2026-10-06) (`docs/architecture/fishing_village_layout.md`).
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
- Review the architecture briefs (`docs/architecture/fishing_village_buildings.md`):
  the kit of parts, household palettes and every building's form.
- Author `FishingVillagePlan` as the only source for structures, the public
  jetty spine and return route, household and work spurs, gangways, boat lanes
  and berths, swim exits, trade and schedules.
- Add a fishing-village mode to `tools/validate_village.gd` before populating
  the plan, including the three-swim-exit and foot-height ramp checks.
- Then build circulation and swim exits, the architectural kit proofs, the
  village, interiors, water work and landscape, and finally schedules and
  dialogue.

Open:

- None blocking: players swim to the village until boats exist.

## 4. Fire Kingdom Caldera City

Status: concept planning complete (2026-10-05); named census and dimensioned
layout (`fire_caldera_layout.md`) approved (2026-10-06). The
current implementation is eight generic homes around an 8.4-metre-wide
decorative lava fountain. The proposed direction replaces it with a terraced
city around a broad natural magma reservoir, with a second public district
beneath the lava that opens after the Lava Helm is obtained. See
`docs/architecture/fire_caldera_city.md` and `docs/handoff_fire_kingdom.md`.

Planning priorities:

- Confirm the lava people's physiology: thermal energy sustains them, while
  rocks, minerals, and metals supply bodily matter and an analogue to flavor.
- Approved (2026-10-06): the fourteen-person register across the Aro, Iren,
  Kel, Vara, Oren, and Nahl households. It combines compatible roles so science, vent
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
courtyard charter and palace restructure were approved on 2026-10-06. Queue: Ohio walkthrough first, then the layout re-fit.

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

## 6. Sky Kingdom Courts

Status: second-pass concept brief (2026-10-06); dimensioned layout approved. See
`docs/architecture/sky_kingdom.md`. The current implementation is a prototype
of four runtime-placed cloud islands with seeded pavilions and six Tempestars,
all revealed only by the Bird Helm.

Planning priorities:

- Approve the six-court, twenty-one-person register, the cuisine, the
  cloud-rooted flora, exchange without merchants, and the leisured culture with
  its costs. The islands and residents are renamed; `sky_kingdom.gd` still uses
  the prototype names until the rebuild.
- Approve the cloud, gold and quartz material system and its gameplay rules
  before any building is designed.
- The hero flies between clouds (Air Gem) and Tempestars float, so islands need
  no bridges; spacing can follow composition and each court's separateness.
- Approved: the dimensioned layout and building programs in
  `docs/architecture/sky_kingdom_layout.md`: an authored frame from a fixed
  staircase landing, Aethra on the arrival axis, the four other courts in a
  ring around Koinon, and every building's footprint and program.
- Review the interiors and cloud planting (`docs/architecture/sky_kingdom_interiors.md`).
- Review the kit of parts and architecture briefs in
  `docs/architecture/sky_kingdom_buildings.md`, then prototype in order: the
  upturned swept roof on its own (fallback: straight floating hip-and-gable
  with raised gold corner finials), the Hall of Mist, and a tholos.

## 7. Boat riding (separate project)

Boats will be rideable. Boat riding is its own project, separate from the
village build, because its controls need their own design. Per the project's
traversal rule it must be a shared `TraversalMode` that every playable
character can drive, not code in one character's script. Until it lands, boats
stay moored or follow scheduled routes, and the village plan already gives each
one an owner, berth and lane.

Planning priorities:

- Design the controls: boarding and leaving, steering, speed, and how a boat
  behaves at berths, swim exits and lane edges.
- Build it as a shared `TraversalMode` wired to every driver, scaled through
  `TraversalContext`, per `docs/traversal_powers_architecture.md`.
- Start from the fishing village's boats and lanes, then Ivo's ferry run to the
  west shore, which could become the village's ordinary arrival route.

## 8. Ocean Kingdom: sea folk city, pirate ships, Kai Mālie and the cage island

Status: first planning pass, in review (2026-10-06). See
`docs/architecture/ocean_kingdom.md` and its three briefs. The current
implementation has the merfolk city with twenty residents, one of the two
pirate ships, and no island village.

Planning priorities:

- Approve the four briefs: the Atlantean-modern sea folk city with air halls,
  glass tunnels, a legged form and renamed residents; the two ships' origins
  and crews; Kai Mālie's community, ahupuaʻa plan and charter, with every
  resident speaking Hawaiian; the cage island and its short tournament (its creatures await the user's
  direction).
- Design the discord the Demon King has sown between the communities and how
  the hero restores harmony.
- Review Kai Mālie's layout (`docs/architecture/ocean_island_village_layout.md`).
  The survey found the island only about 55 m in dry radius, with a steep shore,
  no beach and the dock 83 m offshore, so the layout adds a coastal plain,
  beach, reef flat, taro terraces, a spring and a pier, and enlarges the cage
  island. The sea folk city's layout is in
  `docs/architecture/ocean_sea_folk_city_layout.md` (in review): the castle
  turned to face arrivals, the rings and Ring Current, three air halls, two glass
  tunnels, light pipes, and the existing inn rebuilt as Isaro's guest hall at
  25 Tokoins.
- Review the ship design (`docs/architecture/ocean_pirate_ships_design.md`):
  the *Harbinger* as a sloop-of-war and the *Belle Fortune* as a Dutch fluyt,
  enlarged with decks and rooms for twelve crew each and companion ramps.
- Build a shared **dry volume** system before any hull or air hall: interiors
  register oriented boxes; `LiquidEnvironment` reports no liquid inside them;
  the ocean surface shader discards fragments inside them; the underwater view
  does not switch on inside them. It serves the ships below the waterline and
  the sea folk's air halls and tunnels.
- Then build the second ship and the ships' interiors.
- Give each crew member the watch schedule and work spots in
  `ocean_pirate_ships.md`, section 4, and author two or three wreck sites on the
  seabed for the daily salvage stop.
- The main island becomes an old, eroded 28 m volcano with a windward valley
  holding the taro terraces; the cage island becomes a young crescent crater
  whose rim forms the stands. Review both in the layout and cage briefs.
- Review Kai Mālie's architecture briefs (`docs/architecture/ocean_island_village_buildings.md`).
- Review the sea folk city's architecture briefs (`docs/architecture/ocean_sea_folk_city_buildings.md`).
- Review the planting plan (`docs/architecture/ocean_landscape.md`): Hawaiian
  zonation under north-east trade winds, canoe plants around Kai Mālie, natives
  in the wild, one character per islet, and the new plant builders it needs.
- Review the ocean floor landscape (`docs/architecture/ocean_floor_landscape.md`):
  zonation by depth, fringing reefs, the luminous trail to the city and three
  wreck sites, and the cage island's environment dimensions
  (`ocean_cage_island.md`, section 6).
- Decide how tournament fights work.
- Replace the sea folk's segmented `AquaticTail` with the player mermaid tail's
  design, sized to start at the hips and emerge from them seamlessly, hips in
  the tail's material; in the legged form, hips, legs and feet all in that same
  material. Fish Goblins keep the segmented tail.
- Shared systems: generalise `ChineseLexicon` into a lexicon per language for
  Hawaiian dialogue; let air halls and glass tunnels answer the liquid system
  as dry volumes, reusing the `pressurized_volumes` approach; add a legged sea-folk rig.
- Have every Hawaiian line and gloss reviewed by a fluent speaker.

## 9. Characters: bring every population up to the gendered body rules

Status: not started. The rules (see the `character-design` skill): women's
height tops out lower; only men get the broad-chested build; women's hips are
wider, so their legs are set wider; and women's abdomens never protrude past
the thorax. Audit of every population (2026-10-06):

| Population | State | Fix |
|---|---|---|
| Ohio villagers | gendered height, chest and hip pools | abdomen rule; women's own abdomen pool |
| **Innkeepers (shared `VillageInn`)** | **every keeper is built male**: `apply_profile(keeper, 0, 0, false, ...)` ignores gender, so Mira Holt, a woman, has a male body and a buzzcut even though her profile carries a woman's proportions and a bun | pass each keeper's gender into `VillageInn.create()`; Mira Holt and Isaro (the sea folk keeper) are women; the genders of 林静, Dolma Hearthstone and Ember Rest are not yet stated and need deciding |
| Snow Village | gendered profile | abdomen rule; women's abdomen pool |
| Fire Kingdom | gendered profile | abdomen rule; women's abdomen pool |
| Rock and Ground village | gendered profile | abdomen rule; women's abdomen pool |
| **Chinese village adults** | **not gendered**: gender is picked at random rather than from each villager's identity; one height range for everyone; no chest or hip pools | take gender from the approved identities; apply the gendered pools through a community profile |
| Chinese village children | child chest and hip scales | none |
| Sea folk | fixed women's and men's chest and hips | women shorter than men (both use the same height today); abdomen rule |
| Tempestars | fixed gendered height, chest and hips | abdomen rule |
| **Pirate crews** | **no genders set**: Mara Reef, Nell Crow and Ada Shoal are male-bodied, and Ada has stubble | set every crew member's gender; beards for men only |
| Jungle primates | their own rig | not applicable |

The abdomen rule itself: in `ProceduralFigure`, limit
`ABDOMEN_FRONT_OVERHANG_MAX` (1.12 times the chest's front depth) to men and
keep women's abdomen front flush with the chest.

## 10. Plant Kingdom: the primate village

Status: first full planning pass, in review (2026-10-06). See
`docs/architecture/plant_kingdom_village.md` and
`docs/architecture/plant_kingdom_village_layout.md`. The current village is a
prototype: three giant trees with tiny decks and one villager each, the gate in
the middle, a few roamers.

Planning priorities:

- Approve the community: canopy and floor households, no children because of
  the curse, roles from the residents' own lines, the fruit stall.
- Approve the layout: the commons, a large shared deck at 11.4 m spanning the
  three trees above the gate with the shared amenities; a small ground camp
  with a stable, paddock and gardens; household rings and rope bridges higher
  up; a grand ramp and a 32° public switchback on each tree beside the steep
  climbing ramps.
- Decide the open questions: whether the curse touches apes, whether the
  shadows of the ashed are seen, whether to rename the residents, and whether
  Sun Wu Kong's old seat appears.
- Then building briefs, interiors, planting and dress charters.

