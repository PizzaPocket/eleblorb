# Moy, the city: settlement plan (first real pass)

Status: survey, community brief and settlement concept, second pass, for
review (2026-10-12; revised the same day: no cars or trains, a dense
walkable Tokyo and Hong Kong neighbourhood, everyone named; third revision
the same day: a city standing up out of the desert, its economy, a downtown
of skyscrapers, Singapore-style public housing, and Palbert Pinestein and the
outcast city blorbs). The current
city is a prototype. This pass replaces it with a city built at real
building sizes. Coordinates follow once the concept is
approved (settlement-design stage 4).

## 1. What exists now (survey)

From `scripts/city_generator.gd`, `terrain_generator.gd`, `town_props.gd` and
the world bible.

- **Site.** Centred at world (−540, 0), off the main plateau on the gorge-floor
  wasteland at about −60 m. The flat pad has a radius of 78 m (18 m
  transition), about 156 m across. Beyond it the wasteland floor varies by
  only ±2.4 m. The nearest features:
  - the main plateau's rim, about 300 m east;
  - the Ice plateau, about 490 m away;
  - the Jungle plateau, about 470 m away;
  - the world's skirt, 870 m from the origin.
- **Streets.** Three avenues and two cross streets, each 8 m wide with 2.6 m
  sidewalks.
- **Buildings.** 24 towers in 12 blocks, 6 to 20 floors, on footprints of 2–4
  by 2–3 building cells: **6.4 to 12.8 m wide**. A real tower of that height
  stands on 25 to 40 m.
- **Other built features:**
  - six skybridges between paired towers;
  - fire escapes, balconies and AC units on the facades;
  - lit windows, room lights switched by distance;
  - a far "skyline" level of 24 plain boxes, visible from up to 720 m.
- **People.** 12 named residents with two lines each: Juno Rell, Kade Morrow,
  Suri Vale, Tomas Wren, Nia Calder, Orin Pike, Mara Quill, Venn Harlow,
  Iris Dune, Sol Brant, Pia Rowe and Dax Merrow. They are placed on a grid
  and have no homes or jobs.
- **Shop.** The **Helmsmith**, a helm vendor (shop category "city") in a
  painted ground-floor shop.
- **Bible.** "The outskirts city": a full-scale avenue grid. Wild **City
  blorbs** live in its streets, and a **City Gem** is hidden among them (placed
  by `wilderness_scatter.gd`). It has no gate, and the old City Kingdom gate
  was removed.
- **No rest point.**

### Non-regression requirements

- City blorbs and the City Gem stay in the game, but move **outside the
  bounds** (user, third revision; section 3b).
- The Helmsmith and the "city" shop.
- The 12 residents' names (their roles and lines are revised below).
- The skyline seen from the plateau.
- The distance-based wake and sleep of the detailed city, which is a
  performance requirement.
- Skybridges and elevated routes, as traversal the prototype offers, unless
  the user drops them.

## 2. Direction (user, 2026-10-12)

- **No cars and no trains.** The city is walked. With nothing to drive, a
  street needs no roadway, so streets can be narrow, and the buildings stand
  close together.
- **A dense, walkable city like a neighbourhood of Tokyo or Hong Kong.**
- **Swingable with the Leaf Hat:** buildings close enough together that a
  wearer can cross the city hand over hand.
- **Everyone is named and has a backstory.** No nameless crowds.
- **Real building sizes**, with only some floors realised.
- **The rest point** is a grand hotel with an atrium, a revolving door and a
  giant chandelier, after the great hotels of China.
- **A library**, and the other civic, cultural and public places a city has.
- **The family.**
  - **Jammer's mother** is a lawyer and the hero's blood relative.
  - **Jammer's father** is a tech recruiter.
  - **Jammer**, a little kid, is visiting their grandmother in the **Middle of
    Nowhere**, a future farmland scene where the hero learns where his
    hometown is.

**Third revision (user, 2026-10-12):**
- **A city jutting up out of the desert**, like Las Vegas or Dubai, with no
  body of water nearby.
- **A downtown with skyscrapers**, not only buildings of 5 to 12 storeys.
- **Large public housing, like Singapore's.**
- **Palbert Pinestein**, a mad scientist, created the **city blorbs** in an
  experiment. The city blorbs have since been outcast from the city and are
  not allowed inside its bounds.
- What do the people here do, and what is the economy?

**Fourth revision (user, 2026-10-12):**
- The city's name is **Moy**.
- **No Sign Boneyard**, which took too much liberty with the backstory. The
  city blorbs simply stay outside the city's outskirts.
- **No opulent fountains.**

**Seventh revision (user, 2026-10-12):**
- **No road to a wider world.** There is none: the world ends at the
  planetary ocean beyond the ring of mountains. So nothing comes in or goes
  out by road, and Moy feeds and powers itself.
- **No public bath.**

**Sixth revision (user, 2026-10-12):**
- **No big empty gaps between buildings.** Real cities don't have them:
  every block is built out to its streets.
- **The park is in the city centre.**
- **New names** for Lantern Lane and Parkside Estate (proposed: **Old Moy**
  and the **North Estate**).
- **There are still roads**, even with no cars.
- **Plazas**: the user likes them, so the city has several.

**Fifth revision (user, 2026-10-12):** a field of giant wind turbines, in the
Chinese style, out in the wasteland around the city, as **Moy's power
source.** They must not encroach much on the Jungle and Ice plateaus. A modest number is enough, and only on the city's side of the Crossroads
(the west), not out by the volcano or the Chinese village.

## 2a. The site: a city in the desert

**Yes: a city standing up out of open desert, like Las Vegas or Dubai.** The
site is the gorge-floor wasteland at −60 m, flat to within ±2.4 m, and there
is **no water anywhere near it.** The nearest open water is the eastern lake,
about 760 m east, beyond the main plateau and 60 m up its wall.

The city fills a desert basin ringed by high ground, as Las Vegas fills its
valley. Measured from the new edge (radius 200 m):
- the main plateau's wall, about 120 m east;
- the Jungle plateau's slope, about 120 m south (the world's north is −Z);
- the Ice plateau's slope, about 140 m north;
- the world's skirt, about 110 m west.

From the main plateau's rim the player looks down 60 m onto a skyline that
still rises far above them. At night the city is the brightest thing in the
world.

**The desert around it:**
- pale hardpan and gravel, with broad sand swells (the 18 m terrain grid can
  make swells, not ripples; ripples are decals);
- rock outcrops in clusters of three to five at the plateaus' feet (props,
  with collision);
- desert plants in clumps: yucca and Joshua-tree forms, barrel cactus,
  creosote-like shrubs, dry grass where the ground dips; tumbleweed;
- dust devils (particles), and sand drifted against the city's west edge,
  the windward side.

**Water, with none nearby.** Three parts:
1. **Deep wells.** The gorge was cut by a river long ago, and its water still
   lies in an aquifer under the floor. The **water works** stand outside the
   bounds to the north-west: well heads, a pump house, covered reclamation
   tanks, and a **water tower** about 35 m tall, the first thing the city
   built.
2. **Every drop used twice.** Grey water is reclaimed for the park and the
   street trees. The pipes are buried and not modelled.
3. **Tanks on every roof** (already part of the city's language) hold a
   day's supply.

Water is precious, and Moy treats it so: there are no fountains for show.
The park's trees and its small pond run on reclaimed water. Rafael Ortiz, who
keeps the wells, counts every litre.

**Built for the heat.** Narrow lanes and close buildings are how desert
cities have always kept cool: tall walls shade the lanes most of the day. So
the Tokyo and Hong Kong density already suits the desert. Add:
- the tong lau verandas and the shopping arcade's roof;
- shade sails over the shopping streets;
- date palms and shade trees along the main streets, irrigated;
- the Deck, which shades the street below it;
- the void decks under the public housing (section 7);
- pale tile and white roofs that throw back the sun;
- misters on the plazas and at the hawker centre.

The city is quiet at noon and comes alive after dusk: the night market and
the lit picture signs.

**The bounds: the Rim Walk.** The city ends sharply, with no sprawl. A ring
promenade runs round the whole edge:
- a low wall about 0.9 m high, a parkour ledge;
- a row of date palms, lamp posts, and benches facing out over the desert;
- a gap in the wall at the end of every lane.

Beyond it the paving stops and the desert begins. This is the line the city
blorbs may not cross. It reads as an edge, never as a sign.

**Beyond the bounds** (in the ring between 200 and about 300 m; coordinates
follow approval):
- **All round: the city blorbs** stay out in the open desert just beyond the
  outskirts.
- **No roads out** (user). Westward the desert runs to the mountains, and
  beyond them lies the planetary ocean; eastward there is nothing but rock
  and the main plateau's 60 m cliff. The streets stop at the Rim Walk.
- **West: the battery works**, at the end of West Street.
- **North-west: the water works**, the water tower and the **fish tanks**
  (below).
- **Just beyond: the wind farm**, four turbines in two pairs framing the
  city (below).

**The wind farm: Moy's power.** The city runs on the wind.
- **Why here.** The basin between the plateaus funnels a steady wind from
  the west across the gorge floor; it is the same wind that drifts sand
  against the city's west edge.
- **Precedent:** the giant wind bases in China's deserts (Jiuquan in Gansu,
  Dabancheng in Xinjiang, Inner Mongolia): long lines of huge white
  three-bladed turbines standing in open desert to the horizon.
- **Size:**
  - a tapered white steel tower about 95 m to the hub, about 6 m across at
    its foot;
  - a rotor 130 m across (three blades of about 65 m);
  - about 160 m to the tip of a raised blade.

  The newest real Chinese turbines are bigger still, with tips past 250 m.
  This size keeps them giant beside a 1.9 m hero and the 140 to 280 m
  downtown towers, and lets a field of them fit the world's small map.
- **Number and placement: four**, only on the city's side of the Crossroads
  (user): the west of the map, around Moy. None out by the volcano or the
  Chinese village, and none crowding the Jungle and Ice plateaus.

  They stand in two pairs that frame the city, one pair either side of the
  axis of West Street and Meridian Avenue:
  - the **east pair**, between Moy and the main plateau's cliff;
  - the **west pair**, between Moy and the world's skirt.

  | Site (world x, z; north is −Z) | Where | Nearest plateau centre | From Moy's centre |
  |---|---|---|---|
  | (−310, −200) | east pair, north | Ice: 310 m | 320 m |
  | (−310, 200) | east pair, south | Jungle: 330 m | 320 m |
  | (−740, −270) | west pair, north | Ice: 358 m | 324 m |
  | (−740, 270) | west pair, south | Jungle: 309 m | 324 m |

  **Clearances:**
  - every tower at least 280 m from the Jungle and Ice plateaus' centres:
    140 m beyond the foot of each slope, with the blade tips 75 m clear;
  - 120 m beyond the Rim Walk;
  - the east pair about 100 m off the main plateau's rim (blade tips 35 m
    clear);
  - the west pair's blade tips inside the world's skirt.

  The water works sit nearer the city than the north-west turbine. Heights
  are checked against the terrain in the placement pass.
- **Motion and light.** All face west into the wind and turn together,
  slowly, about ten turns a minute. Red aviation lights on the nacelles blink
  in unison at night, a second skyline around the city's.
- **Detail:**
  - a nacelle with a railed service roof;
  - a door at each tower's foot;
  - a substation beside the **battery works**, which stand at the field's
    edge nearest Moy and store the wind's power for calm days;
  - cables buried, not modelled;
  - a low, slow whoosh near the towers.
- **Collision and play:**
  - Towers are solid cylinders, and the nacelle roof is a landing.
  - **The blades collide with the player** (user, 2026-10-12), and with
    every party member, companion and NME controller, as the collision rule
    requires.
    - Each blade is a moving solid body (`AnimatableBody3D`, synced to
      physics), rotating with the rotor, with a collider of three or four
      tapering capsules or boxes. It is a blocking surface, not a hazard,
      and does no damage.
    - At ten turns a minute a 65 m blade's tip moves at about 68 m/s. The
      push a blade gives is capped (about 12 m/s, to be tuned in play), so
      the hero is swept aside or carried round, not flung across the map.
    - Physics steps are fine enough that a blade cannot pass through a body
      between frames.
    - The blades are close to the ground only at the bottom of their sweep,
      about 30 m up, so walkers never meet them. Swingers, gliders and
      climbers do.
  - The towers are the only swing anchors out in the desert. There is no
    route up inside them (no ladders, by the ramp rule).

## 3. Who lives here, and what they need

### The city's culture

The city is the human world the hero comes from: present day, cosmopolitan,
crowded and proud of it. Nobody owns a car, because nowhere you need is
further than a walk, a lift or a deck away. Life is lived in layers:
- shops at street level;
- clinics, studios, restaurants and offices above them;
- homes above those;
- gardens, laundry and water tanks on the roofs.

People know their lane, their convenience store, their noodle stall and their
neighbours. The elders play chess in the park, and children walk themselves
to school. The days are hot and the nights are the city's best time.

### Why a city here: what people do, and how it earns

A desert city needs a reason to exist. This one has **the wind.**

1. **Energy, the founding industry.** The **Windworks** company runs the wind
   farm and the battery works. The city was built for the Windworks as Las
   Vegas was built for its dam. Everything in Moy runs on it: the lifts,
   the lights and signs, the vertical farm, the pumps at the wells.
2. **Science and technology.** **BLOCK** (renamed from the Lumen Institute,
   user), a research institute with a campus downtown, works on power and on "living current". Start-ups spun out of
   it fill floors of the downtown towers, and Tanglewire recruits for both.
   Pinestein worked at BLOCK.
3. **Professional services.** Corporate law (Raman & Reese: the Windworks's contracts, BLOCK's
   patents and the city's own cases) and finance serve the first
   two.
4. **Hospitality and spectacle.** The Grand Hotel, the cinema and the night
   market serve Moy itself and the rare traveller who crosses the desert on
   foot, like the hero. In a world of villages, the city's lights are
   themselves the sight, as Las Vegas's are.
5. **The everyday city.** Markets, the hawker centre, shops, the clinic, the
   school and the upkeep crews: the residents serving each other.

**Moy feeds itself (proposed).** No road leads out (user), so nothing is
imported or exported. The wind and the wells make a desert city able to
grow its own food:
- the **vertical farm**, a windowless tower of lit growing racks in the
  market lanes, run by Sora Ishida: greens, herbs, vegetables, grain and
  fruit;
- **rooftop greenhouses** on the estate's podiums and the market roofs;
- the **fish tanks** at the water works, fed by the wells, where Rosa's fish
  are netted each morning.

The market lanes sell what Moy grows. The law firm, the recruiters and
BLOCK work for the city's own companies.

### Census (proposed, 2026-10-12)

Forty-five named residents, in about thirty-four households. Everyone has a
home, work, and a reason to be where they are. The twelve existing residents
keep their names. Their genders are those already in the code. The new names
are proposals, apart from Palbert Pinestein (the user's). Five residents were
added in the third revision: Pinestein, Dr. Vera Kask, Omar Haddad, Rafael
Ortiz and Siti Rahman.

The city's windows are full of lit rooms, but nobody walks its streets
unnamed: these forty-five are the people the hero meets.

**The family**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Elizabeth Reese** | the Reese–Miller house, an old tower house in Old Moy; she walks to work across the park | corporate attorney, partner at Raman & Reese, a corporate law firm in the glass tower on Civic Plaza | The hero's aunt by blood: her sibling was the hero's parent. She grew up in the Middle of Nowhere and left for law school; her mother still lives on the farm. Quick, warm, overworked. She has kept a photograph of the hero as a boy on her office shelf for years. |
| **Dan Miller** | the same house; he walks to work with Elizabeth | tech recruiter at Tanglewire, the recruiting firm in the glass tower downtown; he places people at BLOCK, the Windworks and the start-ups | Elizabeth's husband; city born. He can talk to anyone and never forgets a name, and misses Jammer louder than he admits. |
| *(Jammer)* | away, at his grandmother's in the Middle of Nowhere | — | Their son; his room in the apartment is full of drawings of the farm. |

Raman & Reese is named for its two partners, Priya Raman and Elizabeth.
Elizabeth and Dan speak of the Middle of Nowhere freely (user). Draft lines,
in character and pointing nowhere:
- Elizabeth: "Jammer's out at my mother's farm for the summer. We call it the
  Middle of Nowhere, and we mean it kindly."
- Dan: "He calls every Sunday and talks about nothing but the goats. I've
  never been so jealous of a goat."

**The grand hotel (rest point)**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Lucinda Wah** | the manager's flat on the hotel's top floor | general manager; keeps the reception desk herself in the evenings (the rest point's keeper) | Third generation to run the hotel her grandfather built. She knows the chandelier's 3,000 crystals by their faults. |
| **Felix Tanaka** | Old Moy, above the bakery | concierge | Knows every shortcut, every deck and every noodle stall, and talks as if the city were his own living room. |
| **Ah Keung** | Wing Fat Mansion | doorman at the revolving door | Forty years at the door. Greets everyone, and has never once let the door stop turning. |
| **Iris Dune** | Wing Fat Mansion, 11th floor | florist, with a flower stand in the hotel's lobby | Keeps a plant alive on her eleventh-floor sill against all reason, and dresses the atrium every morning. |

**Civic and cultural**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Teodora Vance** | Garden Row townhouse | mayor | Grew up in the market lanes. Walks the whole city every Sunday to see what's broken. She signed the ordinance that put the city blorbs outside the bounds, and does not like to talk about it. |
| **Kenji Mori** | above the park's tea house | city clerk and registrar | Keeps the city's records, and the births and deaths of everyone in this census. |
| **Ada Fong** | Garden Row, with her wife Sora | head librarian | Moved the library into its terraced new building, and still misses the old one's creaking floors. |
| **Nia Calder** | Wing Fat Mansion | the library's map archivist | Counts the towers, reads old maps, and has a drawer of maps nobody can explain. |
| **Benji Okoro** | Old Moy | children's librarian | Jammer's favourite grown-up after his parents. |
| **Dr. Imani Osei** | North Estate, Block 5, with her son Kofi | curator of the natural history museum | Writes long letters to Dr. Hazel Coleman about Dinosaur's bones, and dreams of mounting a cast of him. |
| **Leon Duarte** | above the cinema | projectionist of the old Moonlight Cinema | Runs film reels by hand through clockwork projectors he will not let anyone replace. |
| **Mara Quill** | a rooftop studio in Old Moy | novelist | Writes in the library and the café. Says the city mirrors something, and is writing a book to find out what. |
| **Pia Rowe** | a shared flat over the market | busker on Civic Plaza | Likes the noise at street level; plays where the crowds turn. |
| **Old Fu** | behind the park's tea house | keeps the tea house and the chess tables in the park | Sweeps the park at dawn, pours tea for the chess players, and can beat everyone in the city except Bea Ho. |
| **Sora Ishida** | Garden Row, with Ada | runs the vertical farm in the market lanes | Keeps the racks lit and watered through the night; her mother kept the first rooftop greenhouse in Old Moy. |

**Commerce and food**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Sol Brant** | above his café | runs the breakfast café in Old Moy | Up before the sun, which the towers hide until mid-morning. |
| **Mei Chan** | the market flats, with her daughter Lily | runs the noodle stall at the night market | Cooks at a stall her mother licensed forty years ago. |
| **Hiro Sato** | above the store | keeps the all-night convenience store | Has not closed in eleven years and knows who comes in at 3 a.m. and why: Pinestein, most nights, for batteries. |
| **Rosa Delgado** | the market flats | fishmonger at the wet market | Loud, funny, and the best judge of freshness in the city. Her fish come from the tanks at the water works the morning they are netted, and she will tell you which tank. |
| **Wen Li** | the market flats | greengrocer at the wet market | Grows herbs on the market's roof and sells them below. Her greens come up from Sora's vertical farm before dawn. |
| **Gideon Hale** | behind his shop | **the Helmsmith** | Makes helms for blorbs and their wearers; gruff, precise, and secretly delighted by every new customer. |
| **Zara Quinn** | a studio on the market roof | sign painter | Paints the city's picture signs (no lettering, ever) and hangs them herself. |
| **Siti Rahman** | North Estate, Block 2 | runs the laksa stall at the North Estate hawker centre | The estate's auntie: feeds the shift workers at dawn and the children after school, and knows which flat every lift-button smudge belongs to. |
| **Tomas Wren** | North Estate, Block 1 | courier | Carries deliveries floor to floor on a cargo trike and a hand truck, by lift when he trusts it and by ramp when he doesn't. |

**Work in the towers**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Priya Raman** | Garden Row | senior partner, Raman & Reese | Hired Elizabeth straight out of law school and made her a partner. |
| **Venn Harlow** | Wing Fat Mansion | paralegal at Raman & Reese | Same commute every day, the same fifteen floors; quietly the firm's memory. |
| **Theo Park** | Old Moy | software engineer at a start-up | Dan is trying to place him; he would rather be skateboarding on the decks. |

**The wind, the water and the Institute**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Palbert Pinestein** | a top-floor flat and laboratory in Old Moy, the roof bristling with antennas and coils | none, officially; dismissed from BLOCK | The mad scientist who made the city blorbs (section 3b). Wild-haired, brilliant, tactless, and loyal to the creatures the city threw out. Goes out past the Rim Walk most nights with a pocketful of charged batteries. |
| **Dr. Vera Kask** | a downtown flat | director of BLOCK | Pinestein's oldest colleague, and the one who dismissed Pinestein after the Blackout. Still keeps Pinestein's old notebooks locked in her office. |
| **Omar Haddad** | a flat at the battery works | chief engineer of the Windworks wind farm | Climbs ninety-five metres to a nacelle before breakfast and calls it his commute. |
| **Rafael Ortiz** | the keeper's house at the water works | keeper of the wells and the water works | Counts every litre the city uses twice, and has never once let the park's pond run dry. |

**Care, safety and teaching**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Dr. Arjun Mehta** | above his clinic | the neighbourhood doctor | Treats half the city and remembers all of it. |
| **Kate Byrne** | the police box's back room | officer at the police box | Gives directions more than anything else. Walks stray city blorbs back out past the Rim Walk, gently, and likes that part least. |
| **Yuki Hayashi** | Old Moy | teacher at the primary school | Jammer's teacher; sends him postcards at the farm. |

**Upkeep**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Juno Rell** | North Estate, Block 3, 20th floor | estate superintendent for the Housing Board | Takes the ramps twenty floors most mornings "to keep the knees honest". |
| **Dax Merrow** | Wing Fat Mansion | leasing agent | Has lived on six floors of the same tower: twice for the view, four times for the rent. |
| **Kade Morrow** | the works yard flat | city works: inspector of the decks, bridges and lifts | Knows every tower's creak. |
| **Suri Vale** | Old Moy | window cleaner on the tower gondolas | Loves the lit windows at dusk; "nobody down there looks up". |
| **Orin Pike** | the park lodge | park keeper | The sky does what it wants, and he plants for it. |

**Elders and children**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Bea Ho** and **Wilfred Ho** | Wing Fat Mansion | retired; chess in the park every afternoon | Married fifty-two years. She wins. |
| **Lily Chan** (child) | the market flats | school | Mei's daughter; Jammer's best friend, cross that he is away. |
| **Kofi Osei** (child) | North Estate, Block 5 | school | Imani's son; knows the name of every bone in the museum. |

The three gate lines among the existing residents are rewritten in the
dialogue pass (Juno's second, Mara's first and Dax's second).

### 3b. Palbert Pinestein and the city blorbs

**Fixed (user):** Palbert Pinestein, a mad scientist, created the city blorbs
in an experiment. They have since been outcast and are not allowed inside the
city's bounds. **The rest is proposed.**

- **The experiment.** Pinestein was BLOCK's brightest
  researcher in "living current", and wanted a creature that could live on
  the city's own light, so the city would never go dark again. The
  experiment made the city blorbs, saturated glassy azure, crackling and
  hungry for power: the only blorbs known to have been made rather than
  born. How it was done is left open.
- **The Blackout.** They loved the city too much. They fed on the signs, the
  lifts and the grid, and one summer night the whole city went dark:
  - lifts stopped between floors;
  - the Deck's moving walkways froze;
  - the Grand Hotel's chandelier went out for the first time in its history.
- **The ordinance.** The city council, under Mayor Teodora Vance, banned city
  blorbs from inside the bounds. The Institute, under Dr. Vera Kask,
  dismissed Pinestein.
- **Now:**
  - The city blorbs stay outside the city's outskirts, out in the desert
    beyond the Rim Walk.
  - Pinestein still lives in Old Moy and goes out to them at night,
    with batteries bought from Hiro at 3 a.m.
- **How the city feels about them:**
  - Teodora: defensive.
  - Kate: dutiful but gentle.
  - Lucinda: bitter (her chandelier).
  - Lily and Kofi: they sneak out to see them.
- **Draft lines** (in character, explaining nothing):
  - Pinestein: "They're not pests. They're the first thing this city ever
    made that wanted to live here."
  - Kate: "Back out you go. Past the palms. Go on."
  - Lucinda: "Three thousand crystals, and every one of them dark. I was
    standing right there."
- **In play (proposed):**
  - Wild city blorbs spawn only in the desert just outside the outskirts,
    and their roaming stays outside the Rim Walk.
  - The City Gem moves from the streets to lie out there among them.
  - No text states the ban. The Rim Walk's edge, the blorbs waiting beyond
    it and the residents' remarks carry it.

### Their needs, and where each is met

| Need | Who | Where |
|---|---|---|
| Rest and hospitality | Lucinda, Felix, Ah Keung, Iris | the Grand Hotel |
| Governance and records | Teodora, Kenji | city hall |
| Knowledge | Ada, Nia, Benji | the library |
| Culture | Imani; Leon; Mara; Pia | the museum; the Moonlight Cinema; the plazas |
| Food | Sol, Mei, Rosa, Wen, Hiro | the café; the night market; the wet market; the convenience store |
| Food grown in the city | Sora; Rosa's fish from the water works | the vertical farm; rooftop greenhouses; the fish tanks |
| Health | Dr. Mehta | the clinic |
| Safety | Kate | the police box |
| School | Yuki | the primary school |
| Work | Elizabeth, Priya, Venn; Dan, Theo | Raman & Reese; Tanglewire and the start-up floor |
| Making | Gideon; Zara | the Helmsmith; the sign studio |
| Upkeep | Juno, Dax, Kade, Suri, Orin | the towers, the decks, the facades, the park |
| Moving goods without cars | Tomas | cargo trikes, hand trucks and service lifts; deliveries at dawn through the back lanes |
| Power | Omar | the Windworks wind farm and battery works |
| Water | Rafael | the wells, the water works and the roof tanks |
| Research | Vera; Pinestein, alone | BLOCK; Pinestein's rooftop lab |
| Cheap, good food near home | Siti | the North Estate hawker centre |
| Play | Lily, Kofi; the elders; Old Fu | the giant playground in the park; chess tables in the park and on the void decks; the tea house |

**Utilities, with no cars:**
- Water and power arrive underground.
- Goods move by hand truck and cargo trike from the vertical farm, the
  greenhouses and the water works to the markets, at dawn through the back
  lanes.
- Waste goes to a recycling works beside the battery works at dawn.
- Fire safety uses lane-side hydrants and the ramp towers as escape routes.

## 4. Scale

The world is built at about 1.1 × real size: doors 2.4 m, storeys 3.25 m, the
hero about 1.9 m. City buildings follow it, on the 3.2 m building cell.

| Element | In the city |
|---|---|
| Home storey | 3.25 m |
| Shop or office storey | 4.0 m |
| Lane | 3.2 to 4.8 m |
| Shopping street | 6.4 to 8 m, often under an arcade roof |
| Main street | 9.6 to 12.8 m, tree-lined, with outdoor seating |
| Pencil building (narrow infill) | frontage 6.4 to 9.6 m, depth 16 to 20 m, 6 to 10 storeys |
| Tenement shophouse block (tong lau) | 16 × 22 m, 7 to 9 storeys |
| Mansion block (housing over a podium, in the market lanes) | 32 × 32 m podium, a 22 × 26 m tower, 18 to 28 storeys |
| Public housing point block | about 22 × 22 m, 30 to 40 storeys (about 100 to 130 m), on an open void deck |
| Public housing slab block | 13 to 16 m deep, 60 to 90 m long, 12 to 16 storeys (40 to 52 m), with open corridors |
| Downtown skyscraper | 40 to 45 m square on a podium, 35 to 55 storeys (140 to 220 m) |
| Downtown mid-rise | 20 to 34 m frontage by about 20 m deep, 10 to 22 storeys, filling the blocks round the towers |
| Street building (Old Moy, market lanes) | 6 to 10 m frontage by about 15 m deep, 4 to 9 storeys |
| The Windspire, the tallest | about 45 m square, about 70 storeys, about 280 m with its crown |
| Wind turbine (outside the bounds) | about 95 m to the hub; rotor 130 m across; about 160 m to the tip |
| City block | 45 to 70 m, crossed by lanes |

## 5. Architectural language: a layered vertical city

**Precedents:**
- **Tokyo** (Shimokitazawa, Nakameguro, Yanaka): narrow lanes; pencil
  buildings; tiled facades; rounded corner buildings; covered shopping arcades (shōtengai); police boxes (kōban).
- **Hong Kong** (Central, Sheung Wan, Mong Kok): tenement shophouses (tong
  lau) with verandas over the pavement; stacked vertical signs; mansion
  towers on podiums; footbridge networks; the Mid-Levels' sloping covered
  walkways.
- **Singapore** (Toa Payoh, Pinnacle@Duxton, SkyVille@Dawson): public housing
  estates of point and slab blocks on open void decks, covered linkways,
  hawker centres, and sky bridges with sky gardens.
- **Dubai and Las Vegas:** a downtown of skyscrapers standing up out of the
  desert; the lit Strip.
- **Desert old towns:** narrow, shaded lanes as the way to stay cool.

### Charter (proposed)

The shares are of the city's land.

- **Primary, about 55 percent: the mixed-use street building.** Pencil
  buildings and tong lau shophouses with homes over shops, 6 to 10 storeys,
  built shoulder to shoulder along lanes and streets.
- **About 20 percent: the public housing estate.** Point and slab blocks on
  open void decks, joined by covered linkways (section 7).
- **About 20 percent: downtown.** Skyscrapers of 35 to 70 storeys on two- or
  three-storey podiums, whose roofs carry the Deck.
- **Accent, about 5 percent: the civic landmarks.**
  - the Grand Hotel (art deco grandeur);
  - the library (white terraces);
  - city hall (stone and a clock);
  - the museum;
  - the giant playground in the park.

**Kit of parts:**

| Part | The rule |
|---|---|
| Massing | narrow lots and slender towers; setbacks at 6 to 8 storeys; corners rounded in superellipse curves, the city's signature silhouette |
| Ground floor | shopfronts open to the lane: roll shutters, cloth door curtains (noren), counters on the pavement; tong lau verandas (a column-carried overhang) that turn the pavement into a covered walkway |
| Walls | ceramic tile (the Tokyo facade) and mosaic tile (Hong Kong), painted render, concrete; glass curtain wall only on the office towers |
| Openings | punched windows on homes, with bay windows and balconies; ribbon windows on offices; all with superellipse corners |
| Exterior life | AC units, laundry poles, potted plants, balcony cages, water tanks and dish antennas, each placed where a person would put it |
| Signs | the signature motif: lit **picture signs** stacked vertically up the facades and hung across the lanes, never lettered; painted by Zara |
| Roofs | flat, with parapets; rooftop gardens, water tanks, laundry, rooftop bars on the hotel and offices |
| Circulation on the facade | open gallery corridors on the homes; round **ramp towers** in place of stair towers |
| Downtown | stone-and-glass towers on podiums; setbacks; each tower its own crown, lit at night; sky lobbies; the Windspire's observation deck |
| Public housing | point and slab blocks with open void decks at the ground; open corridors; laundry poles out of every window; painted block numbers as big graphic shapes (numerals only, as on any real estate); sky bridges and a sky garden between twin blocks |
| Shade | verandas, arcade roofs, shade sails, void decks, the Deck, street trees; pale tile and white roofs; misters |
| Palette | pale tile (cream, mint, salmon, pale blue and grey); concrete; sand and white against the desert; warm window light; saturated sign colour at night |

**Hierarchy.** The landmarks are polite: stone, bronze and generous
entrances. The street buildings are vernacular: tile, render, and signs.

**Exclusions:**
- cars, roads, car parks (the estate has none), garages, traffic lights and
  crosswalks;
- lawns that need watering, outside the park;
- trains and stations;
- lettered signs;
- blank glass boxes at street level;
- suburban houses with yards.

## 6. How people move, including vertically

The city is walked in **four layers**. Each has its own job, and they connect
often.

1. **The ground: streets, without cars.** Moy still has a full street
   network (user): only the cars are missing. Streets are paved, kerbless
   shared surfaces for walkers, bikes, cargo trikes and hand trucks, with
   street trees, lamps, benches and hydrants, and a clear service width
   down the middle for deliveries and the fire crew's hand carts. The
   hierarchy:
   - **main streets** (10 to 12 m, tree-lined): the **Park Ring** round the
     park, and the streets running out from it to the Rim Walk;
   - **shopping streets** (8 m), Arcade Street roofed in the market lanes;
   - **lanes** (4 m) through the blocks.

   **The streets, every one named (user):**

   | Street | Kind | Width | Runs |
   |---|---|---|---|
   | Park Ring | main street | 12 m | round the park; every district touches it |
   | Meridian Avenue | main street | 12 m | from the Rim Walk (east) to Clock Street, behind city hall |
   | Meridian North | main street | 10 m | from the Park Ring past Civic Plaza, the hotel and the Windspire to the Rim Walk |
   | Meridian South | main street | 10 m | from the Park Ring past Civic Plaza, the glass tower and BLOCK to the Rim Walk |
   | Clock Street | lane | 4 m | behind city hall, from Meridian North to Meridian South |
   | West Street | main street | 12 m | from the Rim Walk (west) to Arcade Street and Library Square |
   | North Street | main street | 12 m | from the Park Ring to the Rim Walk (north), through the estate |
   | South Street | main street | 12 m | from the Park Ring to the Rim Walk (south), through Market Square |
   | Arcade Street | shopping street | 8 m | Rim Walk to Rim Walk, north to south, roofed in the market lanes |
   | Market Street | shopping street | 8 m | from the Rim Walk (west) to Market Lane |
   | Cinema Lane | lane | 4 m | Rim Walk to Rim Walk through Old Moy |
   | Tank Lane | lane | 4 m | from the Rim Walk to Arcade Street |
   | Pine Lane | lane | 4 m | from the Rim Walk to Arcade Street |
   | Clinic Lane | lane | 4 m | from the Rim Walk to the Park Ring |
   | Library Lane | lane | 4 m | from Arcade Street to North Street, behind the library |
   | Museum Lane | lane | 4 m | from the Park Ring to Market Street |
   | Garden Walk | lane | 4 m | from Library Lane to Library Square |
   | Lamp Lane | lane | 4 m | from Arcade Street to Market Lane; the night market |
   | Estate Lane | lane | 4 m | from the Park Ring to the Rim Walk, east edge of the estate |
   | Market Lane | lane | 4 m | from the Park Ring to the Rim Walk, east edge of the market lanes |
   | Hotel Lane | lane | 4 m | from Estate Lane to the Rim Walk, behind the hotel |
   | Glass Lane | lane | 4 m | from Market Lane to the Rim Walk, behind the glass tower |

   **No dead ends:** every street meets another street, a square, the Park
   Ring or the Rim Walk at both ends (checked in the layout). Streets that
   reach the edge open onto the Rim Walk promenade.

   Blocks are 45 to 70 m, so no walk goes round more than about 60 m. In the estate, every block stands on an open void deck
   you can walk straight under, and covered linkways join the blocks to the
   hawker centre, the park and the Deck.
2. **The Deck, at +6.5 m (two storeys up).** An elevated pedestrian network
   after Hong Kong's footbridges. It runs over the podium roofs and bridges
   the streets, linking:
   - the hotel's mezzanine;
   - the library's second floor;
   - the office towers' lobbies;
   - the market's upper hall;
   - the downtown podiums and the Windspire's lobby;
   - the estate's neighbourhood centre.

   It is reached at every node by a **ramp tower** (a round tower with a
   spiral ramp inside, the world's ramp rule at city scale), a **glass public
   lift**, or an **inclined moving walkway** (the slope of an airport
   travelator, about 12°, standing in for Hong Kong's escalators within the
   no-stairs rule).
3. **The towers.** Lifts in every lobby. In realised buildings they stop at
   the realised floors; elsewhere they are facade-only. Homes have open
   gallery corridors and ramp towers outside.
   - **Downtown:** express lifts to sky lobbies every twenty or so floors,
     then local lifts. The Windspire's express lift runs to the observation
     deck, which is realised and looks out over the whole world.
   - **The estate:** lifts stop at every floor. The twin point blocks share
     **sky bridges and a sky garden at the 26th floor** (after Pinnacle@Duxton),
     realised as a route across.
4. **The roofs.** A designed roof network. Neighbouring street buildings step
   by up to one storey, with gaps of 2 to 4 m across lanes, so a player can
   cross the city roof to roof: gardens, water tanks, laundry lines and the
   rooftop bars on the way. Ramp towers and the hotel's roof lift reach it.

**Swinging with the Leaf Hat** (the vine reaches 78 m; its rope runs 12 to
52 m; an anchor must stand at least 7 m above the swinger):
- The main streets and the shopping streets are **swing corridors**: walls
  of 16 to 40 m (5 to 12 storeys) on both sides, 6 to 13 m apart, with
  cornices, sign gantries and the towers as anchors.
- The towers round the park (the hotel's, the estate's Block 3, the
  library's roof) are the long anchors that carry a swing across the park,
  with the giant playground's 12 to 20 m towers as low anchors in the
  middle.
- **Downtown** is the city's great swing: skyscrapers stand 25 to 50 m apart,
  inside the rope's 52 m, so a wearer can chain from tower to tower.
- Out in the desert the only anchors are the wind turbines' towers.
- The lanes are too tight to swing in and are for walking.

**Climbing:** the library's terraces, the tong lau verandas, balconies, the
sign gantries and the ramp towers' outsides.

## 7. Districts (schematic; coordinates follow approval)

**Every block is built out** (user): buildings stand shoulder to shoulder to
the street line on every side, as in any real city. Open ground is only
ever a street, a plaza, the park, a courtyard inside a block, or the space
under an estate block's void deck. There is no leftover ground between
buildings.

```
                                   N
             (NW, outside: the water works, wells, water tower)
   ┌─────────────────── NORTH ESTATE ──────────────────────────┐
   │  point and slab blocks on podiums · Estate Square and the │
   │  hawker centre on North Street                            │
   ├────────────┬─────────────────────────────┬────────────────┤
   W, outside: the battery works; then desert, the mountains and, beyond
   them, the planetary ocean (no roads out)
W  │  OLD MOY   │ Library    THE PARK     Civic│ DOWNTOWN       │ E: desert,
   │  lanes,    │ Square  giant playground Plaza│ Meridian Ave: │  then the
   │  cinema,   │ (library  tea house · chess   │ the Windspire,│  main
   │  café,     │  on its   pond          (hotel│ Tanglewire,   │  plateau's
   │  clinic,   │  north)   — the Park Ring —  N, │ BLOCK        │  cliff; no
   │  police box│            museum (S)   hall S)│               │  road
   ├────────────┴─────────────────────────────┴────────────────┤
   │ THE MARKET LANES: Market Square on South Street, the wet  │
   │ market, the night market, the arcade, Helmsmith, school   │
   └──────────────────────────── S ────────────────────────────┘
       the Rim Walk rings the whole city: the bounds;
       the city blorbs stay out in the desert beyond it
       (just beyond: four wind turbines, two east, two west)
```

- **The park, at the centre** (user). About 130 × 100 m, ringed by the Park
  Ring, the main street that ties the city together:
  - the **giant playground** at its heart (section 7b);
  - four quarters: the dry garden, the reed pond, the parasols with Old Fu's
    tea house and the chess terrace, and the great lawn (section 7a);
  - four steel wind trees round the playground;
  - **Garden Row**, a short row of three older townhouses, faces it from
    the west, across the Park Ring from Old Moy.

  Every district touches the Park Ring, so the park is the city's common
  ground, and the Deck runs round it.
- **The plazas** (user: "I like the idea of plazas"):
  - **Civic Plaza**, on the park's east side, is city hall's forecourt.
    **City hall heads the plaza on its axis**, facing west across the plaza
    to the park. The plaza's sides are private and unlike each other: the
    Grand Hotel on the north, the glass tower on the south. Shade trees,
    misters and benches; Pia busks here; the Deck's main ramp tower.
  - **Library Square**, on the park's west side where West Street arrives,
    with the library along its north side and the terraced steps where
    people sit.
  - **Market Square**, on South Street, ringed by stalls by day and by the
    night market after dark, with the wet market hall on its east side.
  - **Estate Square**, on North Street in the North Estate: the estate's
    neighbourhood centre, with the hawker centre on its south side and the
    centre building (minimart, kindergarten, community club) on its north.
  - **Cinema Square**, a small square in Old Moy where the Moonlight Cinema
    and Sol's café face each other.
- **Arrival.** No road reaches Moy. The hero comes on foot across the open desert, and any lane's gap in the Rim Walk lets
  him in. From the plateau side the grand way in is **Meridian Avenue**
  (renamed from Harbour Street: there is no harbour in a desert), the
  palm-lined main street. It runs in to the back of city hall and divides
  round it, its two branches passing the Windspire, the hotel, the glass
  tower and BLOCK, to open onto **Civic Plaza** and, past it, the park. The
  Grand Hotel's revolving door is on the plaza.
- **The museum** faces the park from the Park Ring's south side.
- **Old Moy** (west; renamed from Lantern Lane, user) is the **well town**,
  the settlement that was here before the city (user approved, 2026-10-12).
  It stays tall (user): its buildings are 4 to 9 storeys.
  - **Why it is tall.** The first settlers drilled down to the old river's
    water under the gorge floor, and every family wanted to live within
    reach of the wells. So the town grew up instead of out: narrow **tower
    houses** of 4 to 9 storeys, shoulder to shoulder, the lanes between
    them kept cool by their own shade. Precedent: Shibam in Yemen, the
    sixteenth-century "Manhattan of the desert", and the tower houses of
    old Sana'a. When the Windworks came, the new city was laid out round
    this dense old core, and its narrow tall houses became the model for
    the pencil buildings across Moy.
  - **How it looks.** Thick, pale lime-plastered lower walls that thin as
    they rise; small deep windows low down and larger screened windows high
    up; roof terraces where families sleep on summer nights; later tiled
    pencil buildings filling the gaps between the old houses.
  - **Wind towers.** The old houses carry rooftop wind towers that catch
    the breeze high above the lanes and send it down through the rooms.
    Moy lived by its wind long before the turbines; the Windworks is the
    newest form of an old habit.
  - **The wells.** The first well, capped now, stands on Cinema Square with
    its stone trough and the oldest shade tree in the city. **Tank Lane** is
    named for the old water tanks and still leads toward today's water
    works.
  - **Where the picture signs began.** Families marked their tower houses
    with painted pictures instead of names, which is why no sign in Moy
    has ever carried lettering. Zara's lit signs descend from the old house
    marks, and the oldest painted marks still show on Old Moy's walls.
  - **Who lives here.** Elizabeth, Dan and Jammer live in an old tower
    house on Arcade Street (the Reese–Miller house), with a wind tower and
    a roof terrace; Jammer's room, full of farm drawings, is at the top.
    Elizabeth and Dan walk to work downtown every morning, along West
    Street, across Library Square and the park to Civic Plaza and the glass
    tower, about 300 m. Pinestein's laboratory sits on one of the tallest
    tower houses, its antennas beside the old wind tower. Sol's café and the
    bakery are in tower houses; Sora's mother kept the first rooftop
    greenhouse on an Old Moy terrace. The Moonlight Cinema was built later,
    into the old fabric.
  - **Its places:** Sol's café and the Moonlight Cinema on Cinema Square,
    the bakery, the clinic, the police box, Pinestein's rooftop laboratory,
    Mara's rooftop studio, the Reese–Miller house.
- **The market lanes** (south) hold Market Square, the wet market, the night
  market, the covered shopping arcade, the Helmsmith, Hiro's store, Wing Fat
  Mansion and the school.
- **The North Estate** (north; renamed from Parkside Estate, user) is the
  public housing, planned the way Singapore's estates are (user): as
  **precincts**, not as lots. North Street divides it into a west and an
  east precinct, each a single site with no private lots in it.
  - **Blocks stand free in shared gardens.** Point blocks of 30 to 40
    storeys stand well apart round landscaped courts, so every flat has
    light, air and a view: lawns and shade trees on reclaimed water, a
    playground and a fitness corner in each precinct, chess pavilions, and a
    community garden. This open ground is designed and used, not left over.
  - **Slab blocks hold the street edges.** Block 6 lines the Park Ring and
    Block 7 lines North Street, with shops in their void decks, so the
    streets keep a built frontage.
  - **Void decks** under every block: shade, chess tables, letterboxes, and
    room for weddings and wakes.
  - **Covered linkways** join every block's void deck to the neighbourhood
    centre, North Street and the Deck.
  - **The neighbourhood centre** is Estate Square on North Street: the
    hawker centre (Siti's stall) on its south side, facing the park, and the
    centre building on its north (minimart, kindergarten, community club,
    the Housing Board office, a roof garden). There is no car park.
  - **The twins**, Blocks 4 and 5, stand on either side of the west
    precinct's court, joined by a sky bridge and sky garden at the 26th
    floor.

  The distances between blocks are compressed for the game; real estates
  set facing blocks further apart. The Housing Board (Juno) runs the estate.
- **The giant playground**, in the park: see section 7b.
- **Downtown** (east) is the city's workplace and its skyline. **The towers
  stand at the centre, not the edge** (user): they take the most central,
  best-connected land, on full-size blocks round Civic Plaza and along the
  Park Ring, each tower (40 to 45 m square) on a podium. Height rises toward
  the park and the plaza and steps down to the Rim Walk, so the skyline
  peaks in the middle when seen from the desert, and the towers round the
  park anchor swings across it. Towers are never squeezed onto clipped
  sites at the rim.
  - the **Windspire**, the Windworks' headquarters, about 280 m with an
    observation deck, beside the hotel on Meridian North, facing the plaza;
  - the **glass tower** on the plaza's south side (Raman & Reese and
    Tanglewire);
  - the **north tower** (start-up floors) and **south tower** (flats over
    offices) on the Park Ring's east corners;
  - **BLOCK**, the research institute, 6 storeys round a court, beside the
    glass tower on Meridian South;
  - **mid-rise blocks of 10 to 22 storeys** filling the rest of downtown
    round the towers, offices and flats on large footprints (20 to 34 m
    frontage), so the towers rise out of a solid mid-rise mass instead of
    standing among small buildings (user).

  The Grand Hotel's guest tower rises on the plaza's north side.

### 7a. The park and the giant playground (proposed, 2026-10-12)

The park is the city's common ground: about 130 × 100 m at the centre of
Moy, ringed by the Park Ring, with the Deck running round it at +6.5 m. In a
desert it has to earn every drop of water, so most of it is shade and dry
garden, and the one green lawn and the one pond each have a job.

**References:**
- **The Persian four-part garden (chahar bagh):** a garden quartered by two
  crossing walks, with shade along every path. Moy's quarters are divided by
  tree-lined walks instead of water channels.
- **Gardens by the Bay, Singapore:** the Supertrees, steel trees planted
  with climbers that shade, light and frame a park.
- **The Arbre à Vent (wind tree), Paris:** a steel tree whose leaves are
  small silent wind turbines. Moy's version is the Windworks' gift to the
  city.
- **Metropol Parasol, Seville:** a timber canopy of giant parasols shading
  a public square.
- **Bishan–Ang Mo Kio Park, Singapore:** a park that cleans water as it goes,
  with reed beds and boardwalks.
- **Bryant Park, New York:** a central lawn ringed by a double row of trees,
  movable chairs and chess tables.

**Plan.** Two walks cross at the centre:
- the **civic axis**, east to west: from city hall, across Civic Plaza,
  through the park, to Library Square and the library;
- the **north–south walk**: from Estate Square on North Street, through
  the park, to Market Square on South Street.

The giant playground stands where they cross. A double row of shade trees
(ghaf and neem, both drought-hardy) lines the whole edge inside the Park
Ring, with benches and movable chairs under them. Each quarter has a job:

| Quarter | What it is | Why it is there |
|---|---|---|
| **North-west: the dry garden** | Ghaf groves, agave, aloe, desert marigold and boulder outcrops on gravel; never watered. Orin Pike's teaching garden of the desert's own plants | Next to the old town and its wells: the desert as it was |
| **North-east: the reed pond** | A shallow pond of reed beds and open water, crossed by boardwalks. It polishes the city's reclaimed water before it goes back to the street trees; dragonflies, frogs, herons | Beside the hotel and Civic Plaza: water working, not for show (user: no opulent fountains) |
| **South-west: the parasols** | Old Fu's tea house and the chess terrace, under a timber canopy of giant parasols | Facing Old Moy and Garden Row; the Hos play here every afternoon |
| **South-east: the great lawn** | The one irrigated lawn, for picnics, lying down and evening music; the park lodge on its edge | Facing the market lanes and the glass tower: lunch from the market, and the office workers' hour off |

**The wind trees.** Four steel wind trees, 32 m tall, stand at the corners
of the playground. Bougainvillea climbs their trunks. Their crowns carry
hundreds of small leaf-shaped turbines that turn silently in the west wind
and light the park at night. Misters in the crowns cool the playground
below. They are also the park's high anchors (see below).

### 7b. The giant playground

**References:**
- **Monstrum, Copenhagen:** sculpted climbing landscapes that are one big
  object, not a kit of parts.
- **The Woods of Net, Hakone Open-Air Museum, and Toshiko Horiuchi
  MacAdam's knitted nets:** giant hand-knitted nets to climb, roll and
  bounce on.
- **Singapore's 1979 mosaic dragon playground, Toa Payoh:** a single strong
  shape every child in the city knows.
- **The fuwafuwa domes of Japanese parks:** soft white mounds to jump on.
- **Berliner Seilfabrik's rope pyramids:** net towers up to 10 m that
  children climb inside.
- **BMX pump tracks:** packed-earth loops of rollers and banked turns.

**Shape.** One sculpted object about 56 m across at the crossing of the two
walks. It is a desert landscape in miniature: sand dunes on the west,
canyon towers in the middle, a splash pad running toward the reed pond on
the east. Its towers are pale ochre and terracotta like the desert; the
nets and slides are the city's sign colours.

**The parts, from the ground up:**
1. **The pump track:** a 4 m packed-earth loop round the whole playground
   (radius 24 to 28 m), with rollers, banked turns and one long tabletop
   jump over the dunes. Children run it and ride it on scooters.
2. **The dunes:** a sand field of soft mounds on the west, with the long
   wave slide coming down onto it.
3. **The bounce court:** a soft rubber floor on the south, ringed by high
   perches.
4. **The splash pad:** jets from the ground on the east, draining into the
   reed pond.
5. **The canyon towers:** three satellite towers of 12, 14 and 16 m round
   the central **Lookout**, 20 m tall, joined by rope bridges at 9 m.
6. **The great net:** a hand-knitted net slung between the towers at 6 to
   8 m, to climb, roll and bounce on.
7. **The slides:** a tube slide from the 16 m tower, a spiral slide from the
   Lookout, and the wave slide onto the dunes.
8. **The hoops:** eight rings, each 3 m across, hung on cables from the wind
   trees, spiralling up round the Lookout and down over the splash pad.

**Built for the hero's platforming.** Every route is reachable on foot by
the residents' children, through nets, ramps and climbing walls (no stairs,
by the ramp rule). Each suit power also has its own way through, sized to
the hero's real movement (`player.gd`):

| Movement | The hero's reach | What the playground gives it |
|---|---|---|
| Ordinary jump | about 1.4 m up; gaps of about 3 m running, 4.5 m sprinting | The Lookout's spiral of platforms rising 1.2 m at a time; tower-to-tower hops of 2.5 to 4 m |
| Blorb bounce | about 2.5 m off a called blorb | Shortcuts onto the nets and the lower towers |
| Blorb super-jump (a timed jump on the bounce) | about 12 m | The bounce court's ring of high perches at 11 to 12 m, reachable only this way, as in the Demo World's pit |
| Leaf Hat vine swing (rope 12 to 52 m; anchor at least 7 m above) | from tower tops to the wind trees' crowns | The **swing loop**: the four wind trees (32 m, about 52 m apart) and the Lookout (20 m) make a circuit round and over the playground, and out across the park to the towers on the Park Ring |
| Air: cloud platforms and hover | a cloud ahead at shoulder height or underfoot | The **cloud gap**: a 14 m gap from the Lookout's top to the high deck in a wind tree's crown, too far to jump |
| Water jets and Fire hover | a level hover, then flight with four limbs | **Hover gates**: rings over the splash pad and a high platform on the 16 m tower reached only from the air |
| Crystal skates | a self-laid ribbon of ice, anywhere in three dimensions | **The ribbon run**: thread all eight hoops in one flight, up round the Lookout and down over the splash pad |
| Ground dirt bike | rear wheel on dirt; the full bike with the hat | The pump track and its tabletop jump |
| Swimming | — | The reed pond, deep enough to swim in its middle |

Every power belongs to every playable character, so the playground's
features are world-sized and absolute, and Xiao Hou Zi uses the same
routes as the hero. Nets and climbing walls give a small body a way up
wherever a big body jumps.

**Collision:** all towers, platforms, nets, slides, perches, hoops and wind
tree trunks and crown decks are solid; the nets are standable; the hoops'
rims are solid and their centres open. Sand, water and leaves are not.

**People:** Lily and Kofi play tag across it after school. Jammer's
favourite perch is the 12 m bounce perch, and he hasn't been on it since he
left for the farm. Parents sit on the benches round the pump track. No text
explains any route; the shapes do.

**Decided (user):** the Snow snowboard does not sandboard on the dunes, and
the Penguin belly slide does not work on the slides. The rest of the park
and playground design is approved.

### 7c. Downtown's towers (proposed, 2026-10-12)

Downtown has five towers. Each answers the same three things in its own
way: the desert sun, the west wind, and the city's own history. They share
Moy's language (superellipse corners, pale ceramic, crowns lit at night in
the picture-sign colours) but no two look alike. Each rises from a podium
that holds its street edge and meets the Deck at +6.5 m.

**1. The Windspire** (the Windworks' headquarters, about 70 storeys, 280 m)
- **Idea:** the city's wind made into a building.
- **References:**
  - **Shanghai Tower:** a plan that twists as it rises, to shed wind.
  - **Pearl River Tower, Guangzhou:** a curved facade funnelling wind
    through openings that hold turbines.
  - **Burj Khalifa:** a three-lobed plan that steps back as it climbs.
- **Form:**
  - a rounded-triangle plan that turns a quarter-turn from base to crown,
    so its edges spiral up the skyline;
  - three **wind gaps**, at the sky lobbies on floors 20, 40 and 60: open
    slots straight through the tower, where large turbines spin in the west
    wind, visible from the whole city;
  - pale fritted glass behind vertical terracotta fins, which shade the
    west face from the afternoon sun.
- **Crown:** an open steel lattice round the observation deck, with a slow
  vertical-axis turbine as its spire, lit white at night.
- **Play:** the fins and the wind-gap ledges are the highest swing anchors
  and climbing holds in the city. The observation deck is realised.

**2. The glass tower** (Raman & Reese and Tanglewire, about 45 storeys, 180 m)
- **Idea:** a modern tower veiled in the old town's screens.
- **References:**
  - **Al Bahar Towers, Abu Dhabi:** a moving mashrabiya screen of panels
    that open and close with the sun.
  - **Doha Tower:** a cylinder wrapped in patterned screens.
- **Form:**
  - a round-cornered square tower in clear glass, wrapped by an outer skin
    of screen panels;
  - by day the panels close against the sun on the side it strikes; at dusk
    they fold open and the tower goes from screened to glass;
  - each panel is pierced with one of **Old Moy's painted house marks**,
    the pictures the city's signs come from, so the tower carries the old
    town's history on its face.
- **Crown:** the screens stop short of the top; a glass crown lit warm
  amber.
- **Play:** the screen frames are a climbable lattice from the podium up.

**3. The north tower** (the start-up floors, about 45 storeys, 175 m)
- **Idea:** a tower that changes as its tenants come and go.
- **References:**
  - **Nakagin Capsule Tower, Tokyo:** plug-in capsules on a concrete core.
  - **CapitaSpring, Singapore:** an open garden floor halfway up.
- **Form:**
  - a concrete core with **office capsules** plugged into it, each a
    start-up's studio, in different sizes and colours of glazed tile, so the
    tower's outline is stepped and irregular;
  - start-ups move in and out a capsule at a time, so the tower never looks
    the same twice;
  - a **sky garden** open to the air at its middle, on floors 22 and 23,
    shaded and planted.
- **Crown:** the topmost capsules, stacked unevenly.
- **Play:** the city's best climbing tower; the capsules' tops are ledges
  all the way up. Theo works in one.

**4. The south tower** (flats over offices, about 40 storeys, 150 m)
- **Idea:** the desert's dunes, built in balconies.
- **References:**
  - **Aqua Tower, Chicago:** concrete balconies whose edges ripple across
    the facade like a landscape.
  - **The tower houses of Shibam:** deep, shaded openings in pale walls.
- **Form:**
  - every floor's balconies reach out a different distance, so the edges
    ripple across the whole tower like sand dunes seen from above;
  - deep balconies shade the windows behind them, with screens and potted
    plants;
  - pale, sand-coloured concrete and ceramic tile.
- **Crown:** roof terraces stepping back, the residents' gardens.
- **Play:** the rippling balcony edges are a staircase of ledges for
  climbers and swing anchors along the south of Civic Plaza. Dr. Kask lives
  near the top.

**5. The Grand Hotel's guest tower** (21 floors on a 20 m podium, about 100 m to the lantern; full brief in section 8)
- **Idea:** the grand old hotel, older than the other towers.
- **References:**
  - **Peace Hotel, Shanghai:** art deco, with a pyramidal copper roof.
  - **Chrysler Building, New York:** stepped setbacks and a lit crown.
- **Form:**
  - cream stone and bronze art deco, rising in setbacks from the podium;
  - vertical piers between the windows.
- **Crown:** a green-copper pyramid with a lantern at its peak, lit at
  night, the first landmark seen from the plaza.

**The skyline together:** the twisting Windspire with its spinning wind
gaps is the tallest; the screened glass tower, the plug-in capsule tower and
the dune-balconied flats step down around it; the old copper-crowned hotel
stands in front, facing the park.

### The plan file

The layout above is code-ready (2026-10-12): `scripts/city_plan.gd`
(`CityPlan`) holds every named street, square, precinct, numbered building,
lot, courtyard, resident's home and turbine. It is generated by
`tools/city_layout.py`; streets and buildings are changed there and the tool
rerun, never by hand in the plan. `tools/validate_city_plan.tscn` checks the
plan before anything is built, and runs in the pre-push hook
(`VILLAGE=city sh tools/check_village_layout.sh`):
- everything built stands inside the Rim Walk, and the works outside it;
- no footprints overlap, and nothing is built on a street or square;
- every building in a street block has a face on a street, square, the park
  or the Rim Walk, within 6 m across open ground (a front garden or yard);
  estate blocks stand in a precinct instead;
- every street meets another street, a square or the Rim Walk at both ends;
- building numbers are unique and every resident's home exists;
- the turbines keep 280 m from the Jungle and Ice plateaus' centres.

### Building schedule (proposed, 2026-10-12)

Every building in Moy is planned (user). The plan in the visualization draws
each one: about 190 ordinary buildings and the 52 numbered buildings
below.
- **Old Moy and the market lanes:** street buildings, one per lot, 6 to
  10 m of frontage by about 15 m deep, 4 to 9 storeys, homes over shops.
- **Downtown:** mid-rise blocks of 10 to 22 storeys on 20 to 34 m
  frontages, round the towers.
- **The North Estate:** no lots; its blocks stand in precinct gardens.

**Every building has a street face** (user). Each block is filled from
its street edges inward, so every building fronts a street, lane, square
or the Rim Walk. Ground left over inside a block is a shared garden
courtyard; the leftover strips along the Rim Walk are gardens. Green on
the plan means gardens and the park only.

Raman & Reese and Tanglewire share the glass tower on Civic Plaza. The
start-up floors are in the north tower. Dr. Kask's flat is in the south
tower. Five ramp towers (marked R on the plan) stand at the Deck's corners
round the park and on Civic Plaza.

**The park**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 9 | Tea house | 14 × 12 m | 1 storey; flat above and keeper's room behind | Old Fu (keeper); Kenji Mori (above) |
| 10 | Park lodge | 10 × 8 m | 1 storey | Orin Pike (park keeper) |
| 11 | Giant playground | about 36 m across | climbing towers 12–20 m | Lily, Kofi |

**Downtown**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 1 | Grand Hotel | 52 × 60 m | podium of 4 levels round a 20 m atrium; guest tower of 21 floors to a copper crown, about 100 m (section 8) | Lucinda Wah (top-floor flat); Felix, Ah Keung, Iris at work |
| 2 | City hall | 34 × 60 m | 4 storeys and a clock tower, at the head of Civic Plaza | Mayor Teodora Vance, Kenji Mori (clerk) |
| 12 | Windspire | 42 × 42 m | about 70 storeys, 280 m, twisting, with three wind gaps (7c) | the Windworks (headquarters, observation deck) |
| 13 | Glass tower | 40 × 40 m | about 45 storeys, 180 m, in moving screens pierced with the house marks (7c) | Raman & Reese (Elizabeth, Priya, Venn); Tanglewire (Dan) |
| 14 | North tower | 40 × 40 m | about 45 storeys, 175 m, plug-in capsule offices (7c) | start-up floors (Theo Park) |
| 15 | South tower | 40 × 40 m | about 40 storeys, 150 m, dune balconies (7c) | flats over offices; Dr. Vera Kask |
| 16 | BLOCK | 38 × 42 m | 6 storeys, research labs round a court | Dr. Vera Kask (director) |

**North Estate**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 18 | Block 2 | 22 × 22 m | point block, 30 storeys, east precinct | Siti Rahman |
| 19 | Block 3 | 22 × 22 m | point block, 36 storeys, on the Park Ring | Juno Rell (20th floor) |
| 20 | Block 4 | 22 × 22 m | twin point block, 40 storeys; sky bridge and sky garden at the 26th floor | homes (no one the hero meets) |
| 21 | Block 5 | 22 × 22 m | twin point block, 40 storeys | Dr. Imani Osei and Kofi |
| 22 | Block 6 | 54 × 14 m | slab block, 14 storeys, shops in its void deck on the Park Ring | homes (no one the hero meets) |
| 23 | Hawker centre | 38 × 20 m | 1 storey, open-sided, on the Park Ring and Estate Square | Siti's laksa stall |
| 49 | Block 7 | 14 × 50 m | slab block, 14 storeys, shops in its void deck on North Street | homes (no one the hero meets) |
| 50 | Block 8 | 22 × 22 m | point block, 34 storeys, east precinct | homes (no one the hero meets) |
| 51 | Neighbourhood centre | 38 × 32 m | 2 storeys: minimart, kindergarten, community club, roof garden | Juno Rell (Housing Board office) |

**Old Moy**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 3 | Library | 45 × 62 m | 5 storeys, terraced atrium | Ada Fong, Nia Calder, Benji Okoro |
| 5 | Moonlight Cinema | 30 × 28 m | 2 storeys, built later into the old town; flat above | Leon Duarte (lives above) |
| 6 | Police box | 6 × 8 m | 1 storey, back room | Kate Byrne |
| 7 | Clinic | 14 × 18 m | 3 storeys; flat above | Dr. Arjun Mehta (lives above) |
| 17 | Block 1 | 22 × 22 m | point block, 32 storeys, west precinct | Tomas Wren |
| 24 | Garden Row | 23 × 18 m | 3 townhouses, 3 storeys, facing the Park Ring | Teodora Vance; Ada Fong and Sora Ishida; Priya Raman |
| 25 | Sol's café | 16 × 10 m | old tower house, 5 storeys; flat above | Sol Brant |
| 26 | Bakery | 10 × 16 m | old tower house, 6 storeys; flats above | Felix Tanaka (above) |
| 27 | Pinestein's building | 9 × 16 m | old tower house, 9 storeys; laboratory on the roof beside its wind tower | Palbert Pinestein (top floor) |
| 28 | Mara's building | 9 × 16 m | 8 storeys; rooftop studio | Mara Quill |
| 29 | Benji's building | 8 × 16 m | 6 storeys | Benji Okoro |
| 30 | Theo's building | 8 × 16 m | 6 storeys | Theo Park |
| 31 | Yuki's building | 8 × 16 m | 6 storeys | Yuki Hayashi |
| 32 | Suri's building | 8 × 16 m | 7 storeys | Suri Vale |
| 52 | Reese–Miller house | 10 × 16 m | old tower house, 7 storeys; wind tower and roof terrace | Elizabeth Reese, Dan Miller and Jammer (away at the farm) |

**Market lanes**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 4 | Natural history museum | 62 × 38 m | 3 storeys, top-lit hall | Dr. Imani Osei (curator) |
| 8 | Primary school | 23 × 30 m | 3 storeys, roof playground | Yuki Hayashi (teacher); Lily, Kofi |
| 33 | Wet market | 40 × 38 m | 2 storeys; sign studio on the roof | Rosa Delgado, Wen Li; Zara Quinn (roof studio) |
| 34 | Market flats | 28 × 24 m | tong lau, 8 storeys | Mei and Lily Chan, Rosa, Wen, Pia Rowe |
| 35 | Wing Fat Mansion | 32 × 24 m | mansion block, 22 storeys on a podium | Ah Keung, Iris Dune, Nia Calder, Venn Harlow, Dax Merrow, Bea and Wilfred Ho |
| 36 | Vertical farm | 22 × 24 m | windowless, 12 storeys of growing racks | Sora Ishida |
| 37 | All-night store | 8 × 12 m | 5 storeys; flat above | Hiro Sato |
| 38 | Helmsmith | 10 × 12 m | 2 storeys; home behind | Gideon Hale |
| 39 | City works yard | 26 × 12 m | sheds and a flat | Kade Morrow |

**Beyond the Rim Walk**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 40 | Battery works | 22 × 16 m | 2 storeys | Omar Haddad (flat) |
| 41 | Recycling works | 18 × 12 m | 1 storey | — |
| 42 | Water works | 20 × 14 m | pump house and keeper's house | Rafael Ortiz |
| 43 | Water tower | 10 × 10 m | 35 m | — |
| 44 | Fish tanks | 20 × 16 m | covered tanks | — |
| 45–48 | Wind turbines (4) | tower 6 m at the foot | 95 m to the hub, 160 m to the tip | the Windworks; Omar Haddad |

### Site and land

With no roads, a quarter of the land goes to circulation rather than a
third. The program comes to about 75,000 m², and about 100,000 m² with lanes
and streets. The flat pad grows from a radius of 78 m to about **200 m**
(400 m across). Its centre moves a little west, to about (−560, 0). The
gorge floor there is already within ±2.4 m of flat.

Downtown and the estate add height, not land, so the radius holds. The works
beyond the bounds need about 100 m more on the east, south-west and
north-west, inside the 110 to 140 m gaps to the plateaus and the skirt.

## 8. The Grand Hotel (rest point): building brief (proposed, 2026-10-12)

### 8.1 People and purposes

**Why a grand hotel in a city no road reaches.** Moy has almost no outside
visitors, so the hotel lives on the city itself, the way grand hotels in
real cities do:
- **The city's living room:** afternoon tea and drinks under the
  chandelier, weddings and celebrations in the atrium, dinner in the
  restaurant on the mezzanine.
- **Long-stay residences:** five floors of suites let by the year, a
  tradition of the hotel since Lucinda's grandfather's day, after Raffles
  in Singapore and the Chelsea in New York.
- **Guest rooms** for staycations, for families between homes, and for the
  rare traveller who crosses the desert on foot, like the hero.

**History.** Lucinda Wah's grandfather built it in the Windworks' first
boom, as the city's first tall building. It is older than every other
tower, which is why it alone is art deco stone and bronze among the glass.
The Blackout is the night its chandelier went dark for the first time.

**Who works here** (the people the hero meets):

| Person | Role | Where |
|---|---|---|
| Lucinda Wah | general manager; keeps the reception desk herself in the evenings, as her grandfather did, so she is the rest point's keeper | the desk, her office behind it, her flat on the top floor |
| Felix Tanaka | concierge | the concierge desk by the door |
| Ah Keung | doorman | the revolving door, forty years |
| Iris Dune | florist | her flower stand inside the door; she dresses the atrium each morning |

Kitchen, housekeeping and laundry staff work behind service doors and are
never seen on the public floors.

**What goes in and out.** Guests and visitors by the revolving door on
Civic Plaza, the Deck door at the mezzanine, and the park terrace. Food,
linen and stores by cargo trike to the loading door on Hotel Lane at
dawn; laundry the same way. Waste to the city sewer and on to the water
works' reclamation (see 2a).

**References:**
- **Peace Hotel, Shanghai (1929):** art deco stone, bronze and a pyramidal
  copper roof; its jazz bar.
- **Raffles Hotel, Singapore:** shaded loggias and verandas, the Long Bar,
  and long-stay suites.
- **White Swan Hotel, Guangzhou:** the indoor rock garden and pavilion in
  its atrium (the waterfall left out: no opulent water).
- **Chrysler Building, New York:** setbacks and a lit crown.
- **Old Moy's tower houses and wind towers:** the hotel cools itself the
  way the old town does.

### 8.2 Site

The north side of Civic Plaza: 52 m (east–west) × 60 m (north–south).
- **South face, the front:** on Meridian North, facing across it to Civic
  Plaza and city hall.
- **West face:** on the Park Ring, facing the park.
- **North face, service:** on Hotel Lane.
- **East face:** a party wall with the Windspire's podium.
- **The Deck** passes along the south face at +6.5 m, along Meridian North.

### 8.3 Program and stacking

A **podium** of four levels round a full-height atrium, with a **guest
tower** rising from its north half. The structural lines are shared by
every level: the atrium's edges, the tower's walls and its central core.

| Level | Height | Contents |
|---|---|---|
| **Ground** | 0 to +6.5 m (one grand storey) | Loggia and revolving door on the south; vestibule; the **atrium** (26 × 22 m), with the dry rock garden and pavilion at its centre and the **double ramp** up to the mezzanine; reception and Lucinda's office (east); the concierge desk and Iris's flower stand by the door; the **Long Bar**, opening onto the park terrace (west); public washrooms; lift lobby (north); kitchen, stores, staff room and the loading door on Hotel Lane (north-east) |
| **Mezzanine** | +6.5 m, the Deck's level | A gallery 2.4 m wide round the atrium; the **Chandelier Room** restaurant along the west, with a balcony over the park; the tea lounge and washrooms along the east; the **Deck door** in the south face |
| **Levels 3 and 4** | +11.5 to +20 m | Galleries round the atrium; function rooms (west), the hotel's offices and the luggage room (east); the chandelier's winch room under the lantern |
| **Podium roof** | +20 m | The **roof garden**: shade trees in planters, the terrace bar, and two **wind towers** after Old Moy's; the atrium's glass **lantern roof** between them |
| **Tower floors 1 to 14** | +20 to +68 m | Guest rooms, 12 to a floor round a central core |
| **Tower floors 15 to 19** | +68 to +85 m | Long-stay residences, 6 suites to a floor |
| **Tower floor 20** | +85 to +88 m | The grand suites, among them **the party's suite** facing the park |
| **Tower floor 21** | +88 to +91 m | Lucinda's flat, the manager's flat, with its own terrace |
| **The crown** | +91 to +100 m, lantern above | The green-copper pyramid, holding the tower's water tanks (filled from the wells, like the roof tanks across the city) and, at its peak, the lit lantern |

**The tower**, 33 × 22 m, stands on the podium's north half. Its walls
come straight down to the ground as the north band's walls, so nothing
stands on the atrium. The atrium's lantern roof spans only the podium's
south half.
- **Core:** three guest lifts, one service lift, and an escape **ramp tower**
  (a spiral ramp, by the world's ramp rule), carried from the ground to
  floor 21.
- **Corridor:** a ring corridor 1.8 m wide round the core.
- **Rooms** along all four faces, each with its own bathroom on the
  corridor side and the window on the outer wall.

**The atrium void** (26 × 22 m) passes through the mezzanine and levels 3
and 4 up to the lantern at +20 m. Every gallery's rail stands on the void's
one boundary, and no wall below runs under it. The chandelier hangs from
the lantern's central truss.

**Circulation:**
- **Visitors:** revolving door → vestibule → atrium → double ramp or lifts
  → mezzanine.
- **Guests:** atrium → lift lobby → tower lifts.
- **Staff and goods:** Hotel Lane → loading door → kitchen and service lift,
  never crossing the atrium.
- **From the Deck:** the mezzanine door → the gallery → the lifts.

**The double ramp.** Two curving ramps rise either side of the rock garden
from the atrium floor to the mezzanine, 6.5 m. At the world's 32° each
runs about 10.4 m on plan, curving round the pavilion. Each is 2.4 m wide
(grand, two people abreast), with a 3 m landing at its foot and its head.

### 8.4 The chandelier

- About **8 m across and 9 m tall**, hung from the lantern truss so its
  lowest tier is 7 m above the atrium floor.
- **Three thousand crystals** in tiers round a bronze frame, lit from
  within. Lucinda knows them by their faults. During the Blackout they went
  dark for the first time in the hotel's history.
- **A winch room** under the lantern lets the whole chandelier be lowered
  for cleaning, once a year, an event the city turns out to watch.
- **Collision:** solid. Its crown ring at the top is a perch, reached from
  level 4's gallery by a jump. It is not a swing anchor (not 7 m above
  anything the hero could swing from).

### 8.5 Facade and massing

The hotel is the city's landmark of the oldest age downtown: polite, stone
and bronze, the one art deco building, in the charter's 5 % accent for
landmarks (section 5).

| Element | Term | Tradition |
|---|---|---|
| Podium base | rusticated cream stone plinth | art deco, classical base |
| South and west faces at ground | an **arcaded loggia**, 4 m deep, of superellipse-headed arches | Raffles' verandas, in Moy's superellipse |
| Entrance | a **marquise** (projecting bronze-and-glass canopy) over the revolving door, with the swing doors either side | art deco |
| Tower walls | continuous stone **piers** running full height between recessed window bays, with bronze **spandrel panels** between floors | art deco verticality; the piers also shade the windows |
| Spandrel ornament | Old Moy's **house marks** cast in bronze, one mark per floor | the city's signature motif |
| Corners | rounded in a superellipse, the streamline corner | art deco and Moy's signature |
| Top | two **setbacks**, then the **green-copper pyramid** and the lit lantern | Peace Hotel, Chrysler |
| The sign | no lettering: a bronze **chandelier** picture on a hanging sign over the marquise | Moy's picture signs |

**Palette:** cream stone 60 %; bronze and green copper 30 %; amber light
and sign colour 10 %.

### 8.6 Heat and air

- The **loggias** shade the ground-floor glass from the sun.
- The tower's deep **piers** shade its windows.
- The two **wind towers** on the podium roof catch the west wind and drop
  cool air into the atrium. Warm air rises and leaves by vents in the
  **lantern's** clerestory, the old town's way of cooling, at the hotel's
  scale.
- Modern air conditioning does the rest. Its plant sits on the podium roof,
  screened.

### 8.7 The rest point

- **Fixtures (Moy is modern):** every guest room and suite has its own
  bathroom with a flush toilet, a washbasin and mirror, and a shower; the
  suites add a bath. Public washrooms open off the atrium and the mezzanine
  with flush toilets and basins. Waste goes to the city sewer and the water
  works' reclamation.
- **How the hero rests:** at the reception desk, with Lucinda in the
  evening (or Felix by day), then up by lift to the party's suite on floor
  20, the one built guest floor.
- **The party's suite:** sitting room, one bedroom with a double bed at
  world scale (mattress 1.55 × 2.3 m), a bathroom, and windows on the park.
  The swing doors beside the revolving door are 2.8 m wide for big
  companions and mounts; the lifts take them.
- **Price:** open.

### 8.8 Play

- The **marquise**, the loggia's arches and the tower's **piers** are climbing
  holds.
- The **podium roof garden** is reached by the lifts and from the Deck. It
  is a landing between the park's swing loop and the downtown towers.
- The **copper pyramid** and its lantern are a high swing anchor over the
  park and the plaza.
- The **chandelier's crown** is a perch above the atrium.

### 8.9 Realised (fidelity A)

**Only two parts are built inside (user):**
1. **The atrium:** the loggia, vestibule and revolving door; the atrium
   floor with the rock garden, the chandelier, reception, the concierge desk
   and Iris's stand; the double ramp and the mezzanine gallery round the
   void, with the Deck door, because they are part of the atrium's space.
2. **One guest floor, floor 20:** the lift lobby, the ring corridor and the
   party's suite.

Lifts run between the atrium's lift lobby and floor 20 only.

**Everything else is faux and solid:** the Long Bar, the Chandelier Room,
the function rooms, the offices, the kitchen and every other tower floor.
They are closed doors and lit windows that show rooms (the interior-mapping
shader), on solid massing with collision. The roof garden, setbacks and
copper crown are solid exterior surfaces the hero can still land on and
swing from, with no interiors behind them.

## 9. The library, outline

- **Precedents:**
  - **Tianjin Binhai Library:** a white terraced atrium of stepped
    bookshelves, which is also the city's best indoor climb.
  - **The Rose Reading Room, New York Public Library:** the great reading
    room.
- **Size:** about 55 × 55 m, five storeys, on the north side of Library
  Square, west of the park.
- **Inside:**
  - the terraced atrium;
  - the reading room under the roof;
  - the children's library (Benji);
  - the map room (Nia);
  - the Deck entrance on the second floor.

## 10. Fidelity: what is realised

Not every floor is built.

| Level | Built | Which |
|---|---|---|
| **A. Realised** | rooms, people, light, lifts between realised floors | the Grand Hotel's atrium (with its mezzanine gallery) and floor 20 with the party's suite; the library; city hall's chamber; the museum's hall; the Moonlight Cinema; the vertical farm's growing floor; the family's tower house; the Raman & Reese and Tanglewire floors; the Helmsmith; the café; the night market; the wet market; the convenience store; the clinic; the police box; the school's classroom; the giant playground; the park's tea house; Pinestein's rooftop laboratory; the North Estate hawker centre, one void deck and the Lams' block lobby; the twin blocks' sky garden; the Windspire's lobby, express lift and observation deck; the mirror field (outside) |
| **B. Street** | the ground floor as a real shop or lobby, or a shallow room behind glass; upper floors facade only, with lit windows that show rooms | most street buildings |
| **C. Skyline** | real-proportioned massing and window grids; roof and ledge collision only where routes use them | back-of-block towers; downtown's towers above their lobbies; the estate's blocks above the realised flats; the far skyline |

**Windows that look like rooms:** an "interior mapping" shader draws a room
in every lit window at almost no cost. Prototype it first.

**Performance:** stream the detailed city block by block; merge each
building's statics; instance the repeated facade parts and signs. People
simulate only near the player (forty-five named residents are within the
budget the fishing village proved). The Windspire and downtown must read in the
far skyline from the plateau, so the skyline tier gains their silhouettes and
lit crowns.

## 11. Fixed, proposed and open

**Fixed (user, 2026-10-12):**
- real building sizes, with only some floors realised;
- no cars and no trains;
- narrow, walkable streets and close buildings, swingable with the Leaf Hat;
- a dense Tokyo or Hong Kong neighbourhood;
- every resident named, with a backstory;
- the Grand Hotel rest point (atrium, revolving door, giant chandelier,
  after Chinese grand hotels);
- a library;
- Jammer's mother, a lawyer, is the hero's blood relative; she is a
  **corporate attorney**, not a defence lawyer (user);
- Jammer's father is a tech recruiter;
- Jammer is at his grandmother's in the Middle of Nowhere.
- The city's name is **Moy**. No Sign Boneyard: the city blorbs simply stay
  outside the outskirts. No opulent fountains.
- Old Moy keeps its tall street buildings, 4 to 9 storeys; it is not to be
  lowered (user). Its backstory as the well town of tall tower houses, with
  wind towers, the first well and the house marks that became the picture
  signs, is approved (user). Elizabeth, Dan and Jammer live in an old tower
  house in Old Moy and commute downtown (user).
- Every street is named and planned, with no dead ends; every building
  has a street face; downtown is filled with mid-rise blocks round the
  towers; green on the plan means gardens only (user).
- The North Estate is planned as precincts, the way Singapore's estates
  are: blocks free in shared gardens, not wedged among lots. Skyscrapers
  stand on full-size blocks at the centre, not squeezed onto the rim. City
  hall and the hotel are not a symmetrical pair: city hall heads Civic
  Plaza, and the private hotel takes a side (user).
- No road out of Moy to anywhere: the world ends at the planetary ocean
  beyond the mountains. No public bath.
- No road from the plateau side: nothing is there but rock. The research
  institute is called **BLOCK**, not Lumen.
- (sixth revision) Every block built out to its streets, no empty gaps; the
  park at the centre; new names for Lantern Lane and Parkside Estate; real
  streets without cars; several plazas.
- Jammer's parents are **Elizabeth Reese** and **Dan Miller**, married
  (user, 2026-10-12), and they can speak of the Middle of Nowhere. Proposed
  clues: Elizabeth's photograph of the hero as a boy, and Jammer's room full
  of farm drawings.
- Giant wind turbines, after China's desert wind bases, out in the
  wasteland around the city: **Moy's power source** (fifth revision).
- The turbines' blades collide with the player.
- No mahjong; chess is fine. A giant playground in the park. No Element
  Shrine.
- (third revision) a city standing up out of the desert, like Las Vegas or
  Dubai, with no water nearby;
- a downtown of skyscrapers;
- large public housing, like Singapore's;
- Palbert Pinestein, a mad scientist, made the city blorbs in an experiment;
  they are outcast and not allowed inside the city's bounds.

**Proposed:**
- the census of forty-five and its other names;
- the culture;
- the charter;
- the four movement layers (ground, Deck, towers, roofs) and the swing
  corridors;
- the districts;
- the site at a radius of 200 m;
- the Moonlight Cinema, the museum and the
  police box;
- (seventh revision) Moy feeds itself: the vertical farm (Sora), rooftop
  greenhouses and the fish tanks at the water works; the battery works on
  the west edge;
- (third revision) the water story (deep wells, reclaimed water, roof tanks)
  and the water works;
- the economy: the Windworks, BLOCK, law and finance, hospitality, all
  serving the city itself;
- the Rim Walk as the bounds; the city blorbs and the City Gem in the desert
  just beyond it;
- the names **Old Moy** and the **North Estate**; the street names (the Park
  Ring, West, North and South Streets); the five plazas (Civic Plaza,
  Library Square, Market Square, Estate Square, Cinema Square);
- Meridian Avenue (renamed from Harbour Street); the
  Windspire;
- (fifth revision) the wind farm's size, number and placement; the
  Windworks and the Windspire (renamed from the Sunwell and the Sunspire);
- the five added residents; the Blackout.

**Open:**
- the hotel's rest price;
- whether Elizabeth recognises the hero when they meet, and what she tells
  him;
- the skybridges are folded into the Deck;
- the park's small pond (kept, as plain reclaimed water, not a display);
- whether the hero's own city blorbs may follow him inside the bounds.
  Proposed: the ban is the city's law, not a wall, so a party city blorb may
  follow, and the residents react in character (Kate's look, a shopkeeper
  unplugging a sign), never with a stated rule;
- whether Pinestein has a quest, such as a case to let the city blorbs back
  in;
- the Windspire's height against the far skyline's draw distance;
- the turbines' draw cost: four animated rotors seen from across the
  world (proposed: one shared mesh, instanced, rotors as cheap far LODs).
