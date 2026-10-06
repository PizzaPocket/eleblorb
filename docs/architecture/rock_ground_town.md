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

### The dangerous edge

Arriving should feel like riding into a movie Western: a wide, quiet street, a
tumbleweed rolling across it, and someone watching from the saloon gallery.
- **The gang:** a gang of riders (see the census) loiters at the saloon. Their
  horse-bikes are tied up outside, revving now and then, and they size up every
  newcomer.
- **The sheriff** is outnumbered and knows it.
- **Wanted posters** on the jail's board are pictures only, never words.

Nothing explains the tension; the player reads it. What the gang wants, and
whether the Demon King's discord is behind it, is open.

## 3. Community (proposed census, 2026-10-06)

Sixteen residents in ten households. The eight rock-named residents are
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
| **Walt Beasley** | man | the general store | storekeeper; sells everything from beans to wheel bearings |
| **Pearl Dunaway** | woman | the assay office | assayer and banker: weighs the prospectors' ore and keeps the town's money |
| **Hollis Grant** | man | the doctor's | doctor and barber, "Doc" to everyone |
| **Lark Delgado** | woman | the race barn | the town's champion rider and race marshal |
| **Gus Pickett** | man | his shack | an old prospector who has walked the fossil basin for fifty years and knows Dinosaur's bones |
| **Jessup Kane** | man | the gang | leader of the riders who hang around the saloon |
| **Dutch Raker** | man | the gang | the gang's muscle |
| **Sadie Vex** | woman | the gang | the gang's fastest rider, and Lark's rival |

### Livelihood

- **Ranching** cyborg horses: breeding, breaking, training, selling.
- **The livery and garage:** shoeing, repair, tuning.
- **Prospecting and assay:** ore and gems from the Rock half's canyons.
- **The saloon and hotel.**
- **The general store.**
- **Dirt-bike racing:** the town's passion, run from the race barn.

### Governance

Sheriff Calloway keeps the law. Town matters are argued out in the saloon,
where everyone ends up anyway.

## 4. The cyborg horses

The town's horses are cybernetic. **At rest** they are horses, and **for
racing** they transform into dirt bikes.

### At rest (horse form)

- Built on Manchego's functional design and the shared `HorseFigure` rig, in
  the town's own coat colours: duns, bays, sorrels, greys and paints.
- **Subtly visible cybernetics on the lower half:**
  - plated cannon bones;
  - metal fetlock joints;
  - hooves with a machined rim;
  - thin glowing seams where the plating meets the coat;
  - a faint panel line along the belly.

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

### Design notes

- The change is a short, mechanical sequence: plates sliding, legs folding,
  wheels spinning out. It is not a puff of smoke.
- The bike form should read as kin to the Ground suit's own dirt bike: the same
  wheel proportions and the same dirt.
- **Gameplay is open.** Can the player ride one? Do they race the gang or
  Lark? Does Manchego relate to them? Any riding must follow the traversal
  parity rule (CLAUDE.md): one shared `TraversalMode` for every playable
  character, reusing `DirtbikeMode`'s wheel dynamics for the bike form.

## 5. The cowboy hat helm

The town's headgear is advanced technology:
- **At rest** it is a **cowboy hat**.
- **When its wearer rides** it shifts into a **dirt-bike helmet**: a full
  shell with a chin bar and a projecting peak visor that gives the classic
  dirt-bike silhouette.
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

**Proposed way to get one:** the player earns it by racing. For example, Inez
gives one to whoever beats Sadie Vex, or Lark, in the town race. This is open
for the user to decide.

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
- **Accent, about 5 percent: the modern layer.** It is visible but never
  dominant:
  - the livery's garage bay with its tool racks and charging posts;
  - the race barn's timing tower;
  - strings of electric bulbs over the street;
  - a radio mast on the jail.
- **Palette:** weathered timber greys and browns, faded paint (oxblood, mustard,
  sage, dusty blue) on the false fronts, warm red brick, sandstone, black iron.
- **Exclusions:**
  - adobe and pueblo forms, which belonged to the earlier earth-and-stone
    concept;
  - Spanish mission churches;
  - neon;
  - glass towers;
  - anything that makes the modern layer the main look.

### Places the town needs (for the layout)

- **Main street:** the arrival road becomes the street, with the boardwalk
  along both sides.
- **The saloon and hotel** at the head of the street, facing down it: the
  social centre and the rest point.
  - Saloon below, with its bar, piano, card tables and swinging doors.
  - Hotel rooms above, with the party room.
  - A modern washroom with a porcelain toilet: the town is layered present-day,
    like Ohio, so its fixture changes from the earth closet.
- **The jail and sheriff's office**, with the wanted board.
- **The general store.**
- **The assay office and bank.**
- **The doctor's and barber's.**
- **The livery stable and garage**, and Inez's hat shop beside it.
- **The race barn** and the **rodeo arena**, which is also the start and
  finish of a **race course** out across the dirt flats and canyons. This is
  where the Ground half's open dirt and the Rock half's canyons both earn their
  place.
- **The Bell ranch** and corral on the edge of town.
- **Gus's shack** on the road toward the fossil basin.
- **The water tower and windmill pump** over the existing well, which stays
  where it is.
- **Hitching rails** outside the saloon, the store and the jail.

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

**Proposed:**
- the census of sixteen, replacing the eight rock-named residents;
- Dolma's inn becoming the saloon and hotel;
- the Kane gang;
- the cowboy hat as the Ground suit's helm, shifting with `DirtbikeMode`;
- earning it by racing;
- the architectural charter direction;
- the places list;
- the race course;
- the Chihuahuan palette;
- the porcelain toilet.

**Open:**
- what the gang wants, and the town's story role;
- whether the player can ride a cyborg horse, and how;
- how the hat is earned;
- whether firearms appear (the game has none yet);
- the kingdom's name: the user called it the Earth Kingdom and the Earth and
  Rock Kingdom, while the code and bible say Rock and Ground.
