# Fire Caldera: second build pass, instructions

2026-10-18. These are instructions for the next implementation chat. They
follow the user's walkthrough of the first build of the generated walkways
and Heartworks (`54bbf41`), and the loading assessment
(`docs/diagnostics/2026-10-18-fire-kingdom-loading.md`).

**This document lists what changes.** The designs are:
- `fire_caldera_walkways.md`;
- `fire_caldera_heartworks.md` (section 4a);
- `fire_caldera_buildings.md` ("Walkthrough fixes");
- the model, `docs/drawings/fire_caldera_3d.html`.

If this document and the data disagree, the data wins: report it. Do the
steps in order.

## 0. Read first

1. `AGENTS.md`, `CLAUDE.md`.
2. This document.
3. `fire_caldera_walkways.md` sections 2.4, 2.5, 3.1, 3.3 and 4;
   `fire_caldera_heartworks.md` section 4a; `fire_caldera_buildings.md`,
   "Walkthrough fixes".
4. The model's places: *The funicular*, *The Gate Terrace*, *The Renewal grand
   ramps*.

**The plans are generated.** Never edit them by hand. Regenerate them with
`python3 tools/fire_caldera_walkways_layout.py` and
`python3 tools/fire_caldera_heartworks_layout.py`. Both already pass.

## 1. Loading first

The assessment found 114 s from scene request to first frame, almost all of it
spent recomputing terrain heights. Do its steps 1 to 4, in its order:

1. **Cache the coarse grid's vertices once,** after the rivers are set up
   (`fire_kingdom_terrain.gd`, `_vertex` and `_coarse_mesh_height`). Reuse them
   for the mesh, normals, the fine ground's blend, collision and gameplay
   queries. The measured saving is about 83%, with the same geometry.
2. **Skip the coarse wall sampler where the fine bowl's blend weight is
   zero** (`fire_caldera_ground.gd:186`).
3. **Bake static architecture offline,** as Moy and the Chinese village do,
   with a source signature that fails visibly when it is stale. The roofs'
   CSG (section 7) goes into the bake.
4. **Stage Fire's build in the loading queue,** in sub-frame jobs.

Measure before and after, in the diagnostic. Then do the rest of this pass
on the faster scene.

## 2. The walkways: the generic fixes

Each of these was seen in one place but is wrong everywhere. Fix the builder
(`fire_caldera_plan_walks.gd`), not the places.

1. **Build each flight's slope only.** Use `FLIGHTS[...].deck`: it runs mouth
   to mouth and leaves out the landings.
   - A flight's landings are part of its levels' surfaces and are built only
     there.
   - The first build drew every landing twice, at one height. That is the
     flicker at:
     - the gate ramp's head (glass over the terrace's basalt);
     - the ring;
     - the Renewal ramps' tops;
     - the service lanes.
2. **Never build an owned level.** Skip levels with `build: false` (owner set),
   that is `oren-roof`: no deck, no guard. The level exists only for the
   spiral to land on (section 6).
3. **The ground under the walks.**
   - For each level in `SITE.beds` with `kind: "ground"`: cut the ground mesh
     and its collision under the level's surface down to `cut_to`, as the
     plots' bands are cut (`fire_kingdom_terrain.gd:582-622`).
   - Build a basalt retaining edge along each `retaining` run (points
     `[x, ground Y, y]`), its top at the ground, its face down to the walk.
   - Cut the refuge pads the same way, with a retaining edge round their outer
     ends.
   - Cut the ground under each flight's arclength intervals in
     `SITE.flight_cuts`.
   - The promenade is buried by up to 1.4 m today.
   - Check: walk the whole promenade; no ground shows above it.
4. **The glass.** Use `SITE.materials.deck_glass`.
   - A deck is one clear sheet: the top face faces up, the bottom face faces
     down, `CULL_BACK`, alpha 0.2, roughness 0.05.
   - The edges are opaque steel.
   - It must never read as two layers from above.
5. **The guards.** Posts and handrail in `SITE.materials.guard_steel`
   (`CalderaShell.STEEL_BLUED`, metallic 0.9, roughness 0.2). Panes in
   `guard_glass`. This applies everywhere, including the Heartworks.
6. **Winding.** Every face faces out (Godot's front faces are clockwise seen
   from outside). Fix these:
   - `_add_face` (`plan_walks.gd:318-331`) flips any triangle to face up, so
     flight tops face down;
   - level tops are forced to an up cross product;
   - guard panes face inward;
   - `_add_box` posts have inverted normals;
   - `_tube` builds the handrail inside out.
   Then turn culling back on for opaque parts.
7. **Remove** `RenewalGlassFinishInPromenade` (`plan_walks.gd:125-132`). It is
   coplanar with the deck and turned 90° off it. The immersion tongue now
   starts at the deck's lava edge (`SITE.immersion_tongue.start`).
8. **Validator.** Add a check that no two walkable surfaces overlap within
   2 cm of the same height, anywhere in the caldera, buildings included.

## 3. The Gate Terrace and the Tempering Gate

- **The terrace.** Build the `gate` level from the plan: the terrace plus the
  funicular's station wing, with the notch cut out.
  - It is guarded all round: the two open ends are gone.
  - Its openings are only the arrival gallery's mouth, the inn's bridge, the
    two platform gates (`SITE.funicular.gates`) and the stair head.
  - Its plinth goes down to `SITE.gate_plinth.bottom` (41.73), under the wing
    too.
- **The gate.** Rebuild it from `SITE.tempering_gate`, in the language of the
  retired `FireCalderaGround.build_arrival_threshold` (`9aeea61`), at the new
  size:
  - three refractory tubes along a superellipse arch (exponent 6), at depths
    −0.48, 0 and +0.48;
  - basalt SuperEgg feet;
  - a veil of four stained-glass SuperEgg fins hanging under the crown (teal,
    magenta, lime, cobalt), emissive at night, 3.4 m or more clear above the
    terrace;
  - no boxes.
  - Collision on the tubes and the feet; the fins are decorative.

## 4. The funicular

Data: `SITE.funicular`.

1. **Grade the corridor.** In `_legacy_terrain_height`, multiply the noise term
   by a corridor weight:
   - 0 within `corridor.clear` (25 m) of the line from `top` to the profile's
     last point;
   - smoothstepping back to 1 by `corridor.blend` (50 m);
   - converted to world coordinates through `FireCalderaPlan.to_world`.
   This is the same function `tools/fire_kingdom_terrain_bounds.py` uses
   (`noise_weight`). The ground under the track then matches the plan's
   `profile[i][3]` exactly. Check it: sample the live mesh at each profile
   point and report the largest difference (it should be under 5 cm).
2. **The viaduct.**
   - The bed: a basalt deck `bed.width` wide and `bed.depth` deep, its top
     0.15 under the rails, following `profile` (`[x, rail Y, y, ground Y]`).
   - The piers: SuperEgg, at `piers` (top, foot), socketed 1 m.
   - Two tracks, 3.4 m apart, each with two rails at the 1 m gauge.
   - Within the stations the bed rests on the station plinths.
3. **The stair.**
   - It is the walker's way up: build `stair.profile`, `stair.width` wide.
   - Treads where it is steeper than 18%, a ramp elsewhere.
   - Its guards follow `stair.guards`, in blued steel.
4. **The stations.**
   - The top station is the terrace's wing: a glass hood on slender columns
     over its platforms.
   - The lower station is the `funicular-foot` level (3.84) on a socketed
     plinth, with the ramp `FR` down to `foot-ground`.
   - Both have platform gates at the car doors.
5. **The cars.** Two cars; delete the three-box cabins.
   - **Body:** one SuperEgg cabin each, semi-axes `car.semi`, exponents
     `car.eps`, with a smoked-glass band and a door on its outer side.
   - **Ring frame:** the cabin hangs level in a ring frame that tilts with the
     grade, so its floor (`car.floor` over the rail) stays flat.
   - **Livery:** the ember car (red) and the ash car (white).
   - **Orientation:** the cars face along the track.
   - **Motion:** counterbalanced, docking at each station's centre with the
     floor at the platform's level. Move them along the profile's arclength,
     not a straight chord.
   - **Riders:** both characters ride on the car's floor (carried, not
     sliding).
6. **Why no car ran.**
   - `lift` is added to the tree before `set_script`, so it never gets READY
     with its script, and `_process` never starts.
   - The cars were parented to the walkway body
     (`fire_caldera_highline.gd:199-207`).
   - Fix both: set the script before `add_child` (or `set_process(true)`), and
     parent the cars to the funicular node.
   - Check: a car moves, docks, and carries both characters up and down.
7. **Collision.** The bed, piers, stair, guards, stations and cars are solid.
   No gap at the platform gates is wider than the car's door.

## 5. The Renewal grand ramps

- Build `RSE` and `RSW` as ramps, not stairs, from their `deck`.
- Each leaves the Highline landing outward, sweeps round a half-turn, and
  enters the deck at the middle of its side.
- Their guards are blued steel.
- Check:
  - walk both ramps down and up, with both characters;
  - nothing flickers at either end;
  - the feet arrive on the deck's sides, not its front.

## 6. Oren's house

- Delete the walkway glass terrace and its guard over Oren's roof (the
  `oren-roof` level is owned: section 2.2).
- The house's own parapet, paving and lift gap come back.
- The spiral stair lands on the house's terrace at `SITE.spiral.arrival_local`
  (the house's frame, clear of the lift).
- Oren's yard (`oren-yard`) now stops at the house's own ramp-foot landings.
  Build it from the regenerated surface: no back-porch slab over the ramp's
  foot.
- Check:
  - ride the lift to the roof and step off;
  - come down the spiral onto the terrace;
  - walk the ramp's foot and the yard: nothing flickers.

## 7. The buildings

The rules are in `fire_caldera_buildings.md`, "Walkthrough fixes".

1. **The inn's sign** (`_guest_entry_fin`, `fire_caldera_buildings.gd:477-489`).
   Keep the cobalt and amber leaves. Lead the shared bed-and-moon symbol into
   them in stained glass, after `VillageInn.build_bed_and_moon_sign`
   (`village_inn.gd:346`). No lettering.
2. **Clean skylight cuts** (`CalderaShell._build_roof`, `caldera_shell.gd:392-490`).
   Do as the spaceship does (`demo_spaceship.gd` `_build_hull`, `_glaze_windows`):
   - a high-resolution slab;
   - closed cutters, subtracted;
   - the result baked with `SolidModel.bake_when_ready`, crease normals
     rebuilt;
   - each glass dome made from the same cutter intersected with the slab's
     outer shell, outside the roof's CSG tree, with its own decorative
     collision policy.
   Bake the roofs offline (section 1). Check from the Highline that every
   roof reads as one clean slab with punched openings.
3. **City Hall** (`fire_caldera_civic.gd`).
   - **The terrarium:** its glass collides as its convex hull. The player can
     neither enter it nor be trapped in it.
   - **The ramp:** re-route the glass switchback (`_switchback_ramp`,
     :286-319) into the open hall, clear of every slab overhead by 2.4 m. It
     arrives on the upper gallery through the existing gap in its guard
     (x −5.4, z 0.85 to 3.25). If that cannot fit, cut a well in the west
     gallery slab over the ramp, guarded round. Keep the council's chairs off
     the ramp.
   - Check: walk up to the gallery and down again with both characters.
4. **Raised buildings' supports** (`_supertoroidal_pier`,
   `fire_caldera_highline.gd:301-339`).
   - Give the pier collision that matches its shape: stacked convex hulls,
     or cylinders, at its waist and flare, up to the platform. Not one thin
     core.
   - Delete the four orange `_beam` poles (:334-338).
   - Check: no character can walk into any pier.
5. **Entry audit.** Probe every closed visual in the caldera (buildings,
   piers, plinths, the terrarium, the cars, the gate's tubes) for a way in.
   The player must never reach a space not meant for them. Report each one
   found and fixed.

## 8. The Heartworks: lava and air

Data: `SECTION.lava_volumes`; design `fire_caldera_heartworks.md` 4a.

1. **Add `is_lava_at(point: Vector3) -> bool`** to `FireKingdomTerrain`. It is
   true only inside:
   - the reservoir: inside its outline, at or below 29.2, above its bed. Inside
     r 48 the bed is the dome's sphere (`floor.dome`: centre Y, radius); over
     the oculus (r < 7) the reservoir opens into the cascade;
   - the cascade: a frustum, radius by height from 6.0 at 22.2 to 4.2 at
     −29.6;
   - the pool: r 10.5 from −32.8 to −29.6.
2. **Add `get_lava_surface_at(point)`.** It returns 29.2 in the reservoir and
   the cascade, and −29.6 in the pool.
   - Register the cascade at its real shape, replacing `register_lava_column`'s
     infinite radius-10.5 cylinder.
3. **Switch the immersion callers to the 3D queries:**
   - `LiquidEnvironment.read` (its `floor_height` inside r 48 is the dome);
   - `LavaMode.enforce_access`;
   - `player._is_on_lava_surface` and the swim clamp (`player.gd:7233-7310`);
   - Xiao Hou Zi (`xiao_hou_zi.gd:750-765`);
   - the camera tint (`_update_camera_immersion`);
   - the ambience's muffling (`fire_kingdom_ambience.gd:45`).
   Keep `is_lava_area(xz)` for 2D uses: hazards and spawn rejection.
4. **Check:**
   - dive to the oculus and ride the cascade down;
   - step out of the pool onto the gallery: no tint, no swimming, walking;
   - walk every terrace in air;
   - re-enter the pool and swim back up the cascade into the reservoir.
   - Both characters, the full Lava Helm and two fire legs.

## 9. Report

In `docs/diagnostics/2026-10-18-fire-caldera-pass-2.md` (or the day's date),
report:
- the loading times before and after;
- the corridor's largest height difference;
- each check above, as passed, failed or not physically verified;
- every entry found in the audit;
- anything in this document that conflicts with the data.

Do not claim a walk you did not make.
