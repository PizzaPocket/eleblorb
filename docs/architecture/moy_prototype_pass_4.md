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
3. `city.md` 8a.1 (Civic Plaza, the grand square), 8b.1 (City Hall's city
   front) and 7a (the city's clock and the Clock Room).
4. `docs/drawings/moy_city_3d.html`. New places to visit: *Civic Plaza*,
   *City Hall's city front*, *On Civic Plaza*, *The city's clock*, *The Clock
   Room*, *In a clock's eye*.

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

5. **City Hall's landings, guards and lifts.**
   - **New landings.** Build the new landings `L37o`, `L37i` and `L43`, and
     each leg's `outer_landing`.
   - **Guards.** Build every run in `ARCH['front_guard']['runs']`: 1.1 m
     glass on a bronze shoe, with a bronze rail. Each guard is solid
     (collision); its top rail is decorative.
   - **Lifts.** Move the front lifts to their new places, in front of each
     leg and flanking the gate. Drop their +21.8 stop. Move the outer lifts
     onto the walk over the tracks.
   - **Check:** walk every landing's edge with both characters. You must not
     be able to fall except where a flight, a stair, a lift or a platform
     meets the edge.
6. **The clock dome (rebuild it).** Data: `CROSSING.dome`.
   - **Remove** the drum's posts and the steel ring beam.
   - **Build one glass shell**, drum and cupola together. Put a triangulated
     grid of slender white members on it (`lattice`: 72 panes round, rows
     every 2.2 m up the shell, 7 cm members), meeting a crown ring at
     3 m radius. The drawing's code builds it. The glass and the grid are
     solid; the grid has no separate collider.
   - **The eyes.** Cut each clock's hollow centre out of the glass
     (`clocks.eye`), line it with the bronze sleeve, and lay the sill. Leave
     each eye open: no glass, no guard, no collider across it. A glider or
     flier must be able to pass through.
   - **Hang the bell** from the crown ring.
7. **The Clock Room.** Data: `CROSSING.dome.room`.
   - **The helices end at +37.** They do not continue into the dome.
   - **The floor:** terrazzo at the roof's top, with the compass rose under
     the bell.
   - **The arrivals.** Build the `widenings` on the high-line platforms.
     Build the four `arrivals` as escalator pairs from 37 to 41.6. Cut their
     `well`s in the floor, and guard each well on three sides, open at the
     head.
   - **The lifts.** Run the four tower lifts on to 41.6, each with a glass
     lantern whose door faces the bell (`lifts`, `door`). Add the stop to
     their destination menus.
   - **No way up to the eyes.** There are no escalators or landings to the
     eyes (revised 2026-10-18): an eye is reached only by flying or gliding,
     onto its sill.
   - **Check:** ride every way in and out, with both characters:
     - each arrival, both ways;
     - each lift to the room and back;
     - out through an eye with the Leaf Hat, and back in.
8. **The garden towers' ways out.** The third pass's hoops and ribs block
   them.
   - Rebuild each tower's rib cage with **eight** ribs at 22.5° + 45k.
   - Put hoops only at each tower's `hoops` heights: never from a level's
     floor to 2.8 m over it.
   - Check every `ways_out` entry: walk out of each tower at each level, and
     onto the ring and the bridges, with both characters. No rib or hoop is
     in the way, and none collides inside the clear width and height.
9. **The escalators are closed boxes** (`ESCALATORS.section`). In the third
   pass the helices' undersides were invisible and had no collision from
   below. Every flight, straight and spiral:
   - **Top:** the moving treads, unchanged.
   - **Return belt:** inside the box, hidden.
   - **Skirts:** solid side skirts.
   - **Soffit:** a hard brushed-stainless soffit closing it underneath, its
     faces outward.
   - **Collision:** the top and the soffit both solid, as closed convex
     pieces per segment.
   - **Check:** stand under each helix and each straight flight and look up.
     Jump up into its underside: it is solid.
10. **The Grand Hotel stays as built.** The city model draws it as massing
    only, and points to the detailed model, `docs/drawings/moy_grand_hotel_3d.html`.
    Its data is `CityPlan.HOTEL`, which both models read. Keep building the
    hotel from `HOTEL` and the detailed model, as in pass 3; nothing about it
    changes in this pass.

11. **The reed pond is real water** (`PARK.pond`).
    - **The fault.** In the third pass its water stood 0.4 m above the park's
      ground (`MOY_POND_SURFACE` −59.6 over a datum of −60), on a bespoke,
      nearly opaque shader (`moy_pond_water.gdshader`, alpha 0.88), so it
      hovered over its banks and could not be seen into.
    - **The water's surface** is `surface` (0.3 m) below the park's ground.
    - **The bank** shelves down from the ground at `bank_top` (× r) to the
      waterline at r.
    - **The bed** follows `bed`, a reed shelf round the edge and 2.1 m deep at
      the middle. Set `terrain_generator.gd`'s `MOY_POND_SURFACE` and
      `_moy_pond_bed` from these values. The paving and lawn stop at the bank's
      top.
    - **The water** is the world's one water, as every village pond is:
      - `VillageWorks.water_material()` on a flat disc at the surface;
      - marked with `CollisionPolicy.mark_hazard`;
      - meta `water_surface_y` and `water_depth`.
      Delete the bespoke shader. The liquid queries (`is_water_area`,
      `get_water_surface_height`, `get_water_floor_height`) read the same
      surface and bed.
    - **Check:**
      - stand on the bank and look in: the water is translucent, below the
        ground;
      - wade in from the shelf and swim at the middle with both characters;
      - from underwater, look up through the surface.

## 3. Checks

- The building count drops from 50 to 47 (buildings 54 to 56 are gone).
  Update `check_moy_bake.py` and the validators, then rebake.

- `python3 tools/city_layout.py` passes (it checks the square, the front's
  bands, its headroom and the beams' clearance).
- Ride every flight of the front from the forecourt to the sky garden and
  back, both legs. Then do the same on each helix and look up the whole way.
- Walk from the square to each platform by the steps and the scissors, and
  again by the lifts.
