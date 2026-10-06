# Crossroads Fishing Village: Architectural Design Briefs

Status: for review (2026-10-06). This is the design stage the architecture skill
requires between the program briefs (`fishing_village_buildings.md`) and any
code. Read with the style charter in `docs/style_charters.md`, the layout and
route ledger in `fishing_village_layout.md` and the people in
`fishing_village.md`. Interior briefs follow in `fishing_village_interiors.md`.
Nothing here is built until this and the interior briefs are approved.

Frame: local metres, +X east, +Z south, heights relative to the lake surface W.
A plan is described from the door in. "Front" is the face the building's
serving route reaches, taken from the route ledger.

## 1. Style audit

Every visible element, its term and its tradition. A detail must appear in at
least three buildings to count as culture.

| Element | Term | Tradition | Used by |
|---|---|---|---|
| Light frame on piles | post-and-beam on stilts | Southeast Asian stilt vernacular (primary) | all piled buildings |
| Hull with a roofed cabin | houseboat | the same vernacular afloat (primary) | the Mor and Vale houseboats, the barge |
| Hip roof, 32 degrees | hip | primary | Venn, Sen, Aran, cistern, pavilion, Mor houseboat |
| Gable roof, 32 degrees | gable | primary | slip shelter, net shed, Vale houseboat |
| Deep eave, 0.9 m | overhang | primary | all roofs |
| Pent veranda roof, 16 degrees | pent roof | primary | verandas, porches, shelters |
| Top-hung shutter propped as sunshade | awning shutter | Thai and Malay joinery (secondary) | Venn, Sen, Aran, houseboats |
| Carved ridge end and fascia | barge board | Thai and Malay joinery (secondary) | pavilion, Mor houseboat, Aran |
| Woven rattan infill panel | basket-weave panel | primary | all enclosed walls |
| Rope-bound post at every threshold | signature motif | local | all, 12 or more instances |
| Household colour on panels, shutters, ridge cap | accent | local | all |

Two traditions on a building at most: primary plus the secondary joinery on
named elements. Exclusions are in the charter.

## 2. Structural and detail rules shared by every building

- **Module.** 3.0 m bay. Posts stand on every bay line; the ring beam is at 3.3 m
  above the floor (revised from 2.9 m: see 4.2), so a veranda pent fits under the
  main eave with 2.0 m of headroom at its edge. Roof plates sit on the ring beam.
- **Floors.** Public decks W + 0.50. House floors W + 0.75, a 0.25 m ramped
  threshold above the deck, so a blorb can climb it. Houseboat decks W + 0.35.
- **Piles** are 0.3 m squarish timbers on a 3.0 m grid under the deck, braced in
  pairs below it, each with a visible cap at the deck edge. Piles stand only on a
  shelf. A pile that would stand off a shelf is not drawn; the span is carried by
  a longer beam.
- **Roof construction.** Every roof slope is `TownProps.roof_slab` with
  `build_ridge_slab` at ridges and hips: squarish shoulders, one flat cut at the
  ridge, no overlap, as in Ohio. Eave 0.9 m, ridge cap in the household colour,
  gutter along each eave falling to a downpipe and a glazed jar.
- **Openings** are superellipse openings cut from a solid wall plane with the
  piped frame and the reveal in the frame colour (`OpeningTrim`). Doors are 1.2
  by 2.4 m with a half-height lower leaf for air. Windows are superellipse with a
  top-hung shutter that props open as a sunshade.
- **Walls** are never sealed boxes. Between the posts: timber boards to 1.0 m
  (waist), woven rattan panels above, hinged shutters at windows. Interior
  partitions are full-height boards with the same framed doorways.
- **Rails.** A top rail on slender posts wherever a deck edge beside a route is
  more than 0.6 m above the water, except at swim exits and berths.
- **Rope-bound posts.** The two posts of every threshold, and every mooring post,
  have a rope wrapped in a close spiral (a SuperEgg ring stack).
- **Lights.** Lamps hang under eaves and from junction posts. No lights on poles.
- **Collision.** Every wall, floor, post, roof slab and rail is solid through
  `CollisionPolicy`; shutters, ropes, jars and trim are decorative.

## 3. Orientation rules

The brief's rule for settlements: a front door faces the way people arrive; the
service side faces outward; the veranda faces the shared water or the landing.

- Doors on the **spine side (south)** for buildings north of the spine: Venn, Sen,
  cistern, net shed.
- Doors on the **water court (west or south)** for buildings south of the spine:
  Aran (west veranda), pavilion (open on all sides, principal approach from the
  spine on its north side), houseboats (arrival deck toward their gangway).
- Service sides (stores, closets, kitchens, wash) face away from public routes:
  north to the rock, or outward to open water.
- Gangway foot ends meet a houseboat on its arrival deck, never on a cabin wall.

## 4. Building designs

### 4.1 Arrival landing and market deck

- **Plan.** Open deck 14 x 14 m at `x -42..-28, z -12..+2`. A **market shelter**
  of four posts and a pent roof, 12 x 2.4 m, along the north edge (`z -12..-9.6`),
  carrying the notice board (carved pictures only). A bench along the south rail
  facing the shore view west. Ferry berth west edge, skiff berth north-west,
  swim exit 1 south edge.
- **Section.** Deck W + 0.50, piles on the arrival-foot shelf and the Anvil south
  shelf, rail along the south and west edges except at the berths.
- **Openings and facing.** The shelter's open face and the notice board face
  south onto the deck. The Venn veranda opens off the deck's north edge at
  `(-30, -12)`.
- **Roof.** Pent, 16 degrees, falling north away from the deck.

### 4.2 Venn house and lake shop (Nara, Mateo, Lio)

**Built (2026-10-06)** in `FishingBuildings.venn_house()` from the shared
`StiltKit`, proved in isolation by `tools/fishing_building_proof.tscn` (0 FAIL:
collision pairing, clear zones, lanes, stacking, every pile on a shelf) and placed
in the village by `FloatingVillage`. The first brief did not survive its own
drawings; the revisions below are what was built, and why.

- **Plan.** Footprint `x -34..-25, z -20..-12` (9 x 8; the plan rect grew 1 m so
  the house reaches the landing). Main house 9 x 4.5 m (`z -20..-15.5`), three
  3 m bays under one hip roof, floor W + 0.75:
  - **Lio's room** (west bay, 3 x 4.5): his bed head to the north wall, his lamp
    hung in the west window, a rack of practice knots, his shells graded on a
    shelf.
  - **Living room and kitchen** (middle bay, 3 x 4.5): the front door; a clay
    brazier with a hood and a flue in the north-east corner; a low table with
    cushions; crockery shelves; the rope chest.
  - **Nara and Mateo's room** (east bay, 3 x 4.5): bed head to the north wall
    under its window, sea chest at the foot with its hinge to the bed, oilskins
    on pegs, the hammock on its rail.
  - **Shop veranda** 9 x 2.5 m (`z -15.5..-13`) under a pent. Its west part holds
    the **counter** between the two west posts, facing the landing; its east bay
    is the enclosed **dive-gear store** (3 x 2.5), entered from the veranda, with
    the suits' drying rack, helmets on a shelf and the bench where Mateo builds
    the housings.
  - **Threshold ramp** 6 x 1 m (`z -13..-12`) from the landing's deck (W + 0.50)
    up to the veranda (W + 0.75), across the landing's width of the frontage.
- **Why it changed from the first brief.**
  - *Lio's loft is gone.* A 32 degree hip over a 4.5 m deep house rises only
    1.4 m above the plate, and a 32 degree ramp up to a loft needs about 6.7 m with
    its landings, more than the house is long. The program changed; the minimums
    did not. Lio has the west bay as his room.
  - *The counter moved west and the store moved onto the veranda.* The arrival
    landing reaches only to plan `x -28`, so a counter in the east half would have
    faced open water. The store now opens off the veranda, beside the counter where
    the helmets are sold. Mateo reaches the slip from the landing's north-west
    corner, so the store needs no west door and the brief's west spur is dropped.
  - *The footprint stopped 1 m short of the landing.* The threshold ramp joins
    them, and the plan rect now includes it.
  - *The ring beam is 3.3 m, not 2.9 m.* With a 2.9 m plate the veranda pent,
    tucked under the hip's eave, left 1.9 m of headroom at the veranda edge. At
    3.3 m the pent leaves the wall at 2.75 m and keeps 2.03 m at the edge, with an
    11 cm gap under the hip's eave. The charter's module is amended to match.
- **Section.** Piles 0.3 m square on the 3 m grid (`x` at the four bay lines,
  `z -20, -17.75, -15.5, -13`), 16 in all, braced in pairs, capped under floor
  beams; plank floor W + 0.75; boards to 1.0 m, teal panels above, a dado rail;
  flat plank ceiling at the plate, roof space vented at the ridge.
- **Doors.** Front door south, centred in the living room. Lio's and the bedroom
  doors in the bay-line partitions near the front, each swinging into its room.
  The store door swings into the store. (Exterior doors open outward throughout
  the world, so the front door's leaf stands open on the veranda; the way to the
  store passes south of it.)
- **Openings.** North wall: three windows, one per room. West: Lio's window with
  his lamp. East: the bedroom's second window. South: Lio's window onto the
  veranda behind the counter. All narrow casements with ochre shutters.
- **Roof.** Hip, 32 degrees, eaves 0.9 m, ridge east to west with a teal cap;
  pent 16 degrees over the veranda, gutter along its eave to a downpipe and a
  green glazed jar on the landing beside the counter's end.
- **Colour and history.** Teal panels, ochre shutters. The veranda was added when
  Nara took over the trade: its posts are paler, ochre-washed timber, and the two
  either side of the way up from the landing are rope-bound.
- **Remaining.** In-engine walkthrough at eye level with the human, Blorbus and
  Xiao Hou Zi (the proof is isolated; the probe confirms the floors and ramp in
  the world).

### 4.3 Boatwright slip (Mateo)

- **Plan.** `x -46..-40, z -22..-13`. A **tool shelter** 6 x 4 m under a gable
  (`z -22..-18`), timber racks along its back wall, open to the slip. The slip
  itself 4 m wide and 12 m long runs west into the water from the shelter's west
  face with timber rollers; one boat on it.
- **Doors and facing.** The shelter is open to the south and west; the work spur
  from the Venn yard `(-34, -17)` arrives at its east side.
- **Roof.** Gable, ridge east to west, the only gable on the west side.
- **Colour.** Natural timber, sawdust on the deck.

- **Built (2026-10-07)** in `FishingBuildings.boatwright_slip()`. The brief's
  slip ran 12 m west out of a footprint that ends at `x -46`, and gave no way to
  it. As built: the tool shelter `x -46..-40, z -22..-18` under a gable, open
  south and west, no post in its 6 m front opening; a work apron
  `x -42..-40, z -18..-12` joined to the arrival landing by a 1 m bridge; the
  slipway, 4 m wide, from the apron's edge at deck height down 6 m into the slip
  lane on rollers, where the repair boat is hauled up. The north row of piles
  stands just inside the shelf's edge at `z -22`.

### 4.4 Sen house, clinic and school room (Asha, Rian)

**Redrawn (2026-10-06).** The first brief failed its own plan in two ways:
- **The clinic door was in the wrong bay.** It was centred at `x -15`, which
  falls in the middle bay (the school room), while the clinic was the east bay.
- **The family had no private way in.** The sleeping rooms were reached only
  through the clinic or the school room, so Asha and Rian walked through
  patients and pupils to reach their beds.

The redraw keeps the footprint, the porch and the spur, and sorts the house by
a privacy gradient: public rooms on the porch, a private corridor behind them,
and the family's rooms at the back.

- **Footprint.** `x -20..-11, z -20..-10` (9 × 10), unchanged.
  - The main range now takes the full depth behind the porch: 9 × 8 m
    (`z -20..-12`) under one hip roof.
  - The old rear service strip is absorbed; the rock face lies close behind,
    so it served nothing.
  - **Porch** 9 × 2 m (`z -12..-10`) under a pent, floor W + 0.75, reached by the
    Sen spur at `(-15, -10)`. It is the clinic's waiting place, and the bench
    for the queue stands at its east end.
- **Bays.** West `x -20..-17`, middle `x -17..-14`, east `x -14..-11`.
- **Rows.**
  - front row, the public rooms: `z -15.6..-12` (3.6 m);
  - private corridor: `z -17..-15.6` (1.4 m);
  - back row, the private rooms: `z -20..-17` (3.0 m).

| Room | Bay and row | Size | Door |
|---|---|---|---|
| **Family entry and records room** | west, front | 3 × 3.6 | the **family door** from the porch at `x -18.5`, the house's private entrance; an open archway north into the corridor; a leaf door east into the clinic, so Asha reaches her records while treating |
| **Clinic** | middle, front | 3 × 3.6 | the **clinic door** from the porch, centred at `x -15.5`, straight off the spur's end; knot-carved; a leaf door east into the school room |
| **School room** | east, front | 3 × 3.6 | its own door from the porch at `x -12.5`, so pupils never pass through the clinic |
| **Private corridor** | full width | 9 × 1.4 | from the family archway; no door into the clinic or school room |
| **Asha's room** | west, back | 3 × 3.0 | from the corridor |
| **Rian's room** | middle, back | 3 × 3.0 | from the corridor |
| **Kitchen and wash** | east, back | 3 × 3.0 | from the corridor; a clay brazier with a hood and a flue through the hip, a water jar, a wash basin, the woodbox |

- **Routes.**
  - A patient goes spur → porch → clinic.
  - A pupil goes porch → school room.
  - Asha and Rian go porch → family door → corridor → their rooms, without
    entering either public room.
  - Asha moves between the records, the clinic and the school room by the two
    connecting doors, which stay shut when a patient wants privacy.
- **Doors** swing into the rooms they serve. The corridor's doors open into
  the bedrooms and the kitchen, never into the corridor.
- **Windows.**
  - Front rooms: south onto the porch, the clinic's beside its door and the
    school room's facing the water court.
  - Back rooms: north, one each.
  - East end: one window, in the kitchen.
- **Section and roof.** Floor W + 0.75; ring beam 3.3 m; partitions full height
  to a flat plank ceiling at the plate. A hip over the 9 × 8 m range rises about
  2.5 m to a short east–west ridge. A 16° pent over the porch, tucked under the
  hip's eave as on the Venn house. The flue rises through the hip's east slope.
- **Piles.** On the 3 m grid at `x -20, -17, -14, -11` and
  `z -20, -17, -15.6, -12, -10`. The corridor line takes a beam rather than a
  pile row where a pile would fall off the shelf.
- **Colour and history.** Violet panels, cream shutters. Built new when Asha
  and Rian stayed after the storm season; the porch was added later for the
  clinic queue, its posts paler.

- **Built (2026-10-07)** in `FishingBuildings.sen_house()`, proved in isolation
  (0 FAIL) and placed in the village. Three positions moved so every frame
  clears its neighbour:
  - the clinic door to `x -15.95` (at `-15.5` its frame touched the clinic
    window's);
  - the school door to `x -12.0` (at `-12.5` the school room's south window
    had no room between the partition and the door);
  - the porch ramp centred on the clinic door, 2.6 m wide, so it lands on the
    spur's end and passes between the two rope-bound posts.
  Every door in the village now swings inward, into the room it serves
  (`StiltKit.door`): with an outward leaf the clinic door would have filled the
  2 m porch in front of the ramp. The Venn front door became a pair of narrow
  leaves for the same reason inside its 3 m living room.

### 4.5 Rian's shell-works barge

- **Plan.** A floating barge 8 x 3.5 m at `x -20..-12, z -3..0.5`: open work
  deck under a lean-to roof, a bench along the north side with the saw and
  sealing press, shell bins, a small stowage chest, rope coils. Moored on four
  lines to the spine's south piles; a gangway from the spine at `(-15, -5..-3)`.
- **Facing.** Open to the south (light for fine work and the water court).
- **Roof.** Pent, 16 degrees, falling south. Colour violet and cream.

- **Built (2026-10-07)** in `FishingBuildings.shell_barge()`. Until now the
  plan's gangway led to nothing: the builder had no case for a `barge`. The
  lean-to over the north half rises to 2.9 m so its south eave still clears
  2.0 m; the bench breaks where the gangway lands.

### 4.6 Cistern house and shared stores (village; Leena keeps the stores)

- **Plan.** Footprint `x -6..2, z -20..-12` (8 x 8). The house 6 x 6 m at the
  rear against Anvil Rock's foot (`z -20..-14`), the covered cistern and the seep's
  stone channel behind it (a masonry footing 0.6 m high at the rock). A tap and
  bucket ledge on a 2 x 2 m apron at the front (`z -14..-12`). Stores room 6 x 6
  with shelves along three walls.
- **Doors.** One public door south at `x -2` meeting the Cistern spur. A rear hatch
  onto the cistern for cleaning.
- **Roof.** Hip, with a gutter on every face into the cistern. Natural timber,
  green ridge. The base is always damp, with moss on the footing.

- **Built (2026-10-07)** in `FishingBuildings.cistern_house()`. The brief put the
  cistern "behind" a house that already ran to `z -20`, where Anvil Rock's sheer
  face stands at about `z -20.5` (`tools/fishing_rock_section.gd` prints the real
  heights). Resolved in section: the **stone tank** 6 × 1.5 m stands on the shelf
  at `z -20..-18.5` against the rock foot, mossed at the waterline, under a plank
  lid, fed by the seep's stone channel from the face and by the north gutter; the
  **stores house** is 6 × 5 m (`x -5..1, z -18.4..-13.4`), one room with shelves on
  three walls, a north hatch over the tank lid, one south door between two
  rope-bound posts. The brief's 2 × 2 apron became a 3.6 m threshold ramp to the
  spur, with the tap and bucket ledge on the wall above its east part, piped
  round from the tank. Leena's bead ledger and evening stool are by the door.

### 4.7 Net shed (Salim, shared with Jori)

- **Plan.** Footprint `x 4..12, z -20..-12` (8 x 8). Open-sided 6 x 6 m under a
  high gable, with a floored **loft** 2 m wide along the north side reached by a
  ladder-ramp, for traps and floats. Nets hang from the rafters inside like
  curtains.
- **Doors and facing.** Open on three sides; the main face south to the spine at
  `x 8`.
- **Roof.** Gable, ridge east to west, the tallest on the spine (ridge 7.4 m).

- **Built (2026-10-07)** in `FishingBuildings.net_shed()`. The deck fills the
  8 × 8 footprint at public deck height, flush with the spur, so carts and blorbs
  roll in. The shed is 6 × 6 m with posts 4.8 m to the plate (ridge about W + 7.3);
  no post stands in the 6 m front opening, which a deeper beam spans. The loft
  is 2 m deep along the north at 2.6 m, reached by a 32 degree ramp up the west
  side whose foot lands on the front deck. Nets hang from the rafters to 2.2 m
  above the floor, so every route keeps its headroom.

### 4.8 Communal pavilion (Leena)

- **Plan.** Footprint `x -8..4, z -4..4` (12 x 8). Open-sided, four bays by two,
  12 x 6 m, a large hip roof with a raised ridge vent, long tables on the
  north half, a repair bench at the east end, a bell on a post at the south-east
  corner.
- **Facing.** The principal approach is from the spine on the north side; the south
  edge opens onto the water court and swim exit 2.
- **Roof.** Hip over the whole span, natural timber with green ridge and fascia,
  carved ridge ends (the village's centre).

- **Built (2026-10-07)** in `FishingBuildings.pavilion()`. Two corrections:
  - **It had no way in from the spine.** The plan diagram shows a link from the
    spine down to the pavilion on the cistern's line, but neither the route table
    nor `FishingVillagePlan` had it, so the pavilion was reachable only from its
    west end. `PavilionSpur` (3.6 m, `(-2,-7) → (-2,-4)`) is now in both.
  - **Posts on the through-way.** The `x 0` bay line put three posts on the
    straight way from the spur to swim exit 2; they are dropped, and the edge and
    ridge beams span 6 m between the rope-bound posts at `x -3` and `3`.
  The hall is open on every side with the long tables on the north half either
  side of the through-way, the stove in the north-west corner with its flue up
  through the hip, the repair bench at the east end, the bell on the south-east
  post, rain jars in the corners, lamps under the ridge, household mugs on their
  pegs and the height marks on a post. The raised ridge vent rides the ridge on
  short posts, with carved curls at the ridge ends.

### 4.9 Aran house and pearl yard (Mai, Salim, Dala, Pree)

- **Plan.** Footprint `x 6..14, z -3..5` (8 x 8). House 6 x 6 m, two bays, hip
  roof, with a deep **veranda** 2.5 m wide on the west face facing the water court
  where Dala reads the weather. Rooms: living room 3 x 3 (west, onto the veranda);
  kitchen 3 x 3 on the service side (east); Mai and Salim's room 3 x 3 (north);
  Dala's room 3 x 3 nearest the veranda (south-west); Pree's corner under the stair.
- **Wet stair.** A broad stair-ramp from the south side down to the pearl yard
  pontoon.
- **Doors.** The Aran spur arrives at the north-west corner; its public door opens
  from the west veranda, which wraps around that corner. A wet door on the south
  to the stair.
- **Roof.** Hip, mixed-age boards, ochre panels, green shutters, Pree's herb floats
  moored at the veranda.
- **History.** The oldest house, on Dala's generation's first piles, repaired many
  times.

- **Built (2026-10-07)** in `FishingBuildings.aran_house()`, redrawn because the
  brief's four 3 × 3 rooms in a 6 × 6 square left the kitchen diagonal to the
  living room (reached only through a bedroom), and "Pree's corner under the
  stair" had no stair:
  - The house is 6 × 8 m (`x 8..14, z -3..5`), ridge north to south, in three
    rows: **Mai and Salim** (north-west) and **Pree** (north-east, her own small
    room); the **living room** across the whole middle, which the veranda door
    opens into and every room opens off; **Dala's room** (south-west, nearest the
    veranda, a window onto the water, her chair for watching at night) and the
    **kitchen** (south-east).
  - The veranda is 2 m deep, not 2.5: the footprint allows no more. A threshold
    ramp meets the Aran spur at its north end; Dala's worn chair stands at the
    rail with the shell barometer and the weather bell; Pree's herb floats are
    tied below it.
  - The kitchen's **wet door** is on the south wall at `x 12`, west of the
    living-room door's line, so the two leaves leave a way between them; a ramp
    runs from it down to the pearl yard pontoon.

### 4.10 Pearl yard pontoon (Mai)

- **Plan.** A floating pontoon 10 x 5 m at `x 6..16, z 5..10`: clean grading
  tables under a light shade canopy, basket racks and a fresh-water rinse jar.
  Moored to the Aran piles; the wet stair meets it.

- **Dressed (2026-10-07)** by `FishingBuildings.dress("PearlYard")`: three
  grading tables under a cloth shade on four posts, trays, scale and magnifier,
  basket racks of mussels on the east, the rinse jar, a drying frame for shell,
  Mai's covered tray. The Aran wet ramp's landing (`x 11..13, z 5..6.5`) is
  kept clear.

### 4.11 Vale family houseboat (Jori, Osei, Tavi)

- **Plan.** A floating hull 14 x 7 m at `x 26..40, z -10..-3`, deck W + 0.35. From
  west to east: **arrival deck** 3 x 5 m under a pent roof (receives the gangway
  at `(27, -5)`); **living room and galley** 4 x 4 m; **Jori and Osei's cabin**
  3 x 3 m; **Tavi's cabin** 2.5 x 3 m with his cork floats; **work deck** 4 x 5 m
  open to the east for floats, ropes and a gear store 2 x 2 m. Cabin width 4 m with
  a 1.5 m side walkway on the south and 1 m on the north.
- **Doors.** Arrival door west into the living room; a rear door east from the
  galley onto the work deck; the CatchGangway leaves the work deck's south-east
  corner `(38, -3)`.
- **Roof.** Gable over the cabins, ridge east to west, so smoke from the catch
  deck slides past. Coral red panels, natural shutters, cork floats drying on the
  rails.

- **Built (2026-10-07)** in `FishingBuildings.vale_houseboat()`. The brief's
  rooms added up to 16.5 m in a 14 m hull. As built, west to east: a 2.5 m
  covered arrival deck under a pent (the gangway lands on it); the living room
  and galley (3.5 m, brazier in the north-west corner, its rear door onto the
  1.5 m south walkway that leads to the work deck); Jori and Osei's cabin (north)
  and Tavi's (south) side by side, 4 m long, each off the living room; the open
  work deck (4 m) with the 2 × 2 gear store at its north-east, floats drying on
  the east rail, and the catch gangway leaving its south-east corner. A gable
  over the cabins, ridge east to west.

### 4.12 Catch deck, drying shelter and smokehouse (Osei)

- **Plan.** `x 36..44, z 2..14` on the Heron east shelf: a sorting table and rinse
  trough at the berth edge; a **drying shelter** 5 x 5 m with screened slatted
  sides and a pent roof on the north half; a **smokehouse** 3 x 3 m with a stone
  hearth and a short flue at the downwind (east) end. The only fire in the village.
- **Berth.** The working boat's berth east of the deck on the working-boat lane.
- **Colour.** Natural timber, smoke-darkened.

- **Built (2026-10-07)** in `FishingBuildings.catch_deck()`. Heron Rock's face
  stands at about `x 35.5`, just clear of the deck. The catch gangway lands at the
  north-west corner, so the slatted drying shelter takes the north-east
  (`x 39..44, z 2..7`), its screens on the north and east, open to the deck; the
  sorting table and rinse trough stand at the working boat's berth on the east
  edge; the smokehouse (`x 41..44, z 11..14`), a closed hut of smoke-dark boards
  with its door to the west, holds the stone hearth under a short flue and the
  board with the recipe cut in symbols.

### 4.13 Mor guest houseboat (Leena, Ivo, Sela)

- **Plan.** A floating hull 18 x 7 m at `x -26..-8, z 8..15`, deck W + 0.35. From
  west to east along the 15 m cabin and decks:
  - **Covered arrival deck** `x -26..-22`, receives the gangway at `(-22, 8)`.
  - **Common cabin and galley** `x -22..-17` (5 x 5): Leena receives guests, serves
    meals; the dry pantry and galley in its east third with a service door through
    to the cargo deck by the north walkway.
  - **Central party dormitory** `x -17..-12` (5 x 5): four beds, the wake marker
    beside the first.
  - **Two guest cabins** `x -12..-10`, each 2 x 2.4, off a passage from the dormitory.
  - **Stern cabin** of the Mor family, `x -10..-8`, behind a closing door, on the
    north side.
  - **Cargo deck** at the east end, open, with the cargo gangway; a contained marine
    composting toilet and wash space against the outer service wall on the south
    walkway.
- **Roof.** One long hip over the cabins at 32 degrees with eaves 0.9 m deep over the
  1 m walkways, ridge vent, carved ridge ends. Terracotta panels, teal trim and
  shutters, mooring lines at the posts.
- **Section.** Hull below the waterline, shallow draft, collision on the deck and
  the cabin walls so the rest point and gathering area stay aboard.

- **Built (2026-10-07)** in `FishingBuildings.mor_houseboat()`, the rest point
  wired by `FloatingVillage._wire_rest_point()`. The brief's program did not fit
  its own 18 m hull (two guest cabins, a stern cabin and a cargo deck after
  15 m of other rooms) and landed the gangway on the line between two rooms.
  As built, west to east: covered **arrival deck** (3.5 m; the gangway now lands
  at its middle, `x -23.5`), **common cabin and galley** (5.5 m; Leena stands by
  the door), **party dormitory** (4.5 m; four bunks along the hull sides, the
  wake marker by the first), then the Mor **stern cabin** (north, entered from
  the north walkway so the family never crosses the guests' rooms) beside the
  **wash room** with the marine composting toilet, basin, water jar and vent
  stack (south, entered from the dormitory), and the open **cargo deck**. The
  guest cabins are dropped and the south walkway given to the cabins, so they
  are 6 m deep. One long hip covers it all. The earlier placeholder built Leena
  and the rest point on every houseboat; she now exists once.

### 4.14 Ivo's ferry launch

- **Plan.** A roofed cargo launch 6 x 1.8 m at the ferry berth: a forward cargo well
  (open, crates and sacks), a small cab 2 x 1.5 m amidships with a pent roof, a
  stern engine bay. Terracotta hull, teal trim, a lamp on the cab.

- **Built (2026-10-07)** by `FishingBuildings.ferry_launch()` at the ferry
  berth, at true size: terracotta hull, teal sheer, a forward well of crates in
  household colours, the cab under a pent with its lamp lit, the engine box aft.

### 4.15 Ocean portal landing (public)

- **Plan.** `x 26..35, z 16..24` against Heron Rock's south face: the gate on a
  low 0.2 m step facing north-west, 3 m of clear deck behind it, swim exit 3 on the
  south edge, lamps hung from two corner posts. The only deck without a roof.

### 4.16 Heron landing

- **Plan.** `x 18..24, z -3..3`, 6 x 6 m, where the spine ends and the gangway to
  the Vale houseboat and the spur to the portal leave. A bench, a mooring post
  and Jori's first-watch lamp.

- **Landings dressed (2026-10-07)** by `FishingBuildings.dress()` on the plan's
  decks. The arrival market shelter is narrowed to `x -39.6..-34.6` so it neither
  blocks the slip's bridge nor the Venn shop frontage. Lights everywhere are oil
  lamps on rope-bound junction posts (`StiltKit.lamp_post`), five along the spine
  at the spur junctions; the earlier post lanterns were "lights on poles", which
  the charter excludes.

### 4.17 Swim exits (three)

Each 3.4 m wide, timber-planked with cross battens, rails both sides above the
water, upper end flush with its deck, lower end at the derived height
(`W - float depth - 0.10`) at 8.5 m run.

## 5. Variation matrix

| Building | Plan | Roof | Veranda | Colour | Mark |
|---|---|---|---|---|---|
| Venn house | square plus veranda | hip | shop veranda | teal | counter, loft lamp |
| Slip shelter | open shed | gable | none | natural | rollers, sawdust |
| Sen house | deep range, public front and private back | hip | porch with three doors | violet | knot-carved clinic door |
| Rian's barge | open barge | pent | none | violet | saw and press |
| Cistern house | square on rock | hip | tap apron | natural | wet footing |
| Net shed | open | high gable | none | natural | hanging nets |
| Pavilion | open | large hip, vent | none | natural and green | bell post |
| Aran house | square | hip | deep west veranda | ochre | mixed boards, herb floats |
| Vale houseboat | long hull | gable | arrival and work deck | coral red | floats on rails |
| Mor houseboat | long hull | long hip | covered arrival deck | terracotta | mooring lines |
| Ivo's launch | boat | pent cab | none | terracotta | cab lamp |

No two neighbours share more than half their axes.

## 6. Islets: not buildings

Anvil Rock and Heron Rock are **terrain-grade meshes**, not SuperEgg props: a
heightfield on a 1 m grid over each islet's footprint (karst: sheer faces, undercut
notch at the waterline, ledges, a flat crown), built with the terrain's own method
and trimesh collision with backface collision on, its shelf a flat 3.2 m below
the surface with the sheer drop beyond. The village stands against them; no
building terraces the rock into plots.

## 7. Open questions

None blocking. Ratify the floating households (section 0 of
`fishing_village_buildings.md`) with the layout amendments.
