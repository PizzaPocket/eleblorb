# P11 planning handoff — 2026-10-24

For the next planning session (Claude Code, cloud). Start with
`/moy P11` or `/moy plan P11`; this note says where the design stands and
what is left.

## Where P11 stands

**Design accepted by the user, 2026-10-24.** No build has started. The
next step is the **build brief and handoff for the local builder**.

| Piece | Status | Source of truth |
|---|---|---|
| Representative wall: three bays plus one bastion | accepted | `moy_p11_architectural_study.md`, `WALL.kit.study`, model `moy_wall_gardens_3d.html` |
| Whole-ring bay programme | proposed, shown to the user, no objections | `WALL.kit.circuit` (146 slots), model `moy_wall_circuit_3d.html` |
| North/South gatehouse | accepted: open court, bell in the Watch-side tower, plain North court | `moy_p11_gates_study.md`, `WALL.kit.gates`, model `moy_wall_gates_3d.html` |
| East/West joins, West roof garden | accepted with the gates | same |
| Bastion shade canopy on all seven bastions | proposed; the user hasn't objected | `WALL.kit.circuit.rules.canopy` |

Published models (update these URLs, never make new ones):
- study: https://claude.ai/artifact/BzLXjYVgfFBb94ssQavX7a
- whole wall: https://claude.ai/artifact/EAvZDeDsyAkmTf22nWjEgs
- gates: https://claude.ai/artifact/QqXwjfVDt6XD6bKQBPVVEv

## The bay programme, in brief

- the Arches: 5 shuttered bays (P18 keeps shells and shutters);
- service door: the bay behind each of 7 bastions, and both ends of the Line House (9);
- street-end threshold: the bay facing each street that stops at the Rim Walk (11);
- garden and seat alternate everywhere else, restarting with a garden after each fixed bay (50 + 39);
- blind bays at gatehouse flanks and along the Line House.

Arcade Street's north end runs into the Line House, so it gets no threshold.
That's the existing plan, not a change.

## What the next session does

1. **Write the build brief** in `moy_pkg_P11.md`, replacing its withdrawn
   rollout sections (2–9 are historical; section 7 on gates is superseded by
   `moy_p11_gates_study.md`). Follow the `moy_pkg_P0.md`/`P3.md` layout:
   area, target level, depends on, read first, what to build, collision,
   checks, viewpoints, report, decisions.
2. **Hold it to the practical standard** (roadmap, 2026-10-21): a visually
   solid, playable wall at Ohio/Snowhio quality. The parts/joins schedules
   are design references, not certificates; no part-by-part reporting.
3. **Order the build** in coherent batches, for example:
   1. the bay kit and blind bay;
   2. roll it round the ring from `WALL.kit.circuit`;
   3. bastions;
   4. North/South gatehouses;
   5. East/West joins and the West roof garden;
   6. Rim Walk path and planting.
4. **Coordinate with P10** (trains): it owns tracks, platforms, station
   cores, lifts and moving ramps. P11 owns the shell, guards, the watch walk
   and the landscape. The P10/P11 track-midpoint convention is still to be
   reconciled against the actual implementation (see `moy_pkg_P11.md`
   section 3 and P10's brief).
5. **Write `moy_p11_build_handoff.md`** (currently a hold notice) as the
   builder's entry point, then give the user the one-line build prompt from
   the roadmap's quick start.
6. **Update** the roadmap row, then commit as the owner and push to main.

## Known rough edges (polish, not blockers)

- **Night view of the whole-wall model:** the occupied arches barely glow.
- **Whole-wall model's gatehouses:** they share the gates page's code, but
  were load-checked only, not screenshotted.
- **Circuit model's overview:** the estate and downtown towers dominate it
  from some angles.

## Practical notes for a cloud session

- `tools/city_layout.py` needs `shapely` (`pip install shapely`).
- After changing plan data:
  - re-embed the JSON in every `docs/drawings/moy_*.html` that carries
    `/*DATA*/`;
  - refresh the two source hashes (`scripts/city_plan.gd`,
    `tools/city_layout.py`) in `assets/generated/moy_city/manifest.json`
    when the bake builder doesn't read the change;
  - run `tools/check_moy_bake.py`.
- Chromium screenshots of these models are slow (about 30 s per view in the
  software renderer); use `page.screenshot` with a clip, not an element
  screenshot.
- Built P3–P6 source and diagnostics live in the user's local checkout and
  may not be on main. Don't assume or recreate them.
