# Handoff: Crossroads Fishing Village

Status: design brief approved 2026-10-06. No construction has begun and the
`FishingVillagePlan` layout is not yet authored. Read
`docs/architecture/fishing_village.md` first.

The population is now fixed at fifteen named residents in five households. Do
not generate filler NPCs. The complete census, relationships, buildings, boats
and trade responsibilities are in the architecture brief and `world_bible.md`.

Settled: pearls are ordinary cultivated valuables, and the village is anchored
by two steep limestone islets rising from submerged shoulders (Ko Panyi is the
siting precedent). Still open: whether working boats become rideable in this
pass.

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

## First implementation task

Do not start by replacing huts. First survey the lake basin and produce an
authored `FishingVillagePlan` containing:

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
