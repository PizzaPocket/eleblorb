# Package P17: the BLOCK tower

2026-10-18. **Build brief, one build** (user: hand it all off at once, so
it can be played through; keep it simple). Read `moy_build_roadmap.md`
first.

- **Area:** the BLOCK tower, building 13 (`CityPlan.BUILDINGS` 13, world
  x −483 to −443, z 38 to 78), its outside and the three places inside
  that are entered; the climb's east neighbour; data `CityPlan.BLOCK_TOWER`.
- **Target level:** L3, playable end to end: walk up from Civic Plaza, get
  in, fight, win, leave with the mech.
- **Depends on:** nothing. This package builds the tower's outside itself
  (it comes out of P6's scope).
- **Keep:** BLOCK is the city's plain bad guy. A prototype: simple, playable,
  no extra story.
- **The model:** `docs/drawings/moy_block_tower_3d.html` (published:
  https://claude.ai/artifact/Cghz59HZajwK7RoZmrubpH). The tower, its
  section and the way through; the mech with its parts list; Kask and
  Pinestein. Match it.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, `moy_build_roadmap.md`.
2. `docs/architecture/city.md` 7c, "2. The BLOCK tower" (its form).
3. The model (above), all three viewers.
4. For the mech: `docs/traversal_powers_architecture.md`,
   `scripts/rig_adapter.gd`, `scripts/traversal_context.gd`,
   `scripts/party_control_director.gd`, `scripts/titan_suit_host.gd`, the
   two drivers `scripts/player.gd` and `scripts/xiao_hou_zi.gd`, and
   `tools/export_figure_reference.gd` (the hero's joints).
5. For the patterns to copy: `scripts/false_hero_nme.gd` (a boss whose
   suit falls away into joinable blorbs), `scripts/humongous_state.gd`
   (carry in Blorbus's core or mind-merge to pilot), `scripts/npc.gd` and
   `scripts/world_state.gd` (flags).

## 2. The story (user, 2026-10-18)

1. **Sneak in.** Climb the vent hoods to the one open louvre.
2. **Get to the top.** The lift inside goes up to the crown.
3. **The two and the mech.** **Kask** is the one in charge. **Pinestein**
   mind-controls the city blorbs from a distance: the one piloting the
   mech and the six worn as its suit. A thin thread of the city blorbs'
   blue runs from his temples to the mech while he does it.
4. **The fight.** A prototype boss fight against the mech.
5. **Win.** Beating the mech breaks Pinestein's control: the thread snaps,
   the visor opens, and the pilot and the six suit blorbs drop as seven
   wild, joinable city blorbs (as the False Hero's do). The mech kneels,
   empty.
6. **Claim it.** Switched to Blorbus, the hero can **pilot the mech or
   carry it in Blorbus's core**, exactly as with Humongous.
7. **After.** Kask and Pinestein stay, beaten. Talk to them again and they
   sound defeated. The lift takes the hero down to the lobby and out of
   the one door.

**Not in this build:** Pinestein's lab, Kask's floors, the lift's glimpses
(the plan keeps them as solid storeys for later). The Demon King gets one
line, Kask's, after the fight.

## 3. The tower's outside

**Section 12 is binding and wins wherever it differs from sections 3 to 5** (the base,
the slits, the climb, the louvre, the lift, the gallery, the mech).

From `CityPlan.BLOCK_TOWER` and `city.md` 7c. Replace the tower's current
massing in the bake with:
- **the shaft**, blue-black glazed brick, 26 × 24 m to 150 m, on its base
  set back 4 m and 9 m high; hairline slits every 4 m (decorative);
- **three rings of vent hoods** at 30, 55 and 80% of the height
  (`vents`, `vent`): solid, and **parkour landings**;
- **the open louvre**: one hood in the east face at the 55% ring
  (`inside.louvre`), its louvres open, lit warm at night; the way in;
- **the crown**: the four faces folded inward to the canted ridge
  (`crown`), its ribs, and **the eye**, the azure slit in the plaza face
  (`eye`), emissive, the only light;
- **the one door** on the forecourt (`door`): shut, with no way to open it
  from outside; it opens from the lobby;
- **the climb** (user: the way in is the vent-hood climb), from the street
  to the louvre, reachable by the hero and by Xiao Hou Zi:
  - the east neighbour (`inside.approach`, the 34-storey mid-rise 6 m off
    the east face) gets a stack of balconies on its west face every second
    storey, as parkour landings, up to the 30% ring's height;
  - a 6 m leap from them to the 30% ring;
  - from the 30% to the 55% ring, a window-cleaning rail up the east face
    beside the louvre: brackets every 2.5 m as parkour landings;
  - nothing in text marks the way.

## 4. Inside: three places and a lift

The data is `CityPlan.BLOCK_TOWER.inside`; its checks are in
`tools/city_layout.py`. The model's section shows it.

| Storey | Height (m) | Place |
|---|---|---|
| crown (L38) | 150 to 212 | **the arena**: a floor across the shaft at 150 m; the crown's hollow above, its faces and ribs seen from inside; the eye slit lighting it blue; **the gallery**, a glass-fronted balcony on the back slope (`arena.gallery`), reached by a stair from the arena floor; the lift's top stop |
| L20 | 79 to 83 | **the way in**: the plant floor behind the louvre: fans, ducts, the lift's door |
| L0 to L1 | 0 to 8 | **the lobby**: bare, double height; the lift's door; the one door out |
| the rest | | solid, never entered |

- **The lift** (`inside.lifts.lift`): one car in the core, stopping at the
  lobby, the way in and the crown, passing every other storey. Its
  interaction lists the other stops by direction ("Up", "Down") only.
- **Loading:** the inside is its own scene, kept out of the city's bake.
  It is instanced at its true place when the hero reaches the louvre, and
  freed after he leaves by the door. The ride up hides any load.
- **Collision:** solid floors, walls, the lift car and shaft, the gallery
  glass, the crown's faces; parkour landings on the ducts and the crown's
  ribs. The solid storeys need no collision: nothing reaches them.

## 5. The mech

Build it from the model's parts list. It is a playable rig, the third
**driver** (a script that builds a `TraversalContext`), as `CLAUDE.md`
requires: every power works on it.

**Body:**
- **on the hero's own rig**: every joint is the hero's, scaled by **1.05**,
  so 1.99 m to the top of the head. It fits the hero's doors.
- **thin limbs**, SuperEgg tubes joint to joint (upper arm 0.030 m radius,
  forearm 0.027, thigh 0.040, shin 0.034), a slim piston behind each shin,
  actuator balls at the joints;
- **one matte black metal** for body, limbs, neck and head shell; **bright
  steel** on the chest plate only;
- **shoulder shells** (user, 2026-10-18, replacing the first pads, then reshaped): a rounded
  shell 0.13 × 0.12 × 0.13 (ε 2.4) that **covers the shoulder joint**, tilted 18° down toward
  the arm and cut flat just under the joint's centre, so the actuator ball (0.044) and its ring of
  light lie under it and the arm leaves from beneath; the shell lies inside the blorb chest's
  surface (held by the plan's check), so with the suit on only the blorb shows;
- **a robot abdomen**: two stacked armoured plates (ε 5.5 / 5.5);
- **a neck**: a slim column on the hero's neck joint; no collar;
- **the hero's own solid hands** (no fingers) **and feet**, at its scale;
- **the light**, in the city blorbs' own colour (the city blorb's albedo
  and glow): a band between the abdomen plates, rings at the shoulders,
  knees and neck, a vertical slit on the chest plate.

**The head:** the hero's head shape (ε 2.5) at the mech's scale, split by **one
line** (user, 2026-10-18: the first build had two, a sweep and a chin line):
- a **glass visor** in front of the line: the crown's front half, the temples, the
  face and the front of the chin;
- a **black shell** behind and under it: the back half, the jaw and the whole
  underside of the chin;
- the line, in the head's frame normalized to its half-sizes: glass where
  `z > 0.02 + 0.85 × (max(0, −y) / 0.62)³`. Over the crown's front half it is
  the plane z = 0.02; below the temples it sweeps forward and down and closes at
  the chin, one smooth curve all the way round, with no separate chin line;
- the visor **hinges at the crown**, swinging up and forward to let a blorb in.

**The pilot** fills the helmet: the head's own shape, inset from the shell
(0.87 in the model) so that it and its eyes stay inside; the game's own
blorb eyes on its skin, about 0.04 m wide, **lying flat and upright on it** (each set in the skin's own frame: its thin axis on the skin's normal where it sits, its long axis along the skin's up; neither pitched nor rolled), coloured by the blorb rule
(`blorb.gd`); its core inside. A city blorb glows; Blorbus does not.

**Rig:** publishes the rig-neutral joints through its own
`_blorb_suit_pivot_map()`; real joints wherever a power poses one, checked
with `RigAdapter.articulates()`; lengths through `ctx.scaled()`.

**Suit:** worn through the suit system, `suit_rig_scale` 1.05 in its
`PlayableCharacterProfile`. Each piece sits on its rig as on the hero's;
the head blorb sits over the helmet. Draw the pieces in with
`suit_limb_fit` if they read baggy on the thin limbs.

**Parity:** `tools/check_power_parity.py` passes with three drivers, with
no new `EXEMPT` entry.

## 6. The fight (a prototype)

Copy the shape of `false_hero_nme.gd`:
- **the boss:** the mech, piloted by a city blorb and wearing six city
  blorbs, driven by an NME controller; a named boss: far more HP than the
  False Hero (start at about 400) and a far larger XP reward (about 300);
- **it:** walks at the hero, punches in reach, streams city current from
  its arm at middle range (the city blorbs' own stream), and now and then
  leaps; it stays in the arena;
- **Pinestein's thread:** a thin line in the city blorbs' blue from his
  temples to the mech's head, live while the fight runs;
- **the start:** the hero steps onto the arena floor; the two lines in
  section 8 play; the fight begins;
- **if the hero faints**, he wakes as the game already rules, and the
  fight resets in full on his return;
- **the win:** the thread snaps; the visor opens; the pilot and the six
  suit blorbs drop as seven wild, joinable city blorbs; the mech kneels,
  empty, and is the player's. Save it (`WorldState`), so it stays won.

## 7. Carrying or piloting the mech

Copy `humongous_state.gd`: a `MechState` autoload beside `HumongousState`,
with the same three modes (`released`, `carried`, `merged`), saved.
- When Blorbus, under direct control, walks up to the empty mech, he gets
  the choice, as with Humongous:
  - **"Pilot the mech"**: he climbs in, the visor shuts, and awareness moves
    into the mech (through `party_control_director.gd`, as a mind merge);
    the hero follows;
  - **"Carry the mech in Blorbus's core"**: it is stowed, and travels with
    the party across gates.
- From the core: **"Release the mech"** sets it down by Blorbus, and
  **"Pilot the mech"** sets it down and climbs in.
- While piloting: **"Climb out"** opens the visor; the mech kneels and stays.
- The hero alone, not as Blorbus, gets no mech choices.

## 8. The people and their lines

**Looks:** `docs/architecture/moy_pkg_P17_looks.json` (npc.gd properties),
as the model's "people of the tower" shows.
- **Dr. Vera Kask**: tall, iron-grey bun, a long blue-black dress, black
  gloves, an azure pin at the collar. All existing kit except the pin.
- **Palbert Pinestein**: older, slight; wild white hair; glasses; an open
  off-white lab coat from the shoulders to the knees over a mustard shirt,
  a battery glowing in its pocket.
- **New shared pieces**, in the shared figure code, not in their scripts:
  `FigureHair.STYLE_WILD` (fitted through `FigureHair.hair_edges()`);
  `wears_lab_coat` on `npc.gd` (pieces that follow the thorax, abdomen and
  hips, each cut by the same open front; lapels, a collar, sleeves, a
  glowing pocket); a collar pin. Record them in the `character-design`
  skill's toolkit.

**Where they stand:** in the gallery, Kask at the glass, Pinestein beside
her with his fingers at his temples. Both stationary; talkable after the
fight.

**Lines** (in the moment; nothing explains a mechanic):
- When the hero steps into the arena:
  - **Kask:** "All the way up the outside. How persistent."
  - **Pinestein:** "Shh, shh. They're listening to me now. Go on, my
    lovelies."
- When the mech falls:
  - **Pinestein:** "No, no, come back... They've gone quiet. All of them."
  - **Kask:** "He promised me so much more than this." (the one Demon
    King line; it names no one)
- Talked to afterwards (one line each, picked in turn):
  - **Kask:** "Take it, then. Take all of it." / "Don't expect me to
    clap."
  - **Pinestein:** "Years of tuning, and you walk in through a vent." /
    "They don't hum for me any more."
- The mech, when Blorbus reaches it: the line "The visor stands open." with
  the choices in section 7.

## 9. Checks

1. **The plan validator** passes (`tools/validate_city_plan.gd`), and
   `python3 tools/city_layout.py` reports no problem.
2. **The check suite** (P0) on the tower's bounds, if built; otherwise say
   so and list what was checked by hand.
3. **The climb**, with the hero and with Xiao Hou Zi: street, balconies,
   leap, hoods, rail, louvre.
4. **The play-through**, recorded as screenshots: Civic Plaza to the
   louvre; the lift up; the lines; the fight won; the seven blorbs
   befriended; Blorbus pilots the mech, climbs out, carries it in his core,
   releases it; Kask and Pinestein's after lines; the lift down; out of
   the door with the mech. Then reload a save and see it all still won.
5. **The mech:** `check_power_parity.py` passes with three drivers; every
   traversal mode run once on it, a screenshot of each pose; it walks
   through the smallest door the hero uses.
6. **Collision:** the climb's landings hold both characters; nothing in the
   arena traps them.
7. **Performance:** frame time at the forecourt, the louvre and in the
   arena, before and after.

## 10. Report

`docs/diagnostics/<date>-moy-P17.md`: what was built, the checks, the
play-through screenshots, the mech's pose screenshots (front, side,
three-quarter; empty, piloted, suited), performance, and every place the
data and this brief disagreed.

## Decisions log

- 2026-10-18 (user): the way in is the vent-hood climb; Kask and Pinestein
  work together; BLOCK is human villainy first, the Demon King one subtle
  line from Kask; the climax is a boss fight against a blorb mech whose
  suit and pilot are city blorbs (the synthetic blorbs, made by
  Pinestein's experiments; nothing lures them in).
- 2026-10-18 (user): keep the tower minimal: only the places the story
  enters are built; the rest is solid; the inside loads as its own scene.
- 2026-10-18 (user): the mech: on the hero's joints × 1.05; thin limbs in
  one matte black metal, bright-steel chest plate, shoulder pads, a robot
  abdomen, a neck, the hero's hands and feet; light in the city blorbs' own
  colour; the hero's head split into a glass visor down to a chin line and a
  black shell; the pilot fills the helmet with real blorb eyes, inside the
  shell; the suit fits the rig as it fits the hero's.
- 2026-10-18 (user): Kask and Pinestein's looks; Pinestein a mad scientist
  with wild hair and a lab coat from the shoulders.
- 2026-10-18 (user): **one build, a really simple story**: sneak in, lift
  to the top, Kask in charge, Pinestein mind-controlling the city blorbs,
  a prototype fight, the win breaking his control, seven blorbs to claim,
  the mech piloted or carried as Humongous is, the two left defeated. The
  lab, Kask's floors and the glimpses leave this build. One lift: lobby,
  way in, crown; out by the one door. P17 builds the tower's outside, so it
  leaves P6's scope.
- 2026-10-18 (user): **P17 gets a binding parts and joins schedule** (91 parts, 20 joins,
  `BLOCK_TOWER.parts` and `.joins`), as P3 and P4 have, for the outside, the climb, the
  three places inside, the lift and the mech; doors one leaf on one hinge as `world_door.gd`
  builds them; every frame the outline of what closes it.
- 2026-10-18 (user): the mech's visor is **one line**, not a sweep and a chin line; the shoulder
  pieces are **low rounded shells close to the body, inside the blorb chest**; the model
  page has a **Blorb suit** toggle.
- 2026-10-18 (user): the shoulder shell is a **cover over the shoulder joint**, not a pad beside it (the joint must not sit on the pad); the pilot's eyes lie flat and upright on its skin, not pitched up or rolled; the shoulder joints must not clip through the shells (the model measures every vertex of the ball and ring against the shell).
- 2026-10-18 (planning, found while scheduling): the climb's balconies were 7.2 m apart
  and the hero jumps 1.36 m, so they become a fire escape of six ramps (31°) with a landing
  each, the last level with the 30% ring, then a bracket every 1.2 m; the base is set back
  under the shaft, not outside it; the open louvre is an opening at the plant floor under the
  hood; the east face has two hoods; the gallery's glass faces the arena; the slits are vertical.

## 11. Review of the first build (2026-10-18; its fix list is folded into section 13)

Reviewed: `3ca6156`, diagnostic `docs/diagnostics/2026-10-18-moy-P17.md`.
**Result: fix.** A source-and-smoke pass: nothing was played or
screenshotted, as the diagnostic says. Keep the tower's outside in its own
pack, the streamed inside, the lift with Up and Down, the lines (all
correct), the three `WorldState` flags, `MechState`'s three modes, the boss's
400 HP and 300 XP, the seven joinable blorbs, `FigureHair.STYLE_WILD`, the
lab coat and the pin, and parity with three drivers.

**Fix these** (now folded into section 13, with the items the schedule added):
1. **The mech is boxes on top of a figure.** `block_mech.gd` builds a dark
   `ProceduralFigure` and then lays 30-odd `BoxMesh`es over it on the
   `Visuals` root, not on the joints, so when the figure walks the boxes
   stay still. Build it from the model's parts list (section 5): SuperEgg
   tubes joint to joint, actuators, shoulder pads, the two abdomen plates,
   the hero's own hands, feet and head shape, each parented to its pivot.
   No boxes, and no second body under them.
2. **The head:** the hero's head shape split by the brief's one curve into
   the glass visor and the black shell; the visor **hinges at the crown**.
   Today a box rotates about its own middle.
3. **The pilot and the suit:** the pilot is the head's shape inset in the
   helmet, with the game's blorb eyes (section 5). The six blorbs are
   **worn through the suit system** on the mech's pivot map, not six
   quarter-size blorbs placed on its body.
4. **A second mech appears.** Leaving by the door frees the inside, but the
   hero is still within 36 m, so `city_generator.gd` instances it again at
   once, and `_ready()` spawns an empty mech because the fight is won. The
   same happens on every later visit, even while the mech is carried or
   parked elsewhere. Spawn the empty mech only while `MechState` is
   `released` with no world body; and do not re-instance the inside until
   the hero has left the tower's bounds.
5. **The fight does not reset.** If the hero faints, the boss keeps its
   damage. Reset it in full when he returns (section 6).
6. **The way in misses the louvre.** The trigger tests `|z| < 3` about the
   shaft's middle, but the louvre is at `inside.louvre.at` (z 55, local
   −4). Read its place from `CityPlan.BLOCK_TOWER` and centre the trigger
   on the open hood.
7. **Read the plan, don't copy it.** The inside hard-codes its floors,
   lift and gallery. The gallery is built at local z 5.5 to 11.5 with its
   glass at the back; the data puts it at z 2 to 7 (world 61 to 66) with
   the glass facing the arena. Read every place from
   `CityPlan.BLOCK_TOWER.inside`.
8. **No text:** remove `Hud.show_message("The mech kneels, empty.")`. The
   kneel and the open visor show it.
9. **Piloted speed:** with no traversal mode running, the mech walks at
   `MOVE_SPEED` 2.4 instead of its profile's 6.0.

**Then the checks section 9 asks for, played:** the climb with both
characters, the play-through screenshots, the mech's pose screenshots,
and frame times. If the machine cannot run the game rendered, say so; that
is the one thing this pass cannot do without.

**Report:** `docs/diagnostics/<date>-moy-P17-fixes.md`.

## 12. Parts and joins (binding)

**Build every piece from the schedule:** `CityPlan.BLOCK_TOWER.parts` (91 parts)
and `.joins` (20 joins), with its numbers in `.sched` and `.mech`. The model
(`moy_block_tower_3d.html`) draws the same schedule and lists it in its tables
("The parts", "The joins", "The numbers"): match it piece for piece. Nothing is
left to choose. If a piece seems missing or wrong, say so in the diagnostic; do
not invent one. The vocabulary is the tower house's (`moy_pkg_P4.md` 2.7), with
one more shape.

- **Shapes:** `egg` (`SuperEgg.build_part`), `clipped` (`SuperEgg.build_clipped_part`,
  cut by the planes its join names, every cut capped), `wall` (a `SolidModel`
  solid of the outline, openings punched), `punched` (a closed cutter; the glass is the
  cutter intersected with the wall, a ring is the cutter grown by `ring` less the
  cutter), `box` (floors, ceilings and the car's slabs only, for their stated reason:
  they fill to the walls), `decal` (painted), and **`facet`**: a flat plate on three
  or four stated corners (`BT_PT`: the shaft's four top corners and the ridge's four
  ends), thickness `t` inward, for the crown's folds, where two planes must meet on a
  straight edge.
- **Frame:** the tower frame (x east, y up, z south, origin the shaft's centre on the
  forecourt): `world = frame.origin + (x, z)`. The plaza face is z −12.
- **Doors and openings:**
  - The **one door** is one leaf on one hinge, built as `scripts/world_door.gd` builds a
    door: an egg reaching below the floor and cut flat at it (`door_leaf`,
    ε 5.5 / 4.0, half-thickness 0.025), hinged on the west jamb, opening outward 78°.
    It is in the **base wall**, 4 m behind the plan's door line, at x +1 (world x −461).
    Shut and bare from outside; it opens after the fight.
  - Each of the **three lift landing doors** (lobby 0, way in 79.0, crown 150) is one leaf
    on one hinge the same way (`lift_door_leaf`), thrown open while the car is at it.
    The car is open-fronted and has no door of its own.
  - **The frame is the leaf's outline** (`outline`, `clear` 0.015): the door opening, the
    louvre opening and each landing opening are the silhouette of what closes them,
    flat at the floor; each steel ring is that outline grown by `ring`, less it.
  - **The open louvre** is an opening in the east face at z −4 (world z 55), 2.4 × 2.2 m,
    its sill flush with the plant floor (79.0), the hood over its head (the hood's
    underside is the opening's head, 81.2; its top is the 55% ring, 82.5). Its **two
    louvred leaves** (`louvre_leaf`, from one parent by `louvre_set`) are thrown back
    flat on the wall either side, lit warm. The sill ledge (3.0 × 1.2 m) is where the
    climb arrives.
  - **The eye** is a cutter through the crown's first plaza plate (`crown_n1`), 1.2 × 24 m,
    its glass the cutter intersected with the plate. There are no windows.
- **The body:** the base is 18 × 16 × 9 m, set back 4 m from the shaft (the shaft hangs
  over it by 4 m: the first build had it 4 m *outside*; fix that). Its soffit is a built
  face. The shaft is 26 × 24 m, walls 1.0 m. Four pilasters each on the base and the shaft.
  The slits are **vertical** (six a face, spacing 4 m), continued up the crown's plaza and
  back faces to the ridge (the first build drew horizontal courses).
- **The hoods:** 36, in three rings with their tops at the ring heights (45, 82.5, 120 m);
  4 a ring on the plaza and back faces (x ±3.25, ±9.75) and **2 on each side face
  (z ±4)**. Each is 4.5 × 1.3 m and 1.4 m proud. The hood tops are parkour landings.
- **The crown:** seven plates (`crown_fold`, a `meet` join). The plaza and back faces are
  warped quadrilaterals, so each is two plates on one named diagonal; the eye lies
  wholly inside `crown_n1`. Thickness 0.5 m. The inside carries twelve ribs
  (`crown_rib`, landings) under the slits.
- **The climb** (every hop within the hero's jump, held by the plan's checks: jump
  apex 1.36 m, reach 2.9 m): the first build's balconies 7.2 m apart could not be climbed.
  - **The fire escape** on the east neighbour's west face: **six flights** of 12.5 m
    at 31° (7.5 m up each; the world's ramps are at most 32°), 1.5 m wide, with a landing at
    the top of each (2.4 × 2.4 m, tops at 7.5, 15 … 45 m), rails 1.1 m. The sixth landing is
    at 45 m, level with the 30% ring, in front of the east hood (z −4).
  - A **2.2 m leap** from it to the hood.
  - **The rail** up the east face between the two hoods: **29 brackets** (0.9 × 0.18 × 0.7 m,
    tops at 46.2 + 1.2 n, up to 79.8 m), alternating either side of the face's middle
    (z ±0.5), a hold every 1.2 m, and a bar behind them. The last is a short step to the sill.
  - Nothing in text marks the way.
- **Inside** (`.sched.inside`): the **lobby** is the base's inside (15.6 × 13.6 m, 7.8 m
  clear, flat at the forecourt), four light strips, the push bar on the door; the **way in**
  is 24 × 22 m, floor top 79.0, 3.6 m clear, ten wall fans, four ducts (landings), an
  overhead pipe, three lamps; the **arena** is 24 × 22 m, floor top 150.0. The **core**
  (x 0 to 7, z −2 to 5, pit to 156 m) has the **lift cavity** (3.6 m, pit to 154 m) cut
  through it; the car is 3.2 m outside, 2.4 m clear, open-fronted, with a call panel and
  a lamp. **The gallery** is the plan's place (z 2 to 7, floor 164), 17.2 m wide, its glass
  in four bays on the arena side (the first build had it at the back, facing the wrong
  way). The shell is 0.5 m thick, so the standing ground ends near z 6.5. **The stair** is
  two flights of 35 treads (0.2 up, 0.29 along, 2.0 wide) along the west wall, going
  north, a landing at 157, and back south to the gallery (the first build had eight
  steps). Rails on the open sides.
- **Stations:** hero at the lift door's front (3.5, 150, −4), the mech at (7, 150, −8),
  Kask (1.0, 164, 3.4) and Pinestein (3.6, 164, 3.4), both facing the arena.
- **The mech** (30 parts, `BLOCK_TOWER.mech`): built on the hero's joints × 1.05, every part
  parented to its joint, **no boxes and no second body under them**:
  - **limb tubes** (`thigh`, `shin`, `upper_arm`, `forearm`) run joint to joint and are
    **cut flat at both joint centres** (`socket_cut`); the **actuator ball** at each joint
    (at least 1.05 × the tube's radius: the ankle and wrist balls are grown to 0.037 and
    0.03) covers the cut. The pistons are rods, not cut;
  - the torso is a stack (`torso_stack`): pelvis, lower plate, the band of light in the seam,
    upper plate, chest, each cut at the planes it shares (pelvis top = hips + 0.08, the seam
    0.014 about the middle, the chest's foot = chest − 0.15);
  - **shoulder shells** (see section 5): rounded covers over the shoulder joints, inside the blorb chest;
  - the hero's own hand, foot and head at the mech's scale; **the head is split by the one
    line** (section 5), the visor hinged at the crown; the pilot is the head inset to 0.87;
  - collision is one capsule (r 0.28, h 1.99); the parts are decorative;
  - the suit is **worn through the suit system** on the mech's pivot map, `suit_rig_scale`
    1.05, the head blorb over the helmet. The model has a **Blorb suit** toggle to see the mech
    with and without it; with it on, the shoulder shells are not seen.
- **Collision:** `solid` and `landing` as the table says; the louvre leaves, door leaf,
  landing leaves and glass are solid; the fire escape, the hoods, the brackets, the sill, the
  ducts, the ribs, the stair and the gallery are landings.
- **The test**, as the architecture skill sets it: look at every join from both sides. A gap,
  a step, a double thickness or a mismatched profile fails, however small. Report the
  schedule part by part in the diagnostic.

## 13. The one build: what to do, in order

**Build P17 from section 12's schedule, and fix everything the first build got wrong.**
Read `AGENTS.md`, `CLAUDE.md`, then this brief. The first build's code stays where it is
right (the outside's own pack, the streamed inside, the lift's Up and Down, the lines, the
three `WorldState` flags, `MechState`'s three modes, the boss's 400 HP and 300 XP, the seven
joinable blorbs, `FigureHair.STYLE_WILD`, the lab coat and the pin, parity with three
drivers); the rest is rebuilt from the schedule.

1. **The mech** is built from the schedule: each part an egg or a clipped egg parented to
   its joint, cut and capped as its join says, with the one-line head, the shoulder shells,
   the pilot and the six blorbs worn through the suit system. Delete the boxes and the
   second `ProceduralFigure` body.
2. **The outside** is rebuilt from the schedule: the base set back under the shaft's
   overhang, the shaft with its vertical slits, 36 hoods, the louvre with its leaves, the
   crown's seven plates, the eye, the door as `world_door.gd` builds a door; the fire escape
   and the rail. Replace the first build's boxes. Every piece has the collision the table gives.
3. **The inside** is rebuilt from the schedule, every place read from
   `CityPlan.BLOCK_TOWER` (never hard-coded): lobby, way in, arena, core and lift with its
   three landing doors, the gallery on the plan's side with the glass facing the arena, the
   stair of two flights.
4. **Triggers** come from the plan: the inside loads when the hero is within reach of the east
   face; the way-in trigger is centred on the open louvre (`inside.louvre.at`, z −4 local),
   not the shaft's middle.
5. **The second mech:** leaving by the door frees the inside; do not re-instance it until the
   hero has left the tower's bounds. Spawn the empty mech only while `MechState` is `released`
   with no world body.
6. **The fight resets** in full when the hero faints and returns.
7. **No text:** remove `Hud.show_message("The mech kneels, empty.")`.
8. **Piloted speed:** with no traversal mode running, the mech walks at its profile's 6.0
   (scaled), not `MOVE_SPEED` 2.4.
9. **Then the checks of section 9, played:** the climb with both characters (every hop is
   within the jump, by the plan's checks), the play-through screenshots, the mech's pose
   screenshots (with the suit on and off), frame times. If the machine cannot run the game
   rendered, say so.

**Report:** `docs/diagnostics/<date>-moy-P17-fixes.md`, with the schedule part by part.

