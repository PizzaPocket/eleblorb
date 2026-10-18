# Moy: the build roadmap

2026-10-18. This is the map from here to a finished city. The plan's big
strokes are settled (prototype passes 1 to 4). From now on the work is
production: bring every part of the city up to a finish, one package at a
time.

**Start here** in any new session about Moy.

## 1. Quick start for a new session

**Shorthand (Claude Code):** type `/moy` in a new session.
- `/moy`: the status of every package and what should go next.
- `/moy P3`: take package P3 (write its brief, or review its build).
- `/moy plan P17`: write or revise P17's brief.
- `/moy review P1`: review P1's build diagnostic.

The skill is `.claude/skills/moy/SKILL.md`. Or paste one of these in full:

> **Planning session (Claude Code):** We're picking up the Moy build. Read
> `docs/architecture/moy_build_roadmap.md` and take package **P__** (or: review
> the diagnostic for package P__). Follow the roadmap's "How we work".

> **Build session (the implementation chat):** Build package **P__** from
> `docs/architecture/moy_pkg_P__.md`. Read `AGENTS.md`, `CLAUDE.md`, then the
> brief. Write the diagnostic it asks for.

A planning session reads only:
1. this roadmap;
2. the package's own brief, if one exists;
3. the design docs and plan data the brief names.

It does not need this repository's history or earlier chats. Everything that
matters is in the files listed in section 6.

## 2. How we work

**Two roles.**
- **Planning (Claude Code):**
  - designs and decides;
  - keeps the plan data and its checks (`tools/city_layout.py` →
    `scripts/city_plan.gd`);
  - draws the models (`docs/drawings/`);
  - writes each package's brief;
  - reviews each build's diagnostic and screenshots.
- **Building (the implementation chat):**
  - builds a package from its brief in Godot;
  - runs the checks;
  - writes a diagnostic with the standard screenshots.

**One package at a time per area.**
- A package is one district, one kit, one landmark or one system.
- Two packages may run at once only if they touch different files.

**The loop:**
1. A planning session writes or updates the package's brief and marks it
   *ready*.
2. A build session builds it and writes `docs/diagnostics/<date>-moy-P__.md`,
   with the standard screenshots.
3. A planning session reviews the diagnostic and screenshots against the
   brief.
   - If it passes, mark the package *done* at its target level.
   - If not, write a short fix list as a new section of the same brief and
     mark it *fix*.
4. You walk the city at milestones (section 5), not after every pass.

**The plan is locked (version 1).**
- Moving a street, station, level or building footprint is a *change
  request*. Make it in a planning session, on purpose, with the plan's
  checks, never inside a build.
- Inside a package's area, a building's details (its kit, its facade, its
  interior) are open to design.

**The checks do the walking** (package P0). Every bug of the prototype passes
could have been caught by a machine:
- surfaces at one height;
- water over its banks;
- hidden undersides;
- ribs in doorways;
- railings with no opening;
- spaces the player could get into but shouldn't.

Once P0 is done, every build runs the suite and a package is not done until
it passes.

## 3. Levels of finish

Every element of the city is at one of these levels. A package raises named
elements to a target level. That is how a mixed area, like the Crossing with
shippable helices next to rough platforms, gets finished without rework.

| Level | Name | Means |
|---|---|---|
| L0 | absent | not in the game |
| L1 | massing | the plan's volumes, solid, at the right heights; plain materials |
| L2 | built | its real form: kit or bespoke structure, openings, every way in and out walkable, collision as it looks |
| L3 | dressed | materials, signs, planting, lighting, props, animation; reads as the place in the screenshots |
| L4 | shippable | passes the check suite and its screenshots; within the performance budget; you have walked it |

## 4. The packages

The status column is one of: ready (brief written), next (brief to write),
planned, done, fix, or in build.

The levels are estimates until the P0 audit measures them; P0's first
diagnostic replaces this column.

| ID | Package | Area | Now | Target | Status | Brief |
|---|---|---|---|---|---|---|
| P0 | **The check suite and the screenshot rig** | the whole city (and reused by every kingdom) | none | n/a | **ready** | `moy_pkg_P0.md` |
| P1 | Prototype pass 4: grand square, City Hall's front, the clock dome, the Clock Room, tower ribs, closed escalators, the pond | civic core, Crossing | L1 to L3 | L2 | **built, to review** (`03a9d7a`) | `moy_prototype_pass_4.md` |
| P2 | Bake and performance: the rendered probe, budgets, streaming | the whole city | owed | budgets met | planned | |
| P3 | **The market lanes kit**: boom houses, tile houses, lock-ups, the market flats, Arcade Street's roof, Lamp Lane; the Helmsmith moves off Civic Plaza to his shop on Lamp Lane | market lanes | L1 | L2 | **ready** | `moy_pkg_P3.md` |
| P4 | The Old Moy tower-house kit: 60 houses on their old roads, courtyards, the first well | Old Moy | L1 | L2 | next | (design: `moy_tower_house.md`) |
| P5 | The North Estate: slab and point blocks, void decks, linkways, courts, the neighbourhood centre, the hawker centre | North Estate | L1 | L2 | planned | |
| P6 | Downtown: the mid-rise podium kit, and the four towers' exteriors (the Windspire, BLOCK, north, south) | downtown | L1 | L2 | planned | |
| P7 | **The Crossing to shippable**: towers, helices, galleries, roof, the dome and the Clock Room, the ring, bridges, platforms, planting | Crossing | mixed L2 to L3 | L4 | planned (after P1) | |
| P8 | **The park**: the four quarters, the dry garden, the reed pond, the tea house and chess terrace, the lawn, the wind trees, walks, benches | park | L2 | L4 | planned | |
| P9 | **The giant playground**: climbing towers, nets, slides, perches, hoops, the pump track | park, south-east | L1 | L4 | planned | |
| P10 | **The trains**: cars, boarding, stations' finish, the timetable, the line house, the Watch train | all lines | L2 | L4 | planned | |
| P11 | The wall and the gates: the Wall Line, the East Gate (City Hall's arch) and the West Gate, watch posts, the Rim Corridor, the Rim Walk | edge | L2 | L3 | planned | |
| P12 | Streets and the Deck: paving, street furniture, picture signs, lighting, the Deck's gardens | everywhere | L1 to L2 | L3 | planned | |
| P13 | Enterable interiors, one sub-package each (below) | landmarks | L0 to L2 | L3 | planned | |
| P14 | People: the residents' looks, schedules, dialogue, the night market | city | ? | L3 | planned | |
| P15 | Outside the wall: turbines, the battery, water and recycling works, the launch site, city blorbs | desert | L1 to L2 | L3 | planned | |
| P16 | Final polish and performance | city | n/a | L4 | planned | |
| P17 | **The BLOCK tower, a story project** (iterative): its scenes, rooms and levels, Pinestein's sealed lab in its base, the lift to the climax near the top | BLOCK tower | L1 | L4 | **story set**; round P17a (the blorb mech) **ready** | `moy_pkg_P17.md` |
| P18 | **The Arches**: the old goods store in the wall's arches; the fight club (Tuesday, Friday) and the rave (Saturday night) | the wall by the South Gate | L0 | L3 | planned | |

**Order.**
1. P0 and P1 first.
2. Then P3, P4, P5 and P6: they are kits and districts, which fill the city
   and make the most visible difference.
3. Then the landmarks P7 to P11.
4. Then P12 to P15.
5. P17 and P18 are story places: each runs as several planning and build
   rounds of its own, once their districts (P6, P3 and P11) are at L2.
6. P2 runs alongside: re-measure performance after each district package.

**P13, the enterable interiors.** Each is its own sub-package:

| ID | Interior |
|---|---|
| P13a | the Grand Hotel (its public interior is already L2 from pass 3; detailed model: `moy_grand_hotel_3d.html`) |
| P13b | the library's Great Hall and heritage room |
| P13c | City Hall's Hall of the City and the mayor's open door |
| P13d | the Clock Room (finish only; it is built in P1) |
| P13e | the wet market |
| P13f | the hawker centre |
| P13g | Old Fu's tea house |
| P13h | the Reese–Miller house |
| P13i | (moved into P17) Pinestein's laboratory, sealed in the BLOCK tower's base; his Old Moy flat is not entered |
| P13j | Hiro's all-night store |
| P13k | the Helmsmith (his shop front and the move off Civic Plaza are in P3) |

**P17, the BLOCK tower.** One of the big projects, and iterative by design.
- **What it is:** narrative scenes spanning several rooms and levels of the
  tower; Pinestein's sealed laboratory in its base; a lift that rises to
  the top or near it for a climactic scene.
- **How it runs:** first a planning round that writes the tower's story
  beats and a section through it (which floors are entered, and what
  happens on each); then build rounds floor group by floor group, each to
  L3; the climax last.
- **Keep:** BLOCK is the city's plain bad guy, with no elaborate backstory
  (user, 2026-10-18). Its outside stays as P6 builds it.
- **Story round done** (2026-10-18): the vent-hood climb in, Pinestein's lab
  (he and Kask still work together; the city blorbs are their synthetic
  blorbs), the lift, and a boss fight against the blorb mech, suited in city
  blorbs that then join the party; Blorbus mounts the mech.
- **Model:** `moy_block_tower_3d.html`, the section and the route drawn from
  `CityPlan.BLOCK_TOWER.inside`, and the mech with its parts.
- **Minimal** (user, 2026-10-18): four places built (the way in, the lab,
  Kask's floors, the crown), the rest solid; two lifts join them, and the
  inside loads as its own scene on the rides. Rounds P17a to P17e. Rounds P17a to P17f are in the
  brief; P17a, the mech, needs no tower and can be built now.

**P18, the Arches.** One long vaulted hall in five bays of the wall
(`CityPlan.WALL.venue`, `city.md` section 6c), dug 10 m into the fill.
- **Program:** a ring in the middle bay (struck on rave nights), a bar in
  the east bay, a booth in the west; shutters on the Rim Corridor.
- **Nights:** the fight club on Tuesday and Friday nights, where the
  fighting blorbs fight; the rave on Saturday night, late till dawn, with
  lights and music; shut on other days. It hangs on the game's day and
  week clock and P14's schedules (the crowd walks there).
- **No text:** nothing names the nights; the player finds them by being
  there, or by following the crowd.

Each interior gets an architecture and interior brief (the `architecture` and
`interior-design` skills) before its build.

## 5. Milestones for your walk-throughs

| Milestone | After | You walk |
|---|---|---|
| M1 | P0, P1 | the civic core, the Crossing and the Clock Room, with the check suite green |
| M2 | P3, P4 | Old Moy and the market lanes as kits |
| M3 | P5, P6, P2 | the whole city at L2, at frame rate |
| M4 | P7 to P11 | the landmarks finished |
| M5 | P12 to P15 | the dressed city, with people |
| M6 | P16 | ship |

## 6. Where everything is

| What | Where |
|---|---|
| The city's design | `docs/architecture/city.md` (sections by district and landmark) |
| Kits | `moy_market_lanes.md`, `moy_tower_house.md` |
| Plan data and checks | `tools/city_layout.py`, which writes `scripts/city_plan.gd` (never edited by hand) |
| Models | `docs/drawings/moy_city_3d.html`, `moy_plan.html`, `moy_grand_hotel_3d.html`, `moy_block_tower_3d.html`, `moy_train_3d.html` (published: the city model https://claude.ai/artifact/YJq2qoeR9thJ67M5Xr23yd, the plan https://claude.ai/artifact/9qeXfC1J9oGNUT8pFmLWi1, the hotel https://claude.ai/artifact/HQ3yrpKk7SSaapbkDzmTWy, the BLOCK tower and the mech https://claude.ai/artifact/Cghz59HZajwK7RoZmrubpH) |
| Lore | `docs/world_bible.md` |
| Past build briefs | `moy_playable_prototype.md`, `moy_prototype_pass_2.md` to `_4.md` |
| Diagnostics | `docs/diagnostics/*moy*` |
| The game's builder | `scripts/moy_city_bake_builder.gd`, `tools/bake_moy_city.gd`, `tools/validate_moy_runtime.gd`, `tools/check_moy_bake.py` |

**Rules that always hold** (from `CLAUDE.md`):
- commit as the owner, with no AI credit;
- push to main;
- keep the drawings in sync with the plan;
- record new lore in the world bible;
- no explanatory in-game text;
- collision on substantial geometry;
- SuperEgg shapes;
- every power for every playable character.

## 7. Keeping this roadmap

At the end of a planning session, update:
- the package's row (status and level);
- any decision made, as a line in that package's brief.

Keep this file short. Detail belongs in the briefs and the design docs.
