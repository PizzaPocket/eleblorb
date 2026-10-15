# Plant Kingdom: Primate Village Architecture Briefs

Status: building briefs approved (2026-10-06); audited 2026-10-07 against the
architecture skill's brief audit (commons capacity, inn depth and plan, ring
walkways, headroom, roof construction). Read with
`plant_kingdom_village.md` (community and charter), `plant_kingdom_village_layout.md`
(layout) and `plant_kingdom_landscape.md` (planting). Positions, owners and
footprints come from the layout.

## 1. Kit of parts

### Charter

- **Primary, about 70 percent: canopy vernacular built by primates.** It grows
  from the prototype's open treehouse: an open platform, a central timber
  pillar, open sides and a broad leaf roof. It becomes:
  - wrap-around decks lashed to living trunks;
  - open pavilions on those decks;
  - hammock nests;
  - rope-and-plank bridges.
  
  The structural precedents are the high treehouses of New Guinea's lowland
  forests and modern canopy walkways. They are used for their structure only,
  never as cultural costume.
- **Secondary, about 25 percent: ground lodges on short stilts.** These are low,
  wide, thatched houses with a long open front gallery, after the raised timber
  longhouses of Borneo's forest peoples, again as structure only. The apes'
  lodge is built heavier.
- **Accent, about 5 percent:** the commons, the village's one great deck, and
  carved trunk markers, one per household.

### Invariants

| Element | Specification |
|---|---|
| Living trees (2026-10-14) | **nothing is driven into a living tree.** The ring collars are compression collars clamped on bark pads and lashed, and loosened every dry season as the trunk thickens, so they never girdle it. The ramps touch the trees nowhere |
| Joints | **lashed, never nailed** ("bark doesn't hold a nail the way wood does"): every joint wrapped in vine or split rattan, and the lashing visible as the village's signature motif, a dark diagonal wrap at every post head and brace foot |
| Structural module | 1.9 m post spacing, half the 3.8 m landing rise, so floors fall on the existing ring heights (11.4, 22.8, 34.2, 45.6 m) |
| Posts | round timber poles and bamboo culms (`EPSILON` about 2.5); a heavier squared timber only for the commons' six support posts and the ape lodge |
| Decks | split-bamboo or plank decking on joists, lashed, with a small gap between boards |
| Roofs | **broad leaf roofs**: *atap* (nipa-palm leaf folded over battens) laid in three overlapping courses on bamboo rafters, the older brown courses below and the newest course on top in the household's own colour; a squarish superellipse eave outline 1.0 m past the wall plate; pitch **40°** for the whole village (inside the charter's 35° to 45°) |
| Walls | none on most buildings. Where privacy, weather or safety needs one: woven bamboo panels or bark panels, with roll-up rattan blinds instead of shutters |
| Openings | wide round-headed doorways (superellipse), at least 1.5 m clear and 2.4 m high, so the party, blorbs and the apes pass |
| Headroom | every leaf-roof eave, bridge or deck a route passes under clears 2.4 m above the deck, so the hero and the apes walk upright; roofs over the commons and rings keep their eave at 2.4 m or higher and slope up from there |
| Roof construction (revised 2026-10-14) | **the posts carry the roof, visibly.** Round posts at the corners and no more than 3.8 m apart (twice the 1.9 m module) rise to a lashed bamboo **wall plate** at 3.3 m; the rafters run from the plate to the head of the **central pillar**, the prototype's signature, which rises to the peak (a pyramid roof on a square pavilion) or carries a short **ridge pole** (a hip roof on an oblong one). The thatch is 0.3 m thick. With the 1.0 m eave at 40°, the eave's underside is at 2.46 m, clear of the 2.4 m headroom. One builder and one thickness for the whole village (`atapRoof` and `postFrame` in the model), never a flattened leaf mass on poles |
| Rails | rope rails on posts at 1.1 m, with catch nets slung beneath every deck edge more than 3 m above the ground |
| Vertical routes (revised 2026-10-14) | one 32° **trunk spiral** per tree, from the roots to its highest deck: a single continuous ramp, a laminated bamboo deck on two curved stringers, self-supporting as a helix. It rests on the ground at its foot and on each deck's ring beam where it passes through, and hangs between them from the deck above by a few rope hangers. **Nothing is driven into the bark**, and it keeps a 0.3 m well clear of the trunk all the way up. Its rope rail stands on short posts stepped into its own outer stringer. Also the commons hoist and lianas for the climbers; no stairs, no ladders |
| Light | resin lamps in gourd shades (*damar* resin), hung from the roof beams; no lights on poles |
| Water | every roof drains by a bamboo gutter into a gourd or a bamboo tube |
| Palette | 60 percent living bark and lashed timber; 30 percent leaf-green and thatch-brown roofs (the prototype's varied roof colours kept as one household accent each); 10 percent vine rope, rattan and warm fruit colours |

### Exclusions

Nails, sawn-board carpentry and enclosed boxes; glass; lights on poles; fire
anywhere in the trees except the commons kitchen's stone-based hearth;
masks, carvings or posts copied from real peoples' sacred traditions; Chinese
or Greek forms (those belong to the Chinese village and the Sky Kingdom).

### Body scale

The village is built for its own residents and for the party. The tallest
apes and the hero set the clearances:
- 2.4 m headroom under every roof and through every doorway;
- 1.5 m clear on every route;
- hero-length beds in the inn.

The stuffed-animal monkeys use hammocks and nests; the apes use low, wide
sleeping platforms.

## 2. The commons (11.4 m)

### Structure

- **Deck:** a rounded triangle wrapping the three trunks. **Revised by the
  audit (2026-10-07):**
  - **The old figure was too small.** The layout gave about 350 m², but the
    triangle between the trunk centres alone is about 430 m², since the
    trunks stand 30 to 33 m apart.
  - **The program does not fit 350 m².** The amenities need about 350 m² of
    footprint before any circulation:
    - gathering circle about 64 m²;
    - kitchen 48 m²;
    - dining 60 m²;
    - market 48 m² plus 2 m clear in front, about 90 m²;
    - cistern 36 m²;
    - workshop 30 m²;
    - food store 16 m²;
    - privy 3 m².
  - **New size:** the deck is about **520 m²**, its edge about 3 m outside
    the line between the trunks. That leaves 1.5 m routes between every
    amenity and a 2.4 m route from each trunk spiral's landing to the gathering
    circle.
  Main beams run trunk to trunk on ring collars lashed round each trunk, with
  joists across them.
- **Support** (revised 2026-10-13, layout section 11; no posts):
  - a bracket collar round each trunk, 0.3 m off the bark: knee-braced
    bearers to a curved ring beam, joisted beyond;
  - over the plaza, a hung ring beam round the gathering circle, carried by
    rope hangers from six limbs, two from each tree, at about 19 m. No cable
    stays.
- **Trunk spirals:** each tree's 32° ramp, 2.4 m wide up to the
  commons and 1.5 m above, with a rope rail: one continuous self-supporting
  ramp round the trunk, nothing driven into the bark (section 1). Each lands on the commons through an opening beside
  the bark, facing the deck's middle (layout 11).
- **Edge:** rope rails all round, with catch nets 2 m wide beneath.
- **Placement on the deck:**
  - the gathering circle at the centre;
  - the market along the south edge;
  - the kitchen and dining terrace at the north-west, between the Elder and
    North trees, on the edge, so smoke leaves over open ground;
  - the cistern pavilion at the north-east;
  - the inn and the workshop on the East Tree side.

### Gathering circle

- An open ring about 9 m across at the centre of the deck, open to the sky.
- Two rings of log seats: the inner ring for the elders, the outer for
  everyone else, with no gap between canopy and floor.
- A hollow log drum on a stand at one side.
- Its own resin lamps hang from a ring of four poles.

### Shared kitchen (Wangi)

- An open pavilion 8 × 6 m, the deck's one roofed fire, set on the deck's edge.
- **The hearth:** a clay-and-stone firebox on a thick stone base set in a
  timber tray of sand 3 × 3 m. The 1.35 m clear zone in front is kept clear,
  and nothing timber stands within 1.5 m of the firebox.
- The roof has a raised smoke vent at its peak, and the leaf thatch over the
  hearth is lined with clay.
- Water gourds and a bamboo water tube from the cistern beside the hearth.
- A long work bench along the inner side, pot rack, hanging baskets, herb pots
  on the rail.
- **Variation:** the only roof with a smoke vent; the only clay lining.

### Dining terrace

- A long open-roofed terrace 10 × 6 m beside the kitchen.
- Long low tables of split log, with mats and log benches either side.
- Orchid baskets hang from the roof beams.

### Market (Delima's fruit, Rotan's rope)

- A long leaf roof 12 × 4 m on posts, facing the grand ramp's head.
- Two stalls under it:
  - Delima's fruit: tiers of baskets of bananas, durian, rambutan,
    mangosteen and *cempedak*, with a pomegranate in a big pot.
  - Rotan's rope: coils of vine rope and rattan cord on pegs, a twisting frame
    and a bench.
- The sellers' sides are toward the deck's edge, the customers' side toward the
  ramp, with 2 m clear in front.

### Cistern pavilion and washing

- The largest leaf roof on the deck, 6 × 6 m, gutters on all four sides.
- The gutters fill a lashed barrel cistern 2 m across on a reinforced bay of
  the deck, carried by a post straight to the ground.
- Washing basins of hollowed log on a bench beneath, draining by a bamboo
  pipe down a support post to a soak pit on the ground.

### Food store

- A raised basket store 4 × 4 m on four posts above the deck, its legs fitted
  with smooth collars so nothing climbs them, reached by a rope ladder.
- Woven walls; the village's only lockable door, a lashed panel.

### Public privy

- A closet 1.4 × 1.8 m of woven rattan screens with a hung door, at the
  commons' edge beside the food store.
- A timber bench seat over a sealed clay vat, a basket of dry leaf litter and a
  scoop, a water gourd and basin.
- The vat is lowered by rope to the ground and emptied to the garden compost.
  Nothing falls from the deck.

### Jati's workshop

- A half-open pavilion 6 × 5 m on the commons' corner against the East Tree.
- A work bench, a rack of poles and bamboo culms, coils of lashing rattan,
  drawknives and adzes on pegs.
- A spare ramp section under repair.
- **Variation:** the only work clutter on the commons; shavings on the deck.

## 3. The inn (Bima; rest point)

**Site:** a rounded lobe of the commons' deck east of the East Tree,
about 15 × 17 m with 3 m corner radii, one piece with the commons (revised
2026-10-13, review 2). The house is 6.5 m deep with its veranda on the commons
side, and a deck edge with rail stays outside it. It sits in the East Tree's
arms: three saddle limbs, grown just under the deck at −24°, 0° and +24°,
carry the lobe's joists. No posts, no cable stays (layout 11). The walls are woven rattan panels with a wide
door and windows onto the veranda. Its entrance faces back onto the commons. It replaces the ground inn at
`(27, 22)`. The price is unchanged at 15 Tokoins.

**Masses:** one long house 14 × 6.5 m with a deep leaf-thatched roof, and an open
veranda 3 m deep along its commons-facing side. It is **the one house on the
commons with walls**, because guests need privacy and a dry night: woven
bamboo panels and roll-up blinds.

| Room | Size | Description |
|---|---|---|
| **Veranda** | 14 × 3 m | open, facing the commons; Bima's counter at one end with a resin lamp, a guest mat, a bench, orchid baskets and jasmine in a pot at the door |
| **Party room** | 8 × 6 m | eight hero-length sleeping platforms with woven mats and kapok pillows, a bamboo rail for gear, two roll-up windows onto the forest; the party wakes here |
| **Guest room** | 3 × 4 m | one platform, a peg rail, a window |
| **Bima's room** | 3 × 4 m | a hammock, a chest, a shelf of carved fruit-stone tokens from past guests; a basket his sister sends up with spare food |
| **Washroom** | 2 × 3 m | the privy closet (bench seat over a sealed clay vat, leaf litter and scoop), a log washbasin with a water tube from the commons cistern; vat lowered by rope to the compost |

**Plan (audited 2026-10-07):** the 14 × 8 m house is:
- a **passage 1.4 m wide** along its veranda side, entered from the veranda
  by one door;
- the **party room** (8 × 6.6 m) at the west end;
- **Bima's room** and the **guest room** (3 × 4 m each) side by side in the
  east 6 m;
- behind them, the **washroom** (2 × 2.6 m, trimmed from 2 × 3 to fit) and a
  linen and lamp store (4 × 2.6 m).

Every room opens off the passage, so nobody passes through another's room, and
there are no pass-throughs. The veranda's leaf eave clears 2.4 m.

**Roof:** a long hipped leaf roof, the inn's own accent a deep red-brown
thatch, the darkest in the village.

**Variation:** the only walled house on the commons; the longest roof; the
counter faces the commons.

## 4. Household rings

### Ring structure

- A wrap-around deck about 5 m wide round each trunk, on knee braces from a
  ring collar lashed to the trunk.
- **Pavilion bays (revised by the audit, 2026-10-07).** A 4 m deep pavilion on
  a 5 m ring would leave a 1 m walkway, under the 1.5 m minimum, and push
  neighbours through the household's home. So each pavilion stands on a
  lashed **bay** that widens the ring locally to about 6.5 m on its outer
  side. The ring's own 1.5 m walkway runs on the trunk side, past every
  pavilion and never through one.
- **Crown deck** on the Elder Tree at 45.6 m: about 10 × 9 m round the trunk,
  room for the sisters' 7 × 5 m pavilion, the walkway and the basket hoist's
  landing.
- **Capacity:** the ring is about 33 m round at its middle. The fullest rings
  hold:
  - East Tree, 22.8 m: a couple's pavilion, Dahan's pavilion, the bridge
    landing, about 16 m of arc in all;
  - North Tree, 34.2 m: the joined siblings' pavilions, the empty pavilion and
    about 20 m of arc.

  Both fit with gaps between.
- Rope rails and catch nets.
- The ring bears on its trunk's bracket collar. The tree's 32° spiral comes
  up through one opening beside the bark, and lianas hang from the outer edge
  for the climbers (layout 11).

### The household pavilion

The prototype treehouse developed into a home: a round or rounded-square
pavilion about 4 × 4 m on the ring, round its own **central pillar** (the
prototype's signature), with open sides, roll-up blinds on the weather side
and a broad leaf roof. Inside:
- a woven **hammock nest** slung from the pillar to a perimeter post;
- storage baskets;
- a rain gourd;
- a resin lamp;
- the resident's own work at the open side.

Each household carries one carved trunk marker at its landing: a lashed bundle
of its own colours and objects, never lettering.

Pavilions are sized by household:
- a **single pavilion** is about 4 × 4 m with one hammock nest;
- a **couple's pavilion** is about 5 × 4 m with one broad shared nest, a
  second storage bay and a sitting mat by the open side;
- **joined pavilions** are two single pavilions sharing a small deck between
  them.

| Tree, ring | Household | Pavilion | Marks |
|---|---|---|---|
| **Elder Tree, crown deck 45.6 m** | Purnama and Sekar, sisters | the largest, 7 × 5 m: two sleeping alcoves either side of the central pillar, a shared weaving corner at the open side, a visitors' cushion | Purnama's knotted cords counting the seasons since the curse began; Sekar's backstrap loom and stacked mats; a basket hoist from the 34.2 m ring for supplies, so neither sister has to carry loads up |
| Elder Tree, 34.2 m | Senja and Rimba, married | a couple's pavilion facing west, toward dusk | Senja's cord of knots counting the days since Laras's cradle; vines trained round Rimba's listening seat; **an empty cradle hook in the roof beam**, never used |
| Elder Tree, 22.8 m | Abu | a single pavilion at the bridge head, the busiest landing | a spare hammock for guests; carved joke figures on the rail; a covered supper basket on a peg, ready for the evening climb to his grandmother |
| **East Tree, 34.2 m** | Tunas | a single pavilion, the newest, thatch still green, directly above her aunt and uncle | a collection of found things (shells, seeds, a feather from every bird); a few of Embun's spare rope rails, tied by her aunt anyway |
| East Tree, 34.2 m | Bayu | a single pavilion on the wind corner | wind chimes of seed pods and bamboo, a feather vane; a second seat where Tunas learns the wind |
| East Tree, 22.8 m | Jati and Embun, married | a couple's pavilion beside the ramp | Jati's drawings of ramp joints scratched on bark; Embun's extra rope rails and a net slung lower than anyone else's; Tunas's old hammock still rolled in a corner |
| East Tree, 22.8 m | Dahan | a single pavilion at the ramp head | coils of lashing, spare rungs, a mallet; Dahan checks the ramps from here |
| **North Tree, 34.2 m** | Intan and Murai, siblings | joined pavilions with a shared deck between them | Intan's side faces the training grounds, with a pebble tally of comings and goings; Murai's faces the dawn, with gourd bird feeders and a carved board of bird shapes |
| North Tree, 34.2 m | *(Laras and Gilang)* | **the empty pavilion**, on the far side of the ring from Intan and Murai | hammocks still slung, a cradle hanging from the beam, blinds tied down from outside, the thatch going grey; nobody walks that part of the ring |
| North Tree, 22.8 m | Tirta and Bintang, married | a couple's pavilion facing the river, at the bridge head | Tirta's fish traps and nets drying; Bintang's woven map of paths in coloured cords and a pack always half packed |

### Bridges

Rope-and-plank bridges join the three trees at 22.8 m: 2 m wide, rope rails at
1.1 m, nets beneath, a gentle sag. Each lands on a widened ring landing with
2 m clear.

## 4a. Built from the briefs (2026-10-14)

The model drew every tree structure with one placeholder: a flattened leaf
dome on thin poles, which read as a squashed tree crown with nothing visibly
holding it up. Every structure is now built from its brief, with the shared
roof and frame (section 1).

**Design brief by structure** (plan sizes from the layout):

| Structure | Plan and frame | Roof | Its own parts |
|---|---|---|---|
| Single pavilion (Abu, Tunas, Bayu, Dahan) | 4 × 4 m; four corner posts; central pillar | pyramid to the pillar's head | a hammock nest slung from the pillar, storage baskets, blinds rolled up under the plate on the walkway side |
| Couple's pavilion (Senja and Rimba, Jati and Embun, Tirta and Bintang) | 5 × 4 m; posts no more than 3.8 m apart; pillar | hip on a 1 m ridge pole on the pillar | a broad shared nest, a second storage bay |
| Joined pavilions (Intan and Murai) | two 4 × 4 m pavilions on a shared 1.2 m deck | two pyramids | each sibling's side faces their own way |
| Crown pavilion (Purnama and Sekar) | 7 × 5 m; posts at 3.5 m; pillar | hip on a 2 m ridge pole | two sleeping alcoves of woven screens either side of the pillar |
| The empty pavilion (Laras and Gilang) | 4 × 4 m | pyramid, every course gone grey | blinds tied down on all four sides |
| Kitchen (Wangi) | 8 × 6 m; posts at 3.8 m; no pillar over the fire | hip, with a **smoke vent**: a small second roof lifted on four short poles clear over the peak | the firebox on a stone base in a sand tray, the long work bench |
| Dining terrace | 10 × 6 m | hip | two long low split-log tables with benches, orchid baskets from the beams |
| Market (Delima, Rotan) | 12 × 4 m; posts at 3 m | long hip | two counters, fruit baskets and rope coils, the sellers' side to the edge |
| Cistern pavilion | 5.5 × 6 m | hip with a bamboo **gutter** all round the eave | the lashed barrel cistern 2 m across |
| Food store | 4 × 4 m, raised 1.2 m on four posts with smooth collars | pyramid | woven walls, the one lockable door, a rope ladder |
| Jati's workshop | 5.5 × 5 m | hip | woven back and end walls, the bench, the rack of poles |
| Public privy | 1.8 × 1.4 m closet | small pyramid on a 2.6 m plate | woven screens, a hung door |
| Gathering circle | 7.2 m ring, open to the sky | none | two rings of log seats, the log drum, four lamp poles with gourd lamps |
| Bima's inn | 14 × 6.5 m house and 3 m veranda | one long hip over both, the inn's deep red-brown top course | woven walls; its wall plate on the house walls and a row of veranda posts at 3.8 m |
| Trunk spirals | one continuous ramp per tree | — | rope rail on posts stepped into its own stringer; no brackets |

**Style audit** (every visible element, its term and its tradition):

| Element | Term | Tradition |
|---|---|---|
| Roof | pyramid or hip of *atap* thatch in courses | canopy vernacular (Southeast Asian thatch) |
| Roof peak | rolled leaf ridge or tied finial | canopy vernacular |
| Smoke vent | raised vent roof | canopy vernacular |
| Frame | round posts, lashed wall plate, central pillar | canopy vernacular (the prototype's pillar) |
| Joints | vine lashing, dark wrap at every post head | canopy vernacular (signature motif) |
| Walls | woven bamboo panels, roll-up blinds | canopy vernacular |
| Ramp | self-supporting helical ramp of laminated bamboo | canopy vernacular, from canopy walkways |
| Food store | raised store on collared posts | ground-lodge secondary (granary on staddles) |
| Inn | long house with a veranda under one roof | ground-lodge secondary (the longhouse gallery) |

Two traditions at most on any one building. The inn is the one landmark that
takes the secondary's long-house form.

**Variation matrix** (the shared language is fixed; each differs on two or
three axes, for a reason):

| Structure | Plan | Roof type | Walls | Own mark |
|---|---|---|---|---|
| Single pavilion | square | pyramid | none, blinds | the household's top course colour |
| Couple's pavilion | oblong | hip | none, blinds | a broad shared nest |
| Crown pavilion | large oblong | hip | alcove screens | the highest roof in the village |
| Empty pavilion | square | pyramid, grey | blinds tied down | the only grey roof |
| Kitchen | large oblong | hip with smoke vent | none | the only fire, the only vent |
| Market | long | long hip | none | counters to the edge |
| Cistern | near square | hip | none | the only gutter |
| Food store | square, raised | pyramid | woven, locked | the only raised building |
| Workshop | oblong | hip | two woven walls | the only work clutter |
| Inn | long house | long hip | woven, the only walled house | the only red-brown roof |

## 5. The ground camp

All ground buildings stand on short timber stilts (0.8 to 1.2 m) on stone pads,
for the damp and the ground pests. Every floor is reached by a ramp no steeper
than 1:6, never by steps alone. They have long open front galleries under deep
leaf roofs, woven-bamboo or bark walls behind the gallery, and a hung lashed
door.

### Ape lodge (Batu, Sari, Teguh)

- A long house 14 × 7 m, the village's heaviest: squared hardwood posts on
  stone pads, floor 1.0 m up, decking of thick planks, built for apes.
- **Gallery** 2.5 m deep along the front, facing the plaza, with a long log
  bench.
- **Inside:** Sari and Teguh's room with one broad low sleeping platform;
  Batu's room, the end room, with its own door to the gallery so he comes and
  goes without passing his sister's; a shared room with a firepit on a stone
  hearth set into the floor (ground buildings may have fire) and a smoke hole
  in the roof.
- **Marks:**
  - Batu: a locked chest and a bundle of training-dummy parts under a cloth.
  - Sari: a stool at the gallery's end facing toward Kova Kong.
  - Teguh: a carving of a small monkey, Xiao Hou Zi, on the door post.
- **Variation:** the heaviest frame and the biggest posts; the longest gallery.

### Stable, paddock and Ossian's lean-to

- **Stable:** a roofed stall 6 × 4 m, open on the paddock side, with a stone
  floor, a manger, a tack peg rail and a lantern.
- **Paddock:** 12 × 10 m, bamboo rail fence at 1.3 m, a 3.2 m gate lined up
  with the path to the plaza, a water trough fed by a rain barrel, a hay rack,
  a hitching rail outside the gate.
- **Ossian's lean-to:** 5 × 3 m against the stable's side, a newcomer's camp:
  a bedroll on a platform, a saddle on a rail, a travelling chest, a cooking
  tripod over a fire ring in the open.
- **Variation:** the only animal building; the only lean-to.

### Tailed monkeys' house (Rotan, Kilat, Akar)

- A raised hut 10 × 6 m, floor 1.2 m up, with a deep gallery on the front.
- **Inside:** Akar and Kilat's room with a broad shared nest; Rotan's room
  at the back, with his own hammock and the best of his rope; a shared front
  room opening onto the gallery.
- **Under the floor:** coils of vine rope and bundles of rattan stored dry.
- **Gallery:** Rotan's twisting frame, Akar's walking poles, Kilat's pack.
- **Variation:** the highest stilts; rope everywhere.

### Garden house (Delima, Melati)

- A raised hut 9 × 6 m, gallery facing the plaza path and the back door to the
  gardens.
- **Inside:** Delima and Melati's room with one shared sleeping platform; a
  work room with baskets of fruit and seed and drying racks of ginger and
  turmeric; a store at the back for the stall's baskets.
- **Variation:** the only house with a garden gate in line with its back
  door; jasmine at the front.

### Floor hut (Damar, Wangi)

- A raised hut 8 × 6 m, gallery facing the plaza.
- **Inside:** Damar and Wangi's room with one shared sleeping platform; a
  small shared room with pots and herb jars where Bima drops in most
  mornings.
- **Outside:** the *damar* tree with resin cups and a resin store, the village's
  lamp fuel.
- **Variation:** the smallest hut; the resin store.

### Training grounds and shed (Batu)

The training grounds are a real part of the village: a yard where anyone may
spar against dummies, and where those dummies can become NMEs (see the world
bible: a dummy left unobserved for three nights comes to life). The design
shows this without a word of explanation.

- **Site:** a 20 × 16 m yard centred at `(-48, -48)`, just outside the
  village's safe zone, with its gate on the worn path toward the floor huts.
  Any dummy that wakes does so outside the village.
- **Yard:**
  - trampled bare earth inside a bamboo rail fence (1.2 m, rails lashed);
  - one 1.2 m gate facing the village;
  - *mahang* saplings crowding the fence outside.
- **The dummies:** eight, standing on posts set in the earth round a 9 m
  sparring circle. Each is built from forest material:
  - a lashed rattan frame;
  - coconut-fibre stuffing bound in banana leaf and bark cloth;
  - a coconut-husk head;
  - arms of stout cane.
  
  No two are quite alike, because Batu makes each by hand. Some are freshly
  bound; a few lean, scuffed and split from use. They are solid (parkour tops
  are not wanted on them) and sized to an ape, so they stand taller than the
  hero.
- **Furniture:** a rack of practice staves and cane blades, a log bench, a
  water gourd on a post, a basket of spare husk heads.
- **The shed:** 5 × 4 m on the yard's far side, bark walls on a stone footing,
  a leaf roof, its lashed door always shut.
  - Inside (seen only if the door is ever opened): frames in every stage of
    binding, coils of rattan, stacks of husk heads, and one finished dummy
    standing in the corner facing the wall.
  - The village's only fully closed building.
- **Signs of trouble:** one dummy post near the fence stands empty, its
  lashings snapped, and the earth by it is churned. Nobody has replaced it.
- **Variation:** the only fenced yard besides the paddock; the only closed
  building; the only place in the village without a lamp, because Batu takes
  his with him into the shed.

### Tirta's fishing landing

- A small timber jetty 6 × 2 m on the river bank, on posts set in the
  riverbed, with a fish-trap rack and a bench.

## 6. Variation matrix

| Building | Level | Plan | Walls | Roof | Signature |
|---|---|---|---|---|---|
| Commons kitchen | 11.4 m | rectangle | open | leaf, clay-lined, smoke vent | the one fire in the trees |
| Dining terrace | 11.4 m | long | open | leaf | low tables |
| Market | 11.4 m | long | open | long leaf | fruit tiers |
| Cistern pavilion | 11.4 m | square | open | the largest leaf roof | cistern |
| Food store | above the deck | small square | woven | small leaf | collared legs |
| Workshop | 11.4 m | rectangle | half open | leaf | shavings |
| Inn | 11.4 m lobe | long | woven | long hip, red-brown | the walled house |
| Single pavilions | rings | round, 4 × 4 m | open | round leaf, household colour | central pillar, one nest |
| Couples' pavilions | rings | 5 × 4 m | open | round leaf, household colour | shared nest |
| Joined pavilions | North Tree 34.2 m | two rounds and a deck | open | two leaf roofs | the siblings' shared deck |
| The empty pavilion | North Tree 34.2 m | couple's | blinds tied down | greying leaf | the hanging cradle |
| The sisters' crown pavilion | 45.6 m | largest, two alcoves | open | leaf | knotted year cords, loom, hoist |
| Ape lodge | ground | long | bark | long, heavy | squared posts |
| Tailed monkeys' house | ground | rectangle | woven | leaf | rope under the floor |
| Garden house | ground | rectangle | woven | leaf | garden gate |
| Floor hut | ground | small | woven | leaf | resin store |
| Stable | ground | open stall | — | lean-to and gable | horse |
| Training shed | ground | small | bark | leaf | shut door |

## 7. Style audit

| Element | Term | Tradition |
|---|---|---|
| Decks round trunks | ring platform, knee braces | canopy treehouse construction |
| Pavilions | central-pillar open pavilion | the prototype's own treehouse |
| Lashing | lashed joints | forest construction worldwide |
| Roofs | palm-leaf thatch (*atap*) | Southeast Asian forest building |
| Ground houses | raised house on stilts with a front gallery | Bornean longhouse, as structure |
| Bridges | rope-and-plank suspension bridge | canopy walkway |

There are at most two traditions on any building: the canopy vernacular, and
on the ground the raised-house tradition.

## Fixed, proposed and open

**Fixed:**
- the layout's positions, footprints and owners;
- the inn's move to the commons;
- the open treehouse character;
- one fire in the trees.

**Proposed:**
- the kit (lashing, the 1.9 m module, leaf roofs, woven walls, stilts);
- every building's form and rooms;
- the inn as the one walled house on the commons;
- the household pavilions and their marks;
- the public privy;
- Purnama's knotted year cords;
- households, genders and relationships (census, `plant_kingdom_village.md`);
- the empty pavilion and the unused cradle hook.

**Open:** none blocking.
