# Moy: handoff for the next builder and reviewer (2026-10-19)

For Luna (builds) and Sol (reviews), or anyone else picking this up cold.
Read `moy_build_roadmap.md` first; this adds what the roadmap does not say.

## 1. Where things stand

- **P0 (the check suite and rig): done.** `underside` is 0; fixtures 10/10;
  baseline `docs/diagnostics/checks/moy-2026-10-19.*`. Sections 12 and 13 of
  `moy_pkg_P0.md`.
- **P1 (pass 4): done at L2.** Sections 7 and 8 of `moy_prototype_pass_4.md`;
  diagnostic `docs/diagnostics/2026-10-19-moy-P1-fixes-4.md`.
- **Ready to build:** P3 (market lanes), P4 (Old Moy tower houses). P17 (BLOCK
  tower) is *fix* (section 11, folded into section 13 of its brief).
- **Run `git status` and `git log -5` first.** The last session may have left
  commits unpushed or the final audit's baseline files modified.

## 2. Open items, and who owns them

| Item | Owner |
|---|---|
| Four lift calls at the Crossing's deck concourse have no walk cell within 2 m (a +6.5 landing near each tower lift, or drop the stop) | P7, Crossing to shippable |
| The Crossing's `overlap` (136), `solid` (35) and the roof's `headroom` warnings (8) | P7 |
| West Gate towers: 42 `reach` findings (flights and landings) | P11 |
| The arch legs' east wall band is open for the outer platform | P11 (recorded in the roadmap) |
| The park's paving is wound face-down and invisible: `_park_ground_body`, use `_add_facing_triangle` | P8 |
| Under-flight wedges are closed with solid skirts (`_flight_underfill`, `_helix_underfill`); the plan's guard opens where the outer pair leaves the walk | done, in P1's diagnostic |

## 3. Prompts to paste

**Build session (Luna), for package P__:**

> Build package **P__** from `docs/architecture/moy_pkg_P__.md`. Read `AGENTS.md`,
> `CLAUDE.md`, then the brief, then `docs/architecture/moy_handoff_2026-10-19.md`
> section 5. Run the check suite on your area before you say you are done
> (section 4) and write the diagnostic the brief asks for. Do not change the plan
> data (`tools/city_layout.py`) except as the brief says. Do not mark any status
> in the roadmap; the reviewer does. Commit by package, as the repository owner,
> with no AI credit, and push.

**Review session (Sol), for package P__:**

> Review the build of package **P__**. Read `docs/architecture/moy_build_roadmap.md`,
> the package's brief, its newest diagnostic under `docs/diagnostics/`, and
> `docs/architecture/moy_handoff_2026-10-19.md`. Follow section 6 of the handoff.
> Write the result as a new dated section at the end of the brief (the form is
> in sections 8, 10 and 12 of `moy_pkg_P0.md`): "Result: done" or "Result: fix",
> what to keep, an ordered fix list, the report the next build owes, decisions.
> Then update the package's row in the roadmap. Do not build the fixes yourself
> unless asked.

## 4. The commands

Godot is `/Applications/Godot.app/Contents/MacOS/Godot`. Run from the repo root.
**Close the Godot editor before pushing** (the pre-push hook refuses otherwise).

```text
# rebake after any change to the builder or the plan (the runtime refuses a stale bake)
Godot --headless --path . tools/bake_moy_city.tscn
python3 tools/check_moy_bake.py

# the suite: fixtures, then an area, then the whole city (about 4.5 minutes)
Godot --headless --rendering-method gl_compatibility --path . res://tools/world_checks.tscn -- --fixtures=true
Godot --headless --rendering-method gl_compatibility --path . res://tools/world_checks.tscn -- --kingdom=moy --date=<date> --area=x0,z0,x1,z1 [--checks=a,b]
Godot --headless --rendering-method gl_compatibility --path . res://tools/world_checks.tscn -- --kingdom=moy --date=<date>

# looking at a place without walking it
  --reach-map=x0,z0,x1,z1,y0,y1     an ASCII map of reached (R) and unreached (u) cells
  --cell-probe=x,z;x,z              every cell in a column: body, shape, clearance, what is overhead
  --debug-cell=x,z                  the raw hit and the support decision for one column

# the P1 checks and shots (rendered, not headless, for the shots)
Godot --headless --path . res://tools/validate_moy_runtime.tscn -- --p1-only
Godot --path . res://tools/validate_moy_runtime.tscn -- --p1-only --shots
```

World coordinates: model x = world x + 560, z the same, height = model y - 60.

## 5. Gotchas that cost hours

- **A parse error in a Godot script makes a headless run hang forever**, not
  fail. If a run does not finish, read its log's first lines before waiting.
- **GDScript wants tabs.** A patch that writes spaces breaks the file. Check with
  `grep -c "^ " file.gd` (it should print 0).
- **Type inference:** `var x := expr` fails when `expr` comes from an untyped
  array or a `for` loop over one. Annotate (`var x: Vector3 = ...`).
- **`python3 tools/city_layout.py --json <scratch>/c.json`** needs `shapely` (run
  it without `-I`). On this machine it rewrites three long lines of
  `scripts/city_plan.gd` (Old Moy street and lot corners; the installed `shapely`
  differs). Put those lines back to the committed text (`git show HEAD:scripts/city_plan.gd`)
  and keep only your changes. Never edit `city_plan.gd` by hand.
- **A body named with "landing", "platform", "flight", "ramp" or "walkway" is
  tagged a walk deck** by `_add`, and the `underside` check then wants a soffit.
  Name solid fills and skirts something else.
- **The walk grid sees the highest hit of each body in a column.** A glass rail
  on a belt used to hide the belt (fixed: it goes down through box tops under
  0.45 m). If a flight "has no cells", probe a column with `--cell-probe`.
- **A cell inside a body tagged `solid_fill` is not standable** (`_cell_clearance`).
  Tag any solid skirt or fill you build with `set_meta("solid_fill", true)`. The
  test is deliberately not general: a blanket "inside any solid" test rejected
  every deck sitting a few centimetres under an overlapping neighbour and lost
  78,000 reached cells.
- **Escalator belts are 1.2 m wide, 0.9 m deep, boxes centred on their line;**
  the walking surface is 0.45 m above the endpoint's height. Landing pads are
  now placed just past a flight's end (`pad_beyond`), not under the belt.
- **The plan is locked.** A builder fix is fine; moving a street, level or
  footprint is a change request for a planning session.
- **The web build is deprecated:** never commit `build/web`.
- **No AI credit** in commits or pull requests (`CLAUDE.md`).

## 6. How to review a build

1. Read the brief's newest section and the diagnostic. Check every claim you can
   against the code and the data; the last three builds each had a claim that was
   true of the check but not of the world.
2. Run the fixtures. Run the suite on the package's area (and the whole city if
   the geometry changed). Compare with `checks/moy-2026-10-19.*`: **no new
   blocking finding** in the package's own elements, and every old one triaged.
3. Open the screenshots. A flat colour, a camera inside a body, or a view that
   shows no ground is not evidence.
4. For anything the suite calls unreachable, probe it (`--reach-map`,
   `--cell-probe`) before blaming the geometry: three times it was the oracle.
5. Record what you did not verify, in the review, in one line each.
6. Mark the roadmap row; commit as the repository owner; push.
