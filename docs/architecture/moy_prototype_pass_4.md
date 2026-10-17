# Moy: fourth prototype pass, build instructions

2026-10-17. Instructions for the next implementation chat. Keep following
`moy_prototype_pass_3.md` and the briefs it points to. **This document lists
only what changes.** If this document and the data disagree, the data wins:
report it.

## 0. Review of the third pass

Pushed late on 2026-10-17 (`a38fa97`, `2549ea4`); its diagnostic is
`docs/diagnostics/2026-10-17-moy-prototype-pass-3.md`.

Good, keep it:
- the flat annuli and continuous helix strips, with per-contact tangent travel;
- the open lower bridges at both gates;
- the moving tread belts with their closed returns;
- the call-post and destination-menu lifts;
- the honest list of what was not physically verified.

To settle:
1. **Platform edge.** The 7.5 cm boarding gap is authoritative. Keep your
   builder's offset (track, plus car half-width, plus 0.075, plus platform
   half-width). `PLATFORMS.edge` in the data is wrong by 0.475 m. Correcting
   it moves the station escalators, so it will be fixed in a later plan pass.
   Until then, your offset wins.
2. **Generated files.** `scripts/city_plan.gd` is generated. Never edit it by
   hand. If regenerating on your machine gives different rounding, say so in
   the diagnostic.
3. **Still owed from pass 3:**
   - the rendered performance probe;
   - a physical walk and ride of every escalator, ramp and lift end, by both
     characters;
   - all four clock faces at 3:00, 9:15 and 12:00.

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

- The building count drops from 50 to 47 (buildings 54 to 56 are gone).
  Update `check_moy_bake.py` and the validators, then rebake.

- `python3 tools/city_layout.py` passes (it checks the square, the front's
  bands, its headroom and the beams' clearance).
- Ride every flight of the front from the forecourt to the sky garden and
  back, both legs. Then do the same on each helix and look up the whole way.
- Walk from the square to each platform by the steps and the scissors, and
  again by the lifts.
