# Chinese Village: audit and rebuild proposal

Status: population, backstory, quest resolution and postquest civic use are
approved. The layout re-fit in section 4, with its courtyard charter and palace
restructure, was approved on 2026-10-06 but is not yet implemented. No building has moved for this pass.

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
- Total eleven or twelve buildings against nine houses now. The layout in section 4
  is to be re-fitted to this, including how many houses D should hold.

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

### 4.1 Island roles and network

Island roles below are a first guess from the buildings. They are to be
re-fitted to the households and civic program in section 3.6 once that is
approved. The first sketch keeps the seven islands and the Abyss, adds one small
gate island and reroutes the bamboo island so the palace approach is a clear
axis.

```
                 Palace (0,0)
                    |  axial bridge, 44 m
 A -- C             |             B -- D
                    |
        E (inn) --- Gate (0,170) --- Bamboo (95,125)
                    |
              entry bridge to mainland
```

- **Gate island** (new, radius 12, centre (0, 170)): a roofed bridge gate, a
  notice post and a lantern pair. The entry bridge lands here. Forks lead to E,
  to the bamboo island and straight north to the palace's south door.
- **E, the guest island:** inn, a small tea stall, the one landing a visitor
  sees first on the left.
- **Bamboo island moved to (95, 125):** off the axis, reached from the gate
  island and from D. It becomes the working island: bean terraces, a tool shed,
  the farmer's cottage and Pandy's pen on the south half, the clumping grove on
  the north half with a path through it.
- **A, Lantern Row:** lantern workshop, two homes, the play hut stays, and
  Sun Wu Kong's sealing rock on the island's north rim (section 4.6).
- **B, Market Island:** Chen's stall, Hua Chen's bao house and shopfront, two
  homes. Lian Fu's home must be assigned separately, close enough to the entry
  bridge for his lamp round to read clearly.
- **C and D, residential:** two courtyard homes each. C holds the roofer's
  yard.
- **Palace island:** axial complex (section 4.3) with a service yard.

Bridge hierarchy: entry and palace axis 5 m wide with gate posts, island to
island 3.2 m, farm and grove path 2.4 m. Every landing gets a paved apron and
paired deck and apron heights that the validator checks.

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

### 4.6 Sun Wu Kong's sealing rock (approved 2026-10-06)

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
2. Island and bridge rebuild (gate island, relocated bamboo island, hierarchy).
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

1. Population and story state are approved (sections 3.8 and 3.9). Next
   decision: the layout re-fit to them.
2. After that: the gate island and bamboo island move, the courtyard charter
   (4.2), and the palace restructure (4.3), which moves the Royal Kitchen
   entrance and adds a service yard.
