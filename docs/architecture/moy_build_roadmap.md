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

**Current handoff,2026-10-22:** a fresh builder conversation in the same
P5/P6 implementation checkout handles P7 first, then P8/P9 together. Use
`moy_p7_p8_p9_build_handoff.md`. Preserve the local built P3–P6 source/bake;
main is a planning integration base, not a replacement for that working tree.
P5 has an accepted practical L2 review. The user reports P6 built; its local
completion source/report must be recorded at handoff (not found on published
main during the planner check). Old review/fix automation stays paused.
P6 local report is available at `docs/diagnostics/2026-10-22-moy-P6.md`;
its known hotel-side ingress blocker remains open. The latest local415-pack
bake and final superellipse-deck correction are preserved in a verified snapshot.

## Latest user direction — 2026-10-21: playable city, Ohio/Snowhio detail

**Done is better than perfect.** Complete the market town (P3) and Old City
(P4) as nice playable environments broadly matching the provided3D models
and briefs, about as sophisticated as Ohio and Snowhio. This replaces earlier
precision-certification interpretations and universal reachability gates.

The district-level finish line is:

1. Planned building sites are visibly built in their appropriate types;
   no conspicuous unfinished proxy blocks. Preserve locked layout, main
   silhouettes, heights/proportions, facade rhythm, palette and major features.
2. Market town has its recognizable boom/tile/lock-up houses, market flats,
   Arcade roof, Lamp Lane/shop and courts; Old City has recognizable tower
   forms, infill, courts/passages, roof links and the first well composition.
   Existing village-level simple geometry and decorative approximations are fine.
3. Ordinary streets, entered shops, court passages and intentional connecting
   routes work. Major visible surfaces have sensible collision; no major
   holes, broken meshes or circulation blockers. Core shop interactions remain
   usable. Not every surface must be reachable or separately tested.
4. The districts look coherent and complete at normal gameplay distance,
   beside their neighbours, by comparison with the plan models and existing
   villages. Minor seams, small decorative omissions and nonblocking visual
   imperfections may remain as polish; they do not hold up completion.
5. A current integrated bake and a focused gameplay walkthrough verify both
   areas, plus a few representative ordinary-resolution screenshots. Keep
   required repository checks; no exhaustive part/join spreadsheet, millimetre
   fit certification, cinematic capture batch or full route matrix is required.
6. Summarize actual remaining defects honestly. A major gameplay or visual
   defect still matters; minor polish is a follow-up list, not another build gate.

Schedules remain design references, not manufacturing certificates. Use
existing Ohio/Snowhio patterns and pragmatic reusable geometry. No new climbing
system, movement retuning or P2 optimization. Work P3 shared forms then P4,
in coherent construction batches. Use fast local previews during edits;
full bake/stream activation/render runs belong at integration milestones and
final verification, not after every small edit. Do not create new frameworks.

The fresh implementation owner follows `moy_p3_p4_finish_handoff.md` and works
toward both districts being finished, rather than stopping at each coping or
representative for a precision review. Historical raw findings stay intact,
but older gate lists do not override this direct user clarification.

**Reachability clarification (user, 2026-10-21).** Finish architecture kits.
Collision/support applies to substantial geometry; route availability applies
to usable circulation and explicitly authored parkour routes, not every
surface. Keep construction and route acceptance separate. Prior blanket
house076 access blockers are superseded by this decision. Current task:
`moy_p3_boom_construction_finish.md`; no movement investigation or retuning.

**Where the work happens (user, 2026-10-24).** Cloud Claude Code sessions
do planning only, from main. Builds run in the user's local implementation
checkout, which holds built source, bakes and diagnostics that may not be on
main. Planning never assumes, recreates or overwrites that local state, and
reviews a build only once its diagnostic is pushed.

**Two roles.**
- **Planning (Claude Code, cloud):**
  - designs and decides;
  - keeps the plan data and its checks (`tools/city_layout.py` →
    `scripts/city_plan.gd`);
  - draws the models (`docs/drawings/`);
  - writes each package's brief;
  - reviews each build's diagnostic and screenshots.
- **Building (the implementation chat, local checkout):**
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

**The plan decides the parts** (user, 2026-10-18). Every kit carries a
parts and joins schedule in the plan data: each visible piece's SuperEgg
shape and sizes, and how each pair of pieces is cut where they meet. The
build uses it as its design reference; since 2026-10-21 the diagnostic does
not report it part by part and reviews do not certify fit against it.

**The checks do the walking** (package P0). Every bug of the prototype passes
could have been caught by a machine:
- surfaces at one height;
- water over its banks;
- hidden undersides;
- ribs in doorways;
- railings with no opening;
- spaces the player could get into but shouldn't.

Every build runs the repository's required checks. Since 2026-10-21 a
package is done at the practical finish line above: major gameplay or
visual defects block it; residual suite findings that are minor polish go
on a follow-up list.

## 3. Levels of finish

Every element of the city is at one of these levels. A package raises named
elements to a target level. That is how a mixed area, like the Crossing with
shippable helices next to rough platforms, gets finished without rework.

| Level | Name | Means |
|---|---|---|
| L0 | absent | not in the game |
| L1 | massing | the plan's volumes, solid, at the right heights; plain materials |
| L2 | built | its real form: kit or bespoke structure, openings, usable circulation and authored routes walkable, collision as it looks |
| L3 | dressed | materials, signs, planting, lighting, props, animation; reads as the place in the screenshots |
| L4 | shippable | passes the check suite and its screenshots; within the performance budget; you have walked it |

## 4. The packages

The status column is one of: ready (brief written), next (brief to write),
planned, done, fix, or in build.

The levels are estimates until the P0 audit measures them; P0's first
diagnostic replaces this column.

| ID | Package | Area | Now | Target | Status | Brief |
|---|---|---|---|---|---|---|
| P0 | **The check suite and the screenshot rig** | the whole city (and reused by every kingdom) | built | n/a | **done** (reviewed 2026-10-19; section 12's follow-ups built and closed, section 13; baseline `checks/moy-2026-10-19.*`, 282 s: overlap 405, reach 52, trap 0, headroom 39, underside 0, guard 2,769; fixtures 10/10) | `moy_pkg_P0.md` |
| P1 | Prototype pass 4: grand square, City Hall's front, the clock dome, the Clock Room, tower ribs, closed escalators, the pond | civic core, Crossing | L1 to L3 | L2 | **done at L2** (2026-10-19, section 8: rain gardens rebuilt, City Hall's front built and reached, `underside` 0; wedges under the flights closed with skirts, the outer pair fixed; the tower lifts' deck calls and the Crossing's overlaps carried to P7; diagnostic `docs/diagnostics/2026-10-19-moy-P1-fixes-4.md`) | `moy_prototype_pass_4.md` |
| P2 | Bake and performance: the rendered probe, budgets, streaming | the whole city | owed | budgets met | **fix** (second review 2026-10-19, section 11: telemetry/lifetime evidence improved, node growth explained; Estate p95 ~60 ms, stalls and controlled-route proof still open; diagnostic `2026-10-19-moy-P2-fixes.md`) | `moy_pkg_P2.md` |
| P3 | **The market lanes kit**: boom houses, tile houses, lock-ups, the market flats, Arcade Street's roof, Lamp Lane; the Helmsmith moves off Civic Plaza to his shop on Lamp Lane | market lanes | L1 | L2 | **built — practical milestone** (user approved moving on2026-10-22; source/bake/evidence recovery checkpoint saved; streaming/walkthrough/polish follow-ups retained; `moy_P3_P4_checkpoint_2026-10-22.md`) | `moy_pkg_P3.md` |
| P4 | **The Old Moy tower-house kit**: 99 houses (60 on the old roads, 39 on the grid), the courts and their passages, the roof ramps, the first well | Old Moy | partial proxy pass | L2 | **built — practical milestone** (user approved moving on2026-10-22;386-pack integrated bake current; remaining cold-start checks/polish carried forward, not certified all-green; `moy_P3_P4_checkpoint_2026-10-22.md`) | `moy_pkg_P4.md` |
| P5 | The North Estate: slab and point blocks, void decks, linkways, courts, the neighbourhood centre, the hawker centre | North Estate | L2 | L2 | **accepted — practical L2** (sense-check2026-10-22; recognizable district and public circulation, independent12/12 civic/276 landing checks; cold activation remains follow-up; `moy_P5_review_2026-10-22.md`) | `moy_pkg_P5.md` |
| P6 | Downtown: the mid-rise podium kit, and three towers' exteriors (the Windspire, north, south; BLOCK's is P17's) | downtown | L2 | L2 | **built — review; hotel connection blocked** (2026-10-22; ten sites/three tower exteriors; unchanged hotel wing obstructs ingress; `docs/diagnostics/2026-10-22-moy-P6.md`) | `moy_pkg_P6.md` |
| P7 | **The Crossing to shippable**: towers, helices, galleries, roof, the dome and the Clock Room, the ring, bridges, platforms, planting | Crossing | mixed L2 to L3 | L3 build; L4 final | **ready — first in P7–P9 handoff** (72 parts/19 joins; detailed scene shared by both models; focused practical construction checks) | `moy_pkg_P7.md` |
| P8 | **The park**: four quarters, dry garden, reed pond/arched bridge, tea/chess parasols, lawn/lodge and real shade trees | park | L2 | L3 build; L4 final | **ready after P7, with P9** (2026-10-22: one integrated build;41 parts/12 joins; connected grounds and shared model) | `moy_pkg_P8.md` |
| P9 | **The giant playground**: canyon towers, nets, slides, perches, hoops and pump track | park, south-east | L1 | L3 build; L4 final | **ready after P7, with P8** (2026-10-22:30 parts/12 joins; shared park entry and model; practical play build) | `moy_pkg_P9.md` |
| P10 | **The trains**: cars, boarding, stations' finish, the timetable, the line house, the Watch train | all lines | L2 | L3 build; L4 final | **ready after P7–P9** (2026-10-23: hollow cars, doors, service/turnback/streaming, station finish; full schedule and revised model) | `moy_pkg_P10.md` |
| P11 | The wall and the gates: the Wall Line, the East Gate (City Hall's arch) and the West Gate, watch posts, the Rim Corridor, the Rim Walk | edge | L2 | L3 | **gates accepted; build brief next** (2026-10-24: user accepted the open court, bell and plain North court; study accepted; whole-ring programme `WALL.kit.circuit`; gates study `moy_p11_gates_study.md`, `WALL.kit.gates`, model `moy_wall_gates_3d.html`; the build brief next) | `moy_pkg_P11.md` |
| P12 | Streets and the Deck: paving, street furniture, picture signs, lighting, the Deck's gardens | everywhere | L1 to L2 | L3 | planned | |
| P13 | Enterable interiors, one sub-package each (below) | landmarks | L0 to L2 | L3 | planned | |
| P14 | People: the residents' looks, schedules, dialogue, the night market | city | ? | L3 | planned | |
| P15 | Outside the wall: turbines, the battery, water and recycling works, the launch site, city blorbs | desert | L1 to L2 | L3 | planned | |
| P16 | Final polish and performance | city | n/a | L4 | planned | |
| P17 | **The BLOCK tower**, one playable build: its outside and climb, the way in, the lift, the crown arena, the blorb mech (playable, carried or piloted as Humongous), the boss fight, Kask and Pinestein | BLOCK tower | L1 | L3 | **ready** (pilot revised 2026-10-19: Blorbrain, electric-pink Psychic captive; Psychic-only piloting, section 14; binding parts and joins schedule, 91 parts, 20 joins, in section 12; the first review's fix list folded into the one build list, section 13; model republished) | `moy_pkg_P17.md` |
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
| P13d | (moved into P7) the Clock Room: designed with the clock dome in the Crossing |
| P13e | (dropped, user 2026-10-24) the wet market: its building stays, not entered |
| P13f | the hawker centre |
| P13g | (dropped, user 2026-10-24) Old Fu's tea house: its building stays, not entered |
| P13h | the Reese–Miller house |
| P13i | (moved into P17) Pinestein's laboratory, sealed in the BLOCK tower's base; his Old Moy flat is not entered |
| P13j | (dropped, user 2026-10-24) Hiro's all-night store: its building stays, not entered |
| P13k | the Helmsmith (his walk-in shop floor and the move off Civic Plaza are in P3; P13k finishes the shop and the workshop) |

**P17, the BLOCK tower.** One build, handed off whole so it can be played
through (user, 2026-10-18).
- **The story, kept simple:** sneak in up the vent hoods; the lift to the
  crown; Kask in charge and Pinestein mind-controlling Blorbrain, his captured electric-pink Psychic
  test subject and mech pilot, and six city suit blorbs; a
  prototype fight against the blorb mech; the win breaks his control and
  frees Blorbrain and six city blorbs; only Psychic blorbs can pilot;
  Blorbus pilots the mech or carries it in his
  core, as with Humongous; the two stay, defeated; out by the lift and the
  one door.
- **Built:** the tower's outside (it leaves P6's scope), the climb, the way
  in, the lobby and the crown arena; the rest is solid. The lab and Kask's
  floors wait for a later round.
- **Model:** `moy_block_tower_3d.html`, drawn from `CityPlan.BLOCK_TOWER.inside`
  and the game's exported figures.
- **Keep:** BLOCK is the city's plain bad guy (user, 2026-10-18).

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
| P11 wall/garden model | `docs/drawings/moy_wall_gardens_3d.html` (revised 27m architectural study + bastion; design review; published https://claude.ai/artifact/BzLXjYVgfFBb94ssQavX7a) |
| P11 whole-wall model | `docs/drawings/moy_wall_circuit_3d.html` (whole ring at medium detail, bay programme from `WALL.kit.circuit`; published https://claude.ai/artifact/EAvZDeDsyAkmTf22nWjEgs) |
| P11 gates model | `docs/drawings/moy_wall_gates_3d.html` (North/South gatehouse, East/West joins, West roof garden; published https://claude.ai/artifact/QqXwjfVDt6XD6bKQBPVVEv) |
| P11 implementation hold | `docs/architecture/moy_p11_build_handoff.md` |
| P10 rail model | `docs/drawings/moy_train_3d.html` (revised fleet/boarding/cabin/Line House/network; local, external publication pending) |
| P10 builder handoff | `docs/architecture/moy_p10_build_handoff.md` |
| P7 Crossing model | `docs/drawings/moy_crossing_3d.html` (local; publication pending) |
| P6 Downtown model | `docs/drawings/moy_downtown_3d.html` (local; publication pending) |
| P5 North Estate model | `docs/drawings/moy_north_estate_3d.html` (local; publication pending) |
| P2 performance atlas | `docs/drawings/moy_performance_3d.html` (local; reuses the city model, publication pending) |
| The city's design | `docs/architecture/city.md` (sections by district and landmark) |
| Kits | `moy_market_lanes.md`, `moy_tower_house.md` |
| Plan data and checks | `tools/city_layout.py`, which writes `scripts/city_plan.gd` (never edited by hand) |
| Models | `docs/drawings/moy_city_3d.html`, `moy_plan.html`, `moy_grand_hotel_3d.html`, `moy_block_tower_3d.html`, `moy_old_moy_3d.html`, `moy_market_lanes_3d.html`, `moy_train_3d.html` (published: the city model https://claude.ai/artifact/YJq2qoeR9thJ67M5Xr23yd, the plan https://claude.ai/artifact/9qeXfC1J9oGNUT8pFmLWi1, the hotel https://claude.ai/artifact/HQ3yrpKk7SSaapbkDzmTWy, the BLOCK tower and the mech https://claude.ai/artifact/Cghz59HZajwK7RoZmrubpH, Old Moy's tower houses https://claude.ai/artifact/53om5eQsd5KvwUirnxrc7z, the market lanes https://claude.ai/artifact/B4d92cjYsy6TMBUCar7gRT) |
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

P7 revision (2026-10-22): outer-bezel shell fittings, distinct magenta hour/minute markers and planned interior beds; ready for implementation.

P7 garden refinement (2026-10-22): roughly53% green interior grounds with
paved circulation, lighter muted magenta markers, and explicit rooted climbing
vines with pendant tips. Model includes garden-plan and vine close-up views.

P8/P9 combined handoff (2026-10-22): `moy_p8_p9_build_handoff.md`. The user
requested one integrated park pass. Shared model: `docs/drawings/moy_park_playground_3d.html`
(local; external publication pending). Practical L2/L3 construction is the
first milestone; final L4/polish and whole-city budgets remain tracked.

P8 revision2026-10-22: broad lawn patches, a gently humped Chinese-garden
stone bridge, and a checked2m buffer around the full revised pond bank.

P7–P9 integration2026-10-22: `moy_p7_p8_p9_build_handoff.md` supersedes the
separate park handoff. The complete P7 scene is shared by the standalone and
integrated models via `docs/drawings/moy_crossing_scene.js`; no simplified
station alternative remains. The dry garden has curved footprints and a worn
trail. Keep the live P5/P6 working tree when opening the fresh builder chat.

P7–P9 pull/sense-check2026-10-22: latest planner main `fdbd6545` integrated
without replacing the newer local P3–P6 packs. Combined browser model loads,
canonical Crossing parity and merged plan validation pass. Ready for sequential
P7 then P8/P9 implementation; no construction acceptance or new builder launch
claimed. Recovery and checks: `moy_p7_p8_p9_pull_review_2026-10-22.md`.

P10 design2026-10-23: `moy_pkg_P10.md` and `moy_p10_build_handoff.md`.
Build after the P7–P9 integrated review in the same implementation checkout.
TRAIN.kit supplies the complete parts/joins reference; the model shows hollow
cars and real door apertures. Turnback/lane fit is an early build task. Logical
night fleet storage replaces the impossible common depot for disconnected lines.

P11 design2026-10-23: High Line-inspired integrated paths/planting, ground
Rim circuit and upper garden pauses. `moy_pkg_P11.md` and
`moy_p11_build_handoff.md`; WALL.kit39 parts/15 joins. Coordinate P10
midpoint track convention and station-approach ramps before wall rollout.

P11 architectural revision2026-10-23: user rejected the first model/readiness
claim. Handoff withdrawn. Active `moy_p11_architectural_study.md` and proposed
wall charter develop one three-bay section and one complete bastion; revised
model has coordinated elevations/plans/sections and eye views. Review before
gate adaptation or repeated construction. Old39-part rollout is not approved.
