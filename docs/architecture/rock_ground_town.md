# Rock and Ground Kingdom: The Frontier Town

Status: concept and settlement brief, first pass, for review (2026-10-06).
Settlement-design stages 1 and 2 (survey and community brief), with the
culture, the cyborg horses, the hat helm, the architectural direction and the
landscape direction. The dimensioned layout follows once this is approved.

## 1. What exists now

From `rock_ground_kingdom_terrain.gd`, `rock_ground_kingdom_village.gd` and the
world bible.

- **Kingdom:** 1,240 m across.
  - The **Rock half** (west) is banded-sandstone terraces, cliffs, canyons,
    hoodoos, arches and slab fields, climbable with a Ground-leg suit.
  - The **Ground half** (east) is open dirt, holding **Dinosaur's** fossil
    basin at `(185, -145)`, radius 72 m.
  - The gate is the warp from the Crossroads canyon (Mesa) biome.
- **Town:** a level shelf centred at `(-155, 92)`, radius 68 m, in the Rock
  half.
  - Eight generic 2 × 2 one-storey houses in a ring, each with a stone
    masonry front facade (added by direct instruction).
  - Eight residents named for rocks: Petra, Cairn, Mica, Flint, Ochre, Shale,
    Terra and Rook, one line each.
  - A ring-stone well at the centre.
  - The **inn** at town centre + `(18, -48)`, kept by **Dolma Hearthstone** (a
    woman), **20 Tokoins** a night, a rest point. It has the `earth_closet`
    toilet.
- **Plants:** the terrain scatters 95 small scrub bushes. Otherwise the
  kingdom is bare rock and dirt.
- **Dirt bikes already exist:** `DirtbikeMode` is the Ground suit's shared
  traversal power. The wearer's own Ground blorbs become the wheels, in the
  Ground blorbs' body colour. The demo world's Ground stretch is a dirt-bike
  circuit.
- **Helms:** every suit with a helm carries it on its head blorb (the Diving
  Helmet, Lava Helm, Penguin Helm, Toboggan, Bird Helm and Leaf Hat). **The
  Ground suit has no helm yet.**
- **Horses:** Manchego is built by the shared `HorseFigure` rig.
- **Visor technique:** the Space Helm's face opening is a Boolean
  subtraction (`blorb_suit.gd`, `VisorNegative`).

### Non-regression requirements

- Dinosaur, his fossil basin and his resurrection.
- Wild Rock, Ground and Normal blorbs.
- The climbable Rock half.
- The gate.
- The inn as a rest point with its keeper Dolma Hearthstone and its price.
- Stone masonry on building fronts (the user's earlier direction; it suits the
  new style, see section 6).
- The town's protected shelf.

## 2. Premise: cowboy punk

The town is a **Western frontier town** in the manner of the early Texas
towns, a classic movie Western's main street. Like Ohio and Kai Mālie, it is
a **layered** place: old-time frontier life in the present day.
- **Old-time work:** wranglers, a saloon, a sheriff, a general store, an assay
  office, a livery.
- **Modern technology:** at hand, and the town loves one thing above all:
  **dirt biking** across the canyons and dirt flats around it.

Call it cowboy punk.

The fusion runs through everything:
- **Horses** are cyborgs that become dirt bikes.
- **Hats** are smart headgear that become dirt bike helmets.
- **The livery stable** is also a garage.
- **The rodeo arena** is also the start of the race.

### 2a. Mechanical and motor punk (user, 2026-10-12)

The town's look is **cowboy punk, mechanical punk and motor punk** together.
Its technology has real power, electric and battery as much as wind and
springs, because a dirt bike has a motor. What sets the look is that the
machinery is **open**:
- gears, cogs, ratchets, cams, chains and sprockets;
- finned motor casings, exhausts and heavy cables in braided sleeves;
- big knife switches and analog gauges with needles;
- flywheels and leather belts.

Nothing hides behind a smooth panel or a screen. This sets the town apart
from the Fire city's steel and glass and from the sea folk's sealed
engineering.

**The rule.** Every gear, motor and cable does work. They are seen because the
machines are built open, as a garage or a bike shop leaves them, not because
cogs are glued onto walls and hats as ornament. A gear that turns nothing is
excluded, as the interior-design skill already excludes fake pipes.

**Power:**
- **Batteries and motors** run the dirt bikes and the cyborg horses' bike
  form. They charge at the livery's charging posts.
- **Wind.** Steel-bladed windpumps (the kind still standing all over West
  Texas) pump water, turn line shafts, and drive the dynamos that charge the
  batteries and light the town.
- **Springs** wind the hats and the clockwork.

**Where it shows:**
- **The horses.** Geared joints in the lower legs, and an exposed motor and
  chain drive in the bike form (section 4).
- **The hats.** A ratcheting, spring-wound fan of brim segments (section 5).
- **The livery and garage.**
  - An overhead **line shaft** turned by the windpump, with belts down to a
    lathe, a drill press and a grinder.
  - **Charging posts** with knife switches and needle gauges, cables hanging
    in loops.
  - Gears racked by size, chains on hooks, a motor stripped on the bench, a
    horse leg with its cover off.
- **The water tower and windpump.** The geared head turns into the wind,
  pumps the well into the tank, and turns the dynamo for the street's strings
  of bulbs.
- **The mine.** A geared **hoist** at the portal, ore carts on rails, a small
  **stamp mill** at the ore house (a camshaft lifting five iron stamps to
  crush ore, a clatter heard down the mine road), and electric lamps in steel
  cages on a cable.
- **The race barn.** Dirt bikes up on stands with their engines open, the
  smell of oil, and a tall clockwork **race clock** with a geared dial and
  drop numbers. The starting gate is released by a falling weight and a cam,
  so every race starts with the same clank.
- **The saloon.** A **player piano** with its roll turning behind the glass,
  ceiling fans on a belt, and spring-hinged swinging doors.
- **The rodeo arena.** A geared, motor-driven **mechanical bull** that the
  gang runs for newcomers.
- **The shops.**
  - The general store's mechanical cash register.
  - The assay office's geared balance.
  - The jail's heavy cell lock.
  - Inez's hat shop, with a watchmaker's bench of springs and tiny gears.
- **The jail.** A radio mast, and a **heliograph** with geared mirrors for
  signalling the ranch and the mine when the radio is out.

**Materials:**
- blackened and oiled iron and steel;
- worn chrome on engines and exhausts;
- brass on fine mechanisms (hats, clocks, gauges);
- leather for belts, straps and seats;
- rubber-sleeved cable;
- timber for frames and housings.

**Two scales: heavy machinery and fine clockwork (user, 2026-10-12).** Beside
the motors, belts and stamp mill, the town loves **watch gears and clockwork**:
small brass wheels, escapements, balance wheels, mainsprings and jewelled
pivots, worked under a loupe. The fine scale shows in:
- **Inez's hat shop**, the town's watchmaker as well as its hatter. Her bench
  holds a loupe, tweezers, trays of tiny wheels and springs, a hat with its
  band open to show the winding train, and pocket watches in for repair.
- **The hats.** Each brim's ratchet and spring is watch-fine work, wound at a
  small crown on the hat band, and the change runs with a quick tick.
- **The horses' joints.** The small gear trains seen through the cut-outs at
  the fetlock are watch-scale, under glass.
- **Clocks:**
  - the race clock's visible escapement and swinging pendulum;
  - a tall case clock in the saloon;
  - a clock in the assay office's window.
- **People.** Pocket watches on chains are everyday wear, opened to show their
  movement. Inez repairs them all. Gus carries one that has not run in
  twenty years.

**On dress, an honest exception to the rule.** A gear on a machine must
turn something. A gear worn as **jewellery** is a different thing: a person's
adornment made from salvaged watch parts. Allowed:
- a bolo tie slide set with an old balance wheel;
- cufflinks of watch wheels;
- spur rowels cut like gear wheels, which click as their wearer walks.

These belong in the town's dress charter when it is written
(`character-design` skill). They are never glued onto buildings.

**Sound** is part of it: motors revving at the race barn, ticking clocks and
watches,
ratchets, the stamp mill's beat, the windpumps' creak, and the click of a hat
changing.

## 3. Community (proposed census, 2026-10-06)

Eighteen residents in twelve households. The eight rock-named residents are
replaced: their names belonged to the earlier earth-and-stone concept.
**Dolma Hearthstone keeps her name and her house**, which becomes the saloon
and hotel.

The town is cosmopolitan, as the real frontier was. That frontier included
Anglo settlers, Tejano families whose roots in Texas run deepest of all, and
Black cowboys, about one in four of the real trail hands.

| Resident | Gender | Household | Role |
|---|---|---|---|
| **Dolma Hearthstone** | woman | the saloon | keeps the saloon and hotel: the town's social centre and its rest point |
| **Ike Pruett** | man | the saloon | Dolma's husband; tends bar and plays the saloon piano |
| **Ruth Calloway** | woman | the jail | the sheriff, outnumbered by the gang and unbending anyway; lives above the jail |
| **Amos Bell** | man | the Bell ranch | rancher and wrangler; breaks in young cyborg horses |
| **Cora Bell** | woman | the Bell ranch | Amos's wife; horse trainer and the best judge of a horse in town |
| **Josie Bell** | girl, 12 | the Bell ranch | their daughter; wants nothing in the world but to race |
| **Mateo Villanueva** | man | the livery | farrier and mechanic: shoes the horses, fixes their cybernetics, tunes their bike forms |
| **Inez Villanueva** | woman | the livery | Mateo's mother; the **hat maker**, who builds the town's shifting hats |
| **Wes Tolliver** | man | the saddlery | the **saddle maker**; his tack shop stands beside the livery, and his saddles carry the same cowboy-punk technology as Inez's hats |
| **Walt Beasley** | man | the general store | storekeeper; sells everything from beans to wheel bearings |
| **Pearl Dunaway** | woman | the assay office | assayer and banker: weighs the prospectors' ore and keeps the town's money |
| **Hollis Grant** | man | the doctor's | doctor and barber, "Doc" to everyone |
| **Lark Delgado** | woman | the race barn | the town's champion rider and race marshal |
| **Cass Rourke** | woman | the mine house | the town's **miner** and mine foreman: works the Silverback mine in the canyon wall with a drill, a pick and an ore cart, and keeps its timbers sound; added 2026-10-07 |
| **Gus Pickett** | man | his shack | the **old prospector**: fifty years walking the canyons and the fossil basin, knows Dinosaur's bones; never seen without his battered, sweat-stained **prospector's hat** (a wide, floppy-brimmed slouch hat with a dented crown), a pan and a pickaxe on his mule-sized cyborg burro |
| **Dr. Hazel Coleman** | woman | the bone camp | the **paleontologist**, added 2026-10-12: has spent eleven years on Dinosaur's bones at a camp on the fossil basin's rim, measuring, sketching and plastering them; buys her plaster and burlap from Walt and forgives Gus for using the first toe bone he found as a doorstop |
| **Tomás Reyes** | man | the assay office | the **geologist** and surveyor, added 2026-10-12: Pearl Dunaway's husband; reads the canyon's banded layers like pages, keeps a cabinet of labelled stones, and tells Cass where the silver ought to run |
| **Della Lusk** | woman | the race barn loft | the **track boss**, added 2026-10-12: builds and grooms the race course and loves dirt: mixes clay for grip and sand for drainage, reads a track by its colour, and rakes out the gang's ruts every morning |
| **Jessup Kane** | man | the gang | leader of the riders who hang around the saloon |
| **Dutch Raker** | man | the gang | the gang's muscle |
| **Sadie Vex** | woman | the gang | the gang's fastest rider, and Lark's rival |

### Livelihood

- **Ranching** cyborg horses: breeding, breaking, training, selling.
- **Earth science** (user direction, 2026-10-12): a town on rock and dirt
  has people who love them.
  - **Tomás Reyes**, the geologist, maps the strata and finds the mine its
    seams.
  - **Della Lusk**, the track boss, knows every kind of dirt by hand.
  - **Dr. Hazel Coleman**, the paleontologist, studies Dinosaur's bones.
  - Pearl's assay office doubles as Tomás's survey office: its back room
    holds his sample cabinet, maps and a hand lens.
- **The livery and garage:** shoeing, repair, tuning.
- **Mining** (user direction, 2026-10-07): the town's working backbone.
  - **The mine:** Cass Rourke runs the **Silverback mine**, a timbered tunnel
    (an adit) into the canyon wall of the Rock half. It yields silver ore
    and the odd crystal.
  - **The prospector:** old Gus Pickett prospects alone, panning the washes
    and chipping the canyons for new seams. He sells what he finds to the
    assay office.
  - **The assay office:** Pearl Dunaway assays the ore, pays for it and
    banks the proceeds.
  - **The store:** Walt sells the miners' tools, candles and lamp oil. The
    general store's stock and the assay office's money depend on the mine.
  - The mine is one more reason for the town's love of machines. Its ore carts
    run on rails, a geared hoist and a windmill-driven stamp mill do the heavy
    work, its lamps are electric in steel cages, and Mateo maintains the
    machinery.
- **The saloon and hotel.**
- **The general store.**
- **Dirt-bike racing:** the town's passion, run from the race barn.

### Governance

Sheriff Calloway keeps the law. Town matters are argued out in the saloon,
where everyone ends up anyway.

### 3a. Draft lines for the earth-science residents (2026-10-12)

Written to the `npc-dialogue` skill: in the moment, never reciting a role.
No line hints at how Dinosaur could rise.

**Dr. Hazel Coleman**, before Dinosaur rises:
- "Don't step on the string. Every square in that grid is a week of my life."
- "Forty-one ribs so far. Every one of them longer than my wagon."
- "Bones this old ought to be scattered by floods. His are just lying down,
  like he got tired."
- "Gus found the first toe bone fifty years ago and used it as a doorstop. I've
  forgiven him. Mostly."

**Dr. Hazel Coleman**, after Dinosaur rises (a revisit state, backlog item
13):
- "Eleven years I measured his ribs. Now he breathes with them. I can hear it
  from camp."
- "My notebooks are all wrong about how he walks. I've never been happier to
  be wrong."
- "He stepped over my tent this morning. Carefully. I'm choosing to believe it
  was carefully."

In that state her camp changes too: the grid strings are down, the plaster
jackets are open and empty, and she sketches him alive from the rim.

**Tomás Reyes:**
- "See that pale band halfway up the canyon? Water lay here once. Climb up
  and you'll find its shells."
- "Every layer's a page. The canyon's a book with the cover torn off."
- "Cass wants to know where the silver runs. The rock tells you, if you're
  patient. Cass isn't patient."
- "Pick that one up. No, the red one. Feel how heavy? Iron."

**Della Lusk:**
- "Careful, I just raked the start straight. Give it till sundown and it'll
  hold."
- "Clay for grip, sand so it drains, a bit of crushed rock off the mine tips.
  Don't let anyone tell you dirt's just dirt."
- "You can read a track by its colour. Dark means wet. Wet means you're going
  down."
- "The gang tears it up every night. I fix it every morning. That's the deal
  nobody agreed to."

## 4. The cyborg horses

The town's horses are cybernetic. **At rest** they are horses, and **for
racing** they transform into dirt bikes.

### At rest (horse form)

- Built on Manchego's functional design and the shared `HorseFigure` rig, in
  the town's own coat colours: duns, bays, sorrels, greys and paints.
- **Subtly visible mechanics on the lower half:**
  - plated cannon bones;
  - **geared fetlock and knee joints**, small gear trains and a ratchet
    showing at each joint through cut-outs in the plating;
  - piston-and-rod tendons down the back of the legs;
  - hooves with a machined rim;
  - a faint panel line along the belly, where the bike form's motor, battery
    and chain fold away.

  The machinery is oiled steel, a little brass and worn chrome; it is
  mechanical in look, not glowing or screen-like.

  The upper body, neck and head stay fully horse.
- Tied at hitching rails outside the saloon, at the livery, in the ranch corral.
  They stamp, swish and doze like any horse.

### For racing (bike form)

When a rider mounts and prepares to race:
- the body **compresses down to dirt-bike size**;
- the legs fold in, and the lower legs give way to **dirt-bike wheels**, front
  and rear;
- **the horse's head stays**, raised at the front, and serves as the steering:
  the rider holds the reins where handlebars would be.

The result is a dirt bike with a horse's head, mane flying.

**What drives it: a motor.** In the bike form an electric motor and battery
pack sit in the horse's barrel, open to view in the motor-punk way:
- a finned motor casing;
- heavy cables in braided sleeves;
- a chain and sprockets to the rear wheel;
- a needle gauge on the battery's charge by the reins.

The horses charge at the livery's posts.

### Design notes

- The change is a short, mechanical sequence: ratchets clicking, plates
  sliding on geared hinges, legs folding on linkages, wheels swinging out on
  their arms, the chain dropping onto the sprockets. It is not a puff of
  smoke.
- The bike form should read as kin to the Ground suit's own dirt bike: the same
  wheel proportions and the same dirt.
- **Gameplay is open.** Can the player ride one? Do they race the gang or
  Lark? Does Manchego relate to them? Any riding must follow the traversal
  parity rule (CLAUDE.md): one shared `TraversalMode` for every playable
  character, reusing `DirtbikeMode`'s wheel dynamics for the bike form.

## 4a. Manchego and the saddle (user direction, 2026-10-06)

Manchego joins the party as a **chibi** horse in the Plant Kingdom: too small
for the hero to ride, ridden only by Xiao Hou Zi. In this town of horse
experts, the hero can make him full size.

- **The saddle.** The saddle maker **Wes Tolliver** makes Manchego a saddle
  with the town's cybernetic technology built into its tree and stitching.
  Equipped on Manchego, it lets him **grow to full size or shrink back down**.
  Working name: the shifting saddle. How the hero gets it (a commission, a
  race, a favour) is open.
- **From then on, anyone can ride him** (user, 2026-10-06).
  - Walk up to him and the **Ride Manchego** option appears, whether you are
    the hero or Xiao Hou Zi.
  - If he is not the right size for that rider, he **changes size first**
    (full size for the hero, chibi for Xiao Hou Zi), and then the rider
    mounts.
  - After dismounting he **stays at that size** until a rider of the other
    size mounts him.
- **On a reset he is chibi again.** His size is not kept in long-term saved
  data: whenever the game resets (a reload or restart), he defaults back to
  chibi. This keeps the state simple.
- **The change:** quick and mechanical, like the town's horses and hats. The
  saddle's stitching glows, and he swells or settles over about a second,
  changing proportions as he goes: legs lengthening and slimming, tail
  lengthening. No puff of smoke.
- **Traversal parity:** riding Manchego stays one shared mount mode for every
  playable character. The size he grows or shrinks to is chosen from the
  rider's own body scale, not from which character is riding, so a future
  character of any size works the same way.

## 5. The cowboy hat helm

The town's headgear is clockwork:
- **At rest** it is a **cowboy hat**.
- **When its wearer rides** it shifts into a **dirt-bike helmet**: a full
  shell with a chin bar and a projecting peak visor that gives the classic
  dirt-bike silhouette.
- **The change.** The brim is a fan of overlapping segments on a ratchet, wound
  like a watch by turning the hat band. When the wearer rides, a catch
  releases the spring: the segments fan down and round into the shell, and
  the peak swings forward, with a run of clicks.
- The face opening is **punched out by Boolean subtraction**, the same
  technique as the Space Helm's visor.

Inez Villanueva makes them, and every rider in town wears one.

### As the Ground suit's helm

The Ground suit is the only suit without a helm, and its power is the dirt
bike. **The cowboy hat becomes the Ground suit's helm.**
- A Ground blorb that binds the hat wears the cowboy-hat silhouette as its
  head form, in the Ground blorbs' own body colour, as other bound helms take
  their item's shape.
- When the wearer goes into `DirtbikeMode`, the hat shifts into the dirt-bike
  helmet. When they stop riding, it shifts back. This is the same pattern as
  the Diving Helmet changing form when submerged.
- **The hat unlocks the dirt bike's full power** (user direction,
  2026-10-06). To have full access to the Ground suit's dirt bike, the hero
  must be wearing the hat, or have it bound to one of their blorbs. This
  follows the formed-suit pattern, where a helm commands its element's whole
  power (the Lava Helm, the Leaf Hat, the Penguin Helm).
  - **Without the hat:** a pair of Ground legs still gives the **rear wheel**
    from the leg power on dirt ground (`has_dirtbike_legs()`).
  - **With the hat:** the Ground **arm** power adds the **front wheel**, for
    the full **double-wheel** dirt bike and its wheelie
    (`has_dirtbike_arms()`). That arm power requires the hat, worn or bound
    to one of the hero's blorbs.
  - The check lives in the shared mode, so it applies to every character.
- **The hat is bought** (user, 2026-10-06) at Inez Villanueva's hat shop in
  town. It is not a race prize: it comes before racing, because the races need
  it. The demo world's Ground stretch, which already features the
  dirt bike, should then hand the hat out at its portal, as the Water and Ice
  stretches hand out the Nautilus Crown and the Crystal Skates, so the demo keeps full power.

### Design notes

- **The hat:** a cattleman crown with a centre crease and pinched front, and a
  brim curled up at the sides. Built from SuperEgg parts, with the brim a thin
  superellipse disc.
- **The helmet:** the same crown volume rounding into a full shell, with the
  brim drawing in and forward to become the peak visor.

## 6. Architecture (direction for the charter)

**Precedents:** the early East Texas towns of **Nacogdoches** and
**Jefferson**.
- **Nacogdoches** is Texas's oldest town. It has a brick main street and the
  Old Stone Fort, a stone trading house of the 1770s rebuilt in the 1930s.
- **Jefferson** was an 1840s–70s river port. It has brick commercial blocks
  with **cast-iron galleries** over the boardwalk, and Greek Revival and
  Victorian houses.

The town takes their **architecture** and sets it in the **desert-canyon
landscape** of the movie West. The real towns stand in green pine woods, so
this is a deliberate fusion.

- **Primary, about 75 percent: frontier commercial vernacular.**
  - Main-street buildings in frame and brick.
  - Many with a **false front**: a tall square facade hiding a gabled roof
    behind it, for a grander street face.
  - A continuous covered **boardwalk gallery** of posts and a shed roof along
    the street.
  - Hitching rails, double doors, tall narrow windows.
  - **Stone masonry** (the Old Stone Fort's precedent, and the user's earlier
    direction) on the ground storey of the sturdiest buildings: the jail, the
    assay office and bank, the saloon's side walls.
- **Secondary, about 20 percent: Greek Revival**, on the polite buildings only
  (the hotel's upper gallery, the assay office and bank, the Bells' ranch
  house). Pedimented door cases, square columns, symmetrical fronts.
  Jefferson's **cast-iron gallery** for the saloon and hotel's two-storey
  porch.
- **Accent, about 5 percent: the mechanical layer** (section 2a). It is
  visible but never dominant:
  - the livery's garage bay with its line shaft, belts and charging posts;
  - the race barn's open engines on their stands;
  - the race barn's clockwork race clock;
  - windpumps over the well, the ranch and the ore house;
  - strings of bulbs over the street, lit from the windpump's dynamo;
  - the radio mast and heliograph on the jail.
- **Palette:** weathered timber greys and browns, faded paint (oxblood, mustard,
  sage, dusty blue) on the false fronts, warm red brick, sandstone, black iron.
- **Exclusions:**
  - adobe and pueblo forms, which belonged to the earlier earth-and-stone
    concept;
  - Spanish mission churches;
  - neon;
  - decorative cogs that turn nothing;
  - screens, glowing panels and smooth sealed casings: power is shown, not
    hidden;
  - glass towers;
  - anything that makes the modern layer the main look.

### Places the town needs (for the layout)

- **Main street:** the arrival road becomes the street, with the boardwalk
  along both sides.
- **The saloon and hotel, the town's inn** (confirmed 2026-10-07): the inn is
  integrated into the saloon, on the well square at the middle of main street,
  its porch facing the road (revised 2026-10-12; see 6a): the social centre
  and the rest point.
  - Saloon below, with its bar, piano, card tables and swinging doors.
  - Hotel rooms above, with the party room.
  - A modern washroom with a porcelain toilet: the town is layered present-day,
    like Ohio, so its fixture changes from the earth closet.
- **The jail and sheriff's office**, with the wanted board.
- **The general store.**
- **The assay office and bank.**
- **The doctor's and barber's.**
- **The livery stable and garage**, with Inez's hat shop and Wes's saddlery
  beside it.
- **The race barn** and the **rodeo arena**, which is also the start and
  finish of a **race course** out across the dirt flats and canyons. This is
  where the Ground half's open dirt and the Rock half's canyons both earn their
  place.
- **The Bell ranch** and corral on the edge of town.
- **Gus's shack** on the road toward the fossil basin, with a sluice box and
  a panning trough beside it.
- **Hazel's bone camp** on the fossil basin's rim, where she can see the
  whole skeleton (added 2026-10-12):
  - a canvas wall tent and a plank work shed;
  - a dig grid of stakes and string over the nearest bones;
  - plaster-jacketed bones on pallets, sieves, and a hand-cranked sieve shaker
    on gears;
  - a drafting table under an awning, weighted with stones, with her bone
    drawings;
  - a camera on a tripod;
  - a water barrel she fills in town.
- **Della's track gear** at the race barn: a drag rake a cyborg horse pulls, a
  water cart filled from the windpump tank, and heaps of sorted clay, sand
  and crushed tip rock.
- **The mine** (added 2026-10-07), on the Rock half's canyon wall nearest
  town, reached by the mine road:
  - the **adit**: a timbered portal into the rock, with posts, a cap beam and
    a lantern;
  - **ore-cart rails** from the portal down to an **ore house**, where ore is
    sorted and loaded, by the mine road;
  - a hand **winch** and a tool shed;
  - **waste rock tips** spilling down the slope below the portal;
  - **the mine house**, Cass's home, beside the ore house.

  Ore travels down the mine road to the assay office on main street. Inside,
  the adit is a real, short tunnel the player can walk into, but the mine's
  depth and any story in it are open.

  **How to build it with this terrain (proposed 2026-10-07).** The kingdom's
  ground is a heightfield, 141 samples across 1,240 m, so about 8.9 m between
  samples. A heightfield has one height per point, so it can never hold a
  tunnel, an overhang or a crisp portal. The mine is therefore authored
  geometry, as the fishing village's islets and the Water Curtain Cave are:
  1. **The mine bluff.** A localized rock mass, about 30 × 20 m and 12 m high,
     set into the canyon wall with its base sunk below the ground. It is built
     like the Rock half's existing slab and hoodoo clusters (banded sandstone,
     the same rock props) or as a fine 1 m grid mesh. Its outer faces stay
     climbable, like the rest of the canyon.
  2. **The tunnel.** A `SolidModel` Boolean: a solid rock block with a
     superellipse tunnel volume subtracted, baked once, with trimesh collision
     from the same mesh.
     - 3 m wide and 3 m high, its floor on the ground collision layer (not the
       climbable one).
     - About 20 m long, with a gentle bend, so the end is out of sight from
       the portal.
     - Timber sets (two posts and a cap) every 2 m, the ore-cart rails, and
       electric lamps in steel cages on a cable.
     - The tunnel ends at a working face with Cass's drill and an ore cart.
       Anything deeper is open.
  3. **The ground under it.** The heightfield is lowered or excluded under the
     bluff's footprint, as the fire terrain's exclusion zones do, so no
     terrain collider pokes up through the tunnel floor.
  4. **The rest is ordinary props on the heightfield:** the timbered portal,
     the rails down to the ore house, the winch, the tool shed, the waste rock
     tips and the mine house.
  5. **Proof:** build the bluff and tunnel in isolation first, then probe them:
     - floor heights along the tunnel;
     - 2.4 m headroom;
     - no terrain inside;
     - the rails clear of the walking line.

     Render the portal from the mine road before placing it.

  **Decided (user, 2026-10-07):** build the full 20 m tunnel first and judge
  how it feels in play. (The fallback of a portal and 5 m of tunnel ending at
  a barred gate stays in reserve.)
- **The water tower and windpump** over the existing well, which stays where
  it is. Its geared head also turns the livery's line shaft and the dynamo that
  charges batteries and lights the street.
- **The stamp mill** at the ore house, under its own windpump.
- **Hitching rails** outside the saloon, the store and the jail.

### 6a. Town layout concept: a strip on a through road (2026-10-12)

**Why it changed.** The first sketch put the saloon at the head of main
street, facing down it. That makes main street a dead end, with the saloon
blocking it. A town whose culture is dirt bikes and motor horses grows along
a road that goes somewhere, as the Route 66 and highway towns of Texas did
along their roads. Traffic passes through it and stops.

**The through road.** One kingdom road links everything the town lives on.

| Section | From | To | Why people use it |
|---|---|---|---|
| **Mine road** | the town's west end (-222,100) | the Silverback mine on the canyon's east wall (about (-294,112)) | Cass, the ore carts and the miners; ore comes into town at the west end |
| **Main street** | west end (-222,100) | east end (-88,100) | the town itself |
| **Arrival road** | east end (-88,100) | the arrival shelf and the gate at the kingdom's centre | everyone arriving or leaving |
| **Basin road** | the arrival shelf | Gus's shack and Hazel's bone camp on the fossil basin's rim | Gus, Hazel, supplies out and specimens in |

Main street runs east–west across the shelf, about 8 m south of the old well
at the shelf's centre. So the well stands on the street's north side, not in
the road.
- **Carriageway:** 8 m, wide enough for two bikes or two horses to pass a
  parked rig.
- **Boardwalks:** a covered boardwalk on each side, about 3 m.
- **Total:** about 14 m between building fronts, over a length of about
  135 m.

**Order along the street, west to east.** Ore and miners come in from the
west, and travellers from the east.

| | North side | South side |
|---|---|---|
| West end, by the mine road | **General store** (Walt): miners' tools and supplies, first stop off the mine road | **Doctor's and barber's** (Hollis) |
| | **Assay office and bank** (Pearl), with **Tomás's survey room** behind: the ore wagons unload at its side yard off the back lane | a house plot (open, for the census's homes) |
| | **Jail** (Ruth), with the radio mast and heliograph, looking onto the square | — |
| Middle | **The well square**: a widening of the north boardwalk around the old well, with hitching rails and bike stands. The **saloon and hotel** fills the square's north side, its two-storey porch facing the square and the road. The gang sits on that porch watching every rider who passes, which gives arrival its dangerous edge without blocking the road. | **The water tower and windpump** opposite the square, its tank shading the street; the lane south to the Bell ranch leaves beside it |
| | — | **Saddlery** (Wes) |
| | — | **Hat shop** (Inez) |
| East end, the town's front door | the east end's north corner stays open as the view into town | **Livery and garage** (Mateo) with its **charging posts** at the kerb: the first thing an arriving rider reaches, like a filling station at a town's edge |

**Behind the street.**
- **Back lanes** run behind both rows: deliveries, the ore wagons to the
  assay yard, and the residents' yards and sheds.
- **The race barn and rodeo arena** (Lark, Della) stand south-east, behind
  the livery, reached by a side lane at the east end. The race course leaves
  the arena east and south across the flats and never uses main street.
- **The Bell ranch and corral** lie south of the shelf, down the lane by the
  water tower, with their own windpump.
- **Homes** sit above shops and on the open plots, sized in the measured
  layout.

**Why this holds together.**
- Every trade sits where its traffic arrives: the store and the assay office
  by the mine road, the livery by the arrival road.
- The saloon is on the square at the centre, where every traveller passes it
  and where the street widens to let people gather off the carriageway.
- Nothing blocks the through road, and nothing faces away from it.
- The race traffic stays off main street.

The measured layout (plots, footprints, yards and lane widths) follows when
the town brief is approved. The 68 m shelf must be checked against these
frontages then.

## 7. Landscape direction

The kingdom stays a **dirt and rock biome**, almost bare. A few desert plants,
placed sparingly, give it a cinematic movie-Western feel. The palette is the
**Chihuahuan Desert** of West Texas (see the landscaping reference
`chihuahuan_desert_flora.md`).
- **Cacti:**
  - prickly pear in low clumps;
  - a few tall cholla;
  - lechuguilla and sotol rosettes on rocky slopes.
- **Shrubs:**
  - creosote bush, spaced far apart on the dirt flats, as it grows;
  - a few mesquite in the washes.
- **Tumbleweeds:** blowing down the main street and across the flats.
- **In town:** almost nothing. A prickly pear by the jail steps, a barrel
  cactus in a half-barrel planter on the saloon gallery, a mesquite shading the
  corral.

Tumbleweeds are an introduced plant in the real Southwest, an invasive weed
from Eurasia. They are kept here on purpose because the user wants them: the
one exception the landscaping skill's botany rule allows, recorded as such.

The existing 95 scrub bushes become this palette: mostly creosote, thinly
spread.

## 8. Fixed, proposed and open

**Fixed (user direction, 2026-10-06):**
- a Western frontier town after early Texas towns such as Nacogdoches and
  Jefferson;
- the saloon as the social centre;
- a dangerous edge on arrival;
- a layered classic-and-modern "cowboy punk" culture devoted to dirt biking;
- cyborg horses that transform into dirt bikes, keeping their heads as the
  steering, with subtle cybernetic lower halves at rest, built on Manchego's
  design;
- hats that shift into dirt-bike helmets with a Boolean-cut face opening;
- a cowboy hat the player can receive and use as a helm;
- a mostly bare dirt-and-rock biome with a few cacti, shrubs and tumbleweeds.

**Fixed (user, 2026-10-07):** mining is part of the town's economy and
function, with a miner and an old prospector in a prospecting hat; the inn is
integrated into the saloon.

**Fixed (user, 2026-10-06):** no firearms. Nobody in the town carries a gun:
no holsters, gun belts, rifles on racks or shoot-outs. The Western menace comes
from horses, riders, stares and races instead.

**Fixed (user, 2026-10-12):** the look is mechanical punk and motor punk as
well as cowboy punk, with watch gears and clockwork as a fine-scale part of
it. Electric and battery power exist, since dirt bikes have
motors, but machinery is shown open, with gears in view. The details are
proposed in section 2a.

**Proposed:**
- the mechanical and motor layer in section 2a:
  - battery, wind and spring power, shown open;
  - the horses' geared legs, and their bike form's exposed motor and chain
    drive;
  - the clockwork hat;
  - the line shaft, charging posts, stamp mill, race clock, player piano,
    mechanical bull and heliograph;
- the census of twenty-one, replacing the eight rock-named residents,
  including the earth-science residents added 2026-10-12: Dr. Hazel Coleman
  (paleontologist, the bone camp), Tomás Reyes (geologist, with Pearl at the
  assay office) and Della Lusk (track boss);
- the bone camp on the fossil basin's rim, and the draft lines in 3a;
- the Silverback mine, Cass Rourke the miner, and Gus's cyborg burro;
- the Kane gang;
- Wes Tolliver the saddle maker and the shifting saddle for Manchego;
- the cowboy hat as the Ground suit's helm, shifting with `DirtbikeMode`;
- the architectural charter direction;
- the places list, laid out as a strip on the kingdom's through road (6a);
- the race course;
- the Chihuahuan palette;
- the porcelain toilet.

**Open:**
- how the hero gets the saddle;
- what the gang wants, and the town's story role;
- whether the player can ride a cyborg horse, and how;
- the kingdom's name: the user called it the Earth Kingdom and the Earth and
  Rock Kingdom, while the code and bible say Rock and Ground.
