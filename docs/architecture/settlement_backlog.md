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

Done (2026-10-06): `FishingVillagePlan` (`scripts/fishing_village_plan.gd`) holds
the structures, routes, lanes, berths, swim exits, portal gate and trade ledger,
and `VILLAGE=fishing tools/check_village_layout.sh` validates it with 0 failures
(five corrections to the layout are recorded in `fishing_village_layout.md`).
The validator does not yet check the built village; that mode comes with the
build.

Quality audit and first building (2026-10-06, later):

- The plan validator had never actually run: under `--script` it failed to
  compile (autoloads missing) yet exited 0 and printed "0 FAIL". It now runs as
  `tools/validate_fishing_plan.tscn` and reports what it checked (16 structures,
  11 routes, 0 FAIL).
- The islet probe's "hang" was a script error (a Callable compared to a String)
  that stopped it before `quit()`, not the open editor. Fixed, with a watchdog.
  It now passes in the world: islets, decks, swim exits, gangway, the Mor rest
  point (registered, Leena aboard) and Nara.
- `HOUSEHOLD_COLORS` contradicted the briefs (Sen was green, Mor violet); now
  Sen violet, Mor terracotta, shared structures green, as approved.
- **Venn house built** (`FishingBuildings.venn_house()`) from the shared kit
  `StiltKit` (`scripts/stilt_kit.gd`) and `StiltRoofs` (`scripts/stilt_roofs.gd`),
  proved in isolation by `tools/fishing_building_proof.tscn` (0 FAIL) and placed in
  the village in place of its placeholder; Nara sells from the veranda counter.
  Drawing the brief against itself changed it (no loft, counter and store swapped,
  threshold ramp, ring beam 3.3 m); see design brief 4.2.

Next: the Sen house (its brief puts the clinic door in the wrong bay and has no
way to the bedrooms that avoids the clinic; resolve in the drawings first), then
the cistern house, net shed, pavilion and Aran house, each through the proof
scene, then the floating structures. Add each to `FishingBuildings.BUILT`.

Next work:

- Islets built (2026-10-06): `scripts/fishing_islets.gd` makes Anvil Rock and
  Heron Rock, each one body holding its rock stack and its shelf column from the
  lake bed to W - 3.2 m, from the plan's own numbers. The 18 m terrain grid cannot
  hold a shelf, so the shelves are part of the islet bodies, not the height
  field. `tools/fishing_islet_probe.tscn` confirms the collision heights. Not yet
  seen in the engine: check the silhouettes, then add ledge planting.
- **Rework in progress (2026-10-06, after the first walkthrough).** The houses
  and islets first built were placeholders and are being replaced in the proper
  order. Done: the fishing style charter (`docs/style_charters.md`), the floating
  households (Vale houseboat, Rian's barge, Ivo's launch) in the plan and layout,
  architectural design briefs (`fishing_village_building_designs.md`), interior
  briefs (`fishing_village_interiors.md`), and the islets rebuilt as one 1 m-grid
  heightfield mesh with trimesh collision (`scripts/fishing_islets.gd`), not
  SuperEggs. **Not yet verified in the engine** (editor open). Next, once the
  design briefs are approved: build one structure at a time in an isolated scene
  (Venn house first), with real plans, framed openings and interiors, then replace
  the placeholder solids in `floating_village.gd`.
- Circulation built (2026-10-06): `scripts/floating_village.gd` now builds only
  from `FishingVillagePlan`: decks and piles on the shelves, the jetty spine and
  spurs, the houseboat gangway, three derived swim exits, the portal landing with
  the gate turned north-west, owned placeholder houses in household colours, and
  boats at their berths. `tools/fishing_islet_probe.tscn` checks 20 heights and
  the vendor (Nara Venn). Still placeholders: house forms, the houseboat's
  interior and rest point, the pavilion's furnishing.
- Houseboat rest point written (2026-10-06, **not yet run**): the Mor cabin in
  `floating_village.gd` is a walled room with a doorway, three berths, the marine
  toilet, Leena Mor as keeper and a 10 Tokoin rest action, with its wake and
  stand markers aboard. The probe that would check it hung because the editor
  was open; re-run `tools/fishing_islet_probe.tscn` with the editor closed.
- Review the architecture briefs (`docs/architecture/fishing_village_buildings.md`):
  the kit of parts, household palettes and every building's form.
- Then the architectural kit proofs, the
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
  resident speaking Hawaiian; the cage island and its short tournament (its inhabitants are tall
  anthropomorphic mongooses, decided 2026-10-06; their culture, census of
  twelve and the Warren are proposed in `ocean_cage_island.md` section 3).
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

Status: in progress (2026-10-06). Done: the abdomen rule (`feminine_torso` in `ProceduralFigure.build`, fed by `NPC`, `Merfolk` and `Tempestar`), keeper gender through `VillageInn.create(..., keeper_is_female)` for Mira Holt, 林静, Dolma and the sea folk keeper, Chinese adults gendered from their identities with gendered pools, pirate crew genders, and women's shorter sea folk height. Remaining: the Ember Rest keeper (last), a visual check in engine, and the per-profile women's abdomen pools. The audit table below is the pre-fix state. The rules (see the `character-design` skill): women's
height tops out lower; only men get the broad-chested build; women's hips are
wider, so their legs are set wider; and women's abdomens never protrude past
the thorax. Audit of every population (2026-10-06):

| Population | State | Fix |
|---|---|---|
| Ohio villagers | gendered height, chest and hip pools | abdomen rule; women's own abdomen pool |
| **Innkeepers (shared `VillageInn`)** | **every keeper is built male**: `apply_profile(keeper, 0, 0, false, ...)` ignores gender, so Mira Holt, a woman, has a male body and a buzzcut even though her profile carries a woman's proportions and a bun | pass each keeper's gender into `VillageInn.create()`; Mira Holt and Isaro (the sea folk keeper) are women; the genders of 林静 and Dolma Hearthstone are not yet stated and need deciding. Ember Rest is handled last, after every other population update: the Fire City rebuild (item 4) may remove the inn, so do not fix its keeper until then |
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
- Approved 2026-10-06: the inn moves to the commons. Whether the curse touches
  apes and whether the shadows of the ashed are seen are deferred to the
  storyline.
- Landscape and planting plan: `docs/architecture/plant_kingdom_landscape.md`.
- Building briefs approved 2026-10-06: `docs/architecture/plant_kingdom_village_buildings.md`.
- Approve the residents' new names (Malay and Indonesian single names; Ossian
  Redbrow keeps his) and the Water Curtain Cave brief
  (`docs/architecture/plant_kingdom_water_curtain_cave.md`).
- Households, genders and relationships set (proposed 2026-10-06, census in
  `plant_kingdom_village.md`); the building briefs now size every home by
  household, including the empty pavilion of the lost couple.
- Code gap: neither primate rig has a gender. `JungleVillager` and
  `ApeTemplate` need gendered build pools designed in the dress charter
  (character-design skill) before the census genders can show.
- Then interiors and the dress charter.

Code work once approved (not started):

- Done (2026-10-06): the residents are renamed in `scripts/jungle_kingdom_village.gd`
  (both rosters and the innkeeper) and Abu's first line is rewritten.
- End the river at a plunge pool at `x ≈ -640` in
  `scripts/jungle_kingdom_terrain.gd` (coverage, carving and the water sheet),
  and raise the Flower Fruit Mountain plateau to the west.
- Build the cliff, gorge, falls and cave as authored rock geometry with
  `CollisionPolicy`, excluding the terrain under the cave; add the
  mountain-top stream as its own small water volume.
- A world-state switch between the cave's forgotten and reclaimed dressing,
  set by the deferred Sun Wu Kong quest.
- **Jungle density parity with the demo world** (user requirement; backlog
  only, do not start until asked): at least
  5.8 trees and 1.5 emergents per 1,000 m² across the whole kingdom, which today
  has at most 1.2 and 0.3 inside a 420 m disc and nothing beyond it. Requires
  streaming the scatter by seeded 64 m cells and sharing meshes first, so load
  time does not regress; then the emergent-first fill, the 24 to 36 m tall
  tier, the three chained vine routes, and replacing the baobab. The demo
  window must come out the same. See `plant_kingdom_landscape.md` section 2.

## 11. Toilets at every rest point

User rule (2026-10-06), now in the architecture skill: every resting place has
a toilet, true to its culture, with modern fixtures for a modern culture. In
code, every inn already gets one, but it is `TownProps.build_dry_toilet()` for
all of them: the same porcelain pedestal in every culture, including the
open-pavilion treehouse inn.

| Rest point | Culture | Fixture planned | Status |
|---|---|---|---|
| Holt Inn, Ohio | an old English village tradition living in the present day (old-timey town and trades, today's comforts) | modern: the existing **porcelain toilet** in the washroom, with a basin | done; keep as is (user, 2026-10-06) |
| Snowrest Inn, Snow Village | a modern mountain town on a Norse root | modern: flush toilet with cistern, basin and mirror, shower beside the equipment-drying room | code has the porcelain dry toilet; upgrade to a modern washroom |
| Ember Rest, Fire caldera | lava people with advanced thermal engineering; guests only | modern: an **incinerating toilet** in insulated basalt, heated by the city's thermal system, with a cool-water basin for guests | washroom in the brief; fixture to build |
| Rock and Ground inn | Pueblo-style earth and stone | an adobe **privy closet** off the yard: a timber seat over a lined composting vault, ash from the bread oven as cover, a water jar and basin | to add to the brief and code |
| Chinese village inn | classical Chinese, no modern layer (user, 2026-10-06) | a lidded wooden **mǎtǒng** behind a screen in each guest room, and a latrine closet off the back courtyard; night soil to the fields | in `chinese_village.md` |
| Primate village inn, on the commons | jungle lashed-vine | a rattan-screened **privy closet** at the deck's edge: bench seat over a sealed clay vat with leaf litter, lowered by rope to the garden compost | in the layout |
| Sea folk guest hall | Atlantean modern | modern: a **vacuum-flush toilet**, glass basin, shower; sealed holding tank pumped to a treatment vault at the city's edge | in the buildings brief |
| Okafor guest house, Kai Mālie | modern Hawaiian | modern: flush toilets, basins and a shower, upstairs and down; septic tank | in the buildings brief |
| Mor guest houseboat, fishing village | cosmopolitan lake boat people | a contained marine composting toilet and wash space | already in the brief |
| Sky Kingdom | — | no rest point yet; any future one gives guests a washroom in cloud and gold | — |

Done (2026-10-06): `scripts/toilet_fixtures.gd` (`ToiletFixtures.build(kind)`)
builds the earth closet, mǎtǒng, composting seat, vacuum, incinerating and marine
fixtures, and `VillageInn.create(..., fixture)` places the chosen one in the inn's
washroom. Rock and Ground, the Chinese village, the sea folk hall, Ember Rest and
the primate inn now pass theirs. Still to do: the Snowrest Inn's modern washroom
(cistern flush, basin, mirror, shower), a real door-closed closet for the
open-pavilion primate inn, per-culture walls and screens around each fixture
(the mǎtǒng's screen, the privy's yard closet), the Okafor guest house, and the
Mor houseboat's wash space (the `marine` toilet is placed in the houseboat's
south-east corner by `floating_village.gd`; the basin and screen are not).

## 12. Chinese village: palace brief and the sealing rock

- Approved 2026-10-06: `docs/architecture/chinese_village_palace.md`, the
  palace's plan and both states (imperial palace and civic centre) in one
  unchanged shell; and the sealing rock's move from the palace crown to
  Lantern Row (`chinese_village.md` 4.6).
- Done (2026-10-06): the rock is now `SealingRock` (`scripts/sealing_rock.gd`),
  built on island A's north rim at island-local `(0, -15.5)`: about 5 × 3.5 × 3 m,
  moss crown, gold band with six emblems, Mei Lian's red cord, solid collision.
  Sun Wu Kong stands pinned at its north face. Freeing him calls `split()`: the
  halves part once, and a freed save builds them already split with the band
  fallen. The play hut moved to its lee at `(2.5, -10.8)`. The castle-crown
  collision cap is gone. Still to do: the lantern workshop and homes, when the
  Chinese plan is authored, must keep clear of the rock; the children's climbing
  and the changed lines of Mei Lian and the children belong to item 13.

## 13. Story-state changes on revisit (code required)

Several settlements change after story events, and those changes have to be
**coded as triggers**: a story action sets a persistent `WorldState` flag, and
the village reads the flag when it is built. Approved designs describe what
each state looks like; none of the switching exists yet.

Rules for every change:

- **Trigger:** the action that causes it (a fight won, a quest step, a
  handover) sets or advances a `WorldState` flag or counter, saved with the
  game.
- **When it shows:** the village builds the state matching its flags **when the
  player arrives** (each visit or reload), never by swapping props in front of
  the player mid-scene. The one exception is a change the player causes and
  watches (the rock splitting), which plays once and is then built in its new
  state on every later visit.
- **What changes:** props, dressing, doors open or shut, lights, who stands
  where, residents' schedules and their **dialogue lines and actions** (talk
  options, shop or rest actions). Walls, roofs, terraces and routes never
  change between states.
- **Staged changes** (a relationship growing over visits) use a counter of
  visits since the trigger, advanced once per arrival.
- **No text announces a change.** The player notices it.

| Change | Where | Trigger (flag) | What the village builds afterward |
|---|---|---|---|
| Palace becomes the civic centre | Chinese village | `chinese_village_rule_delegated` (exists; Tian Bo made chief) | every room's civic dressing from `chinese_village_palace.md` section 4: gate open, throne gone, village hall benches, communal dining, records and reading rooms, village store, public lookout, open garden; Tian Bo's and the villagers' civic schedules and lines; Liang Zhen in the community kitchen and living in the Chef's old room |
| Liang Zhen and Hua Chen | Chinese village | a new counter of visits since `chinese_village_rule_delegated` | staged: Hua Chen's bao on the kitchen rack, then her apron beside his, then the two of them on the garden bench; their lines advance with each stage |
| The sealing rock splits | Chinese village, Lantern Row | `sun_wu_kong_freed` (exists) | the split halves with the gold band fallen; children climbing them; the children's and Mei Lian's lines about him change |
| The Water Curtain Cave is reclaimed | Plant Kingdom, Flower Fruit Mountain | a new flag (e.g. `sun_wu_kong_seat_reclaimed`), set by the deferred quest that brings Sun Wu Kong back | the cave's reclaimed dressing (`plant_kingdom_water_curtain_cave.md` section 4): ledge cleared, stoves lit, bowls of fruit, new mats, the red-and-gold banner; Sun Wu Kong on his seat when he is not travelling with the party |
| Ossian dismounts | Plant Kingdom village | `manchego_joined` (exists) | Ossian roams as an ordinary resident; his lean-to stays; the stable stands empty or holds Manchego when the party leaves him there |
| The cage becomes a games ground | Ocean Kingdom, cage island | the Ocean Kingdom's reconciliation (flag to be named with its quest) | the grudge board cleared, games gear in the cage, the communities' visitors in the stands, the band's changed lines; the chant stays |
| The Wood Kingdom appears | Plant Kingdom | `ice_kingdom_visited` (exists) | already coded; listed so it follows the same rules |

Future state changes (the courts meeting again after the Air blorbs return,
the Plant Kingdom after the curse lifts, the Ocean Kingdom's communities
reconciled) join this table when their designs are approved.

## 14. Chinese village dress

- Approved 2026-10-06: the dress charter and individual looks (`chinese_village.md` 4.7
  and 4.8): late-imperial commoners' dress, a standing collar with frog
  buttons and edge binding on everyone, short sleeves only as a half-sleeve
  jacket or a vest, never a t-shirt.
- Code once approved: add the garments to the shared figure code
  (`ProceduralFigure` and `npc.gd` flags, as `FigureDress` was): standing
  collar, *dàjīn* and *duìjīn* closures with frog buttons, edge-binding colour,
  below-hip jacket length with side slits, wide sleeves with bound cuffs, the
  vest, apron, sash, pleated skirt, conical straw hat, head wrap and hairpin
  (through `HairOrnaments`). Then a Chinese village profile through
  `VillagerAppearance.apply_profile()` replacing the random `SHIRT_COLORS`
  draw (which includes a yellow the charter excludes), and the per-resident
  looks. Liang Zhen's post-quest look joins the revisit states in item 13.
- Emperor's regalia (approved 2026-10-06): crown board black
  on top and red beneath, twelve strings of jade beads instead of ten
  gold cords, a round-collared robe with gold dragon roundels, a jade hoop belt;
  update the "gold robe" comment in `npc.gd`.

