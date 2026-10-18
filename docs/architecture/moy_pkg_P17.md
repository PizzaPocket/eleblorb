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
- **shoulder pads**, 0.10 × 0.055 × 0.10 (ε 5.5 / 2);
- **a robot abdomen**: two stacked armoured plates (ε 5.5 / 5.5);
- **a neck**: a slim column on the hero's neck joint; no collar;
- **the hero's own solid hands** (no fingers) **and feet**, at its scale;
- **the light**, in the city blorbs' own colour (the city blorb's albedo
  and glow): a band between the abdomen plates, rings at the shoulders,
  knees and neck, a vertical slit on the chest plate.

**The head:** the hero's head shape (ε 2.5) at the mech's scale, split by
one curve:
- a **glass visor** over the face, the temples and the front half of the
  crown, down to a **chin line**;
- a **black shell** behind and under it: the back half, the jaw, the whole
  underside of the chin;
- the cut, in the head's frame normalized to its half-sizes: glass where
  `z > 0.02 + 0.55 × max(0, −y − 0.05)^1.6` and `y > −0.6 + 0.32 x²`;
- the visor **hinges at the crown**, swinging up and forward to let a
  blorb in.

**The pilot** fills the helmet: the head's own shape, inset from the shell
(0.87 in the model) so that it and its eyes stay inside; the game's own
blorb eyes on its skin, about 0.04 m wide, coloured by the blorb rule
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
