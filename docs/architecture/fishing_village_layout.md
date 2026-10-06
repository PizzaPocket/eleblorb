# Crossroads Fishing Village: Civic Layout Plan

Status: layout approved (2026-10-06). This plan places the
approved community, programs and boats on the lake. It fixes relationships,
route hierarchy, approximate footprints, water use and implementation
constraints. Building architecture follows only after this plan is approved.

Read with `fishing_village.md`, which owns the census, households, trade,
architectural charter and the Mor houseboat program. This document owns where
those programs meet the water.

## 1. Survey

These facts come from the current code, not from new assumptions:

- `FloatingVillage.CENTER` is world `(440, 0)`. The lake surface is
  `Terrain.get_lake_water_level()`, currently `-GORGE_DEPTH - 1.65 = -61.65`.
  This plan calls that level **W**.
- The lake floor under the centre is `LAKE_MAX_DEPTH` (135 m) below W. At this
  `x`, `down_from_plateau`, `up_to_mountains` and `lateral_bowl` are all 1, so
  the whole present village stands over the deepest water in the basin. There
  is no shallow water within about 150 m in any direction.
- The nearest shore is the west bank under the Ohio plateau. On the `z = 0`
  line the water is about 1 m deep near world `x = 232` and about 40 m deep by
  `x = 300`. The village centre is therefore about 205 m from wading depth.
  North and south shores are about 300 m away.
- No limestone islets exist in the terrain. The current huts and decks rest on
  decorative 6 m stilts that end in open water.
- The Ocean Kingdom gate stands on `get_portal_anchor()`, at
  `CENTER + PORTAL_OFFSET (-26, 0, 3.5)` and deck height `W + DECK_Y (0.34)`.
  The returning player is placed 3 m behind the gate, so the portal deck must
  keep at least that much clear deck behind it.
- The present three swim ramps are 3.4 m wide with an 8 m run. Their lower end
  is fixed at W − 1.45 m by a copied constant. The rebuild derives that lower
  end instead (section 6).
- The world has no prevailing wind defined in code or lore.

The current village is reached only by swimming. Its stilts, uniform hut grid
and decorative boats are what the rebuild replaces. Its lively colour range,
the shop, the portal and three working swim exits are non-regression
requirements (brief, "What exists now").

## 2. Site decisions

### Islets and shelves

Piles cannot honestly stand in 135 m of water. The approved limestone islets
make the settlement possible: each rises sheer from a **submerged shoulder
shelf** 2.5 to 4 m below W, and every pile-supported structure stands on that
shelf. Beyond the shelf edge the rock drops vertically to the basin floor.
Floating structures (the houseboat, pontoons, small work floats) may sit over
deep water, held by moorings to piles or rock.

This is the Ko Panyi relationship: the rock gives shelter and a fixed anchor,
the piles use the only shallow ground, and the village spreads over the water
because the cliff leaves no level land.

- **Anvil Rock**, the larger islet: centred at local `(-4, -30)`, waterline
  footprint about 36 × 20 m with its long axis east to west, and a broad,
  flat-topped crown about W + 34 m. Its south face is the village's back wall.
  Dala's generation drove the first piles along its foot.
- **Heron Rock**, the smaller islet: centred at local `(30, 10)`, waterline
  footprint about 12 × 10 m, a slender stack rising about W + 21 m.
- **Shelves** (the only areas where piles are allowed):
  - Anvil south shelf: local `x -30..16`, from the rock face at `z ≈ -20` out
    to `z = +6` west of `x = -8` and `z = +4` east of it.
  - Arrival foot: local `x -46..-30`, `z -22..+4`, a western lobe of the Anvil
    shelf facing the shore.
  - Heron shelf: a ring 14 m out from Heron Rock's centre, merging with the
    Anvil shelf's east end around local `(16, 0)`.

The rocks are natural karst: undercut, weathered faces with vegetation only on
ledges, crevices and crowns. Decks tie into their foot; they never terrace the
rock into level plots.

**Drinking water.** Rain soaking through Anvil Rock emerges as a filtered seep
at the base of its south face. The village channels it, with roof runoff, into
a covered cistern. Nobody drinks from the working lake edge.

### Wind and sun

This plan sets a **prevailing breeze from the west**, drawn down off the Ohio
plateau and across the basin. It is a settlement convention for siting smoke,
drying and shelter, recorded here and in the world bible. Downwind is east,
toward open water and the mountains.

- Smoke, drying racks and fish processing go on the east edge (Heron Rock).
- The arrival landing faces west toward the shore and Ohio. Anvil Rock shelters
  the household row from the north.
- Household fronts face south across the jetty to the water court: light,
  views and the communal life of the court.

### Local frame

Local `(0, 0)` is world `(440, 0)`. Local `+x` is world `+x` (east, away from
the shore). Local `+z` is world `+z`, called "south" in this plan. Heights are
given relative to W.

## 3. Plan diagram

Not to scale; local coordinates in metres.

```
                       N (−z)
              ┌────────── ANVIL ROCK ──────────┐            open lake
              │   sheer limestone, crown W+34   │
   z −20 ─────┴──seep──cistern─────────────────┴──────┐
   VENN yard  VENN     SEN house   stores/   net shed  │
   & slip     house    & clinic    cistern             │      HERON
   (west)     + shop                                   │  VALE  ROCK
   ═══ARRIVAL═╪════════════ JETTY SPINE (3.6 m) ════════► HERON house W+21
   LANDING    │                    ║                  LANDING     VALE
   (−36,−6)   │        PAVILION (hinge)          ARAN    ║        drying &
   ferry/skiff│        (−2, 0)                   house   ║        smokehouse
   berths     │  swim exit 2 ↓                  + pearl  ║        (downwind)
   swim exit 1↓   ~~~ WATER COURT ~~~           yard     ╚═ portal spur
              MOR HOUSEBOAT (moored)            mussel      │
              arrival deck → … → cargo deck     lines    OCEAN PORTAL
                                                         LANDING
                                                         swim exit 3 ↓
                       S (+z)                         working-boat lane → E
```

## 4. Districts and footprints

Footprints include verandas and eaves. All are local `x` and `z` ranges in
metres.

| # | Program | Owner | Footprint | Support | Faces |
|---|---|---|---|---|---|
| 1 | Arrival landing and market deck | public; Nara is dockwarden | `x -42..-28`, `z -12..+2` | piles, arrival foot | west to shore, south to water |
| 2 | Venn house with lake shop on its front veranda | Nara, Mateo, Lio | `x -34..-25`, `z -20..-13` | piles | shop counter faces the landing |
| 3 | Boatwright slip, timber rack and tool shelter | Mateo | `x -46..-40`, `z -22..-13`, slip running west into water | piles; slip on the shelf edge | outer west side, off the public deck |
| 4 | Sen house, clinic and school room | Asha, Rian | `x -20..-11`, `z -20..-10` | piles | clinic door south onto the spine |
| 5 | Rian's cutting and sealing deck | Rian | `x -11..-8`, `z -18..-11` | piles | side deck, not on the spine |
| 6 | Cistern house and shared stores | village; Leena keeps the stores | `x -6..2`, `z -20..-12` | piles, tied into the seep | north to the rock |
| 7 | Net shed and gear loft | Salim (shared with Jori) | `x 4..12`, `z -20..-12` | piles | south onto the spine |
| 8 | Communal pavilion | Leena | `x -8..4`, `z -4..+4` | piles | open-sided; the hinge of the spine and court |
| 9 | Aran house | Mai, Salim, Dala, Pree | `x 6..14`, `z -3..+5` | piles, shelf edge | front west to court; wet stair south |
| 10 | Pearl and shell yard (clean work) | Mai | `x 6..16`, `z +5..+10` | pontoon moored to Aran piles | grading tables face the house |
| 11 | Mussel basket lines | Mai | `x 6..16`, `z +14..+30` | buoyed lines in deep water | outside every lane |
| 12 | Vale house | Jori, Osei, Tavi | `x 24..34`, `z -4..+3` | piles, Heron shelf north | front west to the Heron landing |
| 13 | Catch deck, drying shelter and smokehouse | Osei | `x 36..44`, `z +2..+14` | piles, Heron shelf east | east to open water (downwind) |
| 14 | Mor guest houseboat | Leena, Ivo, Sela | about 18 × 7 m at `x -26..-8`, `z +8..+15` | floating, moored to arrival and pavilion piles | arrival deck west, cargo deck east |
| 15 | Ocean portal landing | public | `x 26..35`, `z +16..+24` | piles, Heron shelf south, against the rock | gate faces north-west toward the portal spur; 3 m clear behind |

Every structure has an owner and a program. There are no anonymous huts. The
present seven huts and the portal dock at `(-26, 3.5)` are removed. The portal
anchor moves to the new landing (section 9).

## 5. Routes

### Hierarchy

| Route | Width | Purpose |
|---|---|---|
| Jetty spine | 3.6 m | public route from the arrival landing to the Heron landing at Heron Rock's west foot |
| Pavilion return | 3.0 m | secondary public route from the pavilion along the water court edge back to the landing |
| Household spurs | 2.4 m | spine to each house front |
| Work spurs | 2.4 m | spine or house to a named task |
| Flexible gangways | 2.6 m | fixed deck to floating deck |

All public routes and gangways take a mounted character. Clear headroom over
every public route is at least 3.2 m, including under eaves and pavilion beams.

### Route ledger

| Route | From → to | Points (local) | Notes |
|---|---|---|---|
| Jetty spine | arrival landing → Heron landing | `(-28,-6) → (-10,-7) → (6,-7) → (16,-4) → (21,0)` | gentle bends follow the shelf; ends on a 6 × 6 m Heron landing at `(21, 0)` |
| Pavilion return | pavilion → arrival landing | `(-8,+2) → (-20,+4) → (-28,+2)` | runs along the north edge of the water court; reaches the houseboat gangway |
| Portal spur | Heron landing → portal landing | `(21,+3) → (20,+10) → (23,+17) → (27,+19)` | along Heron Rock's west foot, clear of the mussel lines |
| Venn spur | landing → Venn front | `(-30,-12) → (-30,-13)` | the shop veranda opens directly onto the landing |
| Slip work spur | Venn yard → slip | `(-34,-17) → (-40,-17)` | behind the house; customers never cross it |
| Sen spur | spine → clinic | `(-15,-7) → (-15,-10)` | |
| Rian's deck | Sen house → side deck | internal door only | not public |
| Cistern spur | spine → cistern house | `(-2,-7) → (-2,-12)` | public: anyone may draw water |
| Net shed spur | spine → net shed | `(8,-7) → (8,-12)` | Salim and Jori carry gear here, not through the pavilion |
| Aran spur | spine → Aran front | `(8,-7) → (8,-3)` | |
| Aran wet stair | Aran house → pearl yard | `(10,+5)` | private; never crosses a public deck |
| Vale spur | Heron landing → Vale front | `(23,-1) → (24,-1)` | the Vale veranda opens off the landing |
| Catch spur | Vale house → catch deck | `(34,0) → (38,+3)` | private work route along Heron Rock's north-east foot |
| Houseboat gangway | pavilion return → arrival deck | `(-22,+4) → (-22,+8)` | flexible, 2.6 m |
| Cargo gangway | houseboat cargo deck → cargo float | `(-8,+11) → (-4,+11)` | service only |

The loop closes from the arrival landing along the spine to the pavilion and
back along the court edge. Every route ends at a destination.

### Service and emergency movement

- **Fish** move from the Vale working boat to the catch deck (13), then to the
  smokehouse or drying shelter, and then by Osei along the spine to the
  houseboat galley or the Venn shop. Wet catch never crosses the pavilion, the
  pearl yard or a swim exit.
- **Mussels** move by Mai's punt from the basket lines (11) to the pearl yard
  (10). Edible clams go up the Aran wet stair to the house and to Leena; usable
  shell goes along the spine to Rian's deck (5).
- **Cargo** arrives on Ivo's ferry at the landing's west berth and moves by
  hand cart along the pavilion return to the houseboat cargo deck, or by Lio to
  the shop. Timber for Mateo goes straight to the slip yard.
- **Storm muster:** everyone gathers at the pavilion (8). Dala calls it from the
  Aran house; Leena opens the houseboat common cabin as the second shelter.
- **Rescue:** Sela's utility boat waits at the houseboat's cargo end, with a
  clear run south into open water. Jori takes first watch from the Heron berth.

## 6. Water lanes, berths and swim exits

### Lanes

Lanes are kept as open water. No line, float, basket, mooring or hull may
enter them.

| Lane | Width | Path |
|---|---|---|
| Ferry lane | 8 m | west from the landing's ferry berth toward the shore |
| Court mouth | 10 m | south from the water court, `x -6..+4`, between the houseboat's east end and the mussel lines |
| Working-boat lane | 10 m | east from the catch deck berth into open water |
| Rescue lane | 8 m | south from the houseboat cargo end |

### Berths

| Boat | Owner | Berth |
|---|---|---|
| Narrow dive skiff | Nara (Lio rows the shop skiff) | landing, north-west corner; closest public berth |
| Ferry and cargo boat | Ivo | landing, west berth on the ferry lane |
| Boat under repair | Mateo | on the slip |
| Broad work punt | Mai | pearl yard pontoon; never enters the swimming water |
| Broad working fishing boat | Jori | catch deck, east berth on the working-boat lane |
| Fast utility boat | Sela | houseboat cargo end, on the rescue lane |
| Paddle skiff | Salim | low boarding landing on the Aran house's east side, `(16, 0)` |
| Mor guest houseboat | Mor household | moored in the court's west side; it never moves during play |

There are seven boats plus the houseboat. Each has an owner, a use and a clear
approach.

### Swim exits

| Exit | Location | Descends toward | Serves |
|---|---|---|---|
| 1 | landing south edge, `x -38..-34.6` | south into open water | arrivals swimming from the shore |
| 2 | pavilion south edge, `x -3.7..-0.3` | south into the water court | the court and the houseboat |
| 3 | portal landing south edge, `x 28..31.4` | south into open water | the portal and the Heron end |

Each exit is 3.4 m wide. Its upper end meets its deck flush. Its lower end is
derived, not copied:

```
lower_end_y = W − LiquidEnvironment.float_depth(human head height) − 0.10
```

The run follows from that drop at a grade no steeper than the current ramps
(1.95 over 8 m, about 14°). The 8 m of open water beyond each foot stays free
of hulls, lines and mooring ropes. Low boarding landings for boats are separate
and do not count as exits.

## 7. Heights

| Element | Height |
|---|---|
| Public deck top (spine, landing, pavilion) | W + 0.50 m (the current datum: `DECK_Y` 0.34 plus deck thickness) |
| House floors | W + 0.75 m, one 0.25 m threshold up from the spine, ramped for blorbs |
| Pontoons and houseboat deck | W + 0.35 m; gangway grade ≤ 8° |
| Shelf top | W − 2.5 to W − 4.0 m |
| Pile footing | on the shelf, never in open deep water |

Storm surge is not simulated, so the low public deck is retained for swim-exit
geometry. Houses sit slightly higher to read as dry.

## 8. Adjacency

| | Landing | Pavilion | Pearl yard | Catch deck | Houseboat | Portal |
|---|---|---|---|---|---|---|
| Shop | joined | near | apart | apart | near | apart |
| Clinic | near | near | — | apart | — | — |
| Pearl yard | apart | near | — | **separated** | — | apart |
| Smokehouse | **far** | **far** | **separated** | joined | far | apart |
| Swim exits | joined (1) | joined (2) | clear of lines | clear | clear of hull | joined (3) |

"Separated" means a validator failure if the two touch or share a deck.

## 9. Gameplay anchors

- **Shop:** Nara stands behind the Venn veranda counter facing the landing.
  `ShopCatalog.get_items_for_shop("lake")` and the `lake` category are unchanged.
  The ware display moves with the counter.
- **Ocean portal:** the gate stands on the portal landing (15), facing
  north-west toward the portal spur. `get_portal_anchor()` returns the new
  landing point, and `PORTAL_OFFSET` becomes about `(30, 0, 20)`. At least 3 m of clear
  deck stays behind the gate for the return spawn, and the landing is clear of
  homes, mussel lines and every boat lane.
- **Rest point:** inside the Mor houseboat as specified in the brief. Its wake
  marker and party gathering area stay aboard.
- **Protected bounds:** a 70 m radius around local `(0, 0)` covers both rocks,
  every deck, the mussel lines and the portal. There are no hostile encounters
  inside it.
- **Schedule anchors:** Asha's morning lessons in the school room (4); Leena's
  meals at the pavilion and houseboat; Mai at the pearl yard by day; Salim at
  the net shed; Osei at the catch deck when the boat returns; Dala's weather
  watch from the Aran house veranda; Ivo away on the ferry lane for part of the
  day; Lio between the shop, the slip and every household; Pree's herb floats
  at the Aran front; Tavi at the school room, then the Heron landing to watch
  the boats come in, never the catch deck.

## 10. Implementation constraints

1. **Terrain first.** Add Anvil Rock, Heron Rock and their shelves before any
   structure. The shelves belong in the lake floor height field. The sheer
   rock stacks are authored rock bodies with their own collision, because the
   6.5 m terrain grid cannot make a vertical karst face. Do not raise the
   general basin floor.
2. **One plan source.** `FishingVillagePlan` (`scripts/fishing_village_plan.gd`)
   holds the islets, shelves, footprints, routes, lanes, berths, swim exits,
   trade and schedules in this document. `floating_village.gd` consumes it and
   invents nothing.
3. **Validator mode** (`tools/validate_village.gd`, `--village=fishing`),
   written before population, fails:
   - a pile-supported structure outside a shelf;
   - overlapping footprints, or any structure inside a lane or the 8 m clear
     water beyond a swim exit;
   - fewer than three swim exits, or an exit whose lower end differs from the
     derived height by more than 0.15 m;
   - a route below 3.2 m headroom or narrower than its class;
   - a gangway steeper than 8°;
   - a boat without an owner, berth and lane;
   - a structure or stall without an owner;
   - a "separated" adjacency that touches;
   - the portal deck without 3 m clear behind the gate.
4. **Order:** terrain, plan data, validator, circulation and swim exits, then
   the architectural kit proofs (one house, one work deck, one boat), then the
   village, interiors, water work, landscape, schedules and dialogue.

## Fixed, proposed and open

**Fixed:** the census and household programs; steep limestone islets with Ko
Panyi siting; ordinary pearls; the shop's behaviour and catalogue; the Ocean
portal; at least three derived swim exits; the colour range; the houseboat rest
point.

**Proposed in this document:** Anvil Rock and Heron Rock with their positions,
sizes and shelves; the west breeze; the cliff seep and cistern; every footprint,
route, lane, berth and height above; the portal's move to Heron Rock.

**Open:**

- None blocking. Players reach the village by swimming, as now; boats come
  later with boat riding.

**Settled since:** the layout is approved; arrival is by swimming until boats
exist; boats will be rideable, as a separate project with its own control
design. The berths and lanes above are its starting data.
