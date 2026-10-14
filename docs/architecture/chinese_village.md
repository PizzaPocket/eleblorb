# Chinese Village: audit and rebuild proposal

Status: population, backstory, quest resolution and postquest civic use are
approved. The courtyard charter and palace restructure were approved on
2026-10-06. The settlement re-fit in section 4.1 (land budget, island sizes,
households by island, bridges, fields, public space) was revised on 2026-10-12
and awaits approval. Nothing is implemented yet.

Source of truth today is `scripts/chinese_village.gd` (1572 lines, no plan data
file, no validator). Measurements come from `tools/audit_china.tscn` (headless,
prints islands, NPC positions and non-island children relative to the village
centre at world (250, -650)).

## 1. Inventory

Islands (all at one shared surface y, about -61, over the Abyss):

| Island | Local centre | Radius | Contents now |
| --- | --- | --- | --- |
| Palace | (0, 0) | 62 | Four-level golden castle, Royal Kitchen annex at (0, -31), garden, 14 lanterns, 7 trees, Emperor, Chef |
| A | (-105, -58) | 21 | Kids' play hut with the Jingu Bang among loose sticks, 2 scattered houses, 6 kids, 4 adults |
| B | (108, -48) | 20 | Chen's stall, 2 scattered houses, 4 adults |
| Bamboo | (18, 116) | 25 | 34 stalks as multimesh, farmer Tian Bo and Pandy |
| C | (-118, 42) | 18 | 2 houses, no residents |
| D | (112, 48) | 19 | 2 houses, no residents |
| E | (-62, 124) | 17 | 1 house, the inn (keeper now Lu 吕 and his son Lu Hao, 2026-10-12; was 林静), no other residents |

Bridges (flat, 3.2 m wide, one deck and two rails each, no gate or landing):
Palace-A 44 m, Palace-B 44 m, A-C 65 m, B-D 61 m, C-E 67 m, E-Bamboo 42 m, plus
a 225 m sloped entry bridge running due south from the palace to the mainland.

Residents: Emperor, Royal Chef (hostile agent), farmer Tian Bo, Pandy, vendor
Chen, innkeeper Lu (吕) and his son Lu Hao (replacing 林静, 2026-10-12), eight adult villagers (Mei Lian, Wen Zhao, Bo
Xiang, Hua Chen, Jin Wei, Lian Fu, Yun Tao, Shu Mei), six children (Ting, Xiu,
Pei, Rong, Bao). Sun Wu Kong is sealed on the castle crown (moving to Lantern
Row, section 4.6).

Quest chain (must survive any rebuild): Tian Bo's grievance, Liang Zhen's
audience, blorbs shrunk to buns on the kitchen counter, Chef fight without
blorbs, cleaver drop, Liang Zhen restored without an Emperor fight, Tian Bo
made village chief, Pandy joins, palace becomes a civic centre, Liang Zhen
becomes Tian Bo's advisor, and Lu the innkeeper becomes the community chef. Jingu Bang hunt at the play hut, Sun Wu Kong freed
from the sealing rock.

## 2. Measured defects

1. **Entry bridge crosses the bamboo island.** The bridge runs along x = 0. The
   bamboo island is centred at x = 18 with radius 25, so the deck passes over
   its grass between y = 99 and y = 133, through the grove, and the farmer
   stands 18 m from the bridge's line. The approach to the palace, the one
   processional route, is the bamboo island's thoroughfare.
2. **The inn overlaps a house.** The inn is placed at E + (5, -5). A 2x2 house
   stands at E's origin. The inn lodge half width is 8 m on an island of radius
   17, so no placement on E fits both.
3. **Houses have no orientation or siting logic.** `_build_pagoda` rotates each
   house by a random angle and `_pick_building_position` scatters them with an
   RNG. Doors face nothing. C, D and E use hand-typed offsets with the same
   random rotation. No house relates to a bridge landing or a path.
4. **Houses are interchangeable single boxes.** One `TownProps.build_building`
   shell with a gable roof and two stacked ornamental slabs on top. No
   courtyard, no plinth, no hall hierarchy, no distinction between a dwelling,
   a workshop and a shop.
5. **Bridge hierarchy does not exist.** Every bridge is the same width and
   flat. Landings are the island rim with no gate, no paving and no check that
   deck and island share clearance. The entry bridge slopes 225 m down to
   terrain with no gate at either end.
6. **Residents have no population design.** Islands C, D and E hold five houses and no one.
   Adults on A and B wander a disc at random, with no home, no work and no
   schedule. Their dialogue is atmospheric and generic, and does not name a
   trade, a household or the palace.
7. **Chen's stock has no provenance.** He sells Jungle Mushroom, Seed of Life,
   Blorb Slime, Paper Lantern and Steamed Bun. No household on the island
   steams buns or makes lanterns, and the plot has no bean field. Under the
   trade-provenance rule each item needs a maker or a forager in the village.
8. **Bamboo reads as regular poles.** 34 stalks, one radius band (0.05 to 0.09),
   six identical segments each, scattered in a disc with no clumps, no height
   variation by age and no clearings. Leaves sit at fixed offsets.
9. **The palace is a stack of four slabs.** Four shrinking boxes with interior
   ramps. No axis from the gate to the throne, no courtyard sequence, no Chinese
   roof language (hip-and-gable eaves, ridge ornaments, upturned corners). The
   golden colour is also used by the ordinary house trim, so imperial yellow
   is not exclusive.
10. **Kitchen delivery has no route.** The Royal Kitchen is a rear annex joined
    to the throne hall by one doorway. There is no service entrance, no yard
    and no path for deliveries from the bamboo island or the market.
11. **The farmer has no fields.** His grievance is about land, but the bamboo
    island has no beans, terraces or tool shed to make the claim visible.
12. **No plan data and no validator.** Positions are constants and RNG calls in
    the builder, so overlap, facing, landing and traversal checks that Ohio and
    Snow have do not exist for this village.

## 3. Population and backstory (authored first)

The people decide the buildings. Everything below that is not quoted from the
existing lines is a proposal and goes into `docs/world_bible.md` only once
approved.

### 3.1 What the existing text already says (canon to keep)

| Person | Established by their own lines |
| --- | --- |
| Mei Lian | Lanterns burn until midnight and nobody remembers who made that rule. Few visitors come on purpose. |
| Wen Zhao | His grandfather built half the roofs and no two angles match. He has stopped minding the walk to the well. |
| Bo Xiang | Walks the long southern road in good weather to trade (the line said "the town to the south"; geography makes that Ohio, 730 m due south). Has lived in three different village houses. |
| Hua Chen | No gate, no portal, nothing takes you elsewhere. Wind in the eaves unsettled them for years. |
| Jin Wei | Her mother hung the first lanterns on this row. Jin Wei only replaces the paper. |
| Lian Fu | On some nights every window is lit and the village seems awake together. Stopped asking travellers where they come from. |
| Yun Tao | The tile colour was shipped in long ago and nobody nearby can fire it now. Likes the hour before the lanterns are lit. |
| Shu Mei | Lives at the western end of a waste with no end. Has counted the lamp posts many times and never got the same number. |
| Ting | Pigtails, braves the bamboo, nearly. |
| Xiu | Counts every lantern. Her mother forbids going to the bamboo alone. |
| Pei | Races to the well. Catches crickets and lets them go. |
| Rong | Was shown a bean longer than his arm by the peddler. Adults say the roofs ring because of wind. |
| Bao | Wants to build a roof like Wen Zhao's. Collects stones. |
| Chen | Peddler. Beans from behind the bamboo, lanterns, buns, "whatever the road lacks". |
| Tian Bo | The Emperor takes more of his land every year. Pandy has followed him for years. |
| Emperor | Rules the whole valley and the islands. Lets the Chef decide that sternness makes people obey. |

Two things the lines refer to that do not exist in the world: a well, and a
bean field. The south town and the wasteland road exist only as the entry
bridge. These become requirements for the layout.

### 3.2 Settlement history (proposal)

- The islands are the pieces of one plateau that broke away over the Abyss.
  Families came three generations ago (Wen Zhao's grandfather's time), settled
  the pieces and bridged them. The first Emperor's family ruled from the
  largest piece from the start.
- The palace's yellow glaze is the old shipped stock Yun Tao mentions. It was
  reserved for the palace, which is why homes use local grey and green tile and
  why nobody can mend the yellow roofs any more.
- Ohio is the only other settlement in reach, due south across the wasteland.
  Bo Xiang walks there for flour and salt, which the village cannot grow, and
  carries lanterns, beans and bamboo goods back to sell. Ohio's mill (Cob Ferris)
  is where the bun flour begins.
- The Emperor is a hereditary small ruler. The palace's old bargain with the
  village: a modest share of beans, flour and bamboo shoots, in return for
  keeping the bridges and the lamp posts in repair.
- The Royal Chef arrived a few harvests ago with one recipe and rose to the
  Emperor's ear. Since then the Emperor has chased the perfect *rou bao* and
  the share has risen every year. The land taken falls first on the bamboo
  island, where Tian Bo farms.
- Nobody rebels because the palace still keeps the bridges, because the Emperor
  is distracted rather than cruel, and because the village is small and afraid
  of the drop. The Chef's hand in it is not known to anyone.

### 3.3 Households (proposal)

Children are placed in households first, then the adults around them.

| Household | Members (ages are bands) | Work | Tie to the palace | Hidden or unspoken |
| --- | --- | --- | --- | --- |
| Lantern | Mei Lian (elder), her daughter Jin Wei (adult), Xiu (child, Jin Wei's daughter) | Lantern maker and lamp paper | Lanterns for the palace halls, paper changed on set days | Nobody can say who set the midnight rule |
| Tile | Yun Tao (adult), Bao (child) | Tiler, keeps the last yellow glaze | Palace roof repairs | The glaze stock is nearly gone |
| Bao house | Hua Chen (adult, single mother), Ting (child, her daughter) | Bao kitchen and shopfront | Hua Chen has sent bao trials to the palace kitchen, all rejected | She cannot account for Liang Zhen's changing demands |
| Lamp keeper | Lian Fu (adult) | Tends the entry bridge and public lamps; keeps his own small home | Lights and inspects the palace approach | He sees who crosses after dark but does not know the Chef's secret |
| Carrier | Bo Xiang (adult), Rong (child) | Carrier to the south town | Moves the palace's levy flour and beans to the service yard, and the village's goods south | The only resident who regularly leaves |
| West end | Shu Mei (elder), Pei (child, her grandchild) | Waymarker, trims the entry bridge lamps | None directly | Counts posts to stay occupied |
| Roofer | Wen Zhao (adult) | Roofer, finishes his grandfather's work | Palace roof upkeep | Single, the children follow him around |
| Farm | Tian Bo (elder), Pandy | Beans and bamboo shoots | The land levy | Fears for the island's last terraces |
| Inn and restaurant | **Lu (吕)** (adult; given name to choose), proprietor and cook, and his adult son **Lu Hao**, who have run the inn and its restaurant from the beginning; Chen lodges here | Innkeeper, cook and restaurant | Before the quest, none; after it, Lu cooks the village's communal meals | Few guests, mostly Chen's trade and Bo Xiang's contacts; the restaurant feeds the village on market days |
| Stall | Chen (adult) | Peddler and vendor, lives at the inn | Pays nothing, sells only what the village makes | Keeps the village's route open to outsiders |
| Palace | Liang Zhen (Emperor before the quest), the Royal Chef | Rulership and kitchen before the quest; civic centre and community kitchen after it, with Liang Zhen as advisor | The centre of the levy and later the village's shared house | The Chef's secret; Liang Zhen's long-buried good sense |

The five children and their households are the heart of the population, so the
play hut, the well and the island with most children are where the village's
daily noise should sit.

Palace staff: none added for now. Villagers rotate through palace work by trade
(Jin Wei with paper, Lian Fu with night lamps, Yun Tao and Wen Zhao with roofs,
Bo Xiang with deliveries). The near-empty court is part of the Chef's hold over
Liang Zhen. After the quest, Tian Bo holds village business there with Liang Zhen as
his advisor, and Lu cooks the communal meals; neither role requires adding a
palace servant.

### 3.4 Trade provenance for Chen's stall

- Paper Lantern: Mei Lian's workshop. Steamed Bun: Hua Chen's bun house. Seed of
  Life and bamboo shoots: Tian Bo's terraces. Jungle Mushroom: foraged in the
  grove by the children and Tian Bo. Blorb Slime: foraged wild, never made.
- Flour and salt: Ohio's mill, carried by Bo Xiang. Carrier: Bo Xiang for
  anything that crosses the entry bridge, Chen for the stall.

### 3.5 A day (schedule skeleton)

Dawn: steam in the bun house, Tian Bo to the terraces, Bo Xiang to the entry
gate. Morning: workshop and roof work, children to the play hut and well.
Midday: market at the stall, the carrier's loads cross. Afternoon: roof and tile
work, Shu Mei's lamp round on the entry bridge. Dusk: Lian Fu and Jin Wei light
lanterns, children called in. Night: lamps burn until midnight, windows lit, the
inn lamp last. Concrete times and paths go in the plan data.

### 3.6 Civic program the population requires

- Eight dwellings (Lantern, Tile, Bao house, Lamp keeper, Carrier, West end,
  Roofer, Farm)
  with their trade fronts: lantern workshop, bun house shopfront, tile and roof
  yard, carrier's loading frame, farm shed and bean terraces.
- The inn, the market stall, the play hut, a shared well or rain cistern.
- Palace: service yard (levy deliveries and kitchen) separate from the public
  axis.
- Bridges with lamp posts that Shu Mei and Lian Fu actually tend.
- Total eleven or twelve buildings against nine houses now. Re-fitted in
  section 4.1 (2026-10-12): D holds no houses and becomes the village fields.

### 3.7 Dialogue consequence

The present Chinese lines are generic village mood and carry almost no trade,
family or levy. After approval each adult gets four to six lines tied to work,
household and the palace, each child two to three in a child's voice, all in
Chinese and written under the no-ai-slop rules. Nothing may spell out the
quest. The Chef is never named as the cause by an ordinary resident.

### 3.8 Decisions (approved 2026-10-04)

0. (2026-10-06) The village is classical rather than present-day: unlike
   Ohio and Kai Mālie, no modern layer. Dress, fixtures and comforts follow
   older China.

1. The southern town is Ohio, the starting town. The old line named no one, so
   it now names Ohio. Trade is flour and salt in, lanterns and beans out.
2. The history in 3.2 stands (broken plateau, three generations, yellow glaze
   reserved for the palace, Chef a few harvests ago).
3. The innkeeper is **Lu (吕)**, proprietor of the inn and its restaurant,
   who has run it with his son **Lu Hao** from the beginning (revised
   2026-10-12, replacing 林静). Everyone here speaks Chinese.
4. Palace staff: deferred. Nobody is added for now.
5. Still open: villagers other than the Emperor, farmer and Chef still carry
   Latin display names (Mei Lian, Wen Zhao and so on) while their dialogue is
   Chinese. Converting them to characters belongs in the dialogue pass.
6. Emperor Liang Zhen's name is **梁臻**. The hero never fights him. Defeating
   the Royal Chef breaks the Chef's influence and ends the imperial office.
7. Tian Bo becomes village chief, not Emperor. The palace and gardens become a
   civic centre open to everyone, while Tian Bo continues tending the bamboo.
8. Hua Chen is a single mother and the village's bao maker. Lian Fu is a
   separate lamp keeper with his own home. (Revised 2026-10-12: there is
   **no romance** between Liang Zhen and Hua Chen. After the quest Liang Zhen
   becomes **advisor** to Tian Bo, and **Lu** the innkeeper becomes the
   **community chef**.)

### 3.9 Quest and postquest state (approved 2026-10-04)

1. The hero hears Tian Bo's grievance, then seeks an audience with Liang Zhen.
2. Under the Royal Chef's influence, Liang Zhen mistakes the party's blorbs for
   perfect *rou bao*. They are taken to the kitchen, shrink to hand-sized bun
   scale, and the blorb suit is disabled.
3. The hero returns to the kitchen. The Chef reveals himself as an agent of the
   Demon Lord, assumes his demon form and attacks with the Royal Meat Cleaver.
4. The hero defeats the Chef without blorbs. Ordinary traversal, inventory
   items, weapons and non-blorb companions remain available.
5. The Chef drops the Royal Meat Cleaver and retreats to the underworld. Liang
   Zhen is freed from the influence. There is no combat with Liang Zhen.
6. Liang Zhen relinquishes the imperial title. The hero entrusts Tian Bo with
   the village; he becomes village chief and Pandy joins the party.
7. On subsequent visits the palace is a public civic centre. Tian Bo divides
   his time between civic duties and the bamboo grove, with **Liang Zhen as
   his advisor**: the former Emperor knows the levy, the bridges and the
   palace's records better than anyone, and now puts that to the village's use.
   **Lu**, the innkeeper, becomes the **community chef** and cooks the
   village's communal meals (revised 2026-10-12; no romance).

## 4. Layout (provisional, derived from section 3)

### 4.0 The islands: pieces of one broken plateau (proposed, 2026-10-13)

The user found the island arrangement unnatural and inorganic:
- every island is a round disc;
- the islands are set evenly in a ring round the palace;
- every gap and bridge reads alike.

The islands still float, as the world bible has it. A first proposal stood
them on stone pillars, and the user rejected it. This version is in
`tools/chinese_village_gorge.py`, checked, and drawn in
`docs/drawings/chinese_gorge_3d.html` (with a toggle for today's layout).

**How the pieces came to be:**
- **One plateau broke.** It was a rounded mass about 210 m across. The
  palace's island is its biggest remnant, which broke out whole.
- **The rest of the rim shattered round it.** It broke into a ring of smaller
  pieces along jagged fracture lines: long bends with smaller teeth, the same
  fracture field on both sides of a break, so neighbouring broken edges
  still roughly match. Each piece's outer edge is the old rim: rounded and
  weathered. Each is sized to its program's land (4.1.2).
- **The pieces drifted apart.** Each moved out from the palace by its own
  distance, 26 to 52 m, and turned by its own angle, up to 18°. All of them
  swung slightly the same way as they parted, about 20°. No two gaps are
  alike, and the arrangement is not a ring of equal steps.
- **The north piece shattered.** It stood behind the palace. Four bare shards
  are left, floating at their own heights from 26 m below the village to 7 m
  above it. Lantern Row and the market face each other across the gap.
- **Torn undersides.** Each island hangs a rock keel of its own depth, about
  0.9 to 1.4 times its size, banded by its strata. It tapers unevenly to a
  point off its centre: a torn piece of one mass, not a cone.
- **One surface height.** The lived-on islands keep the village's one
  surface height, which the NPC, Pandy and Sun Wu Kong code relies on. Only
  the bare shards float above and below it.
- **A ragged rim** (asked by the user, 2026-10-13). The Abyss is no longer a
  circular pit. Its rim runs 170 to 216 m from the centre, at least 24 m
  clear of every island. It follows the islands round at that distance, is
  smoothed, bitten back in bays where more ground fell away, and roughened
  with the same fracture noise as the islands' broken edges. The entry from
  Ohio comes straight up from the south to where the rim is nearest the gate.

| Island | Centre | Area m² (needs) |
|---|---|---|
| Palace | (-10, -12) | 12,269 (12,076) |
| Gate | (-14, 138) | 1,191 (1,018) |
| E, Inn | (-90, 93) | 2,817 (2,290) |
| C, Roofers | (-131, 11) | 2,244 (1,521) |
| A, Lantern Row | (-99, -80) | 2,713 (1,963) |
| B, Market | (97, -77) | 2,879 (2,290) |
| D, Fields | (117, 40) | 4,531 (3,632) |
| Bamboo, Farm | (43, 105) | 4,092 (3,217) |

| Bridge | Clear span m | Type |
|---|---|---|
| Rim to Gate | 25 | covered timber cantilever |
| Gate to Palace | 57 | iron chain |
| Gate to Inn | 38 | covered timber cantilever (was a chain) |
| Gate to Bamboo | 15 | covered timber cantilever |
| Palace to Lantern | 30 | covered timber cantilever |
| Palace to Market | 44 | iron chain |
| Lantern to Roofers | 32 | covered timber cantilever |
| Roofers to Inn | 35 | covered timber cantilever |
| Market to Fields | 31 | covered timber cantilever |
| Fields to Bamboo | 25 | covered timber cantilever |

**Abutments** (2026-10-14, after the user asked whether every bridge has
logical grounding at the islands' edges). It did not:
- the broken edges met the bridges at a slant, down to 48° instead of
  square;
- where a bridge landed on a notch, its deck's corners hung over air by up
  to 2.9 m (the axis bridge on the gate island's north spur);
- under each island's lip the rock keel slopes away inward, so the covered
  bridges' log brackets were rooted in empty air below the lip.

Now every bridge lands on a squared stone abutment:
- **The bastion.** Its face is square to the bridge, 3 m wider than the
  deck and 5 m deep. Its back half must bear wholly on rock, and it may
  stand out past the lip by no more than 3 m. As built, every one bears on
  rock and none stands out more than 0.1 m.
- **The spur.** Where the torn edge runs out in a spur too narrow to hold
  it, the abutment stands back where the rock is wide, up to 6 m. The
  deck's first metres then rest on the spur. The clear span is measured
  between the rock either side.
- **Built down the cliff.** The masonry runs about 4 m down the cliff face
  and steps back into the rock below. The chains anchor in it through the
  bridge-head houses, and the cantilevers' log brackets are bedded in its
  face.
- **The landings slide.** Each bridge may shift up to 7 m sideways at each
  end to the landing that seats its abutments best. The rim end stays where
  the road from Ohio arrives.
- `tools/chinese_village_gorge.py` checks all of it. Three placements moved
  to clear the new landings: the tile home is 2 m shorter, the carrier's home
  moved 1.5 m east, and the third field strip's west end is 3 m shorter.

**Checks:**
- every island at least its program's land;
- the palace's piece holds its plan with the axis north–south;
- every island at least 20 m in from the ragged rim (24 m as drawn);
- every pair of pieces at least 12 m apart;
- every bridge within its type's span, and over open air only.

The network in 4.1.4 stands. The coordinates in 4.1.3 are superseded by the
table above, and the placements by 4.0a.

### 4.0a Placements on the islands (proposed, 2026-10-13)

Every compound, building, court, field and garden is placed on its island by
`tools/chinese_village_plan.py`, which reads the islands, rim and bridges from
the gorge tool. It is drawn in `docs/drawings/chinese_gorge_3d.html`, which
builds each item by its rank (4.2) in the Shihu Yuan manner (4.2a).
Coordinates are each island's own, from its centroid, `+z` south.

| Island | Placed |
|---|---|
| Gate | the gatehouse (12 × 10, two storeys, the passage through it, Lian Fu above); the arrival forecourt where the four landings meet |
| E, Inn | the inn compound (22 × 28): front court with a brick lattice screen behind the gate, a guest wing on its west; the two-storey hall with its gallery and the one green ridge; a partition with a moon gate between the front and back courts; the back court with the kitchen, latrine closet and water jars; a moon gate in the east wall to the inn's garden court (13 × 13: lotus pond, rockery and waterfall, a grey-tiled hexagonal pavilion, a scholar's rock, a cloud-pruned pine) |
| C, Roofers | Wen Zhao's home; the roof yard (tile and timber stacks, a practice roof frame); Shu Mei's home |
| A, Lantern Row | Sun Wu Kong's rock on the north rim with its lookout; the play hut and yard in its lee; the lantern home and workshop; Yun Tao's tile home (the one wave coping) |
| B, Market | the market square with Chen's stall and the well; the bao house, its shopfront on the square; the carrier's home and loading shed |
| D, Fields | the threshing floor; eight household plots by the market bridge; four field strips with a lane down the west side (1,578 m² as clipped by the island's edge); the field shed; the pits on the east rim |
| Bamboo, Farm | the grove across the north (nine clumps, a path); Tian Bo's home; the shed and Pandy's pen; three bean terraces stepping down to the south, the levy's boundary stones on the top one |
| Palace | as `chinese_village_palace.md` 3, with the Dining Hall turned to 9 × 16 so its long front faces west onto the front court; the garden's covered corridors run along its south side at `z` -37 |

**Checks** (all passing):
- everything 2.5 m in from its island's edge, for the parapet and a walk;
- buildings and compounds at least 1.5 m apart;
- every bridge landing's 6 × 6 m apron clear;
- every opening opens onto ground a person can stand on, or onto its
  building's raised level (below);
- one path network on each island reaches every landing, door, gate, garden
  opening, ramp foot, yard and field (below);
- field strips at least 1,550 m², bean terraces at least 580 m².

**Openings and paths** (revised 2026-10-13, after the user found the paths
coarse and doubted that the ways in and out added up):
- **Openings are data.** Every gate, door, through passage, moon gate,
  octagonal and square opening and window is one list in the plan, and the
  drawing builds its walls from it: 34 passages and 4 windows. Each passage
  must open onto ground or its building's level, never into a wall, a field,
  another building or the drop. Two openings facing each other across a gap
  of under 5 m are joined directly, as courts in sequence.
- **The palace's levels** are checked as a graph: the terrace (4.2 m), the
  inner court and the high pavilion's plinth (5.6 m) and the mound (9.8 m)
  must each be reached by a ramp from the ground.
- **The path network.** A spine 3 m wide joins each island's landings. A
  branch 2.4 m wide joins every passage, ramp foot, yard, field and the
  sealing rock to the nearest point of the network. Fields, plots and pits
  get earth bunds 1.6 m wide. Paths are found on a 0.5 m grid round
  everything solid, kept off walls, then straightened, given a slight wander
  and rounded: 64 paths, about 1,070 m. Paving is stone in the palace and
  between facing gates, trodden earth elsewhere.
- **What the check found, all fixed:**
  - the entry bridge landed 1 m off the gatehouse's passage, so the
    gatehouse and forecourt moved 1 m west;
  - the gatehouse, the gate pavilion and the chain bridges' bridge-head
    houses were drawn closed; each now has an open passage;
  - the bamboo court's moon gate opened into the apartments, so it now faces
    north;
  - the pond court's west opening opened onto the high pavilion's mound, so
    it now faces east;
  - the moon-gate court's and rock garden's facing gates were out of line and
    1.5 m apart, so the rock garden moved 1 m west; the inn's two moon gates
    were 4.5 m out of line and now face each other;
  - the apartments stood 1 m off the inner court above a 5.6 m drop, so they
    moved 1 m east to meet it;
  - nothing led down from the inner court to the garden, so a ramp now runs
    from the plinth, east of the mound, down to the east corridor;
  - both corridors ran blind into the plinth and now end on open ground;
  - the field shed blocked the farm lane and now stands on the threshing
    floor's corner;
  - the bottom field strip could not be reached; its west end is 3 m
    shorter, leaving a bund.

**Parapets** stand 1 m in from every edge, open at the landings: white marble
balustrades round the palace, timber fences round the fields and the farm,
brick with a tile coping elsewhere.

**Not yet drawn:** the ramp from the inner court down to the kitchen (it needs
a section), and the interiors. Eave corners use the brief's fallback, straight
hips with raised tips, until the swept-roof prototype exists.

**For the code (when approved):** each island's outline and keel come from
plan data (`ChinesePlan`) instead of a radius. The keel is built as stacked
rings tapering to an offset tip, with simplified convex collision for the
top. The shards are built bare, with pines.

### 4.1 Settlement re-fit (revised 2026-10-12)

The first sketch (2026-10-06) kept the existing island sizes and only moved
islands. This revision applies what the Ohio, Snow, fishing-village and
Kai Mālie builds taught (see the `settlement-design` skill's lessons): a land
budget before coordinates, structures that could really stand, real edges at
real drops, a public heart, ground for the food the story talks about, and
one plan data source checked both ways.

#### 4.1.1 Survey of what exists (measured from `scripts/chinese_village.gd`)

- Every island is an authored mesh: a flat grass disc whose rim wobbles by up
  to 8% of the radius, over a hanging cone of rock about 0.75 × radius deep.
  Nothing holds it up. All share one surface height, sampled where the entry
  bridge meets the mainland.
- `walk_radius` is 0.82 × radius. A plot has to fit inside the *smallest* rim
  radius (0.92 × radius) less a 2.5 m edge strip for the parapet and a walk.
- The Abyss is full depth (-400 m) out to 170 m from the village centre and
  rises to ordinary ground by 220 m. Every island must stay inside 170 m.
- Bridges are flat plank boxes 3.2 m wide with 0.7 m rails, 42 to 67 m long,
  with no supports, no chains, no cables and no anchorage. Nothing could hold
  them up, and a 0.7 m rail over a 400 m drop is lower than a hip.

#### 4.1.2 Land budget: the islands are too small

Footprints come from the charter (4.2): a home is a three-bay main room
(3 × 3.2 m by 2 × 3.2 m, the engine's building cell) with a court in front
and a side shed, about **11 × 17 m including its yard wall**. Program areas
are summed, 15% is added for lanes, plus a 6 × 6 m apron per bridge landing,
and the total is divided by 0.65, because rectangles packed into a disc waste
about a third of it (0.8 for open fields).

| Island | Program | Needs (m²) | Usable now (m²) | Radius now → new | Usable new (m²) |
|---|---|---|---|---|---|
| A, Lantern Row | Lantern home and workshop (14 × 18), Tile home and stack (12 × 18), play hut and yard (12 × 12), sealing rock and lookout (8 × 10) | 1,330 | 890 | 21 → **25** | 1,320 |
| B, Market | market square with Chen's stall and the well (18 × 18), Bao house with shopfront (12 × 20), Carrier's home and loading shed (12 × 18) | 1,550 | 790 | 20 → **27** | 1,570 |
| C, Roofers | Roofer's home and roof yard (11 × 17 + 10 × 12), West end home (11 × 17) | 930 | 620 | 18 → **22** | 990 |
| D, Fields (new role) | threshing floor (15 × 15), field strips (1,600), eight household vegetable plots (8 × 40), field shed | 2,570 | 700 | 19 → **34** | 2,600 |
| E, Inn | inn with front court, two-storey hall, back court, kitchen, latrine and guest wing (22 × 28), small Shihu-style garden court (150) | 1,470 | 540 | 17 → **27** | 1,570 |
| Gate | bridge-head gatehouse with Lian Fu's lodge upstairs (12 × 10), arrival forecourt (12 × 12), four landings | 640 | 230 | 12 → **18** | 620 |
| Bamboo, Farm | clumping grove (900), Tian Bo's home (11 × 17), shed and Pandy's pen (100), bean terraces (600) | 2,230 | 1,320 | 25 → **32** | 2,280 |
| Palace | per `chinese_village_palace.md` | fits | 9,350 | 62 (unchanged) | 9,350 |

Every island except the palace was short of land, most by about half. With
the old sizes the eight homes, the inn and the market could not be built
with their courts, which is why the existing builder drops single boxes at
random angles. The new radii roughly double the village's land (5,100 m² to
11,000 m²) and keep every island inside the full-depth Abyss (the outermost,
Bamboo, reaches 170 m). The palace still holds nearly half the land, which is
right for the story: the levy is visible in the map.

**Honest compression.** Real households of this size would farm hectares.
Here the fields are a readable token, and the story already says the village
lives by its crafts and buys flour and salt from Ohio. The fields only have to
read as fields, worked by named people.

#### 4.1.3 Island roles and households

| Island | Centre (was) | Radius | Households and places |
|---|---|---|---|
| Palace | (0, 0) | 62 | Liang Zhen and the Chef; after the quest the civic centre, Lu's community kitchen and Liang Zhen's room |
| Gate (new) | (0, 150) | 18 | **Lamp keeper** (Lian Fu) lives above the gatehouse he tends; arrival forecourt |
| E, Inn | (-62, 124) | 27 | **Inn and restaurant** (Lu, Lu Hao, Chen as lodger) |
| B, Market | (108, -48) | 27 | **Bao house** (Hua Chen, Ting), **Carrier** (Bo Xiang, Rong); market square, Chen's stall, the well |
| A, Lantern Row | (-105, -58) | 25 | **Lantern** (Mei Lian, Jin Wei, Xiu), **Tile** (Yun Tao, Bao); play hut; Sun Wu Kong's rock on the north rim |
| C, Roofers | (-118, 42) | 22 | **Roofer** (Wen Zhao), **West end** (Shu Mei, Pei), at the village's western end as her lines say |
| D, Fields | (112, 48) | 34 | no dwelling: field strips, household vegetable plots, threshing floor, field shed |
| Bamboo, Farm | (80, 112) (was (18, 116)) | 32 | **Farm** (Tian Bo, Pandy); grove on the north half, terraces and farmstead on the south |

Eight dwellings plus the inn, each once, each with an owner. The children sit
on three islands (Xiu and Bao on A by the play hut, Ting and Rong on B by the
well, Pei on C), so play crosses bridges. The Carrier is on B because B's
bridge is the palace's service bridge, where the levy goes in.

#### 4.1.4 Network

```
                 A ──chain── Palace ──cantilever (service)── B
                 │              │                            │
               chain          chain (axis, 5 m)            chain
                 │              │                            │
                 C              │                            D (fields)
                 │              │                            │ stone arch
               chain            │                            │
                 │              │                       Bamboo (farm)
                 E ─cantilever─ Gate ─────────chain──────────┘
                                │
                         chain (entry, 5 m)
                                │
                       mainland bridge-head
```

A ring (Gate, E, C, A, Palace, B, D, Bamboo, Gate) with the processional axis
through its middle. Before the quest the palace's west landing (from A) is a
shut garden gate and its service landing (from B) is for deliveries, so the
villagers walk the outer ring; that the palace sits closed in the middle of
their daily routes is the story told by layout. After the quest both palace
gates open and the palace becomes the short cut and the meeting place.

| Bridge | Span (m) | Type | Deck width | Use |
|---|---|---|---|---|
| Entry: mainland to Gate | 59 | iron chain | 5.0 | arrival; Bo Xiang to Ohio |
| Axis: Gate to Palace | 77 | iron chain | 5.0 | processional |
| Gate to E | 26 | covered timber cantilever | 3.2 | visitors to the inn |
| Gate to Bamboo | 43 | iron chain | 2.4 | farm path |
| Palace to A | 41 | iron chain | 3.2 | garden gate (shut before the quest) |
| Palace to B | 37 | covered timber cantilever | 3.2 | service: levy, kitchen deliveries, carts |
| A to C | 58 | iron chain | 3.2 | ring |
| C to E | 55 | iron chain | 3.2 | ring |
| B to D | 41 | iron chain | 3.2 | ring; night soil and produce |
| D to Bamboo | 11.5 | stone arch | 3.2 | ring; the farm pair |

#### 4.1.5 Bridges: what they are and how they stand

Three classical Chinese types, chosen by span, because nothing stands in the
Abyss to carry a pier:

1. **Iron chain bridges** (*tiěsuǒqiáo*), after the Luding Bridge of 1706 in
   Sichuan, which crosses about 100 m with thirteen iron chains: nine under
   the deck and two each side as handrails. Used for every span over 38 m.
   - **Anchorage.** At each end the chains pass into a stone **bridge-head
     house** (*qiáotóu bǎo*) and wrap iron posts set in a masonry block. The
     house is the landing, the gate and the lamp station. Its weight is the
     visible reason the bridge stays up.
   - **Deck.** Cross planks laid on the floor chains, a running board of
     lengthwise planks down the middle, the chain links showing at the edges.
     A 3.2 m deck has nine floor chains, a 5 m deck fourteen.
   - **Sag** about 1/20 of the span, so the deck dips 2 to 4 m and meets each
     landing at about 11°, well inside the 32° ramp limit.
   - **Guard.** Handrail chains at 1.05 m (the current 0.7 m rail is too low
     for a 400 m drop), with a vertical chain or rope every 1.2 m. One
     continuous blocking collider per side fills the gaps, as the current
     builder already does, so no blorb slips through.
   - **Collision** follows the sag as at least eight straight box segments
     with matching ends, so there is no step at a joint. The visible deck and
     the collider are built from the same curve.
   - **Rank.** The axis bridge's chains are lacquered black, its bridge-head
     at the palace end is the yellow-roofed gate pavilion, and lamps stand on
     every bridge-head. Others are plain iron.
2. **Covered timber cantilever bridges** (*shēnbì mùqiáo*, roofed as a
   *lángqiáo*), after the old cantilevered Wo Bridge of Lanzhou and the roofed
   bridges of Fujian and Zhejiang. Used for spans up to 38 m.
   - Layers of logs project in steps from each abutment, each layer further
     out than the one below, their tails weighted down under a masonry
     abutment house. A short beam span closes the gap in the middle.
   - A tiled gallery roof keeps the timber dry. Benches with curved backrests
     (*měirénkào*) line the sides between the posts, so these bridges are
     sitting places as well as routes.
   - The deck rises gently to the middle (no more than 8°). The gallery
     posts, benches and a balustrade below the bench backs form the guard.
3. **Stone arch** (*shígǒngqiáo*), one segmental arch springing from the rock
   lips of D and the Bamboo island, 11.5 m, a humpback with a ramped deck no
   steeper than 15° (classical humpbacks have steps; ours ramp).

Every landing has a paved apron at deck level; the validator checks the deck
end and the apron share a height and that the apron is clear of buildings.

#### 4.1.6 Public space

- **Before the quest:**
  - B's **market square** with the well is the public heart: Chen's stall,
    Hua Chen's shopfront, the children racing to the well, gossip.
  - The **covered bridges** to the inn and to the palace service yard are
    sitting places.
  - The **gate forecourt** is the arrival.
  - The **threshing floor** on D is where the village gathers for the
    harvest and for festivals, and where Mei Lian's lanterns are hung for
    them.
  - The **play yard** on A.
- **After the quest** the palace front court becomes the village square, the
  Dining Hall feeds everyone on meal nights, and the garden is open.

#### 4.1.7 Farmland and the levy, made visible

- **D, the fields:** four long strips of millet, wheat and soybeans laid
  east to west, eight household vegetable plots by the B bridge (one per
  household, each kept differently), the threshing floor, a field shed, a
  compost heap and night-soil pits downwind on the east rim.
- **Bamboo:** Tian Bo's bean terraces stepping down the south half, his
  farmstead, shed and Pandy's pen, and the clumping grove on the north half.
- **The levy:** before the quest a row of palace boundary stones, capped in
  yellow, cuts across Tian Bo's upper terraces, and those terraces lie
  fallow. After the quest the stones are pulled up and stacked by his shed,
  and the terraces are dug again.

#### 4.1.8 Water, waste and edges

- **Water.** The well on B draws from a spring in the island's rock heart,
  which is why B was settled first (proposed lore). Each courtyard also
  collects roof water in a cistern jar. The palace has its own well in the
  service yard.
- **Waste.** Night soil is carried each morning from the homes, the inn's
  latrine and the palace service yard to the pits on D, by the ring.
- **Edges.** The drop is lethal, so every inhabited rim has a 1.05 m grey
  brick parapet with a tile coping (marble balustrade on the palace), open
  only at the landings and at chosen lookouts with their own rail. The fields
  and the farm have a timber fence on a stone kerb. All are blocking
  collision; the parapet top is a ledge the player may choose to stand on.
- **Elevation.** The islands keep their one shared surface height, which the
  NPC, Pandy and Sun Wu Kong ground code depends on. Level change comes from
  built plinths and terraces, as in the palace.

### 4.2 Courtyard and hall charter (homes decided 2026-10-12)

The village reads as three ranks of one tradition, so the palace stands out
by what the common houses lack. Rank shows in material, colour and
ornament, as it did under the sumptuary rules of imperial China:

| | Palace | Inn | Homes, shops, workshops |
|---|---|---|---|
| Walls | vermilion plaster on white marble terraces | the Shihu Yuan mixed wall: grey brick plinth and piers framing white plaster panels | brick only where weather hits: a grey brick plinth and corner piers, the panels between them of earth or rubble finished in white lime plaster (the northern "gold-framed jade" wall, *jīn xiāng yù*) |
| Timber | red lacquer, painted *cǎihuà* beams | red lacquer at the front, painted beams in the common room | plain timber oiled dark brown; doors painted black |
| Roof | yellow glaze, hip and double-eave forms | grey tile with the one green-glazed ridge | grey tile only, hard gable (*yìngshān*) with brick gable ends, an almost straight eave |
| Eave brackets | full bracket sets (*dǒugǒng*) | simple carved brackets | none; rafters show at the eave |
| Ceilings | painted beams, lacquered joists | painted beams below, lacquered joists above | plain exposed rafters and purlins, darkened by smoke |
| Openings | moon gates, round lattice windows | moon gate to the back court, brick lattice screen to the yard | rectangular lattice windows papered on the inside; at most one small round or square opening in a yard wall |
| Yard wall coping | wave tile | wave tile | plain grey tile ridge |

- **Homes.** A south-facing main room of three bays on its plinth, door in
  the middle bay onto a small walled court, a side room or shed on the east
  or west of the court. The heart of the main room is a **kang**, the heated
  brick sleeping platform of northern China, warmed by the flue of the
  cooking stove beside it: the family sits, eats and sleeps on it. Colour
  comes from the people, not the building: red couplet paper either side of
  the door (pattern only, no readable text), a household's own lanterns,
  drying chillies or corn on the eaves, a blue cloth door curtain.
- **One house a little better.** Yun Tao the tiler has laid his own roof
  better than anyone's, with a short run of wave coping on his yard wall
  that he made from the palace's broken tiles. It is the one home with a
  patterned coping.
- Shops and workshops: the same vocabulary, open front on a timber shopfront,
  ridge ornaments omitted.
- The inn: two-storey hall with gallery, red lacquer sign, the one ordinary
  building allowed a green-glazed ridge. Sanitation is traditional: a lidded
  wooden commode (*mǎtǒng*) behind a screen in each guest room, and a latrine
  closet off the back courtyard with a door, a bench seat over a removable vat
  and a water jar and basin for washing hands. Night soil is collected each
  morning and carried to the village fields, as Chinese villages did.
- Palace: imperial yellow glazed tile, double-eave hip roof, white marble
  terraces, vermilion walls. Yellow is not used anywhere else.
- Everything built from SuperEgg parts, with `CollisionPolicy` on plinths,
  walls, terraces and screens. Fine bracket detail is decorative.

### 4.2a Precedent: Shihu Yuan (十笏园), Weifang (added 2026-10-12)

The user visited Shihu Yuan in Weifang, Shandong, and brought back thirteen
photographs. Shihu Yuan is a small classical garden and residence of the late
Qing. Its name means "ten tablets", a way of saying it is tiny, and it is known
for fitting a great deal of garden into very little ground. That suits a
village of small islands. The photographs show the elements below, and each is
given the place it will be used.

**Character.** Northern rather than southern: grey brick, grey tile,
restrained roof curves and plain timber, with colour kept for the beams,
columns and railings. Gentle eave curves are also far easier to build from
SuperEgg slabs than Suzhou's sharp upturned corners.

**Walls.** The photographs show a mixed wall, not all brick and not all
plaster:
- a grey brick plinth (a dado about 0.9 m high) under every wall;
- grey brick piers at the corners and openings, framing white plaster panels
  between them;
- a grey tile coping along the top of yard walls, laid in wave or scalloped
  patterns;
- brick lattice screen walls, where bricks are laid with gaps in a pattern so
  the wall lets air and glimpses through. These are used for the inn's
  courtyard and the yard walls between neighbours.

Build: the plinth, piers and coping are squarish SuperEgg slabs with blocking
collision. A lattice screen is one blocking box collider with a decorative
mesh of bricks and gaps, so the player cannot snag in the holes. A wave coping
is decorative trim on top of the wall's collider.

**Gates and openings.** Round and square shapes set into the plaster:
- **Moon gates** (*yuèdòngmén*), full circles about 2.2 m across with a level
  threshold cut into the bottom of the circle, so the floor runs through at
  ground level and the gate is a step-free route (as the ramp convention
  requires). Used at the royal garden's moon-gate court (4.4), between the inn
  courtyard and its back court, and as the palace garden's entrance.
- **Square and octagonal openings** with green-painted frames, set at sill
  height as windows or at floor level as doorless passages in a garden wall.
- **Round lattice windows** (*lòuchuāng*) about 1 m across, filled with
  geometric or plant-pattern lattice, so each court shows a glimpse of the
  next.
- Doorways keep their framed superellipse opening and hung leaf (architecture
  skill); moon gates and garden openings are doorless passages and are the
  exception, as they are in Shihu Yuan.

Build: every opening is a CSG Boolean cut through the wall's SolidModel, so
the hole and its collider match. Frames are a ring or square of squarish
SuperEgg trim.

**Ceilings and structure.** Two kinds appear, and both stay visible rather
than being hidden behind a flat ceiling:
- **Painted beams** (*cǎihuà*) in the open halls and corridors: green and blue
  patterned beams under exposed round rafters and the underside of the tiles.
  Used in the covered corridors, the garden pavilions, the inn's common room
  and the palace's public halls.
- **Lacquered beam-and-joist ceilings** in upper rooms: dark red-brown beams
  carrying close-set round joists and floorboards. Used in the inn's upper
  floor, the homes' lofts and the palace apartments.

Build: beams are squarish SuperEggs, rafters and joists round ones in rows
from one shared mesh. All are decorative except where a beam is low enough to
be walked into, and nothing hangs below the 2.2 m headroom.

**The stair through the ceiling.** The photographs show a steep wooden stair
rising straight into a rectangular opening in the beamed ceiling above. Our
levels use ramps, not stairs. The translation is:
- a ramp of 32° or less, with landings of 1.2 m or more, along one wall;
- it rises through a superellipse opening in the upper floor, framed by the
  joists the way the photo's stair hole is, with a railing on the open sides
  upstairs;
- the opening is long enough that a character walking up the ramp keeps
  2.2 m of headroom the whole way.

Used in the inn (to its upper floor), and any two-storey home or palace
apartment.

**Interiors.** Furniture and lamps from the photographs, assigned by room:

| Item | Where |
|---|---|
| Silk lantern lamps on carved wooden stands (desk and table lamps) | the inn's tables, Mei Lian's workroom, the palace records room and Liang Zhen's desk |
| Carved hexagonal palace lanterns with red tassels, hung from beams | the palace halls, the inn's common room (one over the counter) |
| Canopy bed (*jiàzichuáng*) with curtains | the palace apartments; one guest room at the inn; elders' bedrooms |
| Yoke-back armchairs (*guānmàoyǐ*) in pairs | the palace audience hall and records room; the inn's best table; the chief's receiving room after the quest |
| Square tables (*bāxiānzhuō*, "eight immortals" tables) with benches or stools | the inn's common room; every home's main room |
| Curio shelves (*duōbǎogé*) of irregular compartments | the palace records room; Liang Zhen's quarters; Mei Lian's house |
| Couplet boards (*duìlián*) either side of a door or hearth | painted as pattern only, never readable text (no text in the world) |
| Lattice windows with cloth curtains and a fringed valance | bedrooms and the inn's guest rooms |
| Grey brick dado inside, plaster above | main rooms of homes and the inn |

**Garden.** The heart of Shihu Yuan, and the model for the royal garden
(4.4) and, at smaller scale, the inn's courtyard:
- a lotus pond with a shelving stone edge, a small bridge, and a pavilion at
  the water;
- a rockery (*jiǎshān*) of piled weathered stone with a small waterfall into
  the pond, and a path that climbs it (a parkour landing on top);
- small hexagonal pavilions with green columns and red railings;
- cloud-pruned pines (*yúnsōng*) beside the pavilions and gates;
- scholar's rocks (*gōngshí*) standing alone on carved stone plinths;
- paving in hexagonal stone and in pebble mosaic along the paths;
- covered corridors (*yóuláng*) along the walls linking one court to the next.

Collision: the rockery, plinths, pavilion floors and railings are solid (the
rockery top and pavilion roofs as parkour landings); the waterfall and the
pond surface use the hazard/liquid surface API; pine foliage tips are
decorative with solid trunks.

**Courts in sequence.** Shihu Yuan is a chain of small courts entered one
from another. The inn (front court, common room, back court) and the palace
garden follow that chain; homes keep one court each.

**Who gets what.** The full Shihu Yuan vocabulary belongs to the palace and
its garden, and in part to the inn, which has earned it over its long life.
Ordinary homes take only its plainest parts (the brick plinth and piers, grey
tile, lattice windows); see the rank table in 4.2. Decided 2026-10-12.

### 4.3 Palace

- A south gate and processional paved axis from the gate island.
- Public sequence on the axis: gate court, audience hall (ground floor), steps
  to the throne terrace, throne hall. The existing four stepped levels become
  terraces with roofed halls instead of flat slabs.
- Service circulation on the east side: a service yard with its own bridge
  landing from B, the Royal Kitchen at its end, a store and a well. The Chef
  fight room keeps a clear, generous floor.
- Before the quest, private and administrative rooms sit behind the throne
  hall on the west side. Their structure must support conversion after the
  quest into meeting rooms, records storage and public gathering space rather
  than remaining an imperial apartment.
- The Royal Kitchen must support two states without rebuilding its shell: the
  Chef encounter with a clear fight floor and captive-blorb counter, then
  Lu's welcoming community kitchen with communal preparation and meal
  service.
- Sun Wu Kong's sealing rock leaves the palace (section 4.6). Full brief for
  both the imperial and the civic state: `chinese_village_palace.md`.

### 4.4 Royal garden

Four framed views along the axis: a moon-gate court with a pomegranate tree, a
pond with a zigzag bridge and a pavilion, a rock garden of weathered stones, a
bamboo screen and bench court. Stone paths link them, with one pause each.
The garden is built in the Shihu Yuan manner (4.2a): the pond gains a rockery
and waterfall and a hexagonal pavilion, the courts are joined by covered
corridors and moon gates, and scholar's rocks and cloud-pruned pines mark the
pauses.

### 4.5 Bamboo

Clumping groves: 6 to 10 clumps of 5 to 12 culms each, culm height 7 to 14 m
by age, radius 0.04 to 0.1 m, slight lean away from clump centre, nodes
closer together near the base, branching and leaf sprays only in the upper
third, small young shoots at clump edges. A path, two clearings (the
farmer's and a resting spot) and sparse understory.

### 4.6 Sun Wu Kong's sealing rock (kept for now, 2026-10-12)

**Kept for now.** The user raised that a rock is where he was born (the split
stone egg on Flower Fruit Mountain), then chose to keep the rock for now and
work out his lore further later. The alternatives below are parked for that
conversation. The 2026-10-06 version below them stands; its placement (north rim of Lantern Row, the play hut in its lee, the
Jingu Bang among the sticks, Mei Lian's red cord) can carry over to whatever
the prison becomes.

What the prison must do: be made by the sky courts; hold him where the
children can talk to him; be openable only by one of his own monkeys
(Xiao Hou Zi); and leave something visible behind once he is free.

Parked alternatives, each with a root in *Journey to the West*:

1. **The golden cymbals.** In the novel (chapter 65) a demon
   traps him between a pair of golden cymbals clapped shut, and he can only
   be freed by prying them apart from outside. Here the Chrysa, the courts'
   goldsmiths, forged a pair of giant gold cymbals and clapped him between
   them. They sit on the rim like a closed bronze-gold shell, tarnished green,
   ringing faintly in the wind (Rong's "the roofs ring because of wind"). The
   children talk to "the singing bell"; his voice comes from inside. Xiao Hou
   Zi pries them apart; after, the two halves lie open and the children use
   them as a slide and a drum. Made of sky gold, which ties it to the
   courts' decree and gold band.
2. **A sealing pagoda** (*zhènyāo tǎ*). Heaven's pagoda-bearing king subdues
   demons with a pagoda in the novel, and the White Snake is sealed under
   Leifeng Pagoda in another legend. A small, ancient, many-eaved pagoda the
   villagers never built stands on the rim; he looks out of a lattice window
   on its ground floor. Strong silhouette, but the village is already full
   of roofs, and the pagoda belongs to a different legend.
3. **A storm cage.** The weather-shapers bound him in a knot of set
   thundercloud and frozen lightning on the rim, still crackling. Very much
   the Tempestars' own work, but a cloud on the ground over a monster-filled
   Abyss may read as something else.

In the novel the Buddha does pin him under a mountain (Five Elements
Mountain). Our version drops that, because our Sun Wu Kong's birth from
stone makes a stone prison read as a homecoming rather than a punishment.

#### The 2026-10-06 version (current)


The rock is older than the palace, older than the village, and older than the
plateau's breaking. The courts sealed him under it long ago, when the islands
were still one high plateau. When the first families settled three generations
ago, the rock was already there, grown over with moss, and they built round it.
A crown of a palace roof was the wrong place for it.

- **Where:** on the north rim of island A, Lantern Row, facing out over the
  Abyss, clear of the bridge landings, the lantern workshop's yard and the two
  homes' doors.
- **What:** a weathered grey boulder about 5 × 3.5 m and 3 m high, half sunk
  in the turf, with moss and grass on its top. Sun Wu Kong is pinned beneath its
  overhang with his head and shoulders free, as in his legend. The courts' seal
  is a thin gold band bound round the rock, with six small abstract emblems
  for the six courts and no lettering.
- **The play hut** stands in the rock's lee. The children built it there
  because he is the best company on the islands. The Jingu Bang lies among the
  hut's loose sticks, where it fell when he was sealed, and nobody has noticed
  it.
- **The adults** leave the rock alone. Mei Lian, the lantern maker, ties a
  fresh red cord round it each New Year, a habit from her grandmother that
  nobody explains.
- **When he is freed,** the rock splits in two and the gold band falls. The
  halves stay where they fell, and the children climb on them.

### 4.7 Dress charter (approved 2026-10-06)

The village is classical, not present-day (3.8, decision 0), so its people wear
**late-imperial Chinese commoners' dress**, the everyday clothes of Ming and
Qing villages: jackets with **standing collars** (the "Mandarin" collar,
*lìlǐng*), trousers, skirts, sashes and cloth shoes. That period also fits the
Emperor's tasselled crown and the courtyard architecture.

**Environment.** A mild, breezy island climate over the Abyss: light layers,
nothing heavy, sleeves rolled or short for hot work. The carriers, roofers and
farmer work outdoors, so straw hats and tied-in trouser legs belong to them.

**What makes a garment read as period and never as a modern t-shirt.** Every
upper garment has all of these:
- a **standing collar**: a band about 3 to 4 cm high round the neck;
- a **front closure with knotted cloth buttons** (*pánkòu*, "frog" buttons).
  It is either the side-fastening *dàjīn*, a diagonal edge from the collar to
  under the right arm, or the centre-front *duìjīn*;
- **contrasting edge binding** (*xiāngbiān*) along the collar, the front edge,
  the cuffs and the hem;
- **length below the hip**, with side slits at the hem;
- **wide, straight-cut sleeves.**

**Short sleeves** are allowed, and keep all of the above. They come in two
forms:
- the **half-sleeve jacket** (*bànbì*): wide elbow-length sleeves with a bound
  cuff;
- the **sleeveless vest** (*kǎnjiān*) worn over a long-sleeved jacket, or alone
  over bare arms for heavy work.

A fitted, collarless, hip-length, narrow-sleeved shirt is the one thing never
worn.

**Sources and garments**

| Garment | Term | Who |
|---|---|---|
| Short work jacket and trousers | *duǎndǎ* | working men and women: carrier, roofer, tiler, farmer, lamp keeper |
| Side-fastening jacket | *ǎo*, over trousers (*ǎokù*) or a skirt (*ǎoqún*) | women's everyday wear |
| Pleated panel skirt | *mǎmiànqún* | women on festival days and at the inn; elders |
| Long gown | *chángshān* | older men, the village chief on civic days, the peddler on the road |
| Half-sleeve jacket | *bànbì* | anyone in hot work: the bao kitchen, the roofer on the ridge |
| Sleeveless vest | *kǎnjiān* | over a jacket for elders and the cool evening; alone for heavy work |
| Work apron | *wéiqún* | Hua Chen, Lu and Lu Hao |
| Waist sash | | every jacket worn open or for work |
| Cloth shoes | *bùxié*: black uppers, thick white soles | everyone |
| Conical straw hat | *dǒulì* | the farmer, the carrier, the roofer outdoors |

**Skin and hair.** The village's four East Asian skin tones and black to dark
brown hair, unchanged. Greying and white hair for the elders.

**Hair kit.**
- **Men:** a topknot (the existing bun) under a small cloth wrap (*tóujīn*),
  which was the commoner men's style of the period; the farmer stays bald.
- **Women:** buns held with a wooden or silver hairpin (*zān*).
- **Girls:** pigtails or twin buns. **Boys:** a small topknot or a short
  crop.

**Palette**, tied to the village's architecture: white plaster, red lacquer,
grey and green tile.
- 60 percent: **indigo-dyed cotton** (*lánbù*), from light blue-grey to deep
  indigo, and black.
- 30 percent: undyed natural off-white hemp, grey, warm brown and a muted tile
  green.
- 10 percent: lacquer red and jade green, in edge binding, sashes and
  festival skirts.
- **Imperial yellow is never worn by anyone**, as it is never used on any
  building but the palace.

**Signature item:** the standing collar with knotted buttons and contrasting
edge binding, on every person in the village.

**Hierarchy.**
- **Emperor Liang Zhen:** his regalia (the red robe with gold trim, the
  twelve-stringed crown, full boots; see the sense check below). After the
  quest he gives these up for an **advisor's** plain deep-grey *chángshān*
  (long gown) with a black *kǎnjiān* over it and a plain topknot wrap, and the
  crown stays on its stand in the palace (revised 2026-10-12).
- **The Royal Chef:** keeps his existing pale uniform and toque. A foreign,
  court-kitchen look that sits slightly apart from the village is right for
  the Demon Lord's agent.
- **Tian Bo:** a farmer's straw hat and short jacket. As chief, he wears a
  plain *chángshān* only on civic days in the village hall.

**The Emperor's regalia: sense check (approved 2026-10-06, twelve strings).** Checked
against what late-imperial emperors and princes actually wore. What is built
today (`npc.gd`, `_add_emperor_regalia`; the world bible): a red square crown
with ten gold cords front and back, a red robe with gold trim, black boots, a
high bun and a long beard.

| Element | Today | Historically | Recommendation |
|---|---|---|---|
| Crown type | a flat-topped *miǎnguān* | right: the board-topped crown with hanging bead strings is the emperor's highest crown | keep: it is his silhouette |
| Crown colour | red all over | the board (*yán*) is **black on top, red underneath** | black top, red underside and edge |
| Strands | ten gold cords at front and back | strings of **jade beads** (*liú*), **twelve** at front and back for an emperor; nine for a prince; no rank wore ten | **twelve** strings of white-and-coloured jade beads (approved) |
| Robe colour | red | defensible: Song emperors held court in crimson, and Ming princes wore red dragon robes. Yellow was the Ming and Qing emperors' colour | keep red; the yellow stays on his palace roofs, where it already says "emperor" |
| Collar | the generic shirt | the dragon robe has a **round collar** (*pánlǐng*) fastening at the right shoulder | a round collar: it sets him apart from the village's standing collars |
| Motifs | gold trim | **gold dragon roundels** on the chest, back and shoulders | add the roundels; dragons appear only on his robe and the throne screen |
| Belt | none | the **jade belt** (*yùdài*): a stiff hoop of jade plaques worn loose at the waist, the mark of rank | add it |
| Boots | black full boots | black court boots (*zàoxuē*) | correct |
| Hair and beard | a high bun, a long beard | a topknot under the crown; beards were usual | correct |

One liberty stays on purpose: historically the *miǎnguān* was worn only for
the gravest rites, with its own black-and-red ceremonial robes, while daily
audiences used a black winged cap (*yìshànguān*). The game keeps the
*miǎnguān* every day, because it reads at once as "emperor".

The project's notes also disagree on his robe: the world bible says red, but
the character-design skill and a code comment say gold. It is red.

**Exclusions.**
- **No t-shirts,** and no fitted modern cuts.
- **No qipao.** It is a twentieth-century city dress.
- **No Qing queue.** The shaved-forehead braid was imposed by conquest and
  carries that history.
- **No imperial yellow, and no dragon or phoenix motifs,** which were reserved
  for the court; the Emperor's dragon roundels and the throne screen are the
  only dragons.
- **No Japanese or Korean garments** (kimono, hanbok) and no costume-shop
  "Hanfu".
- **No modern sneakers.**

### 4.8 Individual looks (approved 2026-10-06)

| Resident | Look |
|---|---|
| **Liang Zhen** (Emperor) | regalia as built; after the quest, the advisor's plain grey gown above |
| **The Royal Chef** | as built |
| **Tian Bo** (farmer, elder, later chief) | bald; *dǒulì*; a muted-green short jacket with brown edge binding, rolled sleeves, trousers tied at the ankle; a *chángshān* in grey on civic days |
| **Lu (吕)** (innkeeper and cook) | an indigo *duǎndǎ* with sleeves bound back, a long white apron, a cloth over one shoulder; a topknot wrap |
| **Lu Hao** (his adult son) | a light-indigo short jacket with red edge binding, the inn's colour; a serving cloth at his sash; a small topknot |
| **Chen** (peddler) | a travelling *chángshān* in brown, hitched up by a sash; a pack frame; a cloth head wrap |
| **Mei Lian** (lantern maker, elder) | a black *kǎnjiān* over a grey long-sleeved *ǎo*; a red-paper smudge on her sleeve; grey bun with a wooden pin |
| **Jin Wei** (her daughter) | a light-indigo *ǎo* with jade binding, trousers; sleeves bound back with a cord for lantern work |
| **Xiu** (child) | a small red *ǎo* (the household's lantern red); twin buns |
| **Yun Tao** (tiler) | a natural-hemp *bànbì* half-sleeve jacket, dark trousers, a tile-green sash; topknot wrap |
| **Bao** (child) | a short indigo jacket and trousers; a small topknot |
| **Hua Chen** (bao maker) | a white *bànbì* with indigo binding, flour on the apron; a bun tucked under a kerchief |
| **Ting** (child) | a light-blue *ǎo*; pigtails (as now) |
| **Lian Fu** (lamp keeper) | a deep-indigo *duǎndǎ* with long sleeves, a lamp hook at his sash |
| **Bo Xiang** (carrier) | a sleeveless natural *kǎnjiān* over bare arms, black trousers tied at the ankle, a *dǒulì*; a carrying pole |
| **Rong** (child) | a brown short jacket; a small topknot |
| **Shu Mei** (waymarker, elder) | a grey long *ǎo* to the knee over trousers, a black *kǎnjiān*; white hair in a low bun |
| **Pei** (child) | a jade-green *ǎo*; pigtails |
| **Wen Zhao** (roofer) | a brown *bànbì*, trousers rolled to the calf, a *dǒulì* pushed back on his shoulders |

Households share one colour (the Lantern household its red, the Tile household
its tile green), and no two neighbours match.

## 5. Build order after approval

0. Approve and record the population (section 3), then update the world bible.
1. `ChinesePlan` data file (islands, bridges, gates, houses with doors and
   facing, strokes, residents, schedules, ledger) and extend
   `tools/validate_village.gd` to read it: overlaps, facing, door-front paths,
   bridge landing height and clearance, ledger, schedules.
2. Prototype the three bridge types in isolation first (chain deck with sag
   and segmented collision, timber cantilever with its gallery, stone arch),
   per the settlement skill's rule on unfamiliar systems. Then the island and
   bridge rebuild: new radii, the gate island, the relocated bamboo island,
   bridge-head houses and rim parapets.
3. Courtyard homes, workshops, inn.
4. Palace axis, service yard, kitchen route, garden.
5. Bamboo groves.
6. Residents, homes, schedules, quest-state placements and rewritten Chinese
   dialogue, including Liang Zhen's postquest lines as advisor and Lu's as
   community chef.
7. Traversal validation for the player, Blorbus and a mount on every
   bridge, landing, residence entrance, palace level and kitchen door.
8. Visual audit by aerial and eye-level capture.

## 6. Decisions needed

**Fixed:** population and story state (3.8, 3.9); the courtyard charter by
rank (4.2); the palace's two states; Liang Zhen's room.

**Proposed (2026-10-12), for approval:**
1. The new island radii and the two moves (Gate to (0, 150), Bamboo to
   (80, 112)) in 4.1.2 and 4.1.3.
2. The households by island in 4.1.3, with D as the fields.
3. The ring network and bridge types in 4.1.4 and 4.1.5.
4. Public spaces, farmland and the levy stones (4.1.6, 4.1.7).
5. The spring well on B, the parapets and the shared surface height (4.1.8).

**Open:** Lu's given name and Lu Hao's characters (the user will supply).
