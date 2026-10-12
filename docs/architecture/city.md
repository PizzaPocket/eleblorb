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
- **West: the goods yard**, at the end of West Street, where **the west
  road** ends. The road runs out across the desert and through the mountains
  past the world's edge, to the farmland and the coast that feed Moy; the
  player never follows it. **No road runs east** (user): that way there is
  nothing but rock and the main plateau's 60 m cliff.
- **North-west: the water works** and the water tower.
- **Just beyond: the wind farm**, four turbines in two pairs framing the
  city (below), with the battery works by the goods yard.

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
    edge nearest Moy, store the wind's power for calm days, and charge the
    batteries that go out by road;
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
   Vegas was built for its dam. Charged batteries leave by the west road
   for the wider world.
2. **Science and technology.** **BLOCK** (renamed from the Lumen Institute,
   user), a research institute with a campus downtown, works on power and on "living current". Start-ups spun out of
   it fill floors of the downtown towers, and Tanglewire recruits for both.
   Pinestein worked at BLOCK.
3. **Professional services.** Law (Raman & Reese: the Windworks's contracts, BLOCK's
   patents and the city's own cases) and finance serve the first
   two.
4. **Hospitality and spectacle.** People come in from the towns for the
   Grand Hotel, the cinema and the night market. In a
   world of villages, the city's lights are themselves the attraction, as Las
   Vegas's are.
5. **The everyday city.** Markets, the hawker centre, shops, the clinic, the
   school and the upkeep crews: the residents serving each other.

**Imports:** almost all the food. Grain, vegetables and fruit come in by the west
road from the farmland, the Middle of Nowhere among it, and fish come packed in
ice from the coast. The market lanes are full of crates from elsewhere.
**Exports:** power (charged batteries), inventions, legal and financial work,
and hospitality.

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
| **Elizabeth Reese** | the family's flat, Block 3, North Estate, 18th floor | lawyer, partner at Raman & Reese on Meridian Avenue | The hero's aunt by blood: her sibling was the hero's parent. She grew up in the Middle of Nowhere and left for law school; her mother still lives on the farm. Quick, warm, overworked. She has kept a photograph of the hero as a boy on her office shelf for years. She defended Pinestein at the inquiry after the Blackout, and lost. |
| **Dan Miller** | the same apartment | tech recruiter at Tanglewire, the recruiting firm in the glass tower downtown; he places people at BLOCK, the Windworks and the start-ups | Elizabeth's husband; city born. He can talk to anyone and never forgets a name, and misses Jammer louder than he admits. |
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
| **Lucinda Wah** | the manager's flat on the hotel's top floor | general manager | Third generation to run the hotel her grandfather built. She knows the chandelier's 3,000 crystals by their faults. |
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
| **Sora Ishida** | Garden Row, with Ada | runs the Pine Bath, the public bathhouse | Fires the bath's boiler at four every afternoon, the same as her mother did. |

**Commerce and food**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Sol Brant** | above his café | runs the breakfast café in Old Moy | Up before the sun, which the towers hide until mid-morning. |
| **Mei Chan** | the market flats, with her daughter Lily | runs the noodle stall at the night market | Cooks at a stall her mother licensed forty years ago. |
| **Hiro Sato** | above the store | keeps the all-night convenience store | Has not closed in eleven years and knows who comes in at 3 a.m. and why: Pinestein, most nights, for batteries. |
| **Rosa Delgado** | the market flats | fishmonger at the wet market | Loud, funny, and the best judge of freshness in the city. Her fish come in on ice by the west road, two days from the water, and she will tell you which day. |
| **Wen Li** | the market flats | greengrocer at the wet market | Grows herbs on the market's roof and sells them below. Her best greens come from a farm in the Middle of Nowhere, and the crates carry its mark: Elizabeth's mother's farm. |
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
  dismissed Pinestein. Elizabeth Reese defended Pinestein at the inquiry and lost.
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
| Washing and gathering | Sora | the Pine Bath |
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
- Goods arrive by hand truck and cargo trike from a **goods yard** at the
  west edge, where the west road ends.
- Waste leaves the same way at dawn.
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
| Downtown skyscraper | 35 to 45 m square on a podium, 35 to 55 storeys (140 to 220 m) |
| The Windspire, the tallest | about 45 m square, about 70 storeys, about 280 m with its crown |
| Wind turbine (outside the bounds) | about 95 m to the hub; rotor 130 m across; about 160 m to the tip |
| City block | 45 to 70 m, crossed by lanes |

## 5. Architectural language: a layered vertical city

**Precedents:**
- **Tokyo** (Shimokitazawa, Nakameguro, Yanaka): narrow lanes; pencil
  buildings; tiled facades; rounded corner buildings; covered shopping arcades (shōtengai); police boxes (kōban); public
  bathhouses (sentō).
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
   - **main streets** (12 m, tree-lined): the **Park Ring** round the park,
     and four streets running out from it to the Rim Walk: **Meridian
     Avenue** east, **West Street**, **North Street** and **South Street**;
   - **shopping streets** (8 m), some roofed as arcades at about 8 m;
   - **lanes** (3.2 to 4.8 m) through every block.

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
   W, outside:
   goods yard,
   battery works
   ◄── the west road, out past the world's edge
W  │  OLD MOY   │ Library    THE PARK     Civic│ DOWNTOWN       │ E: desert,
   │  lanes,    │ Square  giant playground Plaza│ Meridian Ave: │  then the
   │  cinema,   │ (library  tea house · chess   │ the Windspire,│  main
   │  bath,     │  on its   pond          (hotel│ Tanglewire,   │  plateau's
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
  - the **giant playground** at its heart;
  - Old Fu's tea house and the chess tables;
  - the pond, and shade trees on reclaimed water;
  - **Garden Row**, a short row of older townhouses, faces it from the
    north-west.

  Every district touches the Park Ring, so the park is the city's common
  ground, and the Deck runs round it.
- **The plazas** (user: "I like the idea of plazas"):
  - **Civic Plaza**, on the park's east side where Meridian Avenue arrives.
    The Grand Hotel stands on its north side and city hall on its south
    side. Shade trees, misters and benches; Pia busks here; the Deck's main
    ramp tower.
  - **Library Square**, on the park's west side where West Street arrives,
    with the library along its north side and the terraced steps where
    people sit.
  - **Market Square**, on South Street, ringed by stalls by day and by the
    night market after dark, with the wet market hall on its east side.
  - **Estate Square**, on North Street in the North Estate, with the hawker
    centre on its east side and void decks opening onto it.
  - **Cinema Square**, a small square in Old Moy where the Moonlight Cinema
    and the Pine Bath face each other.
- **Arrival.** Goods and travellers from the wider world come in by the
  west road to the goods yard and walk in down West Street. The hero comes
  on foot across the open desert, and any lane's gap in the Rim Walk lets
  him in. From the plateau side the grand way in is **Meridian Avenue**
  (renamed from Harbour Street: there is no harbour in a desert), the
  palm-lined main street, between the skyscrapers, which opens onto **Civic
  Plaza** and, past it, the park. The Grand Hotel's revolving door is on the plaza.
- **The museum** faces the park from the Park Ring's south side.
- **Old Moy** (west; renamed from Lantern Lane, user) is the old residential
  and craft quarter of lanes and pencil buildings either side of West
  Street: Sol's café, the Moonlight Cinema and the Pine Bath on Cinema
  Square, the clinic, the police box, and Pinestein's rooftop laboratory.
- **The market lanes** (south) hold Market Square, the wet market, the night
  market, the covered shopping arcade, the Helmsmith, Hiro's store, Wing Fat
  Mansion and the school.
- **The North Estate** (north; renamed from Parkside Estate, user) is the
  public housing, after Singapore's, built out to its streets like
  everything else:
  - point blocks of 30 to 40 storeys rising from two- and three-storey
    podiums (the void decks, shops, a kindergarten, the clinic's annexe),
    two of them twins joined by sky bridges and a sky garden;
  - slab blocks of 12 to 16 storeys lining the streets;
  - void decks under every block: shade, chess tables, letterboxes, and room
    for weddings and wakes;
  - Estate Square and its hawker centre (Siti's stall), with a community
    garden on the podium roofs where another estate would have its car park;
  - small courtyards inside the blocks, never open lots.

  Jammer's family lives in Block 3, on the Park Ring, overlooking the park.
  The Housing Board (Juno) runs the estate.
- **The giant playground**, in the park: the biggest the world has seen
  (after Singapore's mosaic dragon playgrounds and the great net-tower
  playgrounds of Europe and Japan):
  - climbing towers of 12 to 20 m joined by rope bridges and net tunnels;
  - long tube slides and a spiral slide from the top;
  - a sand field (desert sand, for once welcome) and a splash pad on
    reclaimed water;
  - shade sails over it all, and benches for the parents round the edge.

  It is a real parkour course for the hero, with collision throughout, and a
  landmark seen from the Deck and every block on the Park Ring. Lily and
  Kofi rule it.
- **Downtown** (east), on **Meridian Avenue** between Civic Plaza and the
  Rim Walk, is the city's workplace and its skyline: a tight cluster of
  skyscrapers of 140 to 220 m on podiums that fill their blocks, and the
  **Windspire**, the Windworks' headquarters, about 280 m tall with an
  observation deck. Here are Raman & Reese, Tanglewire's glass tower, the
  start-up floors and BLOCK. The Grand Hotel's guest tower
  rises on Civic Plaza at downtown's west end.

### Site and land

With no roads, a quarter of the land goes to circulation rather than a
third. The program comes to about 75,000 m², and about 100,000 m² with lanes
and streets. The flat pad grows from a radius of 78 m to about **200 m**
(400 m across). Its centre moves a little west, to about (−560, 0). The
gorge floor there is already within ±2.4 m of flat.

Downtown and the estate add height, not land, so the radius holds. The works
beyond the bounds need about 100 m more on the east, south-west and
north-west, inside the 110 to 140 m gaps to the plateaus and the skirt.

## 8. The Grand Hotel (rest point), outline

The full building brief follows the layout.

- **Precedents:**
  - **White Swan Hotel, Guangzhou:** the atrium's indoor rock garden and
    pavilion (its waterfall left out: Moy has no opulent water).
  - **Peace Hotel, Shanghai:** art deco, with the great chandelier under a
    lantern dome.
  - **Grand Hyatt in the Jin Mao Tower, Shanghai:** guest galleries ringing a
    soaring atrium.
- **Size:** a podium about 66 × 50 m; an atrium about 33 × 26 m and 26 m high;
  a guest tower above, about 33 × 55 m and 25 floors.
- **Arrival:**
  - a revolving door (a drum about 3.3 m across) flanked by swing doors for
    the party and big companions;
  - the doorman, Ah Keung;
  - a canopy on Civic Plaza;
  - the Deck's entrance at the mezzanine.
- **The atrium:**
  - the giant chandelier, about 8 m across;
  - the dry rock garden and pavilion;
  - reception, the concierge desk and Iris's flowers;
  - a grand double ramp to the mezzanine restaurant.
- **Realised:** the atrium, the mezzanine, one guest gallery, and the party's
  suite (one bed at the world's bed size; its own bathroom). Lifts run
  between them.

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
| **A. Realised** | rooms, people, light, lifts between realised floors | the Grand Hotel's atrium, mezzanine, gallery and suite; the library; city hall's chamber; the museum's hall; the Moonlight Cinema; the Pine Bath; the family's flat; the Raman & Reese and Tanglewire floors; the Helmsmith; the café; the night market; the wet market; the convenience store; the clinic; the police box; the school's classroom; the giant playground; the park's tea house; Pinestein's rooftop laboratory; the North Estate hawker centre, one void deck and the Lams' block lobby; the twin blocks' sky garden; the Windspire's lobby, express lift and observation deck; the mirror field (outside) |
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
- Jammer's mother, a lawyer, is the hero's blood relative;
- Jammer's father is a tech recruiter;
- Jammer is at his grandmother's in the Middle of Nowhere.
- The city's name is **Moy**. No Sign Boneyard: the city blorbs simply stay
  outside the outskirts. No opulent fountains.
- No road from the plateau side: nothing is there but rock. The research
  institute is called **BLOCK**, not Lumen.
- (sixth revision) Every block built out to its streets, no empty gaps; the
  park at the centre; new names for Lantern Lane and Parkside Estate; real
  streets without cars; several plazas.
- Jammer's parents are **Elizabeth Reese** and **Dan Miller**, married
  (user, 2026-10-12), and they can speak of the Middle of Nowhere. Proposed
  clues: Elizabeth's photograph of the hero as a boy, Jammer's room full of
  farm drawings, and the farm's mark on Wen Li's crates.
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
- the Pine Bath, the Moonlight Cinema, the museum and the
  police box;
- the goods yard at the end of the west road, which leaves through the
  world's edge (no road east, user);
- (third revision) the water story (deep wells, reclaimed water, roof tanks)
  and the water works;
- the economy: the Windworks, BLOCK, law and finance,
  hospitality; food imported from the farmland;
- the Rim Walk as the bounds; the city blorbs and the City Gem in the desert
  just beyond it;
- the names **Old Moy** and the **North Estate**; the street names (the Park
  Ring, West, North and South Streets); the five plazas (Civic Plaza,
  Library Square, Market Square, Estate Square, Cinema Square);
- Meridian Avenue (renamed from Harbour Street); the
  Windspire;
- (fifth revision) the wind farm's size, number and placement; the
  Windworks and the Windspire (renamed from the Sunwell and the Sunspire);
- the five added residents; the Blackout; Elizabeth's defence of Pinestein.

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
