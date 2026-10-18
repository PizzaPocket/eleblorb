# Moy, the city: settlement plan (first real pass)

> **Building Moy in the game?** Start with `moy_build_handoff.md`: the data to build from, the order, the rules and the loose ends (2026-10-17).

> **First playable prototype (owner authorized, 2026-10-17):** Use
> [moy_playable_prototype.md](moy_playable_prototype.md) with the existing models.
> It resolves precedence among dated revisions and defines the first pass's
> reduced detail, collision, traversal, loading and acceptance requirements.
> Older summaries below remain historical where newer measured data differs.

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
- **The hotel follows John Portman** (user, 2026-10-13): "I'm very inspired
  by John Portman architecture, could we shift the Moy hotel to be in his
  style?" (section 8).
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

**Ninth revision (user, 2026-10-16):**
- **Two simple straight lines** across the city, north–south and
  east–west, at different heights so they never meet; the east–west line
  raised (section 6c).
- **City hall without its clock tower:** a giant timekeeping structure over
  it that the train passes straight through, with no hands from the centre;
  hour and minute keep real-world time, and it shows day and night (8a.0).
- **Clear the mid-rise blocks in front of city hall's east face** and put an
  arching structure there, after the CCTV headquarters or the St. Louis
  arch, framing city hall from the east; a very modern, city-owned
  building, joined to the wall, the train and city hall (8b).
- **BLOCK's old low building becomes mid-rise real estate.**
- **The park's centre becomes a civic structure and modern train station**;
  the playground moves to one section, so the park is shared by the
  station, the playground and the green (7a).

**Eighth revision (user, 2026-10-14):**
- **The NMEs are on the rise** because of the Demon King. They come up to
  cities but never enter (that is how the game is coded), and Moy is
  vigilant. More and more dangerous monsters will be added later.
- **Most people believe blorbs are just another monster** and fear them.
- **A wall**, a plain circle; the works outside it keep their own security.
- **An integrated commuter train**: elevated, on the wall, with cross routes
  through the inner city in conversation with the Deck (section 6c). This
  revises "no trains": the streets stay free of cars and trains, and the
  trains run only on the wall and on viaducts over the Deck.

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

**The bounds: the Rim Walk and the wall.** The city ends sharply, with no
sprawl. A ring promenade, the Rim Walk, runs round the whole edge inside the
wall (section 6c): date palms, lamp posts and benches along the wall's inner
face, the old viaduct's arches still reading in it. Every lane and street
ends on the Rim Walk; four of them pass on through the wall's gates.

Beyond the wall the paving stops and the desert begins. This is the line the
city blorbs may not cross, and the line the NMEs come up to and no further.

**Beyond the bounds** (in the ring between 200 and about 300 m; coordinates
follow approval):
- **All round: the city blorbs** stay out in the open desert just beyond the
  outskirts.
- **No roads out** (user). Westward the desert runs to the mountains, and
  beyond them lies the planetary ocean; eastward there is nothing but rock
  and the main plateau's 60 m cliff. Only the four gate streets pass the
  wall, and they end a few metres beyond it.
- **West: the battery works**, at the end of West Street outside the West
  Gate, with the recycling works beside it.
- **North-west: the water works**, the water tower and the **fish tanks**
  (below).
- **The works keep their own security** (user, 2026-10-14): each stands in
  its own fenced compound with floodlights and a keeper on the gate (Omar
  Haddad at the battery works, Rafael Ortiz at the water works), and the
  Wall Watch's searchlights reach them from the nearest watch posts. The
  wall does not bend out to take them in.
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
   user), a research institute in a dark tower on Civic Plaza, works on
   power and on "living current". Everything
   sinister in Moy is concentrated there (section 7c). Start-ups fill the
   north tower's capsules, and Tanglewire recruits for them and the
   Windworks. Pinestein worked at BLOCK.
3. **Professional services.** The Windworks keeps its own legal department
   in the Windspire (Priya Raman, Elizabeth, Venn); recruiting (Tanglewire)
   and finance serve the city's companies. (Revised 2026-10-14: no law firm,
   and nothing ties Elizabeth's work to BLOCK.)
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
| **Elizabeth Reese** | the Reese–Miller house, an old tower house in Old Moy; she walks to work across the park | corporate attorney in the Windworks' legal department in the Windspire, on Civic Plaza | The hero's aunt by blood: her sibling was the hero's parent. She grew up in the Middle of Nowhere and left for law school; her mother still lives on the farm. Quick, warm, overworked. She has kept a photograph of the hero as a boy on her office shelf for years. |
| **Dan Miller** | the same house; he walks to work with Elizabeth | tech recruiter at Tanglewire, the recruiting firm on the south tower's office floors; he places people at the Windworks and the start-ups (BLOCK does its own hiring, and never through him) | Elizabeth's husband; city born. He can talk to anyone and never forgets a name, and misses Jammer louder than he admits. |
| *(Jammer)* | away, at his grandmother's in the Middle of Nowhere | — | Their son; his room in the apartment is full of drawings of the farm. |

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
| **Teodora Vance** | Garden Row townhouse | mayor; chairs the council | Grew up in the market lanes. Walks the whole city every Sunday to see what's broken. She signed the ordinance that put the city blorbs outside the bounds, and does not like to talk about it. |
| **Kenji Mori** | above the park's tea house | city clerk and registrar | Keeps the city's records, the births and deaths of everyone in this census, and the register of house marks. |
| **Ada Fong** | Garden Row, with her wife Sora | head librarian | Led the library's latest renovation, and still misses the Great Hall's creaking floorboards it replaced. |
| **Nia Calder** | Wing Fat Mansion | the library's map archivist | Counts the towers, reads old maps, and has a drawer of maps nobody can explain. |
| **Benji Okoro** | Old Moy | children's librarian | Jammer's favourite grown-up after his parents. |
| **Dr. Imani Osei** | North Estate, Block 5, with her son Kofi | curator of the natural history museum | Writes long letters to Dr. Hazel Coleman about Dinosaur's bones, and dreams of mounting a cast of him. |
| **Leon Duarte** | above the cinema | projectionist of the old Moonlight Cinema | Runs film reels by hand through clockwork projectors he will not let anyone replace. |
| **Mara Quill** | a rooftop studio in Old Moy | novelist | Writes in the library and the café. Says the city mirrors something, and is writing a book to find out what, at the same table in the library's Great Hall every day. |
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
| **Priya Raman** | Garden Row | general counsel of the Windworks | Hired Elizabeth straight out of law school and made her her deputy. |
| **Venn Harlow** | Wing Fat Mansion | paralegal in the Windworks' legal department | Same commute every day, the same fifteen floors; quietly the department's memory. |
| **Theo Park** | Old Moy | software engineer at a start-up | Dan is trying to place him; he would rather be skateboarding on the decks. |

**The wind, the water and the Institute**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Palbert Pinestein** | a top-floor flat in Old Moy, the roof bristling with antennas and coils, where he watches BLOCK | none, as far as the city knows: he still works with Kask in secret (user, 2026-10-18). His laboratory, where he made the city blorbs, is sealed in the BLOCK tower's base (user, 2026-10-18): the one lab of his the hero enters | The mad scientist who made the city blorbs (section 3b). Wild-haired, brilliant, tactless; the city takes him for BLOCK's outcast. Goes out past the Rim Walk most nights with a pocketful of charged batteries (proposed: bait, to bring city blorbs in to BLOCK). |
| **Dr. Vera Kask** | the top floors of the BLOCK tower | director of BLOCK | Runs BLOCK, the city's bad guy. She lives where she works, and is rarely seen at street level. |
| **Omar Haddad** | a flat at the battery works | chief engineer of the Windworks wind farm | Climbs ninety-five metres to a nacelle before breakfast and calls it his commute. |
| **Rafael Ortiz** | the keeper's house at the water works | keeper of the wells and the water works | Counts every litre the city uses twice, and has never once let the park's pond run dry. |

**Care, safety and teaching**

| Resident | Home | Work | Backstory |
|---|---|---|---|
| **Dr. Arjun Mehta** | above his clinic | the neighbourhood doctor | Treats half the city and remembers all of it. |
| **Kate Byrne** | the police box's back room | officer at the police box | Gives directions more than anything else. Walks stray city blorbs back out through the gates, gently, and likes that part least. |
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

**Kept simple** (user, 2026-10-18: no elaborate backstory, no disgrace, no
trial). It is part of the plain atmosphere of the city: BLOCK is the bad guy.
- **The experiment.** Pinestein experimented on blorbs at BLOCK, and the
  experiments made the city blorbs: saturated glassy azure, crackling and
  hungry for power, the only blorbs known to have been made rather than
  born. His laboratory is sealed in the BLOCK tower's base.
- **Now:**
  - The city blorbs are banished outside the city, out in the desert beyond
    the Rim Walk.
  - Everyone in Moy is still afraid of all blorbs, not only the city ones.
  - Pinestein lives in a flat in Old Moy and goes out to them at night,
    with batteries bought from Hiro at 3 a.m.
- **How the city feels about them:**
  - Teodora: defensive.
  - Kate: dutiful but gentle.
  - Lucinda: wary; she keeps them away from her hotel.
  - Lily and Kofi: they sneak out to see them.
- **Draft lines** (in character, explaining nothing):
  - Pinestein: "They're not pests. They're the first thing this city ever
    made that wanted to live here."
  - Kate: "Back out you go. Past the palms. Go on."
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
| Work | Elizabeth, Priya, Venn; Dan, Theo; Vera | the Windworks (Windspire); Tanglewire (south tower) and the start-up capsules (north tower); BLOCK |
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
| Downtown mid-rise | 20 to 34 m frontage by about 20 m deep, 18 to 34 storeys, filling the blocks round the towers |
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
  - the Grand Hotel (John Portman's atrium modernism: white ribbed
    concrete, bronze glass and glass lifts);
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

**Hierarchy.** The landmarks are polite: stone (or, at the hotel, white
concrete), bronze and generous entrances. The street buildings are vernacular: tile, render, and signs.

**Exclusions:**
- cars, roads, car parks (the estate has none), garages, traffic lights and
  crosswalks;
- lawns that need watering, outside the park;
- trains and stations;
- lettered signs;
- blank glass boxes at street level;
- suburban houses with yards.

## 6. How people move, including vertically

The city is walked in **four layers**, and ridden in a fifth: the trains at
+12 m (section 6c). Each has its own job, and they connect
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
   | Meridian Avenue | main street | 12 m | from the East Gate through Meridian Court, under the Meridian Arch, to Clock Street behind city hall |
   | Meridian North | main street | 10 m | from the Park Ring past Civic Plaza, the hotel and the Windspire to Meridian Court and the Rim Walk |
   | Meridian South | main street | 10 m | from the Park Ring past Civic Plaza and the BLOCK tower to Meridian Court and the Rim Walk |
   | Clock Street | lane | 4 m | behind city hall, from Meridian North to Meridian South |
   | West Street | main street | 12 m | from the Rim Walk (west) to Arcade Street and Library Square |
   | North Street | main street | 12 m | from the Park Ring to the Rim Walk (north), through the estate |
   | South Street | main street | 12 m | from the Park Ring to the Rim Walk (south), through Market Square |
   | Arcade Street | shopping street | 8 m | Rim Walk to Rim Walk, north to south, roofed in the market lanes |
   | Market Street | shopping street | 8 m | from the Rim Walk (west) to Market Lane |
   | Cinema Lane | lane | 4 m | from Tank Lane north to the Rim Walk (south of Tank Lane the old town's own lanes take over) |
   | Tank Lane | lane | 4 m | from the Rim Walk to Arcade Street |
   | Clinic Lane | lane | 4 m | from the Rim Walk to the Park Ring |
   | Library Lane | lane | 4 m | from Arcade Street to North Street, behind the library |
   | Museum Lane | lane | 4 m | from the Park Ring to Market Street |
   | Garden Walk | lane | 4 m | from Library Lane to Library Square |
   | Lamp Lane | lane | 4 m | from Arcade Street to Market Lane; the night market |
   | Estate Lane | lane | 4 m | from the Park Ring to the Rim Walk, east edge of the estate |
   | Market Lane | lane | 4 m | from the Park Ring to the Rim Walk, east edge of the market lanes |
   | Hotel Lane | lane | 4 m | from Estate Lane to the Rim Walk, behind the hotel |
   | Glass Lane | lane | 4 m | from Market Lane to the Rim Walk, behind the BLOCK tower |

   **No dead ends:** every street meets another street, a square, the Park
   Ring or the Rim Walk at both ends (checked in the layout). Streets that
   reach the edge open onto the Rim Walk promenade.

   Blocks are 45 to 70 m, so no walk goes round more than about 60 m. In the estate, every block stands on an open void deck
   you can walk straight under, and covered linkways join the blocks to the
   hawker centre, the park and the Deck.
2. **The Deck, at +6.5 m (two storeys up).** An elevated pedestrian network
   after Hong Kong's footbridges, routed in `DECK` in `tools/city_layout.py`
   (proposed 2026-10-14) and drawn on the plan and the city model. Every run
   has a job, and every branch ends at a door worth walking to at +6.5 m:
   - **The Park Deck**, a 6 m ring over the park side of the Park Ring. The
     walk beneath it is a shaded arcade along the park's edge; the 6 m of
     street outside it stays open to the sky beside the shopfronts. It joins
     every district, which is why the Deck is a ring and not a line.
   - **The hotel skybridge** (revised 2026-10-17): the civic walks along
     Civic Plaza's edges are gone with the buildings that briefly replaced
     the old plaza. The Park Deck's west side sends a short glazed bridge
     east into the Grand Hotel's mezzanine gallery by its west door (section
     8), and from there a glass bridge crosses the Windspire's wind garden
     into its lobby. Two escalator pairs at Civic Plaza's west end, north and
     south of its axis, join the square to the Deck (section 8a.1). Nothing
     crosses Meridian South: BLOCK stays off the Deck.
   - **The Spine walks**, under the Spine Line from the Park Deck's north
     and south sides, across the Crossing Ring, to the Crossing's two
     cross-bridges (section 7a, iteration 3); the middle is left open.
   - **The Library walk**, over Garden Walk's mouth to the library's
     east-wing door and its first gallery (section 9).
   - **The Estate walk**, up the east half of North Street past the hawker
     centre to the neighbourhood centre's roof garden, which is at the
     Deck's level (two storeys of 3.25 m). The estate's covered linkways
     meet it at Estate Square.
   - **The Market walk**, down the east half of South Street past Hiro's
     all-night store, then along Market Square's north edge to the wet
     market's upper hall.

   Not on the Deck, deliberately: BLOCK (a closed research institute), the
   north and south towers (lots stand between them and the Deck; their
   people use the street), Old Moy (its lanes are too narrow, and its
   tower houses are older than the Deck).

   **Ways down:** six **ramp towers**, 8 m across, each two flights of the
   world's 32° ramp with a landing between: four at the park's gates,
   where the park's cross walks meet the ring (each tower's foot opens onto
   the walk, its head onto the Deck), and a pair framing Civic Plaza's
   axis, under the two skybridges *(since revised: the towers that remain
   are the West and East gate pairs in `DECK['ramps']`; Civic Plaza's are
   escalators, section 8a.1)*. **Glass public lifts** stand at Estate
   Square and Market Square. Nowhere on the Deck is more than 75 m from a
   way down (now 68 m), the ramp towers doubling as escape routes.

   **Escalating ramps** (revised 2026-10-14, at the user's direction): inclined
   moving walkways at 12°, after airport travelators, each a pair (up and
   down) 2.6 m wide, standing in for escalators within the no-stairs rule. A
   6.5 m rise runs 31 m, so they stand only where a square can give that
   length along its edge without being cut in two: Civic Plaza (two, at its west end,
   up to the Park Deck; now true escalators, section 8a.1), Market Square (up to the Market walk) and Estate Square
   (up to the Estate walk). Inside the train stations a second pair under
   each platform rises from the Deck through the platform floor (section
   6c).

   **Construction:** a pale concrete deck 0.9 m deep on paired round
   columns at its edges, no more than 12 m apart, so the soffit is 5.6 m
   up. Columns stand clear of every street mouth and park gate (the line a
   walker crosses on), and the skybridges span their street with none.
   *(2026-10-17: the Park Deck had no columns in the data, an error in the
   layout tool, which skipped every ring-shaped run; it now stands on 164
   columns in `DECK.columns`. The Crossing Ring alone stands on the
   Crossing's own supports.)* Steel rails 1.1 m high; the skybridges are
   glazed and roofed. **The parapets stop wherever something walkable meets
   the Deck's edge** (another run, a Crossing tower, a ramp tower, a lift,
   an escalator's head, a building's door), so no railing ever crosses a
   junction; the plan records every parapet's exact ends in
   `DECK.parapets`. Every 12 m street the Deck runs along keeps at least
   4 m (here 6 m) open beside it. All checked in the layout.

   **A garden walk** (2026-10-17, at the user's direction, after New York's
   High Line and Singapore's park connectors): planting beds alternate from
   side to side along every run, 1.2 to 2.4 m wide and 9 to 15 m long with
   3 m between, so a path of at least 3.2 m winds between them; a small ghaf
   (6 m) stands in every second bed 1.8 m wide or more, never within 6 m of
   the Spine (its deck is only 5.5 m above the Deck) or 4 m of a Crossing
   tower. The bed edges are 0.45 m sitting walls. The plan records every bed
   (`DECK.beds`, a centreline and a width) and every tree (`DECK.trees`).

   **Play:** the Deck is a second ground for the hero: a running loop
   round the park, ledges into the plaza trees, and the low first rung of
   the swing corridors (its rails are not anchors: too low for the vine's
   7 m).

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
   rooftop bars on the way. Ramp towers and the hotel's glass lifts reach it.

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

### 6c. The wall and the trains (proposed 2026-10-14)

Data: `WALL` and `CROSS` in `tools/city_layout.py`, written to
`CityPlan.WALL` and `CityPlan.CROSS`, drawn on `moy_plan.html` and
`moy_city_3d.html`.

**Why now.** The NMEs are on the rise because of the Demon King (eighth
revision). They come up to the city but never enter; Moy watches them, and
the wall is how a city of 45 named people shows it is afraid. Most of them
fear blorbs as one more kind of monster, so the wall also stands between
them and the city blorbs outside.

**The Ring Line came first.** In the boom, Moy built a double-track railway
on a viaduct round its own edge: the **Ring Line**, a loop for the city's
commuters and the Windworks' crews. When the NMEs began to rise, the city
filled the viaduct's arches with rammed earth and concrete, faced the outside
in pale tile, and raised a parapet: the railway became the wall. So the wall
and the train are one structure, and the trains still run on its top.
- **The wall:** a plain circle (user), centreline 209.5 m from Moy's centre,
  1,316 m round, 12 m high and 12 m thick, just outside the Rim Walk (its
  inner face at 203.5 m). The old arches' piers still read on the inner face
  above the Rim Walk's palms and benches.
- **The top, from the city side:** a steel rail, the two tracks (centres
  3.4 m apart), the **watch walk** 3.6 m wide, and a 1.2 m parapet on the
  outside.
- **Four gates**, where the main streets pass through: the **East Gate**
  (Meridian Avenue; the grand gate, 84 m along, its wings receiving the
  Meridian Line), the **North Gate** (North Street), the **South Gate**
  (South Street) and the **West Gate** (West Street, out to the battery
  works). Each is a gatehouse 24 m deep that projects outward from the wall:
  a 10 m by 8 m arch for the street, two watch towers on its outer corners,
  and a Wall Line station on its top under a canopy, with a ramp tower and
  lift inside it down to the street. The gates stand open: the NMEs never
  enter, so the gates are watched, not shut.
- **Watch posts:** seven rectangular bastions standing out from the outer
  face between the gates, each with a searchlight that sweeps the desert at
  night. This is how the vigilance shows: lights on the sand, figures on
  the watch walk, a bell at each gate.
- **The Line House:** a bastion on the wall's outside toward the water works,
  60 m along and 16 m out. Its top floor, level with the track, is the car
  shed for both lines' trains; below it are the lines' workshop and the
  **Wall Watch**'s guardroom.
- **The works stay outside** (user): the battery and recycling works beyond
  the West Gate, the water works, water tower and fish tanks to the
  north-west, each fenced and lit with its own keeper (section 2a). The
  battery and recycling works moved a few metres west, and the fish tanks
  north, to stand clear of the wall and its gatehouses.

**Precedents (proposed 2026-10-14).** Three real systems already do what this
one does; the wall, the Deck and the trains take their section and structure
from them, built in Moy's own language (superellipse corners, pale ceramic,
the picture-sign colours at night).
- **The wall: Xi'an's Ming city wall**, for its size and its watch. It is
  12 m high and 12 to 14 m wide on top, people walk and cycle round its top,
  and it has a bastion (*mamian*) every 120 m so the guards can see along
  the face. Moy's wall takes the same height, width and spacing, and its
  watch posts are rectangular bastions like Xi'an's (20 m along, 10 m out,
  14 m high, a searchlight on each). Its gatehouses take the
  gatehouse-and-barbican massing of Xi'an's gates, and each carries two
  three-tier corner towers after Jiayuguan in the Gansu desert, built in
  Moy's tile with flat steel roofs instead of timber eaves. Material: the infill is Old Moy's
  rammed earth (the well town's own way of building), faced outside in pale
  tile.
- **The viaduct it was: Tokyo's Yamanote line.** Tokyo's railway loop runs
  on brick and concrete viaducts whose arches are let as bars, workshops
  and shops (*gādo-shita*, "under the girders", as at Yūrakuchō). Only the
  outer half of each Ring Line arch was filled (in the data: 112 arches of
  9 m bays, 6.5 m wide and 5.5 m high, 5 m deep, clear of the gates and the
  Line House); the inner half
  stays open to the Rim Walk as small rooms (the Watch's posts, stores,
  noodle counters, the lines' staff rooms), so the wall is lived in on the
  city side and blank on the desert side.
- **The Arches: the city's rundown warehouse** (proposed 2026-10-18, at the
  user's request for an abandoned warehouse venue). Five bays of the wall on
  the market lanes' south edge, between Market Lane's foot and the South
  Gate (`WALL.venue`: s 254 to 300 m, bays at 257 to 293, the door on the
  Rim Corridor at the middle bay), knocked through into **one long vaulted
  hall** and dug back 10 m into the old fill. It was a goods store when the
  Ring Line carried the city's freight; since the arches were filled it has
  stood empty, its shutters down, its brick black with old soot. The Wall
  Line's trains still rumble across its roof.
  - **Why here, and not Old Moy or a market-lane lot.** Old Moy is family
    tower houses round wells, with no building big or anonymous enough. A
    market-lane lot is about 23 by 12 m and lived in on every floor. The
    railway arches are where real cities put this (London's viaduct clubs and
    boxing gyms, Tokyo's *gādo-shita*): a long, loud, forgotten room at the
    edge of the night market's nightlife, with nobody living over it.
  - **The nights** (no timetable is announced; the player finds out):
    - **Tuesday and Friday: the fight club.** A ring in the middle bay, a
      crowd standing round it, a bar in the east bay. The fighting blorbs
      (Fighting Type, boxing gloves) fight here.
    - **Saturday: the rave**, from late till dawn: the ring struck, a booth
      in the west bay, lights and music through the whole run of vaults.
      On a Saturday night the people of the city drift toward it; follow
      them and you find it.
    - **Other days and nights:** shut, its shutters down, a light under one
      door.
  - Its build is roadmap package P18 (`moy_build_roadmap.md`). Its in-game text follows the rule:
    nothing names the nights or says what happens there.
- **The Deck under the train: Bangkok's Skytrain and Ratchaprasong
  Skywalk.** In Bangkok the elevated BTS line runs over the main roads on
  single concrete viaducts, and a pedestrian skywalk is slung beneath it on
  the same structure, joining station to station and into the buildings
  either side. Each station is street, concourse, then platform. Moy has the
  same section: street (0), the Deck as concourse (+6.5), platforms (+12).
  Hong Kong's Central footbridges and Singapore's covered linkways remain
  the Deck's precedents where it runs alone.
- **The cross lines and the ring: Chicago's Loop.** An elevated ring around
  downtown, with lines that come in over the streets and use part of the
  ring, on structure built over the streets themselves: the Spine and
  Meridian Lines sharing the park's north side follow its logic.
- **The cars: Lisbon's trams** for size and tight curves (12 m), built of
  SuperEggs in Moy's cream with a band of line colour (section 6e).
- **Structure:** viaducts and the Deck's portal frames in fair-faced
  concrete, piers of rounded-square (superellipse) section, soffits lined in
  pale tile so the shaded walk below stays light.

**The Wall Line** runs round the top, both ways, stopping at the four gates
(329 m apart). Three-car trains of the Moy car (6e) at 10 m/s, two each way, take
about three and a half minutes to go round. From the train you see the whole
city on one side and the desert, the turbines and the NMEs on the other: the
city's vigilance and its commute are the same ride.

**The cross lines** (revised 2026-10-16, at the user's direction): **two simple
straight lines**, one north to south and one east to west, at two levels so
they never meet. Data: `CROSS` in `tools/city_layout.py`.
- **The Spine Line, north to south, level at +13.2 m** (400 m; revised
  2026-10-17 after the first playable prototype): straight down the middle
  of North Street, through the park and down the middle of South Street, at
  the Wall Line's own rail height. **No track in Moy climbs.** It ends at a
  terminus just inside the wall at each gate, its buffer stops short of the
  Wall Line; the two lines never cross or join, and the Spine's platforms
  run on, level, onto the Wall Line's inner platform two metres away
  (section 6f). Stations: **North Gate**, **Estate Square**, **the
  Crossing**, **Market Square**, **South Gate**. Along North Street, the
  park and South Street it rides directly over the Deck, on the Deck's own
  columns carried up through it (after Bangkok's Skytrain and its skywalk).
  *(The first prototype found the line 3 m east of its streets' centre, so
  its trains brushed the east frontage, and its gate flyover climbed at
  29%; both are corrected here, and nothing needs to tunnel through a
  building.)*
- **The Meridian Line, east to west: the high line, at +36 m** (456 m;
  raised from +26 m on 2026-10-17 so the Timekeeper can be a full circle
  clear of city hall's roof). From its east terminus on the lower bridge of
  the **Meridian Arch, which is the East Gate** (8b), straight along the
  civic axis, through the **Timekeeper's** empty centre over city hall
  (8a.0), across Civic Plaza and over the Crossing (24 m over the Spine's
  trains), across Library Square and along West Street to its west station
  on the bridge between the **West Gate's towers**, with a siding for its
  trains beyond. Stations: **East Gate**, **the Crossing**, **West Gate**:
  few stops, the longest views.
- **The Crossing**, at the park's centre, is where they meet: an open ring
  (section 7a).

**Stations and circulation (2026-10-17, at the user's direction).** Every
station is one building that joins all the levels it serves, so a person
can go from the street to any train without leaving it. The levels:

| Level | Height | What is there |
|---|---|---|
| Street | 0 | the avenues, the squares, the park's lawns, the station halls |
| The Deck | +6.5 m | the walkway round the park and up the streets; the Crossing Ring's concourse |
| The Wall Line and the Spine | +13.2 m rail head, platforms +14.2 | one level, so their platforms meet at the North and South Gates; the Wall Line on the wall's 1.2 m trackbed |
| The high line | +36 m rail head, platforms +37 | the Meridian Line |

Every platform's floor is the car's floor, 1.0 m above the rail head
(section 6f).

- **Between the street and the Deck:** the ramp towers, the glass lifts,
  and **escalator pairs** (an up and a down side by side, 30°, 11.3 m long)
  set end-on into the Deck's edge from Civic Plaza, Market Square and
  Estate Square. *(The 12° travelators of the earlier plan ran 31 m and stood
  in the squares and the park as long obstructions; they are gone.)*
- **Up to the Spine's platforms:** a **scissor stack of escalator pairs**
  under each platform, from the street to the Deck (or a middle landing
  where no Deck runs below) and on to the platform (section 6f).
- **The station cores, for everything higher:** open steel frames of
  scissor stacks, glass lifts beside them; open-air, as Singapore runs its
  escalators everywhere, under a roof but open at the sides, the canopies
  shading the moving ramps. Checked in the layout.
  - **The Crossing:** four **garden towers** (section 7a, iteration 3),
    each a double-helix escalator round a steel trunk with a glass lift on
    its inner corner, serving the lawn (0), the concourse (+6.5), one Spine
    platform (+14.2) and one high-line platform (+37): any change of line
    is one tower.
  - **The East Gate (City Hall), revised 2026-10-17:** City Hall's city
    front (8b.1). The City Steps rise from the square to the Rostrum (+14.2),
    which opens straight onto the Wall Line's inner platform. A glazed
    scissor on each leg climbs to the high line's platforms (+37) and the
    sky garden (+43). A crossing at +21.8 inside each leg passes over the
    tracks to the outer platform. Glass lifts serve every level. The Watch
    reaches its command room (+58) by its own lift.
  - **The West Gate:** a scissor in each tower's outer pier, beside the
    train hall, serving the street (0), the Wall Line (+14.2) and the high
    line's west station on the bridge between the towers (+37).
  - **North and South Gates:** the Spine's terminus and the Wall Line's
    station on one level; the change is a few steps along the platform.
- **The high line's platforms and the Deck** are one system with the
  street: from any square you reach the Deck by its escalating ramp, the
  Spine through its platform floor, and the high line by the nearest open
  escalators; no route needs stairs, and almost every route is in the
  open air under shade.

**Rhythm and construction of the supports (2026-10-17).**
- **The Spine** stands on **portal frames on a 12 m bay**: two square
  columns either side of the track and a crossbeam under it. Where it rides
  the Deck, the Deck's own paired columns carry up through the Deck as the
  portals' legs, so the Deck and the Spine are one structure (after
  Bangkok's Skytrain and its skywalk).
- **The high line** stands on **tree piers spaced 36 m, three Spine bays**:
  a round-square stem 2.4 m across in the middle of the street, branching at
  +28 m into a Y that carries **twin steel box girders**, one under each
  track, after Santiago Calatrava's branching supports and the High Line's
  steel. The piers are set out from the Crossing (the nearest stand 54 m
  either side of its centre, a span and a half) and run on at 36 m; at the
  Crossing the line rests instead on two head beams between its four
  towers (13 m either side), so no pier stands in it (iteration 3);
  over Civic Plaza and city hall the girders make one 42 m bridge so no pier
  stands on the hall; at the west end the West Gate's tower carries the
  girders. The checks keep every pier off buildings and the
  Spine and every span within 42 m.
- **The rhythm**, read from the street: the Spine's frames every 12 m, the
  high line's trees every third frame where the lines run together, the
  Crossing's four garden towers, and the wall's arches every 9 m.
- **The Deck is the middle level** between the street (0) and the Spine's
  platforms (+14.2 m).
- **Where no rail goes:** the narrow lanes. Both lines keep to main streets
  and squares; the Meridian keeps 3 m clear of Old Moy's tower houses on
  West Street.
- **Cars:** two-car trains of the Moy car (section 6e). It is a game: the
  trains are there because riding them is fun.

**Structure and checks.** The cross lines stand inside the wall over
streets, squares and the park, or over buildings at least 2 m below their
soffit (the hawker centre); platforms stand on straight track and clear of
tall buildings; stations are at least 60 m apart along each line, and each
line ends at the wall or at an interchange. The wall has no building in it,
every building inside it, the works clear outside it, the Rim Walk clear,
and the turbines more than 40 m off. All checked in the layout.

**Play and collision.** The wall and its gatehouses are blocking; the wall
top, the watch walk and the gatehouse roofs are landings. The trains are
moving solid bodies (`AnimatableBody3D`, as the turbine blades): the hero can
stand on a car's roof or ride inside, and is pushed, not hurt. The cross
lines' viaducts are landings above the Deck. Leaf Hat anchors: the watch
towers and the gatehouse canopies.

**Who keeps it.** Kade Morrow (city works) inspects the wall and the viaducts
as well as the Deck; Omar Haddad's battery works power the lines. The Wall
Watch and the lines' controller are not yet in the census (Open).

### 6e. The Moy car (proposed 2026-10-17, at the user's direction)

**Direction (user):** the train cars are built of SuperEggs, relatively
short, two or three to a train.

**One car for every line** (data: `TRAIN` in `tools/city_layout.py`, checked;
3D preview `docs/drawings/moy_train_3d.html`):
- **9.6 m long, 2.65 m wide, 3.4 m tall** over everything, with a 0.8 m
  bellows between cars. A chubby, soft-cornered tram that belongs to the
  same world as the hero and the blorbs.
- **Every part is a SuperEgg**, as `scripts/superegg.gd` builds it:
  - **the body**, semi-axes 4.8 × 1.3 × 1.325 m, exponent 3.4 above (a
    rounded plan, round ends, soft roof shoulders) and 5.5 below (a flat
    floor), in cream glazed ceramic over an aluminium frame;
  - **the window band**, a dark SuperEgg slightly proud of the body and
    following its curve, wrapping round both ends, so the ends are
    panoramic windows rather than a driver's cab;
  - **the livery band** in the line's colour (the Wall Line ochre, the
    Spine teal, the Meridian violet);
  - **the roof battery**, a flat pod charged from the wind at the battery
    works (the lines have no wires);
  - **two bogies**, dark flat eggs;
  - **lamps**, small round eggs, at the train's two ends only;
  - **the bellows**, a dark egg between cars.
- **In the game** the builder makes each part with `SuperEgg.build_part`;
  the windows can be cut as apertures with `build_hollow_shell_mesh` when
  the interior is built. The car is a moving solid (`AnimatableBody3D`) with
  a simplified collider: the hero rides on the roof or inside.

**Two or three cars, by line:**

| Line | Cars | Length | Platform | Why |
|---|---|---|---|---|
| **Wall Line** | 3 | 30.4 m | 40 m | the ring is the commute, round the whole city |
| **Spine Line** | 2 | 20.0 m | 30 m | short runs on the Deck and separate +20 m gate flyovers |
| **Meridian Line** | 2 | 20.0 m | 30 m | the high line: few stops, a ride for the view |

**Why short cars.** The 9.6 m car is compact for the station platforms and
quick service. The Spine and Wall Line are separate services; neither uses
a curve or junction to the other. One fleet serves every line because the
same simple car suits all three routes and shares the Line House workshop.

**Checked in the layout:** every line uses the Moy car; each train is two
or three cars and stops at least 4 m short of its platform's length; the
car's swing on the tightest curve stays within its allowance; every part
stays inside the car's envelope and uses exponents superegg.gd supports.

**Boarding (2026-10-17):** the car is 3.6 m tall over everything, its floor
1.0 m above the rail head and level with every platform, 2.3 m clear and
2.4 m wide inside; two doors a side per car, each 1.4 m wide and 2.1 m
tall, open for the whole stop (section 6f).

**The first playable prototype (2026-10-17)** built each car as its own
rideable body following its path, which stays. Its gate flyovers, block
interlock, four-second stops and the train tunnels cut through the
All-night Store, the Hawker centre, the Neighbourhood centre and the lots
along the Spine's east frontage are **superseded** by the level Spine on
its streets' centre line, the gate interchanges and the timetable
(sections 6c, 6f, 6g). Its turbines (facing the west wind, 2 rpm), colour,
offset street surfaces and pond water stay.

### 6f. Platforms, boarding and the escalators (proposed 2026-10-17, after the first prototype, at the user's direction)

**Direction (user):** no track climbs; real platforms right beside the
trains, which players can step onto; escalators that run both up and down;
crisscross where it suits, spirals where they suit, all part of the
architecture rather than tacked on. Data: `PLATFORMS`, `ESCALATORS`, the
stations' `_stacks` and `_interchange`, and `CROSSING.towers` in
`tools/city_layout.py`, all checked.

**Platforms.** Every platform's floor is the car's floor, **1.0 m above the
rail head**: +14.2 m for the Wall Line and the Spine, +37 m for the high
line. Its edge stands **1.4 m from its track's centre**, 7.5 cm from the
car's side, so boarding is level and nobody steps over a gap. Platforms are
3 m wide, one beside each track (side platforms), 40 m long on the Wall Line
and 30 m on the cross lines, under a canopy 3.2 m up wherever nothing else
shades them. Trains stop with their doors at marks on the platform; the
doors stay open for the whole stop.

**The gate interchanges.** At the North and South Gates the Spine's two
platforms run on past its buffer stops, across the end of the line, onto the
Wall Line's inner platform, which overhangs the wall's city face over the
Rim Walk: one level floor, two metres from one train to the other. The
Wall Line's two platforms at every gate, one beside each track, stand on
the wall's top; at the East and West Gates they run through the train halls
in the arch's legs and the West Gate's towers, which now follow the wall's
curve.

**Escalators: always an up and a down.** Moving ramps without steps, as
everywhere in the city, 1.2 m treads, always built in pairs. Three ways to
stack them, each where it suits:
- **A pair** rises one level: from the squares to the Deck, 30°, 11.3 m.
- **A scissor** (crisscross) stacks pairs: each flight starts where the
  last ended and turns back, so every flight carries both flows. Under the
  Spine's platforms (street → Deck or a middle landing → platform), in City
  Hall's two front scissors and the West Gate's towers. A scissor's flights
  alternate between two bands side by side, so no flight runs under or into
  another (the arch's first cascades stacked theirs in one band and
  collided; retired 2026-10-17).
- **Handrails (user, 2026-10-17):** every lane, straight or spiral, has a
  moving handrail on both sides, moving with the treads, on a clear glass
  balustrade. At each end it runs on 0.9 m past the incline over the landing
  (the newel). Between the up and the down lane of a pair stand two
  balustrades, one for each lane. Data: `ESCALATORS.handrail`.
- **A double helix** winds an up spiral and a down spiral together round
  one eye, half a turn apart, so they never meet; after the double-helix
  stairs of the Château de Chambord and the Vatican Museums, and the trunk
  spirals of the Plant Kingdom's treehouses. 25°, wound round a steel
  trunk 2.4 m across (an eye 2.8 m), a 2.6 m band, 7.9 m of rise a turn and
  3.5 m of headroom between the hands, with a 1.8 m gallery outside the
  band at each level it serves. Used in the Crossing's four towers
  (iteration 3); the lift stands outside the tower on its inner corner,
  since a lift in the eye cannot reach a gallery past the hands.

**Integrated, not tacked on.** Each kind lives inside a structure it
belongs to: the pairs end-on in the Deck's edge, the scissors under the
platforms they serve and in the gate buildings' own frames, the helices
inside the Crossing's towers, which are also its structure. Each kind
carries the city's planting at its landings (section 6d).

### 6g. The timetable (proposed 2026-10-17, at the user's direction)

**A clock-face service.** One real second is one game minute (a game day is
24 real minutes, as the day-night cycle runs). **Every line runs a train
every 60 real seconds, which on the game's clock is one train every hour,
on the same minute of every hour**: a Moy schedule anyone can remember.
Data: `TIMETABLE`, derived and checked in `tools/city_layout.py`; the city
model runs its trains to it and shows a departure board.

| Line | Trains | Cars | Round trip | Notes |
|---|---|---|---|---|
| Spine | 3 | 2 | 3 h (180 s) | turns round in 21 min at each gate |
| Meridian | 3 | 2 | 3 h | turns round in 31 min at each gate |
| Wall Line, clockwise | 3 | 3 | 3 h round the city | |
| Wall Line, anticlockwise | 3 | 3 | 3 h round the city | |

- **Stops:** 8 min at ordinary stations, 12 min at the interchanges (the
  Crossing and the four gates). On the game's clock these are generous;
  in real time they are 8 and 12 seconds, enough to step aboard.
- **Hours:** 5:00 to midnight. Through the night the Wall Line keeps one
  **Watch train** each way, the city's vigilance going round the wall;
  the others stand in the Line House.
- **Timed changes:** the Spine's southbound and the Meridian's westbound
  trains stand together at the Crossing on the hour; the Wall Line's trains
  in both directions stand at the North Gate in the middle of the Spine's
  turnaround. Changes take 6 to 16 game minutes (6 to 16 real seconds).
- **Checked:** every line's round trip is a whole number of headways; no
  turnaround is shorter than 12 min or long enough to put two trains at
  one terminus; every train fits its platforms.

### 6d. A city in a garden: green infrastructure after Singapore (proposed 2026-10-17, at the user's direction)

**Direction (user):** the trains, the stations and the civic structures take
their inspiration from Singapore's urban design, a famously green city whose
greenery is built into its infrastructure rather than set beside it.

**References (Singapore):**
- **The Garden City and "City in a Garden":** the city's long policy of
  planting every road, flyover and public building, so that green is part of
  the infrastructure's own fabric. Its planted flyover and viaduct edges,
  troughs of bougainvillea and climbers on the columns, are the model for
  Moy's two lines.
- **LUSH (Landscaping for Urban Spaces and High-Rises, URA, 2009) and
  Skyrise Greenery (NParks):** a building gives back, on its terraces, roofs
  and walls, the green its site took. Moy applies the rule to its own civic
  buildings: the arch, the gate towers and the Crossing.
- **WOHA's Oasia Hotel Downtown:** a tower wrapped in a mesh that creepers
  climb, with open-sided sky gardens. The model for the high line's pier
  sleeves.
- **WOHA's Parkroyal on Pickering:** sky gardens stacked in the building's
  face. The model for the arch's sky terraces.
- **WOHA's Kampung Admiralty:** a public building with a community farm and
  park on its roof. The model for the West Gate's roof garden.
- **Gardens by the Bay's Supertrees:** steel trees planted with climbers.
  The model for the Crossing's garden towers, which are working ones.
- **The Park Connector Network:** green walks linking the parks across the
  city, with covered walkways to the stations. The Deck is Moy's park
  connector.
- **The Rail Corridor:** the old railway line kept as a 24 km green walk.
  The model for the Rim Corridor at the wall's foot.
- **ABC Waters and Bishan–Ang Mo Kio Park:** infrastructure that cleans and
  holds water in planted beds. The model for the rain garden under the
  Crossing, beside the reed pond that already polishes the city's water.

**Moy's terms: a desert, not the tropics.** Singapore's greenery is watered
by the rain; Moy's must be paid for in water. So:
- **A small, hardy palette**, six kinds and no more on the infrastructure:
  **bougainvillea** (drought-hardy and already Moy's climber on the wind
  trees), **coral vine** (a fast desert climber for meshes), **ghaf** (the
  park's shade tree), **date palm**, **agave and aloe**, and **desert
  grasses**.
- **Every drop used twice:** the reclaimed water from the works, polished in
  the reed pond, runs in a **green main** inside every viaduct and up every
  core, feeding drip lines at night. Planters are deep troughs with mulch;
  no lawn on the infrastructure (the great lawn stays the city's one).
- **Shade is the job.** Every planting shades a walk, a platform, a ramp or
  a glass wall, so the green cools the city it costs water to keep.

**Where it goes** (data: `GREEN` in `tools/city_layout.py`; the palette,
each element's keeper, its collision and its fit are checked):

| Element | Planting | After |
|---|---|---|
| **The Spine's edges** | a planter trough hung on each edge of the viaduct, bougainvillea spilling over it, bright blooms every 6 m | Singapore's planted flyover edges |
| **The Spine's frames** | coral vine on a steel mesh up each portal frame's columns | the greened columns under Singapore's viaducts |
| **The high line's piers** | a stainless mesh sleeve round each tree pier's stem, coral vine climbing it from +2 m to the Y at +28 m: a row of green trees down the civic axis | Oasia's mesh, the Supertrees |
| **The high line's edges** | bougainvillea troughs on both edges, so the line reads from the street as a green line across the sky | Singapore's flyovers |
| **The Deck** | a garden walk: beds alternating from side to side so the path winds, a small ghaf in every second wide bed (`DECK.beds`, `DECK.trees`) | the High Line; the Park Connector Network |
| **The Crossing** | coral vine and bougainvillea up each garden tower's mesh from planters at every gallery (`CROSSING.climbers`); the ring a garden walk like the Deck; a rain garden of reeds and grasses round each tower's foot, fed by the roof through the trunks (`CROSSING.rain_gardens`); desert grasses on the roof's rim | the Supertrees; Oasia; ABC Waters |
| **The open escalator towers** | planters along the escalating ramps' outer edges and at every landing, coral vine trailing down the frame and shading the flights below | Singapore's planted open-air station escalators |
| **The Meridian Arch** | sky terraces cut into the legs' east faces at +18 and +48 m, each with a ghaf; the lower bridge's roof (+42 m) a public sky garden over the high line's station, looking down the civic axis to the Timekeeper | Parkroyal on Pickering; LUSH |
| **The West Gate** | the bridge's roof is Old Moy's community garden: date palms, herb and vegetable beds on drip, a shade pergola; agave and aloe on the towers' roofs | Kampung Admiralty |
| **The Rim Corridor** | the Ring Line's old service road at the wall's inner foot, kept as a green walk all the way round: ghaf shade, desert grasses, bougainvillea over the wall's arches | the Rail Corridor |

**Who keeps it.** Kade Morrow's city works keep the planting on the lines,
the cores and the arch, from the green main's valves in the Line House; Orin
Pike, the park keeper, keeps the Crossing, the Deck and the Rim Corridor and
chooses the plants; Old Moy's residents keep their roof garden on the West
Gate, with Orin's help.

**Play and collision.** Troughs, meshes, terrace floors, roof-garden beds
and pergolas are solid with their structure, and the terraces and roof
gardens are landings; foliage, blooms and grasses are decorative. The green
lines change no route and add no text: they make the lines read as places
to walk under and look at.

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
  - **the Crossing** at its heart, the city's station where the two train
    lines cross (section 7a, revised 2026-10-16);
  - four quarters round it: the dry garden, the reed pond, the parasols
    with Old Fu's tea house and the chess terrace, and the **giant
    playground** with the green (sections 7a, 7b);
  - the park's trees, each with a job: a banyan over the pond, ghafs,
    flame trees and date palms (`PARK.trees`, section 7a);
  - **Garden Row**, a short row of three older townhouses, faces it from
    the west, across the Park Ring from Old Moy.

  Every district touches the Park Ring, so the park is the city's common
  ground, and the Deck runs round it.
- **The plazas** (user: "I like the idea of plazas"):
  - *(Revised 2026-10-17: Civic Plaza is now one grand square from the
    park to City Hall, the Meridian Arch; see 8a.1. The commercial blocks,
    Meridian Walk and Hotel Passage that briefly replaced the old plaza are
    gone.)*
  - **Civic Plaza**, on the park's east side, is city hall's forecourt.
    **City hall heads the plaza on its axis**, facing west across the plaza
    to the park. The plaza's sides are private and unlike each other: the
    Grand Hotel on the north, the BLOCK tower on the south, dark and
    windowless, watching the city's living room. Shade trees,
    misters and benches; Pia busks here; the Deck's two plaza ramp towers
    frame the axis under the skybridges.
  - **Library Square**, on the park's west side, the library's forecourt
    between its curved front and West Street (revised 2026-10-17: halved).
    It was 49 by 60 m, as big as Civic Plaza, and its south half beyond
    West Street had no job, so West Street now runs on through to the Park
    Ring, the square keeps the library's side (49 by 24 m, the portal, the
    broad sitting steps and the shade trees), and the south half is
    built up as an ordinary block of the market lanes' houses round a
    courtyard. The police box faces West Street, opposite the library.
  - **Market Square**, on South Street, ringed by stalls by day and by the
    night market after dark, with the wet market hall on its east side.
  - **Estate Square**, on North Street in the North Estate: the estate's
    neighbourhood centre, with the hawker centre on its south side and the
    centre building (minimart, kindergarten, community club) on its north.
  - **Cinema Square**, a small square in Old Moy where the Moonlight Cinema
    and Sol's café face each other.
- **Arrival.** No road reaches Moy. The hero comes on foot across the open
  desert to one of the wall's four gates (section 6c); a hero with the
  powers to climb it can also come over the wall. From the plateau side the grand way in is **Meridian Avenue**
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
  - **How it looks** (the tower house kit, `moy_tower_house.md`, after the
    user's reference photo of a highland Yemeni tower house, 2026-10-13):
    battered bases of coursed rammed earth with rounded corners, a white
    gypsum cornice, brick storeys above with white-outlined windows under
    semicircular fanlights, projecting box windows, crenellated parapets
    with horned corners, roof terraces where families sleep on summer
    nights; later tiled pencil buildings fill the narrowest lots.
  - **How it is lived in now** (proposed): built as one family's house
    each, most towers are now a ground-floor shop and a flat on each floor
    above, sharing the ramp core and the roof; a few are still whole.
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
  - **The Well Quarter: the old roads and their blocks** (proposed
    2026-10-16; **revised 2026-10-17, at the user's direction**). The first
    version wound a dozen lanes and dead-end alleys through the old fabric,
    which left plots no real house could stand on and lanes running into
    buildings. The old town is small, two blocks either side of West Street,
    so it now keeps **only the roads that were there before the grid**, and
    the grid was laid round and across them. **References:**
    - **Broadway and Greenwich Village, New York:** roads older than the 1811
      grid, which the grid was mapped round, so they meet it at odd angles
      and make wedge-shaped blocks.
    - **Barcelona's Ciutat Vella and the Eixample:** an old town held inside
      a modern grid, its few old roads running on into the new streets.
    - **Al Fahidi (Bastakiya), Dubai:** a small quarter of wind-tower houses
      in compact blocks round courtyards, surrounded by modern roads. The
      closest in scale and climate to Moy's well town.
    - **Vieux-Québec:** an old town inside its wall, its houses facing the
      street that runs round the wall's inner side.

    **The old roads** (data `OLD_TOWN`, checked: at most three, each running
    road to road, through no building):
    - **The Old High Street**, the caravan road from the plateau's foot: it
      leaves **Cinema Square** (the capped first well and the oldest shade
      tree) north across West Street and bends north-east past Mara's
      building to Arcade Street; south of the square it runs between the
      cinema and Sol's café to Clinic Lane, which cut off the rest of it.
      6 m wide, a swing route.
    - **Mara's Lane**, a short old branch from the Old High Street east to
      Arcade Street along the north side of Mara's building (named for the
      district's old name).

    **The blocks** (data `OLD_HOUSES`, checked): every block is the ground
    between roads, and its buildings come first. A perimeter row of tower
    houses faces every road the block touches: the old roads and the square
    first, so the oldest houses face them, then the grid streets, then the
    **Rim Walk**, which the houses at the city's edge face as Québec's face
    the street inside its wall. Each plot is cut square to its frontage, 6
    to 10 m wide and up to 14 m deep; slivers at corners join their
    neighbour only where that makes a buildable plot, and otherwise become
    part of a courtyard. Every house has at least 30 m², is at least 4.5 m
    across and nearly convex. The middle of each block is its **shared
    courtyards**, reached through the houses, as in Al Fahidi. Sixty tower
    houses, about 94 m² each, covering about three quarters of the ground.
    There are no lanes inside a block and no dead ends.
  - **The seam with New Moy.** The boom cut **West Street** straight
    through the well town (the Meridian Line now runs above it), and New
    Moy's grid streets (Arcade Street, Tank Lane, Clinic Lane, Market
    Street) run round it. The houses along the grid streets stand square to
    them, so the old town reads from the grid as straight frontage with the
    old roads leaving it at an angle. The cistern block south of Clinic
    Lane is now an ordinary block of the same perimeter houses; Theo's
    tower house moved to its corner on Clinic Lane.
  - **Swinging through.** The Old High Street is 6 m wide and walled at
    least three quarters of its length by tower houses 16 m or taller, with
    anchors in the vine's reach (12 to 52 m, 7 m above) the whole way: a
    swing route from Arcade Street through Cinema Square to Clinic Lane.
    Mara's Lane is for walking, and the tower house roofs, a few metres
    apart across the courtyards, are for running roof to roof.
  - **Its places:** Sol's café and the Moonlight Cinema on Cinema Square,
    the bakery, the clinic, the police box, Pinestein's rooftop laboratory,
    Mara's rooftop studio, the Reese–Miller house.
- **The market lanes** (south) hold Market Square, the wet market, the night
  market, the covered shopping arcade, the Helmsmith, Hiro's store, Wing Fat
  Mansion and the school. Their street buildings are Hong Kong tong lau
  (`moy_market_lanes.md`, proposed 2026-10-13): four- and five-storey
  **boom houses** with verandas over the pavements, built for the
  Windworks' first workers, and six- to nine-storey **tile houses** with
  balconies and rounded corners, built as the city grew; narrow pairs share
  one ramp core on their party wall; slivers hold two-storey lock-up shops;
  Arcade Street is roofed in the shōtengai manner.
- **The North Estate** (north; renamed from Parkside Estate, user) is the
  public housing, planned the way Singapore's estates are (user): as
  **precincts**, not as lots. North Street divides it into a west and an
  east precinct, each a single site with no private lots in it. Section 7d
  has the full plan.
  - **Broad blocks, close together, round a court** (user, 2026-10-13).
    Each precinct is a ring of broad slab and point blocks, 10 to 20 m
    apart, enclosing a shared court, after the precinct plans of
    Singapore's 1980s estates and the linked blocks of Pinnacle@Duxton.
    The blocks form the precinct's walls; the court is its living room.
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
  - **Turned off the grid:** the blocks standing back from the streets
    turn 30° together onto the estate's own grid; the street-edge blocks
    keep the city's (7d).
  - **The twins**, Blocks 4 and 5, stand side by side facing the library,
    joined by a sky bridge and sky garden at the 26th floor over the gap
    between them, which is the west court's gate.

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
  - the **BLOCK tower** on the plaza's south side, BLOCK's headquarters,
    BLOCK's only building (its old six-storey labs behind it are ordinary
    mid-rise real estate now);
  - the **north tower** (start-up capsules) and **south tower** (flats over
    offices, Tanglewire) on the Park Ring's east corners;
  - **mid-rise blocks of 18 to 34 storeys** filling the rest of downtown
    round the towers, offices and flats on large footprints (20 to 34 m
    frontage), so the towers rise out of a solid mid-rise mass instead of
    standing among small buildings (user).

  The Grand Hotel's guest tower rises on the plaza's north side.

### 7a. The park and the giant playground (proposed, 2026-10-12)

The park is the city's common ground: about 130 × 100 m at the centre of
Moy, ringed by the Park Ring, with the Deck running round it at +6.5 m.

**Revised 2026-10-16 (user): a shared park.** Its centre, where the two cross
walks meet and the two train lines cross, is **the Crossing**, the city's
civic structure and station. **Revised 2026-10-17 (user): open air.** The
lattice dome first proposed blocked the view across the park, so the Crossing
is now an open ring, after **Sou Fujimoto's Grand Ring at Expo 2025 Osaka**
(a ring of timber frames you walk on and under, open to the sky in the
middle).

**Revised 2026-10-17 (plan iteration 3, at the user's direction): designed
from what people do there.** The first open ring had a halo at +18 m that
sheltered nothing anyone waited on, 48 slender columns of several sizes, two
spirals that ate holes through both rings and clipped the concourse, and the
high line's piers rising through it. It is redesigned from its purpose:

- **What people do there.** Every change of line is between one Spine
  platform (+14.2, east or west of the Spine) and one high-line platform
  (+37, north or south of the Meridian). So there are **four garden
  towers**, one in each quarter, each in the corner where a Spine platform
  and a high-line platform pass each other, 13 m from the centre on both
  axes. Each joins the lawn (0), the concourse (+6.5), its Spine platform
  and its high-line platform, each a 1.1 m bridge from its gallery. Any
  change of line is one tower, up or down; no one crosses a track.
- **A tower:** a steel **trunk** 2.4 m across (its rain downpipes inside);
  a **double-helix escalator** (section 6f) wound round it, the up hand and
  the down hand half a turn apart; a 1.8 m **gallery** outside the helix at
  each level it serves, which riders step onto sideways where their hand
  meets the level; **eight ribs** in a ring 12 m across carrying a steel
  mesh that coral vine and bougainvillea climb from planters at every
  gallery, bays left open where a bridge or the ring leaves; and a round
  **glass lift** on the tower's inner corner, standing between the two
  platforms, which opens straight onto both.
- **The towers are the structure.** Head beams between them carry the
  Spine (east-west, 1.6 m deep, at +10.4 to +12.0) and the high line
  (north-south, at +30.6 to +32.6): no other column stands under either
  line inside the Crossing, and the high line's nearest piers stand 54 m out.
  One roof rests on the towers' tops.
- **The concourse** is the station's mezzanine at the Deck's level: the
  **Crossing Ring** (24.7 to 32.7 m from the centre, 8 m wide), a garden walk
  round the four towers whose outer faces it touches, which the Deck's Spine
  walks join from north and south; and two **cross-bridges**, tower to tower
  under the Spine's tracks, hung from its head beams (3.9 m of headroom),
  which join the towers and both Spine platforms below the trains. The ring
  is a steel box girder 1.6 m deep spanning at most 20 m between its eight
  supports: the four towers and four pairs of Deck columns (two where the
  Spine walks cross it, two pairs either side of the cross walk east and
  west, clear of it). Its program: the information desk, the
  lost-and-found, kiosks and water fountains, between its beds.
- **The middle is open** from the lawn to the sky: nothing stands in it but
  the lines passing over.
- **One roof**, a louvred table on the four towers at +41 m (1 m over the
  high line's trains), a superellipse 44 m across: it shelters the high
  line's platforms, where people wait, and the towers' top landings, shades
  the middle and the Spine's platforms from the high sun, and its rain runs
  down the trunks to a **rain garden** of reeds and grasses round each
  tower's foot. Desert grasses on its rim. The Spine's platforms have their
  own louvred canopies at +17.4, over their bridges to the towers.
- **The city's clock (2026-10-17, at the user's direction; dome revised the
  same day):**
  - **The dome.** A glass dome stands on the roof. Its drum is a rounded square
    in plan (the roof's superellipse, 40 m across, 17 m high), with a **ring
    clock 16 m across** set flush in each side. The clocks face north, south,
    east and west, down the four streets to the park. A cupola rises above the
    drum to about 70 m.
  - **One shell.** Drum and cupola are one shell of clear glass on a fine
    **triangulated grid** of slender white members. It is modelled on Foster's
    Queen Elizabeth II Great Court at the British Museum:
    - every pane is a triangle;
    - the grid sweeps from the near-square base up to a small crown ring, which
      carries the bell and a little glass lantern;
    - it has no posts and no ring beam. The first dome's 24 posts and steel
      ring read as a cage.
  - **The clocks.** Each is a ring clock: the hour ring and, outside it, the
    minute ring, each with a lit arrow, and a fixed bezel with hour marks and
    minute ticks. The seconds bead is gone (user, 2026-10-17). They keep the
    game's time, so the dial and the bell agree.
  - **The eyes.** Each clock's hollow centre is an **open eye** through the
    glass, 5.7 m across. It is lined with a bronze sleeve inside the turning
    hour ring, with a bronze sill 3.1 m wide and 5.25 m clear above it. There
    is no glass and no guard, so it is a way in and out for climbers, gliders
    and fliers, and a balcony onto the street it faces.
  - **The bell.** A **great bronze bell** (4.4 m across the mouth) hangs from
    the crown ring. It rings three times a day, never on the hour (an hour is
    one real minute), after the Angelus and the old curfew bell:
    - **the dawn bell** at 5:00 (sunrise): three strokes three times, then
      nine;
    - **the noon bell**: twelve strokes;
    - **the evening bell** at 19:30, half an hour before sunset: as the dawn
      bell.

  Data: `CROSSING.dome`.
- **The Clock Room (2026-10-17, at the user's direction).** The dome's floor
  (the roof's top, +41.6) is a public room under the glass and the bell. It is
  a destination you go to on purpose, not a stop on the way:
  - **The towers.** The garden towers' escalators end at the high line, so
    everyone gets off at the station first.
  - **Ways in.** Every way in is one of the room's designed openings:
    - **the arrival wells.** At the middle of each high-line platform, directly
      under the clock, the platform widens 2.6 m on its outer side into a
      landing. From it, two escalator pairs, one either side of the axis, climb
      4.6 m through glass-guarded wells in the floor. They arrive by the glass,
      under a clock's eye. Each well is guarded on three sides and open where
      riders step off.
    - **the lift lanterns.** The four tower lifts run on through the roof, and
      each arrives in a glass lantern whose door faces the bell. The lifts
      stop at the ground, the Spine, the high line and the room.
    - **the clock eyes,** for fliers and gliders only.
  - **No way up to the eyes (revised 2026-10-18, at the user's direction).**
    - The escalators that rose from under the bell to a landing behind each
      eye are gone.
    - An eye is not a place to carry ordinary people up to: it would be a
      ledge to fall from.
    - A flier lands on its bronze sill; nothing walkable or rideable rises
      toward it, and the plan checks that.
  - **Inside:**
    - a bronze **compass rose** is set in the terrazzo under the bell, its
      points toward the four clocks;
    - beds of desert grasses run along the glass.
  - **Checks.** The plan checks that:
    - the eyes are big enough to pass through, inside the hour ring;
    - the arrivals stay clear of the towers, the lifts and the glass;
    - the widenings stay on their platforms;
    - no opening fouls another;
    - nothing rises toward an eye;
    - the bell hangs clear over the room.

  Data: `CROSSING.dome.room`.
- **The reed pond is real water (revised 2026-10-18, at the user's direction).**
  In the third pass it hovered: its water stood 0.4 m above the park on a
  bespoke near-opaque shader.
  - **The water.** Its surface lies 0.3 m below the park's ground, its edge the
    plan's ellipse.
  - **The banks.** They shelve from the ground (at 1.15 × its radii) down to
    the waterline, under reeds and flat stones, with no wall.
  - **The bed.** A reed shelf round the edge, then down to 2.1 m in the middle.
  - **The material.** It is built with the world's one water,
    `VillageWorks.water_material()`, as every village pond is: translucent and
    two-sided, a hazard on the liquid queries.
  - Data: `PARK.pond` (checked: the water below its banks, nothing on the
    banks).
- **The towers' ways out (revised 2026-10-18, at the user's direction).** In
  the third pass, the ring every 4.1 m round each tower crossed the ways out at
  head height, and with twelve ribs a rib stood in each diagonal way out to the
  ring.
  - **Ribs.** Eight ribs at 22.5° + 45k, so every way out (all at multiples of
    45°) is in the middle of a bay.
  - **Hoops.** Only where nobody walks out: never from a level's floor to 2.8
    m above it, and at most 4.2 m apart elsewhere (`towers[...].hoops`).
  - **The check.** The plan lists each tower's ways out (`ways_out`: level,
    bearing, width, clear height) and fails if a rib stands in one or a hoop
    crosses one.
- **The escalators are closed boxes (2026-10-18).** In the third pass the
  helices' undersides were invisible and had no collision from below. Every
  flight, straight or spiral, is now a closed section 0.9 m deep
  (`ESCALATORS.section`):
  - the moving treads on top, with the return belt hidden inside;
  - solid skirts at its sides;
  - a hard brushed-stainless soffit underneath, facing down.
  - Top and soffit both collide.
- **Planted:** the towers' climbers (`CROSSING.climbers`), the ring's beds
  and small ghafs (`DECK.beds`, `DECK.trees`), the rain gardens
  (`CROSSING.rain_gardens`), the roof's rim.

Data: `CROSSING` (towers, tower, ring, roof, head beams `_beams`, ring supports
`_ring_supports`), checked: the towers' bridges and lifts against both
platforms, their clearance from both lines' decks, headroom under the head
beams, the ring's spans, the roof over the trains and over the platforms and
towers, and everything off the park's walks, pond, playground and buildings.

The giant playground moved whole to the south-east quarter (7b), beside a
smaller green and the park lodge. In a desert it has to earn every drop of
water, so most of it is shade and dry garden, and the one green lawn and the
one pond each have a job.

**References:**
- **The Persian four-part garden (chahar bagh):** a garden quartered by two
  crossing walks, with shade along every path. Moy's quarters are divided by
  tree-lined walks instead of water channels.
- **Gardens by the Bay, Singapore:** the Supertrees, steel trees planted
  with climbers; the Crossing's towers are working ones.
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

The Crossing stands where they cross. Low shrubs line the park's edge under
the Deck's arcade (a tree there would put its crown into the Deck); the
shade trees stand inside the quarters, each with a job. Each quarter has a
job:

| Quarter | What it is | Why it is there |
|---|---|---|
| **North-west: the dry garden** | Ghaf groves, agave, aloe, desert marigold and boulder outcrops on gravel; never watered. Orin Pike's teaching garden of the desert's own plants | Next to the old town and its wells: the desert as it was |
| **North-east: the reed pond** | A shallow pond of reed beds and open water, crossed by boardwalks. It polishes the city's reclaimed water before it goes back to the street trees; dragonflies, frogs, herons | Beside the hotel and Civic Plaza: water working, not for show (user: no opulent fountains). The reclaimed water reaches it through the open runnel across the hotel's atrium floor (8.8) |
| **South-west: the parasols** | Old Fu's tea house and the chess terrace, under a timber canopy of giant parasols | Facing Old Moy and Garden Row; the Hos play here every afternoon |
| **South-east: the great lawn** | The one irrigated lawn, for picnics, lying down and evening music; the park lodge on its edge | Facing the market lanes and the south tower: lunch from the market, and the office workers' hour off |

**The trees (2026-10-17, replacing the four steel wind trees, at the user's
direction).** Real trees from the plant kit (`NatureProps`), each placed for
a job and recorded exactly in `PARK.trees` (kind, trunk point, height), at the
kit's proportions (`TREE_KIT`: the clear trunk and the crown's radius as
fractions of the height):

| Where | Trees | Job |
|---|---|---|
| The pond | a **banyan** (13 m) on its north-west bank, its crown over the water; three **ghafs** (8 to 9 m) on its east bank and toward the Park Ring | shade by the water; a screen from the street |
| The playground | three **ghafs** (9 to 10 m) round its rim | shade for the parents' benches |
| The tea house and chess terrace | three **flame trees** (9 m) | shade over the tables, colour |
| The dry garden | five **date palms** (10 to 12 m) in a loose group among rocks and agave | the dry garden's oasis |
| The cross walk | eight **date palms** (12 m), an allee east and west of the Crossing under the high line | shade along the civic axis |

Every crown keeps 1.5 m inside the park's edge (clear of the Deck), clear of
the Crossing Ring and its towers and of the high line's piers; trunks keep
off the walks, the pond, the lawn and the playground (checked). The small
planting is recorded too: shrubs along the edge (`PARK.shrubs`), reed clumps
and flat stones round the pond (`PARK.reeds`, `PARK.rocks`), boulders and
agave in the dry garden (`PARK.rocks`, `PARK.agave`). The wind trees' jobs in
the playground move (7b): the Crossing's south-east tower (41 m, about 34 m
from the Lookout) and the high line's pier on the park's east side (36 m)
are its high anchors; its hoops hang on cables between its own towers.

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

**Moved (2026-10-16):** the whole playground now stands in the park's
south-east quarter at 0.55 of the size below (about 31 m across), its towers
keeping their heights; the Crossing took the centre. Distances below are
the original design's.

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
8. **The hoops:** eight rings, each 3 m across, hung on cables strung
   between the playground's own towers, spiralling up round the Lookout and
   down over the splash pad.

**Built for the hero's platforming.** Every route is reachable on foot by
the residents' children, through nets, ramps and climbing walls (no stairs,
by the ramp rule). Each suit power also has its own way through, sized to
the hero's real movement (`player.gd`):

| Movement | The hero's reach | What the playground gives it |
|---|---|---|
| Ordinary jump | about 1.4 m up; gaps of about 3 m running, 4.5 m sprinting | The Lookout's spiral of platforms rising 1.2 m at a time; tower-to-tower hops of 2.5 to 4 m |
| Blorb bounce | about 2.5 m off a called blorb | Shortcuts onto the nets and the lower towers |
| Blorb super-jump (a timed jump on the bounce) | about 12 m | The bounce court's ring of high perches at 11 to 12 m, reachable only this way, as in the Demo World's pit |
| Leaf Hat vine swing (rope 12 to 52 m; anchor at least 7 m above) | from tower tops to the Crossing's towers and the high line's pier | The **swing loop** (revised 2026-10-17, proposed): the Lookout (20 m), the Crossing's south-east tower (41 m, about 34 m away) and the high line's pier on the park's east side (36 m, about 32 m away) make a circuit over the playground and out across the park to the towers on the Park Ring; the ghafs on its rim (crowns to 10 m) serve short swings |
| Air: cloud platforms and hover | a cloud ahead at shoulder height or underfoot | The **cloud run** (revised 2026-10-17, proposed): from the Lookout's top (20 m) to the south-east Crossing tower's gallery at +14.2, about 30 m off, too far to jump |
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
the picture-sign colours) but no two look alike.

**Breathing room and a life at their feet** (revised 2026-10-14, after the
user's review of the model). No irregular tower takes its whole plot. Each
shaft stands back at least 6 m from every neighbour and leaves at least 40%
of its plot as public ground, and that ground has a use: a garden, a
forecourt, a court or a low pavilion of one or two storeys whose roof is a
terrace at the Deck's +6.5 m. Data: `TOWER_SITE` in `tools/city_layout.py`,
checked. Round them, downtown's mid-rise mass is raised to **18 to 34
storeys (65 to 122 m)**, a third to a half of the towers' height, so the
towers rise out of a city rather than over a plain, as in Hong Kong's
Central or Tokyo's Marunouchi.

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
- **Structure through the gaps** (revised 2026-10-14: the first model read
  as a tower balanced on thin poles). Each wind gap is a slot open west to
  east, not a waist: a broad concrete core and three steel mega-columns at
  the triangle's corners run unbroken through it, and a two-storey transfer
  truss band sits under and over every gap, as round the turbine openings
  of the Pearl River Tower. The turbines spin between the columns.
- **Site:** a 28 m shaft set back in the **wind garden**: desert grasses that
  move in the wind, a ring of small turbines at head height, shade trees and
  benches on Meridian North facing Civic Plaza. The lobby's glass hall stands
  on the hotel side, and a glass bridge at +6.5 m crosses the garden from
  the hotel's mezzanine into it (the Deck's indoor run).
- **Crown:** an open steel lattice round the observation deck, with a slow
  vertical-axis turbine as its spire, lit white at night.
- **Play:** the fins and the wind-gap ledges are the highest swing anchors
  and climbing holds in the city. The observation deck is realised.

**2. The BLOCK tower** (BLOCK's headquarters, about 38 storeys to 150 m, its crown to 212 m; revised 2026-10-14: the glass tower is now BLOCK's)
- **Idea:** the city's one dark tower, facing its living room. Everything
  sinister in Moy is concentrated here, and none of it is said: the
  architecture says it. Pinestein's old laboratory is sealed in its base.
  Data: `BLOCK_TOWER`.
- **References:**
  - **33 Thomas Street, New York:** a windowless granite skyscraper (the
    telephone exchange) with ventilation hoods where windows should be.
  - **Boston City Hall:** the mass looming over a recessed base.
  - **Revised 2026-10-17 (user): a menacing silhouette, not a flat top,
    and an original one.** A flat-topped box reads as a filing cabinet,
    not a threat; a borrowed crown (Nashville's AT&T building was the
    example of a dynamic, ominous crown, not a model) reads as a costume.
    What makes a tower ominous is tension: a form that narrows and sharpens
    as it rises, leans toward what it watches, and gives away almost no
    light. The crown folds **inward**, so it never reaches over its
    neighbours' air.
    - **Hugh Ferriss's night towers:** dark masses with almost no light, so
      the little there is reads as eyes.
- **Form:**
  - a blue-black glazed brick shaft, 26 by 24 m, in a city of pale tile;
    at a low sun it shows an azure sheen, the city blorbs' colour;
  - **no windows**: hairline slits every 4 m, and three rings of vent hoods
    (at 30, 55 and 80% of its height) that breathe warm air at night;
  - its base set back 4 m and 9 m high, so the shaft hangs over its own
    door;
  - **the shaft rises sheer to 150 m**; there its four faces **fold
    inward** to a knife-edge ridge, so the crown narrows from the shaft's
    full 26 m to a 2 m edge;
  - **the ridge is set close to the plaza face** (3 to 5 m back from it):
    the plaza face rises almost sheer and the back falls away in one long
    slope, so from the side the crown is a blade raised toward Civic
    Plaza, and from the plaza a tall narrowing shard;
  - **the ridge is canted**, off-centre to the west and falling from 212 m
    at its west end to 198 m at its east, so the blade looks raised and
    turned rather than a symmetrical obelisk;
  - **ribs** continue the shaft's slits up the folding faces and converge
    on the ridge;
  - **one light**, in a skyline where every other tower is lit: a single
    **vertical azure slit**, 1.2 m wide and 24 m tall, in the crown's plaza
    face, the colour of the city blorbs. At night the tower is a dark shard
    with one slit pupil.
  - Checked in the layout: the crown stays inside the shaft's footprint;
    the ridge sits in the plaza-side third and is canted; the eye fits the
    crown's face and faces Civic Plaza; the crown stays below the Windspire
    (262 m).
- **Site:** a forecourt of bare pale paving in full sun on Meridian South,
  no bench and no tree, and **one door**; the rest of the plot is black
  gravel, raked every morning, that no one walks on. It is the only tower
  without a life at its foot, and that is the point. It stays off the Deck.
- **Who:** Dr. Vera Kask, the director, lives on the top floors and is rarely
  seen at street level. No one else the hero knows works there, except Pinestein, in secret (user, 2026-10-18).
- **Story:** the hero climbs the vent hoods to get in; inside are Pinestein's
  lab and the climax, a boss fight against the blorb mech (package P17,
  `moy_pkg_P17.md`).
- **Play:** the vent hoods are the only holds; the ridge is an anchor no one
  should swing from.

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
- **Site:** the capsules start at the third floor, so the ground under them
  is open round the core: workshops and a cafe in the shade of the capsules
  above, and the **makers' yard** on Hotel Lane, with bike racks and the skate
  run Theo uses at lunch.
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
- **Site:** a two-storey colonnade under the first balconies (the lobby, a
  nursery, the residents' room) opens onto the residents' garden: a pergola,
  a play lawn and a sand pit, with a shaded garden on Market Lane.
- **Crown:** roof terraces stepping back, the residents' gardens.
- **Play:** the rippling balcony edges are a staircase of ledges for
  climbers and swing anchors along the south of Civic Plaza. Tanglewire has
  its office floors above the colonnade.

(BLOCK's old six-storey labs behind the tower became ordinary mid-rise real
estate on 2026-10-16; everything of BLOCK's is in the tower now.)

**What happens at BLOCK** (proposed 2026-10-14, in review; the user asked
for the evil activities and people to be concentrated there).
- **One person.** Dr. Kask keeps BLOCK running with machines: the tower's labs work through the night with
  no one in them, and she is the only person the hero ever sees go in. It
  is the one building in Moy without named people inside, and that is
  what is wrong with it.
- **The work never stopped.** The living-current work that made the city
  blorbs goes on. At night the tower draws more power than the rest of
  downtown together (Omar Haddad sees it on the battery works' meters
  and says nothing), and the azure slit in its crown is the colour of the city blorbs.
  Proposed: Kask lures city blorbs in from the desert with the grid's power
  to study and drain them, the very creatures the city banned and fears.
- **Pinestein knows.** He watches BLOCK from his roof in Old Moy, and the
  batteries he takes out to the city blorbs at night are partly to keep
  them away from it.
- **Open:** whether BLOCK serves the Demon King, as the Royal Chef does in
  the Chinese village; what the hero finds inside, and when.


**5. The Grand Hotel's guest tower** (28 levels, 96 m, and the drum to 108 m, rising from a 44 m atrium block; full brief in section 8, proposed 2026-10-13 after the user's direction to follow John Portman)
- **Idea:** the oldest tower downtown, the boom's idea of the future: a
  white cylinder with glass lifts running up its face.
- **References:**
  - **Westin Peachtree Plaza, Atlanta, and Westin Bonaventure, Los
    Angeles (John Portman):** the cylinder tower, the revolving restaurant
    at the top, and outside lifts that climb the face.
  - **Hyatt Regency Atlanta (Portman):** the atrium, the bulb-lit capsule
    lifts and the revolving Polaris lounge.
- **Form:**
  - a cylinder 28 m across in white board-formed concrete, ribbed every
    2.2 m round its face, with bronze glass recessed between the ribs;
  - four glass capsule lifts, outlined in bulbs, riding up its south face
    from the atrium to the crown.
- **Crown:** the drum: a ribbed ring hiding the water tanks, the Windrose
  revolving lounge in bronze glass over it, and a shallow dome lit at
  night, the first landmark seen from the plaza.

**The skyline together:** the twisting Windspire with its spinning wind
gaps is the tallest; the dark, unlit BLOCK tower, the plug-in capsule tower
and the dune-balconied flats step down around it; the old white drum of the
hotel, its glass lifts climbing it, stands in front, facing the park.

### 7d. The North Estate: precinct plan (proposed, 2026-10-13)

**The direction (user, 2026-10-13):** the blocks are broader and closer
together. The first plan stood slim 22 m point blocks well apart in open
gardens. It read as scattered towers in leftover ground, unlike the dense
city round it.

**The model: the precinct round a court.** From the late 1970s Singapore's
Housing Board stopped lining blocks up in parallel rows and grouped them
into **precincts**: six to eight blocks round a shared court, small enough
for neighbours to know each other, each with its own playground, pavilion
and void decks (Tampines, and the later precincts of Toa Payoh and Ang Mo
Kio). Pinnacle@Duxton (2009) adds the second idea: broad blocks linked by
sky bridges into one building. The North Estate takes both. Each precinct
is **one near-continuous wall of broad blocks round a court**, with gaps at
the corners for light, wind and the linkways.

**Turned off the grid (user, 2026-10-13).** The blocks that stand back
from the streets turn **30° anticlockwise** off the city grid together,
so each precinct's ring sits on its own grid, running west-south-west to
east-north-east. The blocks that hold a street edge keep the city grid:
Block 6 on the Park Ring, Block 7 on North Street, Block 3 on the corner of
the Park Ring and Estate Lane, and Block 8 on Estate Lane. Behind that
street wall the turned blocks stand in their gardens, the way Singapore's
new towns were laid out on their own lines, regardless of any older grid.
- **Wind.** The west wind funnels through the basin. Turned, the gaps
  between blocks meet it on the diagonal and draw it through the courts,
  instead of letting it skim past slabs parallel to it. Singapore's Housing
  Board orients its blocks by wind studies for the same reason.
- **Sun.** The long faces look north-north-west and south-south-east, away
  from the low western sun.
- **Views.** Flats face out on diagonals, over the city, the park or the
  desert, so no window looks straight down a street or into a neighbour.
- **Character.** The estate reads as its own place, a later layer on the
  old grid. The triangles left between the street-edge blocks and the
  turned ones become planting and play pockets.
- **Play.** Diagonal gaps give long swing lines across the courts that
  the street grid never offers.

The plan stores each turned block as its footprint plus an angle
(`CityPlan.corners()` gives the true outline), and the validator tests the
true outlines.

**Why broad and close suits Moy:**
- It matches the city: Old Moy's walls and downtown's mid-rise mass are
  continuous, and now the estate is too.
- A broad block puts many flats on each floor along an open corridor
  (laundry poles out of every window), so fewer, broader blocks house the
  same people.
- The gaps between blocks, 10 to 20 m, are **swing gaps**: a Leaf Hat rope
  (12 to 52 m) spans them, so the courts are walls to swing between,
  corridor rail to corridor rail. The old gaps of 30 to 40 m were too wide
  to play.
- Closeness is shade: a desert court between tall walls is in shadow most
  of the day.

**The west precinct** (west of North Street, north of Library Lane). The
ring of Blocks 1, 4, 5 and 9 is turned 30° about the west court's centre:

| No. | Block | Footprint | Height | Place in the ring |
|---|---|---|---|---|
| 17 | Block 1 | 14 × 34 m, turned | slab, 28 storeys | the west-south-west end, backing onto Arcade Street; Tomas Wren |
| 53 | Block 9 | 46 × 16 m, turned | slab, 24 storeys | the north-north-west wall, its back to the community garden and the Rim Walk |
| 20 | Block 4 | 22 × 20 m, turned | broad point block, 40 storeys | the twins: the south-south-east wall, facing the library and the park |
| 21 | Block 5 | 22 × 20 m, turned | broad point block, 40 storeys | the twins; Dr. Imani Osei and Kofi |
| 49 | Block 7 | 14 × 74 m, on the grid | slab, 16 storeys | the east side, shops in its void deck on North Street |
| 22 | Block 6 | 67 × 16 m, on the grid | slab, 14 storeys | outside the ring, south of Library Lane, shops in its void deck on the Park Ring |

- **The west court**, about 64 × 19 m inside the turned ring, opens at its
  east end toward Block 7 and North Street, and south-south-east through
  the 10 m gap between the twins, the court's gate, toward Library Lane,
  the library and the park. In it: the precinct playground, a chess
  pavilion, shade trees on reclaimed water, and the fitness corner.
- **The twins' sky bridge and sky garden** span the gate at the 26th
  floor, so the court's gate is a bridge 85 m up.
- **Behind Block 9**, the ground to the Rim Walk is the **community
  garden**, residents' plots on reclaimed water.
- Between the turned ring and Library Lane lies a triangle of garden;
  Block 6 keeps a 14 m garden on its north side.

**The east precinct** (east of North Street, round Estate Square):

| No. | Block | Footprint | Height | Place in the ring |
|---|---|---|---|---|
| 19 | Block 3 | 25 × 32 m, on the grid | broad point block, 36 storeys | the south corner, on the Park Ring; Juno Rell, 20th floor |
| 50 | Block 8 | 21 × 44 m, on the grid | slab, 34 storeys | the east wall, on Estate Lane |
| 18 | Block 2 | 36 × 18 m, turned | slab, 32 storeys | the north wall, toward the Rim Walk; Siti Rahman |
| 51 | Neighbourhood centre | 38 × 32 m | 2 storeys, roof garden | the west side, on Estate Square |
| 23 | Hawker centre | 38 × 20 m | 1 storey, open-sided | on the Park Ring and Estate Square |

- **The east precinct is too narrow to turn its street-edge blocks**, so
  only Block 2, standing back toward the Rim Walk, turns with the west
  ring.
- **The east court**, 8 m wide along the centre's north side and opening
  to about 20 m at its east end beside the turned Block 2, lies between Block 2 on the north and the
  neighbourhood centre and Block 8 on the south, overlooked by the
  centre's roof garden. The second playground and chess pavilion are here.
  An 8 m linkway passage between the centre and Block 8 joins it to Estate
  Square.
- Estate Square is the precinct's front; Block 3 and Block 8 stand 12 m
  apart on its east side.

**Spacing.** Blocks stand 10 to 20 m apart, the twins 10 m. Flats face out
of the ring, over the city, the park or the desert, and the open corridors
face the court, so no window looks straight into another across 10 m.

**Linkways.** A covered linkway runs round the inside of each ring from void
deck to void deck, and out through the gaps to North Street, Estate Square
and the Deck, so no one crosses the estate in the sun.

**Play.** Swing corridor rail to corridor rail across the courts. The sky
bridge is a realised route between the twins. The linkway roofs, 3 m up,
are a low run round each court, within a blorb bounce of the ground.

### The plan file

The layout above is code-ready (2026-10-12): `scripts/city_plan.gd`
(`CityPlan`) holds every named street, square, precinct, numbered building,
lot, courtyard, resident's home and turbine, every building's height and
crown, the towers' plan forms, and the park and playground. It is generated by
`tools/city_layout.py`; streets and buildings are changed there and the tool
rerun, never by hand in the plan. The same data (`--json`) draws the plan, the park plan, the computed
skyline and the tower elevations, so they always agree. `tools/validate_city_plan.tscn` checks the
plan before anything is built, and runs in the pre-push hook
(`VILLAGE=city sh tools/check_village_layout.sh`):
- everything built stands inside the Rim Walk, and the works outside it;
- no footprints overlap, and nothing is built on a street or square,
  tested on the true outlines of turned blocks;
- every building in a street block has a face on a street, square, the park
  or the Rim Walk, within 6 m across open ground (a front garden or yard);
  estate blocks stand in a precinct instead;
- every street meets another street, a square or the Rim Walk at both ends;
- building numbers are unique and every resident's home exists;
- the turbines keep 280 m from the Jungle and Ice plateaus' centres.

### Building schedule (proposed, 2026-10-12)

Every building in Moy is planned (user). The plan in the visualization draws
each one: about 190 ordinary buildings and the 53 numbered buildings
below.
- **Old Moy and the market lanes:** street buildings, one per lot, 6 to
  10 m of frontage by about 15 m deep, 4 to 9 storeys, homes over shops.
- **Downtown:** mid-rise blocks of 10 to 22 storeys on 20 to 34 m
  frontages, round the towers.
- **The North Estate:** no lots; broad blocks stand in a ring round each
  precinct's court, the ones back from the streets turned 30° off the grid
  (7d).

**Every building has a street face** (user). Each block is filled from
its street edges inward, so every building fronts a street, lane, square
or the Rim Walk. Ground left over inside a block is a shared garden
courtyard; the leftover strips along the Rim Walk are gardens. Green on
the plan means gardens and the park only.

BLOCK has the tower on Civic Plaza's south side; Dr. Kask lives at the top of the tower. The Windworks (with its legal
department) has the Windspire, the start-ups the north tower's capsules,
and Tanglewire the south tower's office floors. Six ramp towers (marked R on the plan) stand at the park's four gates
and in a pair on Civic Plaza; glass lifts (L) at Estate Square and Market
Square (section 6, the Deck).

**The park**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 9 | Tea house | 14 × 12 m | 1 storey; flat above and keeper's room behind | Old Fu (keeper); Kenji Mori (above) |
| 10 | Park lodge | 10 × 8 m, beside the green | 1 storey | Orin Pike (park keeper) |
| — | The Crossing | four garden towers 12 m across, 41 m to the roof, a garden ring 65 m across at +6.5 m, at the park's centre (7a) | the city's station where the two lines cross | — |
| 11 | Giant playground | about 31 m across, the park's south-east quarter (7b) | climbing towers 12–20 m | Lily, Kofi |

**Downtown**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 1 | Grand Hotel | 52 × 60 m | atrium block of 12 levels (44 m) round its void; cylinder guest tower of 28 levels (96 m) with the revolving drum to 108 m (section 8) | Lucinda Wah (top-floor flat); Felix, Ah Keung, Iris at work |
| 2 | City hall | 34 × 60 m | exterior only: portico, balcony, side wings, and the Timekeeper standing over it (8a.0), at the head of Civic Plaza (section 8a) | Mayor Teodora Vance, Kenji Mori (clerk) |
| — | The Meridian Arch (the East Gate) | two legs 22 × 18 m straddling the wall, 72 m high (8b) | the East Gate's station on three levels; city offices; the Wall Watch's command room | — |
| — | The West Gate | two towers 22 × 16 m straddling the wall, 44 m high (8b) | the West Gate's station: the Wall Line and the high line's west station | — |
| 12 | Windspire | 42 × 42 m | about 70 storeys, 280 m, twisting, with three wind gaps (7c) | the Windworks (headquarters, observation deck) |
| 13 | BLOCK tower | 40 × 40 m | about 38 storeys to 150 m, a windowless dark shaft, its crown folded inward to a canted ridge at 212 m (7c) | BLOCK's headquarters; Dr. Vera Kask (director, top floors) |
| 14 | North tower | 40 × 40 m | about 45 storeys, 175 m, plug-in capsule offices (7c) | start-up floors (Theo Park) |
| 15 | South tower | 40 × 40 m | about 40 storeys, 150 m, dune balconies (7c) | flats over offices; Tanglewire (Dan) |

**North Estate**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 17 | Block 1 | 14 × 34 m, turned 30° | slab block, 28 storeys, west side of the west court | Tomas Wren |
| 18 | Block 2 | 36 × 18 m, turned 30° | slab block, 32 storeys, north side of the east court | Siti Rahman |
| 19 | Block 3 | 25 × 32 m | broad point block, 36 storeys, on the Park Ring | Juno Rell (20th floor) |
| 20 | Block 4 | 22 × 20 m, turned 30° | twin broad point block, 40 storeys; sky bridge and sky garden at the 26th floor | homes (no one the hero meets) |
| 21 | Block 5 | 22 × 20 m, turned 30° | twin broad point block, 40 storeys | Dr. Imani Osei and Kofi |
| 22 | Block 6 | 67 × 16 m | slab block, 14 storeys, shops in its void deck on the Park Ring | homes (no one the hero meets) |
| 23 | Hawker centre | 38 × 20 m | 1 storey, open-sided, on the Park Ring and Estate Square | Siti's laksa stall |
| 49 | Block 7 | 14 × 74 m | slab block, 16 storeys, shops in its void deck on North Street | homes (no one the hero meets) |
| 50 | Block 8 | 21 × 44 m | slab block, 34 storeys, east side of the east court | homes (no one the hero meets) |
| 53 | Block 9 | 46 × 16 m, turned 30° | slab block, 24 storeys, north side of the west court | homes (no one the hero meets) |
| 51 | Neighbourhood centre | 38 × 32 m | 2 storeys: minimart, kindergarten, community club, roof garden | Juno Rell (Housing Board office) |

**Old Moy**

| No. | Building | Footprint | Size | Who lives or works here |
|---|---|---|---|---|
| 3 | Library | 45 × 62 m | art deco limestone, renovated; the galleried Great Hall, 22 m, with a heritage room below (section 9) | Ada Fong, Nia Calder, Benji Okoro |
| 5 | Moonlight Cinema | 30 × 28 m | 2 storeys, built later into the old town; flat above | Leon Duarte (lives above) |
| 6 | Police box | 6 × 8 m | 1 storey, back room | Kate Byrne |
| 7 | Clinic | 14 × 18 m | 3 storeys; flat above | Dr. Arjun Mehta (lives above) |
| 24 | Garden Row | 23 × 18 m | 3 townhouses, 3 storeys, facing the Park Ring | Teodora Vance; Ada Fong and Sora Ishida; Priya Raman |
| 25 | Sol's café | 16 × 10 m | old tower house, 5 storeys; flat above | Sol Brant |
| 26 | Bakery | 10 × 16 m | old tower house, 6 storeys; flats above | Felix Tanaka (above) |
| 27 | Pinestein's building | 9 × 16 m | old tower house, 9 storeys; laboratory on the roof beside its wind tower | Palbert Pinestein (top floor) |
| 28 | Mara's building | 9 × 16 m | 8 storeys; rooftop studio | Mara Quill |
| 29 | Benji's building | 8 × 16 m | 6 storeys | Benji Okoro |
| 30 | Theo's building | 8 × 16 m | 6 storeys | Theo Park |
| 31 | Yuki's building | 8 × 16 m | 6 storeys | Yuki Hayashi |
| 32 | Suri's building | 8 × 16 m | 7 storeys | Suri Vale |
| 52 | Reese–Miller house | 10 × 16 m | old tower house, 7 storeys; a tailor's shop and three let flats below, the family on the top three floors, Jammer's room the manzar on the roof (moy_tower_house.md 4) | Elizabeth Reese, Dan Miller and Jammer (away at the farm) |

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
| 38 | Helmsmith | 10 × 12 m | 2 storeys, a lock-up shop open onto Lamp Lane; home behind (the game's legacy stall on Civic Plaza moves here in P3) | Gideon Hale |
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

## 8. The Grand Hotel (rest point): building brief (proposed, 2026-10-13, after the user's direction to follow John Portman)

**The direction (user, 2026-10-13):** "I'm very inspired by John Portman
architecture, could we shift the Moy hotel to be in his style?" This brief
replaces the art deco design of 2026-10-12 (stone, bronze and a copper
pyramid). The people, the program and the hotel's story stay; the building
is redesigned in the manner of Portman's atrium hotels. The 3D drawing is
`docs/drawings/moy_grand_hotel_3d.html`.

### 8.1 People and purposes

**Why a grand hotel in a city no road reaches.** Moy has almost no outside
visitors, so the hotel lives on the city itself, the way grand hotels in
real cities do. Portman called his atria "people space": a public room so
big and so full of light that the city comes in to sit in it. That is what
the hotel is for Moy:
- **The city's living room:** afternoon tea and drinks on the atrium floor
  under the chandelier, weddings and celebrations in the atrium, with the
  guests watching from the galleries, dinner in the Chandelier Room on the
  mezzanine, and a drink at the top in the Windrose, the revolving lounge.
- **Long-stay residences:** five floors of suites let by the year, round
  the top of the atrium, a tradition of the hotel since Lucinda's
  grandfather's day, after Raffles in Singapore and the Chelsea in New
  York. The residents tend the planters on their galleries, so the green
  that hangs down the void is their window boxes.
- **Guest rooms** for staycations, for families between homes, and for the
  rare traveller who crosses the desert on foot, like the hero.

**History.** Lucinda Wah's grandfather built it in the Windworks' first
boom, as the city's first tall building. The boom built its gifts to
itself, the library and city hall, in limestone and bronze. He built what
the boom thought the future looked like: a white concrete tower with glass
lifts running up its face, and a room 44 m high where the whole city could
sit indoors out of the sun. It is still the oldest tower downtown, and the
one that taught Moy to build tall.

**Who works here** (the people the hero meets):

| Person | Role | Where |
|---|---|---|
| Lucinda Wah | general manager; keeps the reception desk herself in the evenings, as her grandfather did, so she is the rest point's keeper | the desk, her office behind it, her flat on the tower's top floor |
| Felix Tanaka | concierge | the concierge desk in the entrance hall |
| Ah Keung | doorman | the revolving door, forty years |
| Iris Dune | florist | her flower stand in the entrance hall; she dresses the atrium each morning |

Kitchen, housekeeping and laundry staff work behind service doors and are
never seen on the public floors.

**What goes in and out.** Guests and visitors cross the forecourt to the
revolving door, facing Civic Plaza; walkers on the Deck come in by the
skybridge to the mezzanine; the park's people come in through the Long
Bar's terrace. Food, linen and stores come by cargo trike to the loading
door on Hotel Lane at dawn; laundry goes the same way. Waste goes to the
city sewer and on to the water works' reclamation (see 2a).

**References:**
- **Hyatt Regency Atlanta (John Portman, 1967):** the first modern atrium
  hotel. Guest rooms open off galleries round a 22-storey void; glass
  capsule lifts outlined in bulbs ride up it; a revolving lounge in a dome
  (the Polaris) crowns the roof, and a lounge hangs out over the atrium
  floor.
- **Hyatt Regency San Francisco (Embarcadero Center, 1973):** a 17-storey
  atrium whose galleries step out into the void storey by storey, so its
  wall leans; planting cascades down the slope; a great sculpture hangs
  in the void.
- **Marriott Marquis, Atlanta (1985):** the white ribbed concrete of the
  void, its gallery fronts read as continuous curving bands.
- **Westin Peachtree Plaza, Atlanta, and Westin Bonaventure, Los Angeles
  (both 1976):** the cylinder tower, the revolving restaurant at its top,
  and outside lifts that rise from the lobby, pass through the roof and
  climb the face of the tower.
- **White Swan Hotel, Guangzhou:** the indoor rock garden and pavilion,
  the "great hotels of China" in the original direction (its waterfall is
  left out: no opulent water).
- **Old Moy's wind towers:** the atrium cools itself the way the old town
  does.

### 8.2 Site

The north side of Civic Plaza: 52 m (east–west) × 60 m (north–south), world
(−483, −98) to (−431, −38). Local coordinates below run x from the west
face (0) to the east (52) and z from the north face (0) to the south (60).
- **South face, the front:** on Meridian North, facing across it to Civic
  Plaza and city hall. The ground floor stands back behind a **forecourt**.
- **West face:** on the Park Ring, facing the park; the Long Bar's terrace.
- **North face, service:** on Hotel Lane.
- **East face:** a party wall with the Windspire's podium.
- **The Deck** runs along Civic Plaza's north edge at +6.5 m. A glazed
  **skybridge** carries it over Meridian North into the mezzanine, and a
  glass bridge from the mezzanine's east gallery crosses the Windspire's
  wind garden into its lobby, so the hotel is a room on the Deck, a city within the city, the
  way Portman's hotels are joined to their neighbours.

**No porte-cochère.** Portman's hotels open on a drive for cars; Moy has
none. The front is a **pedestrian forecourt**, 52 × 6 m, under the
mezzanine's ribbed soffit, carried on a row of ribbed concrete columns at
the street line. Cargo trikes never use it.

### 8.3 Massing

Two masses, Portman's pair:
- **The Court:** the atrium block, the whole 52 × 60 m site, twelve levels
  to a roof at +44 m, its rooms on open galleries round the void.
- **The tower:** a cylinder 28 m across, centred at (26, 14) on the
  site's north half, rising from the ground to +96 m and carrying the
  **drum** crown to +108 m. Its walls come straight down to the ground, so
  nothing stands on the atrium; its curved south face is the atrium's north
  wall, and the glass lifts ride up it.

**The leaning front.** From level 3 up, each level of the Court's south
range stands 0.8 m north of the one below, 8 m over ten levels, after
Hyatt Regency San Francisco. Outside, the front steps back from the plaza
in planted terraces; inside, its galleries lean out over the void.

**Levels.** The ground is one grand storey of 6.5 m, up to the Deck; the
mezzanine 5 m; every level above 3.25 m. Level n starts at
+11.5 + (n − 3) × 3.25 m.

| Level | Height | Contents |
|---|---|---|
| **Ground** | 0 to +6.5 m | The **forecourt** (z 54 to 60) under the mezzanine; the **revolving door** at its centre between two 2.8 m swing doors; the **entrance hall** (z 48 to 54) with Felix's concierge desk and Iris's flower stand; the **atrium floor**, with the dry **rock garden and pavilion** at its centre, the runnel, trees in planters, the feet of the **double ramp** and of the four **capsule lifts**; reception and Lucinda's office (east range); the **Long Bar**, opening onto the park terrace (west range); public washrooms; kitchen, stores, staff room and the loading door on Hotel Lane (the north corners, either side of the tower) |
| **Mezzanine** | +6.5 m, the Deck's level | The gallery round the void, 2.4 m wide; the **Chandelier Room** restaurant along the west, with a round terrace cantilevered 5 m into the void beside the chandelier, after Portman's lounge pods; the tea lounge along the east; the **Deck door** and the skybridge in the south; the link to the Windspire's podium in the east; washrooms |
| **Levels 3 and 4** | +11.5 to +18 m | Galleries round the void; the ballroom and function rooms (west), the hotel's offices and the luggage room (east) |
| **Levels 5 to 7** | +18 to +27.75 m | Guest rooms on the galleries |
| **Levels 8 to 12** | +27.75 to +44 m | The **long-stay residences**, about 8 suites a floor on the galleries, their planters hanging over the void |
| **Court roof** | +44 m | The **roof garden**: shade trees in planters, the terrace bar, the two **wind towers** after Old Moy's, the air plant behind a screen; the atrium's **skylight** between them, its high edge along the tower at +47 m, under the tower's louvres and gutter |
| **Tower, levels 3 to 12** | +11.5 to +44 m | Guest rooms round the north of its core; its south arc is the lift lobby, open to the atrium, joined to the Court's galleries at the north corners |
| **Tower, levels 13 to 26** | +44 to +89.5 m | Guest rooms, 16 a floor round the core |
| **Level 27** | +89.5 to +92.75 m | The grand suites, among them **the party's suite**, facing the park |
| **Level 28** | +92.75 to +96 m | Lucinda's flat, the manager's flat, with its terrace under the drum's overhang |
| **The drum** | +96 to +108 m | The **tank ring**, +96 to +101 m: the hotel's water tanks, filled from the wells like the roof tanks across the city, behind a ribbed concrete band 32 m across; the **Windrose**, +101 to +105.5 m, the revolving lounge in bronze glass, turning once an hour; a shallow dome to +108 m, lit at night |

**The tower.**
- **Core:** 11 m across: a service lift, a firefighting lift and the
  escape **ramp tower** (a spiral ramp, by the world's ramp rule), from the
  ground to level 28 and the drum. The guests' lifts are the glass
  capsules outside.
- **Corridor:** a ring corridor 1.8 m wide round the core.
- **Rooms:** wedges round the ring, about 6.7 m deep, each with its own
  bathroom on the corridor side and its window between two ribs.

### 8.4 The atrium

**The void.** 32 m east–west (x 10 to 42) at every level. North–south it
runs from the north corners (z 22) and the tower's curved face (z 28 at
its centre) to the south galleries, which lean in: z 48 at the floor and
the mezzanine, z 40 at level 12. So the void is about 32 × 26 m at the
floor and 32 × 18 m at the top, and 47 m from the floor to the
skylight's high edge.

**The galleries.** Every level's gallery is 2.4 m wide, cantilevered from
the column line, with a solid board-formed parapet 1.1 m high whose top
is a planter trough. Creeping fig and pothos trail from the troughs, the
longest strands three storeys down, so the walls of the void are green
from the top. Every rail stands on the void's one boundary for its
level, and no wall below runs under it.

**The floor.** The dry **rock garden** at the centre, about 12 m across
round (26, 37): raked gravel, upright stones and the timber **pavilion**,
5 × 4 m, where tea is served. Trees stand in planters round it (olive
and ficus, which take the indoor light). The **runnel** crosses the floor
(8.8). The **double ramp** rises at the south. The four **capsule lifts**
land on the north, at the foot of the tower.

**The roof, the lifts, the chandelier and the rain, designed together**
(2026-10-14). Two earlier drawings ran the capsules up through the glass, and
the fix after them, a concrete collar round the tower's foot pierced by glass
hoistways, put a solid shelf across the lifts' path and a ridge girder through
the middle of the skylight. Both were withdrawn. The four requirements are
solved as one:
1. **The lifts never cross a roof.** They run in four slots let into the
   tower itself (below), inside its outline, so the skylight never meets them.
2. **Nothing pierces the glass.** No shaft, collar, girder or rope passes
   through it; the chandelier hangs from an arm under it.
3. **Rain always runs away from the tower** to gutters that are reached from
   the ranges, never across the glass toward a joint it could leak through.
4. **Everything that needs servicing is inside the building:** the winch, the
   gutters' outlets, the lifts' machinery.

**The skylight.** One pitch of bronze glass, falling south, away from the
tower. Its high edge, at +47 m, bears on a ring beam along the tower's face; its
low edge, at +44.6 m, bears on the leaning front's top beam. It is never flatter
than 7° (7.6° at the corners to 11° at the middle), steep enough for glass to
shed water and dust. White-cased steel trusses at 4 m centres run from the
tower's ring beam to the front. Between the glass's high edge and the tower's
**gutter** at +48 m runs a band of **louvres**, where the void's warm air leaves
(8.8).

**The lifts' slots.** Four vertical slots are let into the tower's south face,
from the atrium floor to the Windrose at +101 m. They keep the tower's rhythm
(revised 2026-10-14, after the user asked whether the lifts' fittings fit the
windows). The tower has 40 ribs, one every 9° (2.2 m apart), with a window bay
between each pair. Each slot is **two bays wide**: the rib between them is left
out, and the ribs either side frame the slot, so its clear width is two bays
less a rib, 3.8 m, and it is 3.4 m deep. The slots are centred on the ribs at
18° and 45° either side of due south. The tower's face onto the atrium (54°
either side of south) is then twelve bays, read from the middle outward on
each side: glass, glass (the rib at due south between them is the one the
chandelier's arm leaves by, 8.5), slot, glass, slot, the outer slot's last rib
meeting the north corner's gallery. Each capsule rides its rails at the back
of its slot, entirely inside the tower's round outline, and its doors open
into the tower's lift lobby at every level. The slot's front is bronze glass
in the plane of the windows, so from the plaza the four lit capsules are seen
climbing the tower behind glass in a double bay; inside the atrium the slots
are open to the void below +47 m, and the capsules rise free past the
galleries. The floor edges cross each slot as lintels at every level, in line
with the windows' spandrels. Above the tower the drum's tank ring carries the
same 40 ribs up, and the Windrose's fixed glass has a mullion over every rib
(its floor turns; its glass does not). `tools/city_layout.py` checks that
every capsule is inside the tower's face, that every slot is a whole number
of bays centred on a rib and lies wholly on the face onto the void, that the
slots stand clear of each other, and that the drum's ribs and mullions carry
on the tower's.

**The double ramp.** Two board-formed concrete ramps curve out either
side of the rock garden, from feet at (18, 38) and (34, 38) on the
atrium floor to heads on the mezzanine's south gallery at (12, 48) and
(40, 48). Each rises 6.5 m along about 12.5 m of curve, at about 28°,
inside the world's 32°. Each is 2.4 m wide (two people abreast) with a
3 m landing at its foot and its head. Their undersides are open and
smooth, sculpture as much as route, in Portman's way.

**The capsule lifts.** Four glass capsules, 2.6 m across, in bronze frames
outlined in bulbs, ride in the tower's four slots (above). They rise from the
atrium floor, stop at the mezzanine and every level, and climb on up the tower,
in full view of the plaza through the slots' glass, to the Windrose at +101 m.
At night the four lit capsules moving up the white tower are the hotel's sign.

**Circulation:**
- **Visitors:** forecourt → revolving door → entrance hall → atrium floor →
  double ramp or capsule lifts → mezzanine.
- **Guests:** atrium floor → capsule lifts → the tower's lift lobby at
  their level → their room in the tower, or through the north corners to
  the galleries of the Court below +44 m.
- **From the Deck:** skybridge → Deck door → mezzanine gallery → ramps or
  lifts.
- **Staff and goods:** Hotel Lane → loading door → kitchen and the core's
  service lift, never crossing the atrium floor.

### 8.5 The chandelier

- About **8 m across and 16 m tall**: a column of crystal in five tiers on
  bronze rings, hung over the rock garden down the middle of the void,
  after the great sculptures Portman hung in his atria. Its lowest tier is
  at +15 m, above the mezzanine and the level 3 galleries; its crown ring is
  at +31 m. It weighs about 8 t, crystal, rings and frame (the largest
  chandeliers built weigh 4 to 12 t).
- **What it hangs from** (resolved 2026-10-14, after a glazing truss and
  then a ridge girder through the glass were both withdrawn, 8.4):
  - **The arm:** a tapered steel box beam, 1 m wide, 1.4 m deep at its root
    and 0.8 m at its tip, cantilevered from the tower's concrete core at
    level 13. It runs south out of the tower between the two middle slots
    and over the void to a tip straight over the chandelier at (26, 37). Its
    underside is at +43.2 m, at least 0.6 m under the glass everywhere, so the
    skylight passes over it untouched. Its root is built into the core
    behind the ring beam, and the core takes the 8 t as it takes the floors.
  - **The ropes:** two hoist ropes and two safety ropes, each able to carry
    the whole chandelier alone, run along inside the arm on sheaves and hang
    from a pulley block at its tip to the crown ring, 11 m below.
  - **The winch room:** inside the tower on level 13, beside the arm's root,
    reached by the service core. The winch, the sheaves and the block are
    inspected from inside the arm, which is a crawlway, without scaffolding
    and without going onto the glass.
  - **Power:** the winch runs on the hotel's supply with the Windworks'
    batteries behind it, and a handwheel lowers it by hand if both fail.
  - `tools/city_layout.py` checks that the arm's tip is over the chandelier,
    that it stands at least 0.6 m under the glass and clear of the slots, and
    that there are at least 6 m of rope above the chandelier.
- **Three thousand crystals** in strands round the rings, lit from within.
  Lucinda knows them by their faults.
- **Lowered once a year** for cleaning: the winch lets it down 10 m
  through the void until its lowest tier hangs just over the pavilion's
  roof, and it is cleaned from the atrium floor. The city fills the
  galleries and the ramps to watch.
- **Collision:** solid. Its crown ring is a perch, and its crown and
  cables are a Leaf Hat **swing anchor** inside the atrium, 24.5 m above
  the mezzanine, for swinging from gallery to gallery across the void.

### 8.6 Facade, materials and style

The hotel takes the charter's 5 % accent for landmarks (section 5): the
city's one building in Portman's atrium modernism, white and ribbed among
the tile and glass, and the oldest tower downtown.

| Element | Term | Tradition |
|---|---|---|
| Massing | a hollow **atrium block** (the Court) and a **cylinder tower** with a drum crown | Portman: Hyatt Regency Atlanta, Westin Peachtree Plaza |
| Front | the south range **stepping back in terraces**, 0.8 m a storey, its galleries leaning into the void | Hyatt Regency San Francisco |
| Walls | white **board-formed concrete**; on the tower, **ribs** 0.6 m wide and 0.9 m deep every 2.2 m round the cylinder | Marriott Marquis; the ribs shade the glass |
| Glass | **bronze-tinted**, recessed 0.9 m between the ribs, and under 1.2 m concrete **hoods** on the terraces | Portman; the desert's shade |
| Ground | the **forecourt**: ribbed concrete columns carrying the mezzanine, the revolving door between two 2.8 m swing doors | Portman's entrance, without the drive |
| Lifts | glass **capsules** outlined in bulbs, riding in glazed slots let into the tower's face | Hyatt Regency Atlanta, Westin Bonaventure |
| Crown | the **drum**: a ribbed tank ring, the revolving Windrose in bronze glass, a shallow lit dome | the Polaris, Peachtree's revolving restaurant |
| Corners | the Court's corners rounded in a superellipse | Moy's signature |
| Signature motif | Old Moy's **house marks**, cast into the forecourt's columns, one to a column | the city's signature |
| The sign | no lettering: a bronze **chandelier** picture sign hung in the forecourt over the revolving door | Moy's picture signs |

**Palette:** white concrete 60 %; bronze glass and bronze 30 %; the
galleries' green, the lifts' bulbs and the warm light of the void at
night 10 %.

**At night** the atrium glows through the skylight and the terraces, the
four capsules climb the tower, the Windrose turns its ring of light at the
top, and the chandelier is lit in the middle of it all.

### 8.7 Structure

- **The tower** is a concrete tube: the ribs are its columns, joined by
  the floor edges into one wall, round a concrete core. The floors span
  from the ribs to the core. The drum's tank ring cantilevers 2 m beyond
  the tube on brackets from the ribs.
- **The Court** is a concrete frame. One column line stands behind each
  gallery; the gallery slabs cantilever 2.4 m from it. The south range's
  columns rake, leaning 0.8 m a storey, and each floor ties them back to
  the east and west ranges.
- **The skylight's** trusses bear on a ring beam along the tower's face at
  +47 m and on the leaning front's top beam at +44.6 m.
- **The chandelier's arm** is cantilevered from the tower's core at level 13
  (8.5); each lift slot is two of the tower's bays, framed by ribs, with one
  rib left out and its load carried by the floor edges, which bridge the
  slot as lintels at every level.
- **The ramps** are board-formed concrete, cantilevered from the
  mezzanine's edge, each with one support at its foot landing.

### 8.8 Heat, air and water

- **The cool well.** The two **wind towers** on the Court roof catch the
  west wind and drop it down shafts in the west range to grilles at the
  foot of the atrium. The air crosses the atrium floor over the runnel and
  the planting, warms, and rises the 47 m of the void to leave by the
  louvres along the skylight's high edge. The stack draws even on still days. It is Old Moy's
  way of cooling, at the hotel's scale.
- **Working water, not a fountain.** The city's **reclaimed water**, on
  its way from the water works to the park's reed pond, crosses the
  atrium floor in an open stone **runnel** 0.6 m wide and leaves under
  the west wall for the pond. The air drawn over it is cooled. There is no
  fountain (user: no opulent fountains).
- **Shade.** The tower's ribs keep out the low east and west sun; the
  terraces' hoods and planters shade the south; the skylight is bronze
  glass between deep trusses.
- **Rain** (2026-10-14). Rare in the desert, but a cloudburst comes all at
  once. The tower's own runoff is caught by the **tower gutter** at +48 m
  above the louvres, which falls east and west to the ranges' roofs, so none
  runs onto the glass. The skylight sheds south to a **box gutter** along the
  leaning front at +40 m, falling 1:100 east and west to **outlets** at x 8
  and 44, inside the east and west ranges where they are reached from a
  service door. Pipes down the ranges' piers carry it to the **rain cistern**
  under the forecourt, 32 × 6 m and 1.6 m deep (307 m³, about twice a 50 mm
  cloudburst on the whole roof). The cistern tops up the runnel and
  overflows to the street drains and the park's reed pond.
- Modern air conditioning does the rest. Its plant sits on the Court
  roof, screened.

### 8.9 The rest point

- **Fixtures (Moy is modern):** every guest room and suite has its own
  bathroom with a flush toilet, a washbasin and mirror, and a shower; the
  suites add a bath. Public washrooms open off the atrium floor and the
  mezzanine with flush toilets and basins. Waste goes to the city sewer
  and the water works' reclamation.
- **How the hero rests:** at the reception desk, with Lucinda in the
  evening (or Felix by day), then up by capsule lift, up the void
  and on up the tower's face behind the slot's glass, to the party's suite on
  level 27, the one built guest floor.
- **The party's suite:** sitting room, one bedroom with a double bed at
  world scale (mattress 1.55 × 2.3 m), a bathroom, and windows on the
  park. The swing doors beside the revolving door are 2.8 m wide for big
  companions and mounts; the capsules, 2.6 m across, take them.
- **Price:** open.

### 8.10 Play

- **The terraces** of the leaning front are a staircase of ledges, 0.8 m
  deep every 3.25 m (each within a blorb bounce), from the skybridge's
  roof to the Court roof at +44 m.
- **The tower's ribs** are climbing holds all the way up the cylinder.
- **The Court roof garden** is reached by the terraces, the lifts and
  the Deck. It is a landing between the park's swing loop and the
  downtown towers.
- **The drum**, at +108 m, is a high swing anchor over the park and the
  plaza.
- **The chandelier's crown** is a perch and a swing anchor above the
  atrium (8.5); the galleries are its landings.

### 8.11 Realised (fidelity A)

**Only two parts are built inside (user):**
1. **The atrium:** the forecourt, the revolving door and the entrance
   hall; the atrium floor with the rock garden and pavilion, the runnel,
   the chandelier, reception, the concierge desk and Iris's stand; the
   double ramp and the mezzanine gallery round the void, with the Deck
   door and the skybridge; and the galleries of levels 3 to 12, as
   walkable ledges round the void with closed room doors, because they
   are the atrium's walls.
2. **One guest floor, level 27:** the capsules' lobby, the ring corridor
   and the party's suite.

The capsule lifts run between the atrium floor, the mezzanine and level
27 only, and the ride up the outside of the tower is real.

**Everything else is faux and solid:** the Long Bar, the Chandelier Room,
the function rooms, the offices, the kitchen, the Windrose and every
other floor. They are closed doors and lit windows that show rooms (the
interior-mapping shader), on solid massing with collision. The terraces,
the Court roof and the drum are solid exterior surfaces the hero can
still land on and swing from, with no interiors behind them.

## 8a. City hall: building brief (proposed, 2026-10-13)

> **Superseded 2026-10-17 (user):** City Hall moved into the Meridian Arch
> (8b), and this building and the Timekeeper over it are removed. Its site,
> Clock Street, Meridian Court and the old plaza are one **Civic Plaza**
> from the park to the arch (8a.1); the city's clock is the Crossing's glass
> dome (7a). The brief below
> is kept for its program (the Hall of the City, the council chamber, the
> plaques), which moves into the arch; its building and clock are history.

### 8a.0 The Timekeeper (revised 2026-10-16, at the user's direction)

City hall's clock tower is replaced by a giant timekeeping structure standing
over the hall, which the Meridian Line passes straight through. Data:
`TIMEKEEPER` in `tools/city_layout.py`, checked against the line and the
roof. **Revised 2026-10-17 (user):** a full circle, not dipping into the
roof, and a plain twelve-hour clock (the game's day ring is dropped: it
would not read).
- **Form:** a full ring 27 m across in the north–south plane, over the
  middle of the hall (3 m thick, centre 37.5 m up), its bottom 2 m clear of
  the 22 m roof. It stands in a **bronze cradle**: two pylons rise from the
  roof 15 m either side of the centre and grip the bezel at its sides,
  after the cradles of great bells and observatory telescopes. It faces the
  plaza and the park on one side and Meridian Court and the arch on the
  other.
- **No hands from the centre:** the centre is an empty opening 12 m across,
  and the high line runs through it at +36 m. Time is read from rings
  instead, each turning past a fixed **index** at the top (a lit triangle),
  after the ring clocks whose numbers turn past a pointer.
- **The rings, from the centre out:**
  - the **hour ring** (6 to 9 m) and, outside it, the **minute ring** (9 to
    12 m), as a minute hand is the longer: each carries one lit **arrow**
    and keeps **real-world time** (user), the minute ring turning once an
    hour, the hour ring twice a day, clockwise as seen from the plaza;
  - the fixed **bezel** (12 to 13.5 m): twelve hour marks, the index, and
    rungs on its frame (a swing anchor at its top, 51 m).
- **Reading it (2026-10-17, arrows at the user's direction):** each moving
  ring's marker is a lit crimson arrow spanning the ring's band, its base on
  the inner edge (the hour's 20° wide, the minute's 10°) and its point on
  the outer edge, standing proud of both faces, so it points at an exact
  place on the dial: the minute arrow's point touches the bezel. The
  bezel's twelve dark hour marks run across its whole band, the quarters
  wider, with 48 short minute ticks on its inner edge between them. A lit
  **seconds bead** runs round the bezel's rim once a minute, through the
  cradle's grips (`TIMEKEEPER.markers`, `seconds`, `marks`). The city
  model's Timekeeper runs on the viewer's own clock.
- **Material:** pale enamelled steel rings in the bronze cradle; the markers
  and index lit at night.
- **Sound:** the old tower's bell is kept, hung in the cradle at the top of
  the north pylon, striking the real hours.

### 8a.1 People and purposes

**What city hall is for.** Moy governs itself; no one outside it ever
arrives to do so. City hall is where the city:
- **decides:** the council meets in public, and anyone may come and
  listen;
- **records:** births, marriages and deaths, homes, and the **register of
  house marks**, every picture sign in the city, each registered when it is
  first hung;
- **marries:** weddings in the marriage room, with the party moving on to
  the Grand Hotel's atrium across the plaza;
- **is met:** the mayor's door is open on weekday mornings.

**Who works here:**

| Person | Role | Where |
|---|---|---|
| Teodora Vance | mayor; walks the whole city every Sunday to see what's broken; signed the ordinance that put the city blorbs outside the bounds and does not like to talk about it | her office over the portico, its window on the plaza |
| Kenji Mori | city clerk and registrar; keeps the births and deaths of everyone in the census, and the register of house marks | the registry counter in the Hall of the City; the strongroom below |
| Zara Quinn | registers every new picture sign she paints | at Kenji's counter, often |

**The council** (proposed): seven residents elected by the city, who meet
in the council chamber. Teodora chairs. The other six are drawn from the
census: Priya Raman, Dr. Arjun Mehta, Rafael Ortiz, Juno Rell, Sol Brant and
Ada Fong. It was this council that banished the city blorbs.

**History.** The third of the boom's civic buildings, with the Grand Hotel
and the library, built to face the park down the civic axis from the head
of Civic Plaza. Its clock was the first public clock in Moy; Old Moy had
told the hour by the shadow of its wind towers.

**References:**
- **Hilversum Town Hall (Willem Dudok, 1931):** interlocking horizontal
  masses and one tall clock tower, of the same era as the library (the
  tower itself is replaced by the Timekeeper, 8a.0).
- **Stockholm City Hall:** the **Blue Hall**, a great covered courtyard used
  as the city's public room, and the **Golden Hall**, a council hall walled
  in gold mosaic telling the city's story.
- **The Spanish ayuntamiento:** a balcony over the main square from which
  the city is addressed.

### 8a.2 Site

The head of Civic Plaza: 34 m (east–west) × 60 m (north–south).
- **West face, the front:** on Civic Plaza, facing across it and the park to
  the library at the other end of the civic axis.
- **North and south faces:** on Meridian North and Meridian South, the two
  branches of Meridian Avenue.
- **East face, the back:** on Clock Street, facing Meridian Court and the
  Meridian Arch (section 8b) across it, where Meridian Avenue arrives
  head-on. The old clock tower here is gone (revised 2026-10-16): the
  **Timekeeper** stands over the middle of the hall instead (8a.0), framed
  by the arch in the long view up the avenue from the East Gate.
- **The Deck** runs along Meridian North at +6.5 m; city hall's north door
  meets it.

**The hero never goes inside** (user, 2026-10-13). City hall is built as an
exterior only: a landmark, a climb, and the face of the city's government
on its main square. Its doors stay shut. Everything below is designed so
the outside tells the story of the rooms behind it without them being
built.

### 8a.3 Behind the facade (not built)

What the elevations express, west to east across the 34 m depth:
- **the west range**, 10 m deep: the portico and entrance hall on the
  ground floor, the mayor's office above them, and the **council chamber**
  above that, from +11 to +20 m, walled in gold mosaic of the city's story
  (after Stockholm's Golden Hall), opening onto the balcony;
- **the Hall of the City**, 16 × 30 m, the city's covered public room
  (after Stockholm's Blue Hall), with the wall of house marks; its roof is
  the louvred clerestory seen above the side ranges;
- **the east range**, 8 m deep on Clock Street, under the Timekeeper's slot;
- **the north and south ranges**, 15 m each along the front: the registry
  (north, with the Deck door) and the marriage room (south);
- **the strongroom** below ground, holding the registers.

None of these rooms is built. Their story reaches the player through the
exterior, the people on the plaza, and the lore (the register of house
marks is Kenji's; Zara registers each new sign with him).

### 8a.4 Massing

Interlocking horizontal masses with one vertical, after Dudok:

| Mass | Plan (west to east, north to south) | Height | Reads as |
|---|---|---|---|
| **The front block** | the west range, the middle 30 m of the front | +22 m to its parapet | the council chamber over the portico: the tallest of the low masses, on the civic axis |
| **The side ranges** | north and south, 15 m of front each, the full depth less the east range | +14 m | two long low wings with window bands, stepping down either side of the front |
| **The clerestory** | the hall, 16 × 30 m, behind the front block | +16.5 m | a long louvred lantern seen over the side ranges from Meridian North and South |
| **The east range** | the full 60 m on Clock Street, 8 m deep | +18 m | the back wall, plain, facing Meridian Court |
| **The Timekeeper** | a full ring 27 m across over the middle of the hall, in the north–south plane, in a bronze cradle | its top at +51 m | the one vertical (8a.0): seen over the front block from the plaza, framed by the Meridian Arch from the east |

From the plaza the composition steps: the wings at 14 m, the front block at
22 m, the Timekeeper rising behind it to 48 m.

### 8a.5 Facades

**West front, on Civic Plaza (the civic axis):**
- **Steps:** three broad steps, 1.2 m in all, the full 30 m of the front
  block, where people sit in the evening; a ramp at each end (the world's
  ramp rule).
- **The portico:** six square limestone piers, 1.4 m square, 6.5 m
  tall and about 4 m apart, under an entablature to +8.8 m; the portico
  is 4 m deep and carries the balcony. Behind it, three pairs of tall
  **bronze doors**, shut, their panels cast with house marks; deep shadow
  and warm light round their edges.
- **The balcony:** at +11 m across the middle 18 m of the front block,
  with a bronze rail whose balusters are the house marks. Three tall doors
  open onto it from the chamber, their glass glowing gold.
- **The chamber windows:** five tall narrow windows, +11 to +20 m, between
  plain piers, gold-lit at night: the mosaic glimpsed, not shown.
- **The parapet:** a plain limestone band at +22 m with a thin bronze
  coping; no ornament on the skyline but the Timekeeper.
- **The sign:** a picture of the Timekeeper's rings cast in bronze beside the
  middle doors, no lettering.

**North and south faces (Meridian North and South):**
- Two long horizontal **window bands**, one per storey (0 to 6.5 m and 6.5
  to 14 m), in bronze frames, Dudok's signature, with a deep flat stone
  canopy at +6.5 m.
- On the north face, the **Deck door**: a bronze-framed opening at +6.5 m
  where the Deck arrives, under the canopy (shut, like the rest).
- Above the wings, the clerestory's **louvres**: tall bronze blades
  between stone fins, angled to throw the hall's warm air out.

**East face, on Clock Street:** the plain back wall of the east range,
with narrow vertical windows and the staff door, facing Meridian Court; over
it the Timekeeper's east face, seen through the Meridian Arch from the
avenue.

**Materials and palette:** pale limestone 60 % (the same stone as the
library); bronze and gold 30 % (doors, frames, rail, the Timekeeper's
frame, louvres); the gold glow of the chamber and the Timekeeper's markers
10 %.

**At night:** the chamber's windows and balcony doors glow gold, the window
bands warm white, the Timekeeper's markers and index bright and its day
ring softly lit. Lit windows are
emissive panels; no room is built behind them.

### 8a.6 Play

The outside is a climb from the plaza to the top of the Timekeeper:
- **Onto the portico:** its roof, the entablature over the piers at
  +8.8 m, is the first landing: a super jump from the steps, or along the
  wings' canopies (+6.5 m, reached from the Deck) and a blorb bounce up.
- **Portico to balcony:** the balcony floor at +11 m is one more bounce.
- **Balcony to roof:** the chamber's piers carry stone bands every 2.4 m
  (+13.4, +15.8, +18.2, +20.6), each within a blorb bounce, to the parapet
  at +22 m.
- **The wings:** the side ranges' window-band canopies at +6.5 m are ledges
  the full 60 m of each side, reachable from the Deck on the north; their
  roofs at +14 m are the way round to the clerestory and the back.
- **Up the Timekeeper:** from the east range's roof (+18), onto the bezel
  where it rises out of the slot, then up the rungs on its fixed frame
  (every 2.4 m, within a blorb bounce) to its top at +48 m. The turning
  rings carry a rider round with them (moving solid bodies) but never
  through the opening, which stays clear for the train.
- **The top as anchor:** a Leaf Hat swing anchor 48 m up over Civic
  Plaza, Meridian Court and the avenue, and the high point from which the
  swing across the plaza to the hotel and the Windspire's podium begins.

**Collision:** the whole massing is solid (`CollisionPolicy` blocking);
the steps, pier tops, entablature, balcony and its rail, parapets, canopies,
roofs and the Timekeeper's bezel rungs and top are parkour landings; the
rings are moving solid bodies (`AnimatableBody3D`); the louvre blades and the
lit markers are decorative on solid backing. The doors are part of the solid wall.

### 8a.7 Realised: the exterior only

- **Built:** the full exterior at street fidelity: the steps, portico,
  bronze doors, balcony, chamber windows, window bands, canopies, the Deck
  door, the clerestory, the east range, and the Timekeeper with its
  turning rings and its bell. Every roof
  and ledge on the climb is walkable.
- **Not built:** every room. The doors stay shut; the windows are lit
  panels.
- **People:** Teodora is met on the portico steps on weekday mornings (the
  mayor's door is open, in the city's phrase, but she holds it on the
  steps); Kenji crosses the plaza to the tea house at noon; on council
  evenings the plaza fills to hear the meeting from the balcony.

## 8a.1 Civic Plaza, the grand square (2026-10-17, at the user's direction)

**Why.** The three commercial blocks that briefly stood on the old Civic
Plaza hid the Grand Hotel's front. They, Meridian Walk and Hotel Passage are
gone, and the whole space from the park to City Hall is one square.

**References:**
- **Washington's National Mall:** one long axis with a reflecting pool,
  lawns, and rows of trees along its edges.
- **Tiananmen Square:** an open forecourt before a gate with a rostrum
  where the nation is addressed.

**The square** (data: `CIVIC_SQUARE`, checked) is 124 by 60 m, between
Meridian North and Meridian South, from the Park Deck (x −483) to City Hall
(x −359). From west to east:
- **The west monument site** on the axis, where the square opens from the
  park. Two escalator pairs come down from the Park Deck either side of it.
- **The water mirror,** 72 by 8 m, down the axis under the high line. The
  line's tree piers stand in the water, which doubles them and City Hall.
  Reclaimed water, recirculated; it cools the square.
- **Two lawns** either side of the water, crossed on the Grand Hotel's door
  (x −457) by a walk with a fountain in each lawn: the hotel's cross-axis.
- **Statue plinths** along the lawns' edges by the water, and the **east
  monument site** at the water's end: a low memorial under the high line.
- **The forecourt,** 45 m of open paving before City Hall, where the city
  gathers to face the Rostrum. Two flagstaffs stand before the Rostrum,
  either side of the axis, and the City Steps rise either side (8b.1).
- **Tree rows** of shade trees along the long edges, after the Mall's elms:
  along Meridian South, and along Meridian North only in front of the
  Windspire. Nothing taller than a lawn or a fountain stands between the
  hotel's front and the water.

**The hotel.** The Grand Hotel faces the square across Meridian North with
lawn, its fountain and the water before it. The Deck no longer runs along
its front: a short glazed skybridge crosses the Park Ring west from the
Park Deck into its mezzanine.

**Open:** the subjects of the two monuments and the statues. The west site
suggests a bronze caravan walking east up the axis, for the caravan road
the city grew on; the east site a low memorial for the Wall Watch.

## 8b. The Meridian Arch (the East Gate), the West Gate and Meridian Court (proposed 2026-10-16, revised 2026-10-17, at the user's direction)

> **City Hall (2026-10-17, at the user's direction):** the arch is now City
> Hall as well as the East Gate and its station. City Hall's public hall (the
> Hall of the City, with the house-mark plaques) opens at the foot of the legs
> beside the station hall; the city's offices fill the legs; the council
> chamber and the mayor's office sit in the top bridge's cantilever, looking
> down the civic axis over Civic Plaza to the park; the Wall Watch keeps its
> command room in the top bridge's east end. Meridian Court is now part of
> Civic Plaza. Data: `ARCH.program`.

**Why.** The mid-rise blocks between city hall's back and the East Gate hid
city hall from the east, the way most people first see the city. They are
gone: **Meridian Court**, an open court between Clock Street and the wall
either side of Meridian Avenue, takes their place, and over it stands the
**Meridian Arch**, framing the Timekeeper in the view from the East Gate.

**References:**
- **CCTV headquarters, Beijing (OMA):** a building that is a loop: two leaning
  towers joined at the ground and at the top by a cantilevered bridge, so the
  building frames the sky.
- **The Gateway Arch, St. Louis:** an arch that frames a city's view and is a
  gate to it.

**Revised 2026-10-17 (user): larger and grander, and the arch is the East
Gate.** The station is a civic amenity, so the arch takes the gate, the Wall
Line's station and the high line's terminus into one building.

**Form** (data: `ARCH`, checked):
- **Two legs** straddling the wall either side of Meridian Avenue, each 22
  by 18 m, 72 m high, clad in a diagrid of pale ceramic-clad steel over
  glass (Moy's tile in the CCTV's structural pattern). The avenue passes
  between them through a **24 m opening**, the grandest gate in the city.
- **The Wall Line's train hall (2026-10-17):** the wall's trains must not
  run into the legs, so a **train hall** is cut through both legs at +12
  to +21 m, a straight void between two piers in each leg, set on the
  wall's line and sized for its curve: both tracks and the station's
  platform (on the outer side) clear its sides by at least 0.5 m along the
  leg's whole length, its lit ceiling clears the cars by 3 m, and the piers
  beside it stay at least 1 m thick, the diagrid left off the hall's mouth
  (checked in the layout). Between the legs the platform crosses the
  avenue's opening under a glass canopy. The West Gate's towers have the
  same hall, their escalator cores moved into the outer piers clear of it.
- **Three levels of station:** a glazed **station hall** at the foot of each
  leg opening on Meridian Court; the **Wall Line's East Gate station** at
  +12 m, its tracks running through the legs and over the opening; and the
  **high line's east terminus** on the **lower bridge** (+32 to +42 m),
  directly above it and at right angles, its platforms looking west through
  the Timekeeper. Its city front is in 8b.1.
- **The top bridge** at +58 to +72 m across both legs, **cantilevered 12 m
  west** toward city hall: the **Wall Watch's command room**, looking east
  over the wall and the desert and west down the city's whole axis to the
  library. From the desert road the loop of legs and bridges reads as one
  frame round the Timekeeper.
- **City-owned:** the legs hold the city's offices (planning, works, water,
  the Housing Board's downtown desk) above the station.
- **Green (section 6d):** after WOHA's Parkroyal on Pickering and
  Singapore's LUSH rule, sky terraces with ghaf trees are cut into the legs'
  east faces at +18 and +48 m, greeting the desert road, and the lower
  bridge's roof is a public sky garden, reached by the front's scissors.

### 8b.1 City Hall's city front (2026-10-17, at the user's direction)

**Why.** The first cascades on the legs' faces stacked flight over flight in
one band 16 m long. Their flights overran it, ran into each other, and
carried both directions on one ramp. They also gave the civic seat no front
to stand on, and no clear way to the platforms. A city hall wants a calm,
symmetrical front with one place to stand before the city. Its station
wants short, legible ways to every platform.

**The front** (data: `ARCH['front']`, checked) mirrors about the axis:
- **The Rostrum** at +14.2, the Wall Line's level. It is a balcony 7 m deep
  across the whole west front and over the gate's opening, with a speaker's
  bay on the axis, after the Gate of Heavenly Peace. Over the opening it
  meets the Wall Line's inner platform; in each leg, portals lead through
  to the platform.
- **The City Steps,** one before each leg: a 4.4 m stair to climb or sit
  on, with an up escalator on one side and a down escalator on the other.
  They rise in two flights with a shared half-landing, from the square's
  forecourt to the Rostrum.
- **A glazed scissor on each leg** above the Rostrum. Every flight is a pair
  (an up lane and a down lane), and the flights alternate between two bands
  side by side, so no flight runs under or into another (5.5 m of
  headroom at the closest):
  - +14.2 to +21.8 outward;
  - +21.8 to +29.4 inward;
  - +29.4 to +37 outward;
  - a gallery inward at +37 to the high line platforms' west ends;
  - one more flight to +43 and a gallery onto the sky garden.
- **The Wall Line's outer platform.** The landing at +21.8 crosses over the
  tracks inside each leg, just above the train hall's ceiling, and a pair
  goes down the leg's east side to the outer platform. Any platform reaches
  any other without going down to the street.
- **The high line's terminus.** The lower bridge runs out 6.5 m west of the
  legs' faces, so the platforms' west ends meet the scissors, and 9.5 m
  east of them, to a concourse beyond the buffer stops that joins the two
  platforms.
- **Landings and guards (revised 2026-10-17, at the user's direction).**
  - **Every flight ends on a landing.** F3 arrives on a landing at +37 beside
    the gallery, F4 leaves from another, and F4 arrives on one at +43. The
    outer pair's foot has a platform-side landing inside the leg. The plan
    checks that both ends of every flight meet a deck.
  - **Every open edge has a guard:** clear toughened glass 1.1 m high on a
    bronze shoe, with a bronze rail. This covers every landing and gallery,
    the Rostrum's front, ends and bay, the deck across the opening, the walk
    over the tracks and the Steps' half-landings.
  - **Guards open only where something meets them:** a flight, the Steps, a
    lift door, the leg's face or a platform. No opening is wider than the way
    through it. The runs are in `ARCH['front_guard']`.
- **Lifts (revised 2026-10-17: every stop opens onto a deck, checked):**
  - **The front lifts.** A glass lift stands in front of each leg, in line
    with the tubes, flanking the gate's opening. Its door opens onto the
    tubes' inner ends, at the Rostrum, +37 and +43.
  - **The +21.8 stop is dropped.** Nothing at the tubes' inner end meets it.
  - **The outer lifts.** A second lift, at the east end of the walk over the
    tracks, serves the ground, the outer platform's landing and the walk.


**The West Gate** (data: `WEST_GATE`, checked) is the arch's plainer
partner: two towers 22 by 16 m, 44 m high, straddling the wall either side
of West Street, the Wall Line running through them at +12 m and the high
line's west station on a glazed bridge between them at +32 to +42 m, with a
siding for its trains beyond the wall's line. In each tower's face on West
Street an open loggia of escalating ramps, glass lifts beside it, joins the
street hall, the Wall Line and the high line. Its bridge's roof is Old Moy's
community garden, after WOHA's Kampung Admiralty (section 6d). The bands of the towers repeat
every 6 m, the Wall Line's and the high line's levels among them.

**Meridian Court:** pale paving under the arch, the avenue running through
it, rows of date palms along its north and south edges, benches facing city
hall. Meridian North and Meridian South now end at the court's corners on
the Rim Walk.

**The old BLOCK labs** (the six-storey block on Meridian South) are ordinary
mid-rise real estate now: the plan fills their plot with downtown lots.

## 9. The library: building brief (proposed, 2026-10-13)

**Direction (user):** a classic building renovated over the years, after
the Brooklyn Public Library's Central Library. The earlier terraced-atrium
design is withdrawn: its shelves were knee-to-waist risers that nobody could
use properly (Tianjin Binhai's own failing, where the upper "shelves" are
printed pictures of books).

### 9.1 People and purposes

**What a library is for in Moy.** In a closed city where nothing new
arrives by road, the library keeps everything the city knows:
- **Lending and reading** for the whole city.
- **The city's memory:** Old Moy's history, the wells, and the catalogue of
  house marks, the painted pictures every Moy sign descends from.
- **Children's books and stories**, every afternoon after school.
- **A quiet hall** for writers and readers, out of the heat.

**Who works and reads here:**

| Person | Role | Where |
|---|---|---|
| Ada Fong | head librarian; led the latest renovation and still misses the Great Hall's creaking floorboards, which it replaced | her office off the top gallery |
| Nia Calder | map archivist; keeps a drawer of maps nobody can explain | the map room in the heritage room below the hall |
| Benji Okoro | children's librarian; Jammer's favourite grown-up after his parents | the children's library and its garden court |
| Mara Quill | novelist, writing a book to find out what the city mirrors | the Great Hall, the same table every day |
| Lily, Kofi | after school, and up the galleries when Benji isn't looking | the children's library, the galleries |

**History: three layers, like Brooklyn's.**
1. **The boom building.** Built in the Windworks' first boom, the same
   years as the Grand Hotel but in limestone and bronze, art deco, the city's gift
   to itself. Its heart was the galleried **Great Hall**.
2. **The middle renovation.** Lifts, air conditioning, and the deep stacks
   wing behind the hall.
3. **Ada's renovation.** It opened the ground floor to Library Square with a
   glass **welcome hall** behind the old stone, moved the children's
   library to the ground floor round a garden court, joined the library to
   the Deck, and turned the old basement stacks into the **heritage room**.
   It also replaced the Great Hall's worn floorboards; Ada had the old
   boards relaid in the heritage room, so they still creak, below ground.

**What goes in and out.** Readers from Library Square (south) and the Deck
(+6.5 m); books and deliveries by trike at the loading door on Library Lane
(north).

**References:**
- **Brooklyn Public Library, Central Library (1941):** art deco limestone;
  a front that curves inward round its plaza like an open book, with the
  entrance at the spine; a monumental portal framed in gilded bronze
  figures; a recent renovation that opened the ground floor in glass.
- **George Peabody Library, Baltimore:** a tall top-lit hall ringed by
  tiers of cast-iron galleries, every wall shelved, every shelf reachable
  from its gallery.
- **The Long Room, Trinity College Dublin:** a long galleried hall of
  timber cases and reading desks.
- **The Rose Main Reading Room, New York Public Library:** long tables and
  green lamps.

### 9.2 Site

The north side of Library Square, at the west end of the civic axis (city
hall, Civic Plaza, the park, Library Square, the library): 45 m (east–west)
× 62 m (north–south). The front faces south onto the square; the west face
is on Arcade Street, the east face on Garden Walk, the service face on
Library Lane. The Deck arrives at the front at +6.5 m.

### 9.3 Program and stacking

**Massing, after Brooklyn's open book:** two **wings** (the pages) run
north–south along Arcade Street and Garden Walk; the **spine** between them
holds the portal and, behind it, the Great Hall. The front curves inward
round Library Square, about 8 m deep at the centre.

| Level | Height | Contents |
|---|---|---|
| **Heritage room** | −4.5 m to 0, under the Great Hall | The old basement stacks: Old Moy's archive in the old timber cases, on the Great Hall's old floorboards; the catalogue of house marks, the well records; **Nia's map room** in its north-east corner |
| **Ground** | 0 to +6.5 m | The **portal** at the spine; the glass **welcome hall** behind the stone of both front wings (lending desk, returns, the city's notice of events in pictures); the **children's library** round a garden court (west wing); lifts and washrooms (east wing); sorting and the loading door (north) |
| **The Great Hall** | 0 to +22 m, the spine | One hall about 29 × 32 m. Reading tables with green lamps on its floor. Four tiers of cast-iron **galleries**, at +6.5, +9, +11.5 and +14 m, run round all four walls; every wall is shelved from floor to the top gallery |
| **Wings, upper floors** | +6.5 to +20 m | The stacks (north wing), study rooms, Ada's office off the top gallery, the Deck door (front of the east wing, +6.5 m) |
| **Roof** | +22 m, lantern to +26 m | The Great Hall's **skylight**, a coffered glass roof under a lantern of louvres; the wings' flat roofs behind a stepped art deco parapet |

**Lines that stack.** The wings' walls run unbroken from the heritage room
to the roof. The Great Hall's galleries hang on cast-iron columns standing
on the hall floor's perimeter, 2.5 m in from the walls, over the heritage
room's own walls. The skylight bears on the spine's walls.
- **Core:** east wing, two lifts and the washrooms; the service lift from
  the sorting room.
- **Ramps** (the world's ramp rule): two curving ramps in the Great Hall's
  north corners climb gallery to gallery; an escape ramp tower stands in
  the north-west corner.

**Every book is reachable.** Floor-level cases are reached from the hall
floor. Each gallery is 2.5 m wide, with cases 2.3 m high on its wall side,
reached from that gallery. Rolling ladders hang from rails for the top
shelves. Readers take books down to the tables on the floor or to desks set
along the gallery rails.

**Circulation:**
- **Readers:** square → portal → welcome hall → the Great Hall, then the
  corner ramps or the lifts to the galleries.
- **From the Deck:** the east wing's door at +6.5 → the first gallery.
- **Children:** welcome hall → children's library, without crossing the
  Great Hall.
- **Staff and books:** Library Lane → sorting → service lift.

### 9.4 Facade

| Element | Term | Tradition |
|---|---|---|
| Walls | pale limestone, deep reveals | art deco; Brooklyn |
| Front | **concave**, curving round the square like an open book | Brooklyn |
| Portal | a recessed **portal** 15 m tall at the spine, framed in gilded bronze **relief screens** of figures from Moy's stories (the well-diggers, the first wind towers, the children of Old Moy), pictures only | Brooklyn's portal; Moy's no-lettering rule |
| Ground floor | **glass** set back behind the stone piers along both front wings, the welcome hall | Brooklyn's renovation |
| Windows | tall narrow slots between limestone **piers** | art deco |
| Top | a stepped **parapet**; the lantern over the Great Hall | art deco |
| Signature motif | the house marks, cast in bronze in the portal's frame | the city's signature |
| The sign | an open book in gilded bronze over the portal, no lettering | Moy's picture signs |

**The civic set.** The library and city hall come from the same boom and
share their art deco stone and bronze; they face each other down the civic
axis across the park, the library at its west end and city hall at its
east. The Grand Hotel is of the same boom but not of the set: its builder
chose the boom's daring over its stone (section 8.1, revised 2026-10-13
in John Portman's manner).

**Palette:** limestone 60 %; bronze, timber and cast iron 30 %; gilding,
green lamps and sign colour 10 %.

### 9.5 Light, heat and the books

- **No sun on the books.** The hall is lit from above through the louvred
  lantern and the coffered skylight; the slot windows are deep and narrow.
- **The heritage room is the coolest place in the city**, below ground,
  where the oldest papers are kept.
- **The hall cools itself:** warm air rises and leaves through the lantern's
  louvres, drawing air in at the shaded portal.
- **Modern air conditioning and dehumidifiers**, from the middle
  renovation, keep the stacks steady.

### 9.6 Washrooms

Moy is modern: public washrooms in the east wing on the ground floor and at
the top gallery, with flush toilets and basins, to the city sewer.

### 9.7 Play

- **The Great Hall is the city's best indoor climb.** The galleries are
  2.5 m apart, too high for one jump, so the climb goes through the iron:
  from a gallery's floor onto its rail (1.1 m), then up to the next
  gallery through the gaps in its rail where the rolling ladders hang.
  The column brackets under each gallery are ledges for a smaller body.
- **The skylight's coffers and the lantern** are a high run over the hall,
  reached from the top gallery by the corner ramp.
- **Outside,** the portal's bronze screens and the limestone piers are
  climbing holds, and the stepped parapet is a run toward the park.

### 9.8 Realised (fidelity A)

- **Built inside:** the portal and welcome hall, the Great Hall with all its
  galleries and ramps, the children's library, and the heritage room with
  Nia's map room.
- **Faux and solid:** the stacks wing, the study rooms, Ada's office and the
  sorting room (closed doors).
- **Lifts** run from the welcome hall to the galleries.

## 10. Fidelity: what is realised

Not every floor is built.

| Level | Built | Which |
|---|---|---|
| **A. Realised** | rooms, people, light, lifts between realised floors | the Grand Hotel's atrium (with its mezzanine and galleries) and level 27 with the party's suite; the library's welcome hall, Great Hall and galleries, children's library and heritage room (section 9.8); the museum's hall; the Moonlight Cinema; the vertical farm's growing floor; the family's tower house; the Windworks' legal floor in the Windspire and Tanglewire's floor; the Helmsmith; the café; the night market; the wet market; the convenience store; the clinic; the police box; the school's classroom; the giant playground; the park's tea house; Pinestein's rooftop laboratory; the North Estate hawker centre, one void deck and the Lams' block lobby; the twin blocks' sky garden; the Windspire's lobby, express lift and observation deck; the mirror field (outside) |
| **B. Street** | the ground floor as a real shop or lobby, or a shallow room behind glass; upper floors facade only, with lit windows that show rooms | most street buildings; city hall, exterior only, its doors shut (section 8a.7) |
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
  after Chinese grand hotels), in John Portman's style (user,
  2026-10-13);
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
  are, not wedged among lots; its blocks are broad and close together round
  each precinct's court, and angled off the city grid (user, 2026-10-13). Skyscrapers
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
  (user, 2026-10-12), and they can speak of the Middle of Nowhere. The
  family is **a small Easter egg, not a plot point** (user, 2026-10-13):
  no recognition scene and no quest. Elizabeth does not single the hero
  out; the connection is left for observant players in her photograph of
  him as a boy, Jammer's farm drawings, and the family's passing talk of
  the farm.
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
- the five added residents;
- (2026-10-13) the Grand Hotel's design after Portman (section 8): the
  atrium block and cylinder tower, the leaning front, the capsule lifts
  up the outside of the tower, the chandelier hung down the void, the
  Windrose revolving lounge, the runnel of reclaimed water and the
  skybridge to the Deck.
- (2026-10-14) the Deck's route (section 6): the Park Deck ring, the civic,
  library, estate and market walks, two skybridges, six ramp towers and two
  glass lifts; travelators dropped;
- (2026-10-17, plan iteration 3, at the user's direction) **the Crossing
  redesigned from its purpose**: four garden towers carrying both lines, a
  garden ring and one roof, the halo, the slender columns and the spirals
  gone; the Park Deck's missing columns restored; parapets open at every
  junction; the Deck a garden walk; the park planted with the kit's trees
  in place of the wind trees, every tree, bed, shrub and parapet recorded
  in the plan; the Timekeeper's markers made arrows (6, 6c, 6d, 6f, 7a, 7b,
  8a);
- (2026-10-17) **the ASAN launch complex** north-east of Moy, the way to
  the Space Kingdom (section 12);
- (2026-10-17, after the first playable prototype) **level lines and real
  platforms**: the Spine recentred on its streets and level at the Wall
  Line's height, ending at gate interchanges inside the wall (no flyover,
  no tunnels); platforms at the car's floor; escalator pairs, scissors and
  the Crossing's double-helix spirals (since replaced by its garden towers); the train halls following the wall's
  curve; a clock-face timetable (6c, 6e, 6f, 6g, 7a);
- (2026-10-17) **the Well Quarter simplified**: two old roads (the Old High
  Street and Mara's Lane) with the grid laid round them, and blocks of
  perimeter tower houses round courtyards, replacing the winding lanes and
  dead-end alleys;
- (2026-10-17) **green infrastructure after Singapore** (section 6d): the
  lines' planted edges, the piers' climbing sleeves, the Crossing's planted
  ring, planted open-air escalator towers and cascades (the cores opened to
  the air), the arch's sky terraces and sky garden,
  the West Gate's community roof garden, the Rim Corridor;
- (2026-10-17) the Meridian raised to **+36 m**; the **Timekeeper** a full
  twelve-hour circle in a bronze cradle; the **arch as the East Gate** and
  **the West Gate's towers**, each an integrated station; **the Crossing**
  an open ring; station cores, and the rhythm of the lines' supports
  (6c, 7a, 8a.0, 8b);
- (2026-10-16) **two straight lines** (the Spine at +12, the Meridian at
  +26), **the Timekeeper** over city hall (8a.0), **Meridian Court and the
  Meridian Arch** (8b), **the Crossing** at the park's centre and the
  playground in the south-east quarter (7a), BLOCK's old labs as mid-rise
  real estate;
- (2026-10-14) **the wall and the trains** (section 6c): the Ring Line's
  viaduct filled into a circular wall 12 m high, four gates, watch posts and
  the Line House; the Wall Line on its top; the elevated Spine and Meridian
  Lines over the Deck; the works outside with their own security.

**Open:**
- who keeps the Wall Watch and who runs the lines: two new residents
  (proposed: a Watch captain living in the Line House, and the lines'
  controller), taking the census to 47;
- whether a line ever leaves the city, up the main plateau's cliff toward
  Ohio (this would revise "no road to a wider world");
- whether the gates ever shut, in a story alarm;
- the hotel's rest price;
- the park's small pond (kept, as plain reclaimed water, not a display);
- whether the hero's own city blorbs may follow him inside the bounds.
  Proposed: the ban is the city's law and the gates are watched, not shut,
  so a party city blorb may follow, and the residents react in character (Kate's look, a shopkeeper
  unplugging a sign), never with a stated rule;
- whether Pinestein has a quest, such as a case to let the city blorbs back
  in;
- the Windspire's height against the far skyline's draw distance;
- the turbines' draw cost: four animated rotors seen from across the
  world (proposed: one shared mesh, instanced, rotors as cheap far LODs).
- what lets the hero board the ship at the launch site and launch it
  (section 12).

## 12. The launch site: the way to the Space Kingdom (proposed 2026-10-17, at the user's direction)

The Space Kingdom is on the roadmap. Unlike the other kingdoms it has no
gate: the hero goes by rocket. Its entry point is a launch complex in the
open desert outside Moy, where the ship from the Demo World (the **ASAN
launch vehicle**, `scripts/demo_spaceship.gd`) stands upright, ready to fly.
This first step only places and plans the site; nothing is built in the game
yet. Data: `LAUNCH_SITE` in `tools/city_layout.py` (exported to
`scripts/city_plan.gd`); drawings: the plan's *The launch site* (site plan and
section) and the city model's *The launch site* view.

### 12.1 Where

North-east of the city, centred on the mount at **(−250, −580)**: about 440 m
beyond the wall, on the desert floor between the Ice plateau and the main
plateau's cliff, with the service track running out from the **North Gate**.
The plan tool checks that the site keeps 300 m from the wall, 220 m from every
turbine, 50 m off every plateau's slope (the fence itself stays off them), 120
m inside the world's edge and 300 m from the Chinese village, that the landing
zones stand 150 m from the mount, that everything sits inside the fence, and
that the hangar and the firing room stand further from the mount than 1.2
times the stack's height (the fall zone).

| Part | Where | Size |
|---|---|---|
| Launch mount | (−250, −580) | 30 × 30 m, deck +8 m; the flame trench runs north 80 m, away from the tower, the hangar and Moy |
| Launch tower | (−221, −580), on the doorway's (east) side | 12 × 12 m open steel frame, 118 m, a 12 m lightning mast; glass lift; crew arm at +46 m |
| Hangar | (−250, −380), doors north | 44 × 100 m, 34 m tall (vaulted roof) |
| Erector rails | from the hangar door to the mount, x −250 | gauge 12 m, 135 m long |
| Firing room | (−205, −430) | 24 × 16 m, 6 m, behind an earth blast bank, its windows on the pad |
| LZ-1, LZ-2 | (−150, −720), (−345, −705) | 25 m radius each |
| Fence and gate | round all of it; the gate at (−200, −320) | |
| Service track | North Gate → site gate | 8 m, unpaved |

### 12.2 Standing the ship up

The Demo World's ship lies along its own Z axis, nose +Z, doorway +X, with
its two booster-like pods along its flanks and four engine bells at the tail.
Its exterior parts are SuperEggs (exponent 3) with box colliders.

- **The rotation.** The upright ship is the same scene under a parent rotated
  **−90° about its X axis**: local +Z (the nose) becomes up, +X (the doorway)
  stays facing the tower, local Y becomes world −Z. Nothing in the ship is
  re-authored; the parent node carries the turn. Its origin sits at **+52 m**
  (the mount's deck, +8, plus 2 m of clearance below the engine bells, whose
  bottoms are 42 m behind the origin); the nose stands at **+102.5 m**, the
  doorway at **+46 m**, the booster bells at +16.6 m. The tower (118 m) is
  checked to stand at least 6 m above the nose.
- **How it got there (told by the site, not by text).** After the Falcon 9's
  transporter-erector and the Soyuz's rail erector: the ship is built lying
  down in the hangar, rolled out on a **strongback** along the erector rails,
  and raised a quarter-turn about a **hinge at the mount**; the strongback
  then lowers back onto its rails. The lowered strongback, its saddles and the
  rails stay in view, so a player who looks can read the story. A later pass
  could animate the raise as a cutscene, as one rotation of the parent about
  the hinge.
- **Inside, on end.** The cabin's deck (`DECK_Y`) becomes a vertical wall when
  the ship stands. Boarding is therefore a **seated launch**: the hero passes
  through the doorway from the crew arm and is placed in a seat; the cabin is
  not walked while upright. When the ship arrives in space it flies level
  again, as it does in the Demo World, so its interior works as it already
  does.

### 12.3 Boosters, and showing the idea

The two flank pods read as strap-on boosters. The design follows the Falcon
Heavy: two side boosters that **separate in flight, relight, fly back and
land upright** on the two landing zones. The concept is shown, never
explained:

- the boosters carry **folded grid fins** at their heads and **folded landing
  legs** along their feet (in the model: the small fins and the dark strips);
- the **landing zones** are visible, painted pads north of the mount, empty
  before a launch;
- **after a launch**, the two boosters stand on their pads, legs out,
  scorched, and the mount is empty; a player who returns sees what happened;
- the launch itself (if the camera follows it before the fade) shows the
  separation as two bodies peeling away.

The core keeps its four bells and goes on alone. Expendable boosters falling
into the desert were considered and rejected: they leave nothing to show, and
fly-back boosters give the site a visible before and after.

### 12.4 Boarding and launch (planned, not built)

1. The hero follows the track from the North Gate to the site's gate.
2. **The condition.** Something must be true before the gate, the lift or the
   doorway lets him through. **Open: the owner decides.** A natural candidate
   is the Space Helm (a bound Space blorb lets him breathe in vacuum). Any
   such condition is shown in the world (the doorway's seal stays shut, the
   crew arm stays folded back), never stated in text.
3. The tower's glass lift to the crew arm; across the arm to the doorway.
4. Inside, the seated launch: the hero in a seat; the trigger to launch is
   the cockpit's controls, as in the Demo World (proposed).
5. Countdown, ignition (the four core bells and both boosters), lift-off, a
   roll toward the east.
6. Booster separation; the boosters relight and turn back.
7. A fade, and the **next scene loads**: the Space Kingdom, where the ship
   flies level without its boosters. Back at the site, the boosters now stand
   on LZ-1 and LZ-2 and the mount is empty (until the ship returns: open).

### 12.5 Open

- the boarding condition and how the world shows it;
- whether the raise is ever seen (a cutscene) or only implied;
- who runs the site (ASAN's own crew, or Moy's), and whether anyone is there;
- how the hero comes back, and whether the ship returns to the pad;
- the Space Kingdom itself.
