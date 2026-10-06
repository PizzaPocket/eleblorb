# Handoff: Crossroads Fishing Village

Status (2026-10-06): plan, islets, circulation, swim exits and the Mor rest
point are built and verified in the world (`tools/fishing_islet_probe.tscn`, 0
FAIL). The Venn house is the first real building; every other structure is
still an owned placeholder in `floating_village.gd`. Current state and next
steps are in `docs/architecture/settlement_backlog.md`, item 3. The Sen house
brief was redrawn on 2026-10-06 and is ready to build.

How to build the next structure: write or fix its drawings in
`fishing_village_building_designs.md`, add a builder to
`scripts/fishing_buildings.gd` using `StiltKit` and `StiltRoofs`, run
`Godot --headless --path . tools/fishing_building_proof.tscn -- --building=Name`
until it reports 0 FAIL, render it with a window (`--shots=/abs/dir`) and look,
then add it to `FishingBuildings.BUILT`. New `class_name` scripts need one
`Godot --headless --path . --import` before headless runs can see them.

The population is now fixed at fifteen named residents in five households. Do
not generate filler NPCs. The complete census, relationships, buildings, boats
and trade responsibilities are in the architecture brief and `world_bible.md`.

Settled: pearls are ordinary cultivated valuables, and the village is anchored
by two steep limestone islets rising from submerged shoulders (Ko Panyi is the
siting precedent). Boats will be rideable, but boat riding is a separate project
with its own control design and a shared traversal mode for every playable
character; this village build does not wait for it.

## Sequence

Finish the remaining Snow Village visual and walked checks, then plan and build
this settlement. Chinese Village implementation is held afterward; its approved
story brief remains in `docs/handoff_chinese_village.md`.

## Existing implementation

- `scripts/floating_village.gd` owns the current construction.
- `FloatingVillage.CENTER` is `Vector3(440, 0, 0)` and the deck height is tied
  to `Terrain.get_lake_water_level()`.
- `get_portal_anchor()` is consumed by the Crossroads Ocean Kingdom portal.
- The current lake shop uses `ShopCatalog.get_items_for_shop("lake")` and the
  NPC shop category `lake`.
- The current draft's varied terracotta, teal, ochre, violet, coral-red and
  green palette is a visual non-regression requirement. It may be reorganized
  into coherent household and boat palettes, but must not be replaced by a
  uniform brown settlement.
- At least three broad public swim ramps, the shop and the portal deck are
  functional requirements, although their positions may change with the plan.
  Each ramp must finish flush with its deck and descend to about the human
  player's foot height in the normal surface-floating pose. Derive that lower
  elevation from the shared water level and swim pose, not a copied absolute Y
  coordinate, and validate the route with the human, Blorbus and Xiao Hou Zi.

## Survey findings (2026-10-06)

- The present village stands over the deepest water in the basin: 135 m below
  the surface, about 205 m from wading depth on the west shore. Piles there are
  implausible, so the layout adds Anvil Rock and Heron Rock with submerged
  shoulder shelves 2.5 to 4 m deep, and only those shelves take piles.
- No limestone islets exist in the terrain yet. Adding them is the first
  implementation step.
- The world had no prevailing wind; the layout sets a west breeze off the
  plateau so smoke and drying sit downwind on the east edge.
- The current swim ramps use a copied 1.45 m submerged base; the layout gives
  the derived formula instead.

## First implementation task

After the layout is approved, do not start by replacing huts. Add the islets
and shelves to the terrain, then author `FishingVillagePlan` from the layout
plan, containing:

1. fixed and floating structure footprints;
2. public loop, household spurs, work spurs and gangways;
3. open boat lanes, berths, at least three measured swim exits and the portal
   return clearance;
4. the five approved households, their workplaces and communal programs;
5. trade sources and destinations;
6. schedule anchors and protected settlement bounds.

Add a fishing-village mode to `tools/validate_village.gd` before populating the
plan. It should fail overlapping structures, blocked routes, gangways that are
too steep or narrow, boats without clear water approaches, cultivation gear in
swim or portal lanes, unreachable doors, unowned stalls or work structures,
fewer than three public swim exits, or a swim ramp whose submerged end does not
meet a surface-floating human at approximately foot height.

## Standing constraints

- Cosmopolitan and original, not assigned to one real-world race or nation.
- Use George Town's Clan Jetties as the primary built precedent: a working
  timber access spine with branching stilt homes, work sheds and moorings. Do
  not reinterpret this as Singapore shophouse or generic Peranakan design, and
  do not copy the real settlements' surname-clan social organization. Ko
  Panyi informs siting against the limestone islets only.
- Freshwater mussels and clams support local pearl work; do not place unexplained
  marine oyster beds in the lake.
- Preserve the Ocean portal, lake merchant behavior, underwater equipment
  guidance and liquid rendering rules.
- Build the Mor guest houseboat as the settlement's real rest point. Leena
  charges 10 Tokoins through the shared transaction UI; its dormitory wake
  marker and party gathering area must remain aboard the collidable boat.
- Use real functional water architecture: piles, pontoons, flexible gangways,
  moorings, roof drainage and contained sanitation.
- Preserve the current draft's varied color culture. Carry its recognizable
  hues into household fronts, boats, shutters and selected roof or trim accents
  rather than homogenizing the rebuild.
- No anonymous filler huts or decorative boats without owners and uses.
- Final dialogue receives the repository's `no-ai-slop` pass.
