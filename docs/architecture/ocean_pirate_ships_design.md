# The Pirate Ships: Architecture, Decks and Crew Programs

Status: design brief for review (2026-10-06). Read with `ocean_pirate_ships.md`
(the crews, origins and dress). This document designs each ship as a building
that moves: its type, decks, rooms, who uses them, and how the hero moves
through them, including below the waterline.

## 1. Survey

From `ocean_kingdom_denizens.gd`:

- One ship exists: an `AnimatableBody3D` following an elliptical route. Its hull
  is a single solid box 11 × 3.2 × 29 m whose **bottom sits at the waterline**:
  the ship has no draft and no interior. A deck slab, a raised helm deck aft
  (+6.8 m), three masts with sails, a wheel, lanterns, side stairs from the
  water to the deck, and eight crew wandering two lanes.
- The second ship is missing.

### How water works today (and why below-deck needs new work)

`LiquidEnvironment.read()` decides whether a body is in water from its
horizontal position alone: in the Ocean Kingdom every point is water, and a
body below the surface height (0 m) is submerged. The ocean surface is a flat
mesh drawn everywhere. The terrain decides the underwater view. So today, a
body on a deck below the waterline would:

1. be treated as swimming, because its feet are under the surface;
2. see the ocean's surface sheet cutting across the room;
3. get the underwater fog and tint when the camera dips below 0 m.

Section 6 fixes all three with one shared system.

## 2. Real ships behind the design

### The *Harbinger*: a ship-rigged sloop-of-war

A British naval sloop-of-war, ship-rigged on three masts: the smallest naval
vessel with a frigate's layout, about 30 to 33 m on the gun deck with a beam of
about 8.5 m. Its organisation follows naval practice:

- **Weather deck:** forecastle at the bow (ship's bell, heads, anchors), the
  waist amidships (ship's boat stowed on the booms, main hatch, capstan) and the
  quarterdeck aft (wheel, binnacle, the captain's post).
- **Gun deck:** the guns along both sides; the captain's great cabin aft behind
  the stern windows; the galley stove forward; mess tables slung between the
  guns.
- **Berth deck:** hammocks for the crew forward; small cabins for the officers
  aft around a common room (the wardroom); the surgeon's space.
- **Hold:** water casks, food, cables, spare sails and timber, and the powder
  magazine, lined and kept far from any fire.

### The *Belle Fortune*: a captured Dutch fluyt

A Dutch **fluyt**, the merchant ship of the seventeenth century: round-bellied
with a pronounced tumblehome (the sides curve inward so the deck is much
narrower than the hull), a narrow, tall, rounded stern, a large hold, and
famously able to sail with a small crew. Buccaneers commonly took and kept
merchant ships like it. This replaces the earlier "galleon": a fluyt matches
the brief's broad, round-bellied hull and tall stern, explains how a small
crew handles it, and fits its Dutch navigator.

- **Weather deck:** a short forecastle with the galley; the narrow open waist
  crowded with lashed cargo and the boat; the tall sterncastle aft in two
  tiers.
- **Sterncastle:** the great cabin (the crew's council room, with the articles
  nailed up and the dice table), and above it the captain's small cabin and the
  poop deck with the wheel.
- **Lower deck:** guns cut in later, unevenly; hammocks wherever there is room.
- **Hold:** the fluyt's great hold, now full of plunder in heaps, water casks
  and powder.

## 3. Crews sized to the ships

A three-masted ship cannot be worked by eight. Real fluyts sailed with as few
as twelve to fifteen; a naval sloop needed far more to fight but could be
sailed short-handed by a dozen or so. Each ship therefore carries **twelve**
named crew. Privateers and pirates often sailed short-handed after losses, and
both crews say so.

**New aboard the *Harbinger*** (British): boatswain **Silas Thorne** (man),
cook **Eben Marsh** (man), sailmaker **Hester Lane** (woman) and coxswain
**Josiah Penn** (man), who handles the ship's boat.

**New aboard the *Belle Fortune***: carpenter **Gaspard Ferrand** (man, French),
surgeon **Henri Dufour** (man, French), lookout **Inês Prado** (woman,
Portuguese) and able seaman **Jacob de Wit** (man, Dutch).

## 4. Game scale

Real ships had 1.5 to 1.8 m between decks, too low for the game. Every deck the
hero walks keeps at least **2.4 m** clear headroom (the architecture skill's
minimum is 2.0 m; beams take the rest), and both ships grow about a third over
their real sizes to keep the proportions right.

| | *Harbinger* | *Belle Fortune* |
|---|---|---|
| Length on deck | 42 m | 38 m |
| Beam (widest) | 11.5 m | 10 m at the waterline, narrowing to 7 m at the weather deck |
| Draft (below waterline) | 5.0 m | 4.2 m |
| Masts | three, square-rigged | three, square-rigged with a lateen mizzen |

### Levels (metres relative to the waterline)

| Level | *Harbinger* | *Belle Fortune* |
|---|---|---|
| Hold floor | -4.4 | -3.6 |
| Lower living deck | berth deck, floor -1.6 (straddles the waterline) | lower deck, floor -0.6 (straddles the waterline) |
| Main deck | gun deck, floor +1.4 | weather deck, floor +2.4 |
| Weather deck | spar deck, floor +4.4 | — |
| Raised aft deck | quarterdeck, +7.2, over a chart room (the coach) at spar-deck level | great cabin floor +2.4; captain's cabin and poop deck, +5.2 |
| Forecastle | +7.2, over a boatswain's store at spar-deck level | +5.2, over the galley at weather-deck level |

Every deck height leaves at least 2.4 m clear under the deck above. Everything
below 0 m is inside the hull and must stay dry (section 6).

**Audit (2026-10-07).**

- **Headroom.** The *Harbinger*'s quarterdeck and forecastle stood at +7.0 m,
  only 2.6 m above the spar deck. With a deck about 0.25 m thick, that left
  2.35 m clear in the coach and the boatswain's store, under the 2.4 m
  minimum. Both now stand at **+7.2 m**. Every other step is 2.8 to 3.0 m,
  floor to floor, and clears.
- **Rooms against the hull.**
  - *Harbinger* gun deck, inside about 38 m of usable length: the great cabin
    (about 8 m), the battery of four guns a side at about 3 m spacing (about
    14 m), the galley (about 5 m), and two companion ramps (about 7 m each with
    landings, laid fore and aft beside the centreline). That is about 41 m
    including the ramps, so the ramps stand beside the battery, not in line
    with it.
  - *Harbinger* berth deck: the wardroom's three officer cabins (about
    2.5 × 2.5 m each round a 3 m table) and the surgery fit within the aft
    10 m.
  - *Belle Fortune*: the great cabin as council room (about 8 × 6 m) fits the
    7 m weather-deck beam only if it narrows with the tumblehome. Draw it 8 m
    long and 5.5 m wide at its floor, its windows on the stern.
- **Ramps.** A deck pair 3.0 m apart needs about 4.8 m of 32° ramp plus two
  1.2 m landings (about 7.2 m) for each companion ramp. Draw them before the
  rooms.
- **Drawn (2026-10-13):** every deck plan at true size; see section 9. As
  expected, the first drawing failed the hull at both ends of both ships.

## 5. Rooms and who uses them

### *Harbinger* (twelve crew)

| Level | Space | Program | Who |
|---|---|---|---|
| Quarterdeck | wheel, binnacle | steering and command | Brine at the wheel; Old Kelp beside him |
| Spar deck, aft | the coach, under the quarterdeck | chart room | Old Kelp |
| Forecastle | forecastle deck and the boatswain's store beneath | ship's bell, anchors, heads at the bow, rope and blocks | Silas Thorne |
| Spar deck, waist | open waist | capstan, main hatch, the ship's boat on its booms | Josiah Penn; the watch on duty |
| Masthead | foremast top | lookout platform reached by the shrouds | Nell Crow |
| Gun deck, aft | great cabin | day cabin behind the stern windows with the chart table and logbook; sleeping cabin | Brine |
| Gun deck, amidships | the battery | eight guns, mess tables between them where the crew eat | Rook Gale keeps the guns |
| Gun deck, forward | galley | iron stove with a flue through the deck, water butt, provision locker | Eben Marsh |
| Berth deck, forward | crew berth | hammocks in rows, sea chests | the crew |
| Berth deck, aft | wardroom and cabins | small cabins for Mara Reef, Old Kelp and Ada Shoal round a shared table | officers |
| Berth deck, aft corner | surgery | a cot, a chest of instruments, a lamp | Ada Shoal |
| Berth deck, side | carpenter's walk and store | timber, plugs, tools | Tobias Wake |
| Berth deck, side | sail room | spare canvas, palm and needles | Hester Lane |
| Hold | stores | water casks, food, cables, spare spars | Pip Salt fetches |
| Hold, forward | magazine | powder in a lined, lamp-free room | Rook Gale only |

### *Belle Fortune* (twelve crew)

| Level | Space | Program | Who |
|---|---|---|---|
| Poop deck | wheel | steering | Souci, elected, at the wheel |
| Sterncastle upper tier | captain's cabin | small; the captain's chest and hammock | Souci |
| Sterncastle lower tier | great cabin (council room) | the articles nailed to the bulkhead, a long table for votes, dice and shares; Anneke's charts | everyone; Bastien Roux keeps the ledger |
| Weather deck, under the forecastle | galley | stove, hanging pots, Teo's stores | Teo Abad |
| Weather deck, waist | open waist | lashed cargo, the boat, the main hatch | Yaw Mensah runs the deck |
| Masthead | lookout | | Inês Prado |
| Lower deck | crew quarters and guns | hammocks anywhere, six guns cut in unevenly, sea chests painted every colour | the crew; Bridget Nolan's guns |
| Lower deck, aft | sickbay | a hammock, a sea chest of remedies | Henri Dufour |
| Lower deck, side | carpenter's corner and sail locker | timber and canvas | Gaspard Ferrand, Sami Haddad |
| Hold | plunder and stores | heaps of plunder, water casks, the powder room behind a door | Jacob de Wit; Moineau fetches |

## 6. Water below deck: one shared "dry volume" system

The fix serves the ships, the sea folk's air halls and glass tunnels, and any
later hull, through one interface.

1. **Dry volumes.** A ship registers its interior as a set of oriented boxes, one
   per deck and the hold, in a shared group (as `pressurized_volumes` does for
   air). Each box moves with the ship.
2. **No swimming inside.** `LiquidEnvironment.read()` first asks whether the
   point lies in a dry volume; if it does, there is no liquid, so the body walks,
   whatever its height relative to the sea. This is one change in the shared
   liquid code, so every playable character and party member behaves the same,
   as the traversal rules require.
3. **No water sheet inside.** The ocean surface shader discards any fragment that
   falls inside a dry volume: the ship passes the shader a small array of box
   transforms each frame. (Godot 4.7's stencil buffer is an alternative: an
   invisible mesh of the hull's interior writes a stencil mark that the water
   skips.) From outside, the hull's planking hides the cut-out; from inside, the
   rooms are dry.
4. **No underwater view inside.** The underwater environment switch checks the
   camera against dry volumes before changing to fog and tint.
5. **The hull is watertight to the eye.** Below the waterline the hull is a
   continuous closed shape, so from the water the ship's bottom is solid and
   from inside no seam shows the sea.

The spaceship's `pressurized_volumes` answers "can I breathe here?"; dry volumes
answer "is there water here?". A sea folk air hall is both. The two interfaces
should live side by side so one body can register as either or both.

## 7. Movement, access and parkour

- **From the water:** the existing exterior stairs become the side steps at the
  entry port amidships, rising from swimming level to the spar or weather deck,
  as real ships had battens on their sides. Keep them on both sides.
- **Between decks:** real ships used steep ladders. Following the world's ramp
  convention, each ship has one broad **companion ramp** per deck (1.4 m wide,
  no steeper than 32°, landings at both ends) beside the main hatch, plus narrow
  ladders for show. Blorbus and the party can reach every deck the hero can.
- **Parkour:** the masts, shrouds, yards, tops and bowsprit remain climbable
  landmarks.
- **Moving platform:** decks and ramps carry a standing body as the ship sails.
- **Light:** lanterns on deck from dusk to sunrise as now; enclosed lamps below
  deck, none in the magazine.

## 8. Implementation order

1. The dry volume system (section 6) with one test hull at rest.
2. The *Harbinger*'s hull with draft, decks, companion ramps and the great
   cabin and galley interiors.
3. The *Belle Fortune* on a second route, sailing the opposite way.
4. The remaining interiors, crew schedules and dialogue.

## 9. Deck plans at true size (2026-10-13)

The audit in section 4 left one item: draw every deck at true size. It is now
drawn and checked. `tools/pirate_ships_layout.py` holds both ships (hull shape,
decks, rooms, companion ramps, masts, dry volumes, crew, work spots and routes),
checks them and writes `scripts/pirate_ships_plan.gd` (`PirateShipsPlan`), the
one plan the ship builder reads. `tools/validate_pirate_ships_plan.tscn` checks
the same rules in Godot in the pre-push hook (`VILLAGE=pirate_ships`). The
deck plans, a midship section and both routes are drawn on the Ocean Kingdom
Chart.

### Hull shape

One function, `PirateShipsPlan.hull_half_breadth(ship, z, y)`, gives each hull's
half-breadth at any length and height, so the builder lofts the hull and the
validator fits rooms against the same shape. Ship-local axes: +z the bow, x
athwartships, y up from the waterline. Every room stands inside the hull less
0.3 m of planking and frames, tested at its corners and middle at 0.3 m and
2.0 m above its floor.

| | *Harbinger* | *Belle Fortune* |
|---|---|---|
| Length, beam, draft | 42 × 11.5 m, 5.0 m | 38 × 10 m, 4.2 m |
| Plan | fine bow, full quarters, flat transom (62 % of the beam) | round bow, round tall stern (55 %) |
| Sides | slight tumblehome (8 % over 7.2 m) | the fluyt's strong tumblehome: 10 m at the waterline, 7 m at the weather deck |

**What drawing it changed.** As predicted, the first drawing failed the hull at
both ends of both ships: rectangles drawn to the beam amidships do not fit
where the hull tapers.

- *Harbinger*: the great cabin narrows to 7.6 × 6.0 m and starts 2 m from the
  stern; the coach and quarterdeck to 6.8 m wide; the forecastle and boatswain's
  store to 5.6 m; the battery to 9.6 m between the gun ports; the crew berth to
  8.6 m. The quarterdeck and forecastle ramps moved 2 m inboard of their old
  feet, so their heads land on the raised decks instead of short of them.
- *Belle Fortune*: the stern was made fuller (it fitted no great cabin at
  all), and the council room is **4.5 × 6.0 m** clear at shoulder height, wider
  at the floor, under the poop deck. The brief's 5.5 m is only its floor width;
  the tumblehome takes the rest, as the audit warned. The lower deck's crew
  quarters are 6.4 m wide, with the carpenter's corner and sail locker either
  side of a 1.6 m passage to the bow.

### Rooms

| *Harbinger* deck (floor) | Room | Size (beam × length) | z |
|---|---|---|---|
| hold (−4.4) | hold stores | 5.2 × 14.0 | −11.0 to +3.0 |
| hold | magazine | 4.4 × 4.6 | +7.6 to +12.2 |
| berth deck (−1.6) | crew berth | 8.6 × 10.2 | +2.4 to +12.6 |
| berth deck | carpenter's walk, sail room | 2.1 × 10.9 each, either side | −9.5 to +1.4 |
| berth deck | wardroom | 4.0 × 5.5 | −16.0 to −10.5 |
| berth deck | cabins of Mara Reef and Old Kelp | 2.6 × 2.7 each | −13.2 to −10.5 |
| berth deck | Ada Shoal's cabin and the surgery | 2.4 × 2.8 each | −16.4 to −13.6 |
| gun deck (+1.4) | great cabin | 7.6 × 6.0 | −19.0 to −13.0 |
| gun deck | battery | 9.6 × 21.4 | −12.4 to +9.0 |
| gun deck | galley | 7.6 × 5.0 | +9.6 to +14.6 |
| spar deck (+4.4) | coach | 6.8 × 6.0 | −19.6 to −13.6 |
| spar deck | waist (open) | 8.0 × 26.0 | −13.0 to +13.0 |
| spar deck | boatswain's store | 5.6 × 4.0 | +13.6 to +17.6 |
| quarterdeck (+7.2) | quarterdeck | 6.8 × 6.4 | −19.6 to −13.2 |
| forecastle (+7.2) | forecastle | 5.6 × 4.4 | +13.2 to +17.6 |

| *Belle Fortune* deck (floor) | Room | Size (beam × length) | z |
|---|---|---|---|
| hold (−3.6) | plunder hold | 4.8 × 14.0 | −10.0 to +4.0 |
| hold | powder room | 4.0 × 4.0 | +6.4 to +10.4 |
| lower deck (−0.6) | crew quarters and the six guns | 6.4 × 21.0 | −11.0 to +10.0 |
| lower deck | sickbay | 5.6 × 4.0 | −15.4 to −11.4 |
| lower deck | carpenter's corner, sail locker | 1.9 × 2.6 each | +10.4 to +13.0 |
| weather deck (+2.4) | great cabin (council room) | 4.5 × 6.0 | −16.4 to −10.4 |
| weather deck | waist (open) | 5.0 × 20.6 | −9.6 to +11.0 |
| weather deck | galley | 3.0 × 3.4 | +12.2 to +15.6 |
| poop deck (+5.2) | captain's cabin | 3.8 × 3.4 | −17.0 to −13.6 |
| poop deck | poop deck (the wheel) | 4.8 × 3.2 | −13.4 to −10.2 |
| forecastle (+5.2) | forecastle | 2.8 × 3.8 | +12.2 to +16.0 |

Every enclosed room has at least 2.4 m under the deck above. Masts rise through
rooms, as they do on every ship; no ramp meets one.

### Companion ramps

One 1.4 m ramp at 32° per deck pair, with 1.2 m landings, laid fore and aft
beside the centreline and alternating sides so no two on one deck overlap:

- *Harbinger*: hold to berth deck (port, climbing aft from z −4.0), berth deck to
  gun deck (starboard, aft from −2.6), gun deck to spar deck (port, aft from
  +6.2), spar deck to quarterdeck (port, aft from −8.6), spar deck to forecastle
  (starboard, forward from +8.6).
- *Belle Fortune*: hold to lower deck (port, aft from −2.4), lower deck to
  weather deck (starboard, forward from −4.4, through the main hatch), weather
  deck to poop deck (port, aft from −5.6), weather deck to forecastle
  (starboard, forward from +7.6).

### Dry volumes

Each ship registers two boxes (section 6): the hold and the deck that
straddles the waterline (*Harbinger* −4.9 to −1.6 and −1.6 to +1.4; *Belle
Fortune* −4.0 to −0.6 and −0.6 to +2.4). Every room below +0.3 m lies in one.

### Routes and timetable

The survey found the old elliptical route (285 to 350 m out) never passed the
three wrecks the crews salvage daily. The ships now sail two **nested loops in
opposite directions** among the islands, inside the Kraken's water with a 40 m
margin, at least 60 m from the dock and over water at least 3 m deeper than
their draft:

- The *Harbinger* sails the outer loop (1.87 km) three times a day at about
  4 m/s, and lies hove to over the **brig** from 14:42 to 15:42.
- The *Belle Fortune* sails the inner loop (1.34 km), round the west and north
  of the main island and between the eastern islets, five times a day at about
  5 m/s, and lies hove to over the **schooner** from 12:00 to 13:00.
- Both pass within 45 m of the **galleon** they fight over.

Each ship sails a whole number of laps between stops, so its timetable repeats
exactly every day and it is over its wreck at the same hour. The stop hours
are phased so that over a simulated week the two ships never come within 60 m
of each other (74 m at closest). The validator's `position(ship, t)` is the
function the ship builder moves the ships with, so the game and the check
agree.

### For the rebuild (`ocean_kingdom_denizens.gd`)

- Replace the 350 × 285 m ellipse with each ship's `route`, `speed`,
  `stop_index`, `stop_hour` and `stop_minutes`, moved by `position()`.
- Loft the hull from `hull_half_breadth()`; build decks, rooms and ramps from
  the plan; register the dry boxes.
- Spread each room's people over its floor at the work spots in `schedule`.

## Fixed, proposed and open

**Fixed:** two three-masted ships; exterior stairs; parkour; lanterns; the two
captains; the British and French origins; Brine's eight crew and Souci's eight.

**Proposed:** the *Harbinger* as a ship-rigged sloop-of-war and the *Belle
Fortune* as a captured Dutch fluyt; twelve crew per ship with eight new names;
the enlarged game-scale dimensions, levels and rooms above; companion ramps;
the shared dry volume system.

**Open:** none blocking.
