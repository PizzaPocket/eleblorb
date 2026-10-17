# Moy: fourth prototype pass, build instructions

2026-10-17. Instructions for the next implementation chat. Keep following
`moy_prototype_pass_3.md` and the briefs it points to. **This document lists
only what changes.** If this document and the data disagree, the data wins:
report it.

The third pass was not on GitHub when this was written (main only, no other
branches or pull requests). Push it first, so it can be reviewed against this
brief.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`.
2. This document.
3. `city.md` 8a.1 (Civic Plaza, the grand square) and 8b.1 (City Hall's city
   front).
4. `docs/drawings/moy_city_3d.html`. New places to visit: *Civic Plaza*,
   *City Hall's city front*, *On Civic Plaza*.

## 2. What changes

1. **Civic Plaza is one grand square.** Remove the two blocks of shops and
   offices (buildings 54 to 56), Meridian Walk, Hotel Passage, and the civic
   walks on the Deck. Build the square from `CityPlan.CIVIC_SQUARE`:
   - paving over its `rect`;
   - the reflecting pool (`mirror`; hazard policy, water surface API);
   - two lawns split by the paved cross-axis, with a fountain on each;
   - the tree rows along the north and south edges (kit trees; trunks solid);
   - the statues on the lawns and the two monuments, as plinths with simple
     massing for now (subjects are open);
   - the flagstaffs.
   The Grand Hotel's skybridge now runs west to the Park Deck
   (`DECK['runs']`, *Hotel skybridge*).
2. **City Hall's city front replaces the cascades.** `ARCH['cores']` is empty.
   Build `ARCH['front']`:
   - the **Rostrum** at the hall's level, with its bay and portals;
   - the **City Steps**, two flights, each with a stair between an up and a
     down escalator, and a half-landing;
   - the **scissor escalators** up each leg. Each flight lies in the band
     its data names (A or B). Consecutive flights alternate bands, so no
     flight runs into the next;
   - the galleries at each platform level, which lead to the platforms'
     west ends;
   - the over-track walk, the outer pair, and the lifts at their stops.
3. **Every escalator has moving handrails** (`ESCALATORS['handrail']`): a
   rubber handrail on a glass balustrade on both sides of every lane, straight
   and spiral, moving at the treads' speed in the lane's direction, with a
   newel at each end. The handrail is decorative; the balustrade is solid.
4. **Nothing structural enters a helix's band.** On the Crossing's double
   helices, the train's support crossbeams cut the riders' headroom. The
   Spine's head beams must end at the drum's ring girder, outside the band.
   Keep at least 1.6 m (checked in `tools/city_layout.py`) between any beam and the
   band. Check it in the validator: no collider other than the hand itself
   may enter the band's volume up to 2.6 m above the treads.

## 3. Checks

- `python3 tools/city_layout.py` passes (it checks the square, the front's
  bands, its headroom and the beams' clearance).
- Ride every flight of the front from the forecourt to the sky garden and
  back, both legs. Then do the same on each helix and look up the whole way.
- Walk from the square to each platform by the steps and the scissors, and
  again by the lifts.
