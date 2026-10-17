# Moy: handoff for the first low-fidelity build (2026-10-17)

> **Playable prototype execution contract, 2026-10-17:** For the owner's next
> implementation chat, read [moy_playable_prototype.md](moy_playable_prototype.md)
> first. It uses this handoff and the existing 3D/design documents, narrows the
> scope to a traversal prototype, and supplies performance/QA gates. The
> [readiness review](../diagnostics/2026-10-17-moy-prototype-readiness.md) records
> two current Godot plan failures and the missing estate data export. This
> earlier handoff is not evidence that those preflight checks pass. The short
> starter is [here](../prompts/moy_playable_prototype_luna.md).

This is the snapshot to build from. The plan is settled enough for a first
pass: block out every street, building, landmark and line at the right size
and place, with collision, so the city can be walked, climbed and ridden.
Detail comes later. Read the project rules in `CLAUDE.md` first; they apply
throughout.

## The source of truth

- **`scripts/city_plan.gd`** (`CityPlan`): every number the build needs, as
  GDScript consts. It is **generated**: never edit it by hand. Change
  `tools/city_layout.py` and run `python3 tools/city_layout.py` from the repo
  root. The tool checks the plan with shapely; if it prints any `PROBLEM`
  line it writes nothing. A clean run prints only "wrote scripts/city_plan.gd".
- **`docs/architecture/city.md`**: the brief: why everything is where it is,
  section by section. The data comments name the section each const comes
  from.
- **The drawings** (all generated from the same data, `docs/drawings/README.md`):
  - [plan](https://claude.ai/artifact/9qeXfC1J9oGNUT8pFmLWi1) (`moy_plan.html`):
    the plan, elevations, park section, tower elevations, skyline;
  - [3D model](https://claude.ai/artifact/YJq2qoeR9thJ67M5Xr23yd)
    (`moy_city_3d.html`): the massing model with places to visit; **this is
    the closest thing to the target for the first build**, and its code shows
    how each const turns into geometry;
  - [the Moy car](https://claude.ai/artifact/TCaCRZZRBNV5ApNiDuTEoN)
    (`moy_train_3d.html`): the trains, part by part in SuperEggs.
- **`tools/validate_city_plan.gd`** checks the plan in Godot
  (`Godot --headless --path . tools/validate_city_plan.tscn`). It was **not
  run** during the last design rounds, since Godot was not available, so run
  it first and fix anything it reports about rules the Python tool does not
  share.
- **`scripts/city_generator.gd`** is the existing in-game city builder,
  written for an earlier version of the plan. Expect it to be out of date
  with the consts below; rework it rather than starting a parallel builder.

## Coordinates and units

World metres; +X east, -Z north (so north is negative z). Moy's centre is
(-560, 0) (`CENTER`). The Rim Walk's radius is 200 m (`RIM_RADIUS`); buildings
stand within 197 m (`BUILT_RADIUS`). Rects are `(x0, z0, x1, z1)`. Heights are
metres above the basin floor; levels are fixed:

| Level | Height | What |
|---|---|---|
| street | 0 | streets, squares, the park |
| the Deck | +6.5 | the walkway (`DECK`) |
| the Spine Line / Wall Line | +12 main / +20 gate flyover vs +13.2 wall rail | independent services, no junction; `CROSS` profile and gate station rail |
| the Meridian high line | +36 (rail) | `CROSS` service 1 |

## What to build, in order

Each step should leave the city walkable. Low fidelity means plain SuperEgg
or box massing at the right size, not missing collision.

1. **Ground, streets and squares:** `STREETS`, `OPENS`, the park
   (`PARK`: its gardens, pond, lawn, playground, wind trees), the Rim Walk ring.
2. **Ordinary buildings:** `LOTS` (plain blocks at `storeys` ×
   `STOREY[kind]`, with `LOT_KITS` where present) and `BUILDINGS` (numbered;
   each entry carries its `height`, `form` and `corners`; `BUILDING_KITS`
   for the tower houses).
   The North Estate's blocks are turned: use their `corners`.
3. **The Well Quarter (Old Moy):** `OLD_TOWN` (two old roads and Cinema
   Square, as `lane_polys` and `squares`) and `OLD_HOUSES` (60 tower houses:
   an outline, storeys, the road each fronts, a kit). The outlines are not
   rectangles: extrude the outline for the base, square the tower above
   where needed (`moy_tower_house.md`, "Turned houses"). The middle of each
   block is courtyard (`yards`).
4. **The wall:** `WALL`: a circle of radius 209.5 m, 12 m high and 12 m thick
   (its `centreline`), arches, watch posts, the Line House (`shed_poly`), the
   North and South gatehouses. The East and West Gates are buildings
   (step 6): leave the wall open there.
5. **The Deck:** `DECK` runs (centrelines and widths at +6.5 m), its columns,
   ramp towers, lifts and escalating ramps.
6. **The landmarks**, each in its own section of `city.md`:
   - the **Timekeeper** over city hall (`TIMEKEEPER`, 8a.0): a full ring in a
     bronze cradle, hour and minute rings turning with real time;
   - the **Meridian Arch** as the East Gate (`ARCH`, 8b), with the Wall
     Line's **train hall** through its legs (`train_hall`: x range per leg,
     y 12 to 21) and its escalator cascades on the court faces (`cores`);
   - the **West Gate** towers (`WEST_GATE`), the same train hall;
   - the **Crossing Ring** in the park (`CROSSING`, 7a) and its open
     escalator towers;
   - **BLOCK's tower** (`BLOCK_TOWER`, `TOWER_SITE[13]`, 7c): a shaft to
     150 m, the crown folded inward to a canted ridge (212 m at its west
     end, 198 m at its east), one vertical slit lit azure;
   - the other towers (`TOWER_SITE`, 7c) and the Grand Hotel (`HOTEL`, section 8).
7. **The lines:** `CROSS` (the Spine on 12 m portal frames, the Meridian on
   tree piers at `piers`), stations (`stations`, with the escalating ramps in
   `_esc`), station cores with their `flights`, and the trains (`TRAIN`):
   one 9.6 m SuperEgg car; three to a Wall Line train, two on the cross
   lines. Trains are moving solids (`AnimatableBody3D`) the hero can ride.
8. **Green infrastructure** (`GREEN`, 6d): planter troughs on the lines,
   vine sleeves on the piers, roof gardens. Optional in the first pass.

## Rules that bite on this build

- **Everything is SuperEgg** (`scripts/superegg.gd`): props, cars, planters.
  Use `TownProps`, `VillageWorks` and `NatureProps` builders where they
  exist; add a reusable builder rather than one-off geometry.
- **Collision** (`CollisionPolicy`): every substantial thing is solid: walls,
  buildings, the Deck, viaducts, piers, platforms, the Timekeeper's rings,
  the trains. Roofs, the Deck, the wall top and the viaducts are landings
  (parkour policy). Foliage, blooms and fine trim are decorative.
- **No in-game text** that explains a mechanic or points the way (`CLAUDE.md`).
  Signs show shapes and colours, not words.
- **Traversal:** the Old High Street is a vine-swing route (6 m wide, walled
  by houses 16 m or taller); the city's towers and the Timekeeper's bezel are
  swing anchors (`city.md` 7, 7c, 8a).
- **Any UI** goes through `UITheme`/`UIKit`.
- **Commits** use the owner's identity and credit no AI (`CLAUDE.md`).

## Known gaps and loose ends

- `CROWNS[12]` says the Windspire reaches 280 m; `HEIGHTS[12]` is 262 m (the
  roof). The crown is the extra 18 m.
- The station core interiors (escalating-ramp flights) are data only; the
  first pass can block each core as an open frame with its landings.
- City NPC schedules, interiors and the people's homes (`RESIDENT_HOMES`) are
  not part of this pass.
- Every design in `city.md` marked "proposed" is the user's direction as
  drawn, awaiting their review in play: build it as specified, and raise
  anything that does not work at game scale rather than redesigning it.
- The backlog rows for this work are Ci9 to Ci20 in
  `docs/architecture/settlement_backlog.md`; each names its "builder later"
  part.
