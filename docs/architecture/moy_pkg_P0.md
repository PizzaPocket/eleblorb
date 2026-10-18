# Package P0: the check suite and the screenshot rig

2026-10-18. Build-session brief. Read `moy_build_roadmap.md` first.

## 0. Why

Every bug the user found by walking the prototypes was a machine-checkable
fault:

| Fault | Where it was seen |
|---|---|
| two surfaces at one height, flickering | Fire's ramp heads and the ring; Oren's yard |
| water standing over its banks | Moy's reed pond |
| an underside that cannot be seen and does not collide | Moy's helices |
| a rib or hoop across a doorway | the Crossing's towers |
| a railing with no way through | Fire's funicular foot |
| a walk buried in the ground | Fire's promenade |
| a space you can get into and not out of | Fire's terrarium and piers |

This package builds those checks once, as one suite every package runs before
it is done, and a fixed set of screenshots that a reviewer can read without
playing. It is generic: Moy first, then the Fire Kingdom and the other
kingdoms reuse it.

## 1. What to build

**The command.** `tools/world_checks.tscn` (a headless scene) with
`tools/world_checks.gd`. It loads a kingdom's scene, waits for its build or
bake, runs every check, and writes:
- `docs/diagnostics/checks/<kingdom>-<date>.json`: every finding, with
  position, node path and check id;
- `docs/diagnostics/checks/<kingdom>-<date>.md`: a summary by check, with
  counts and the first 20 findings of each.

It exits non-zero when a check marked *blocking* fails.

Run it as:
`godot --headless --path . tools/world_checks.tscn -- --kingdom=moy [--area=x0,z0,x1,z1] [--checks=a,b]`

**Sources of truth.**
- **Walkable surfaces:** the static colliders the character can stand on
  (normal within the character's floor angle), read with the physics
  server's shape queries, not the meshes.
- **Visuals:** the MeshInstance3Ds.
- **What should be reachable:** the plan's markers. For Moy:
  - every `DECK.doors` entry;
  - every station platform;
  - every lift stop;
  - every landing in `ARCH.front`;
  - the Clock Room's entries;
  - every building door marker the builder places.
  Make the builder tag each door and landing with a `reach_target` meta, so
  the suite needs no Moy-specific code.

## 2. The checks

Each check has an id, a default (blocking or warning) and a tolerance.

**1. `overlap`: two surfaces at one height (blocking).**
- Rasterise the top faces of every walkable surface onto a 0.25 m grid.
- Flag any cell where two different mesh instances' faces lie within 2 cm of
  each other in height, with both facing up.
- Report each cluster once, with both node paths.

**2. `buried`: a walk in the ground (blocking).**
- For every walkable surface cell, sample the terrain's height.
- Flag the cell where the terrain stands above the surface by more than 2 cm
  inside its outline.

**3. `water`: water over its banks (blocking).**
- For every node tagged as water (meta `water_surface_y`), sample the ground
  along its outline, 0.5 m outward.
- Flag it where the ground is lower than the water's surface, unless the
  edge is marked as a weir or spout.
- Also flag water whose material is not the shared water material.

**4. `reach`: every target reachable on foot (blocking).**
- Flood-fill the walkable grid from the spawn and from each station
  platform. Use the character's step height, slope limit, a 0.45 m radius
  and a 2.0 m standing height.
- Let lifts, escalators and trains join their stops as links.
- Report every `reach_target` not reached, with the nearest reached cell.

**5. `trap`: spaces you can get into but not out of, and insides you should
not reach (blocking).**
- **Trapped:** from each reached cell, test whether the spawn's region can be
  reached back. Report any one-way pocket.
- **Inside:** report any reached cell inside the bounds of a building, pier,
  plinth or closed shell that is not tagged `enterable`.

**6. `headroom`: low ceilings over walks (warning; blocking on flights and
doorways).**
- From each reached cell, cast up 2.2 m (2.4 m on a flight).
- Report hits that are not the cell's own deck.
- Report ribs, hoops and beams across a doorway or a `ways_out` entry
  separately.

**7. `underside`: undersides and winding (blocking for walkable decks and
flights).**
- For every walkable deck and flight, check that a face is visible from below
  (front face facing down, or a material that is not culled), and that a
  collider blocks an upward ray from 1 m beneath.
- Report meshes whose winding faces inward (the face normal against the mesh
  centre on closed shapes).

**8. `solid`: substantial geometry without collision (warning).**
- Flag any visual mesh over 1.5 m in two dimensions that has no collider
  within 5 cm of it and is not tagged decorative (`CollisionPolicy`).

**9. `guard`: edges with a drop and no guard, and guards with no way through
(warning).**
- Walk every walkable surface's outline.
- Report a drop of 1 m or more with no guard or wall within 0.3 m.
- Report a reachable surface whose whole outline is guarded, with no flight,
  door or ground edge.

## 3. The screenshot rig

- **The set.** `tools/world_shots.tscn` renders a fixed set of named
  viewpoints for a package: a camera position and target, 1280 × 720, noon
  and dusk. It writes them to
  `docs/diagnostics/images/<date>-<package>/<name>-noon.png` (and `-dusk`).
- **Where the viewpoints come from.** For Moy, from the city model's places
  (`docs/drawings/moy_city_3d.html` `PLACES`: id, cam, at), converted with
  the model's mapping. Model x is world x + 560, and z is the same. Add
  height: model y + world datum (−60).
- **Per package.** Each package's brief lists its viewpoint ids. Add the
  standard set:
  - an overview;
  - two eye-level street views per district built;
  - one view looking up from under each flight built.
- **Rendering.** Run it rendered, not headless (the dummy renderer draws
  nothing). If the machine cannot render, say so in the diagnostic.

## 4. Proof that it works

Seed each check with a known fault and show that it catches it. Then remove
the fault. Use temporary scenes under `tools/world_checks_fixtures/`:

| Check | Seeded fault |
|---|---|
| `overlap` | two boxes at one height |
| `buried` | a slab under the ground |
| `water` | a pond whose water stands 0.4 m over its bank |
| `reach` | a platform with no way up |
| `trap` | a closed box with a hole in its top |
| `headroom` | a beam at 1.8 m over a walk |
| `underside` | a deck with no bottom face |
| `solid` | a 3 m box without collision |
| `guard` | a fully railed pad |

Run the suite on Moy as it stands after pass 4. List every finding by check;
do not fix them in this package. That list is the measured "now" for the
roadmap's levels.

## 5. Done when

- The suite runs headless on Moy in under 5 minutes.
- Every check catches its seeded fault.
- The rig renders the pass 4 places at noon and dusk.

## 6. Report

Write `docs/diagnostics/<date>-moy-P0.md` with:
- the suite's summary on Moy;
- each check's run time;
- the fixtures' results;
- the screenshot set;
- anything in this brief that could not be built as written, and why.

## 7. Review of the first build, and fixes (2026-10-18)

Reviewed: `3ca6156`, diagnostic `docs/diagnostics/2026-10-18-moy-P0.md`.
**Result: fix.** The diagnostic is honest: this is the suite's frame, not
the suite. Keep the command, the check ids, the timings, the JSON and
Markdown reports, the wait for Moy's packs, the exit code, and the rendered
screenshot rig.

**Fix these, in order:**
1. **One walk grid under every check.** Cast rays down on a grid over
   `--area` (0.5 m; 0.25 m for `overlap` only), keeping every hit whose
   normal is within the floor angle: each hit is a walk cell, with its
   height and its collider. Stack cells at one (x, z) by height. This
   replaces the AABB proxies in `overlap`, `buried`, `reach`, `trap`,
   `headroom` and `guard`.
2. **`reach` and `trap` as flood fills** over that grid, as section 2 says
   (step height, slope, 0.45 m radius, 2.0 m headroom), with lifts,
   escalators and trains as links. `trap` is the reverse fill from the
   spawn's region, plus reached cells inside untagged shells.
3. **`underside`:** an upward ray from 1 m under each walk deck and flight
   must hit a collider, and a face must be visible from below. Ignore
   meshes that are not walk decks (clouds, foliage).
4. **`overlap`:** only two *different* bodies' walk cells within 2 cm, one
   finding per cluster. The 2,252 findings today are mostly rails and track
   segments meeting end to end: exclude pieces of one run.
5. **`headroom`:** cast from walk cells only, not collider centres. The 295
   findings today are the Rim Walk's own wall.
6. **The fixtures** (section 4): all nine, each caught, then removed.
7. **Builder tags:** `reach_target` on every door, landing, lift stop and
   platform the builders place; `enterable`; `CollisionPolicy` decorative
   marks where missing. Tags only: change no geometry.
8. **The rig reads places:** `--package=P4` takes the brief's viewpoint ids
   from `moy_city_3d.html`'s `PLACES` (mapping in section 3), plus the
   standard set. Render the pass 4 places.
9. **Time:** under 5 minutes on all of Moy. If a 0.5 m grid is too slow on
   the whole city, run per package `--area` and say so.

**Report:** `docs/diagnostics/<date>-moy-P0-fixes.md`: each check's method,
its fixture result, the Moy baseline counts, the times, and the place shots.
