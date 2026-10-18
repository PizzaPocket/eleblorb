# Package P17: the BLOCK tower, a story project

2026-10-18. Planning brief, round 1 (the story and the section). Read
`moy_build_roadmap.md` first.

- **Area:** the BLOCK tower, building 13 (`CityPlan.BUILDINGS` 13, world
  x −483 to −443, z 38 to 78), its forecourt and the shaft's outside; data
  `CityPlan.BLOCK_TOWER`.
- **Target level:** L4, built in rounds (section 6).
- **Depends on:** P6 for the tower's outside at L2 (rounds P17b to P17e).
  Round P17a, the blorb mech, needs no part of the tower and can be built
  now.
- **Keep:** BLOCK is the city's plain bad guy, with no elaborate backstory.
  Its outside is P6's (`city.md` 7c); this package works inside it and on
  its vent hoods.

## 1. Read first

1. `AGENTS.md`, `CLAUDE.md`, `moy_build_roadmap.md`.
2. `docs/architecture/city.md` 7c, "2. The BLOCK tower" (its form), and the
   residents' rows for Pinestein and Kask (grep `Pinestein`, `Kask`).
3. `docs/world_bible.md`: "BLOCK, where the sinister side of Moy lives",
   "Pinestein and the city blorbs", "The BLOCK tower as a story place".
4. For round P17a: the model's mech section and parts list
   (`docs/drawings/moy_block_tower_3d.html`), `tools/export_figure_reference.gd`,
   `docs/traversal_powers_architecture.md`,
   `scripts/rig_adapter.gd`, `scripts/traversal_context.gd`,
   `scripts/party_control_director.gd`, `scripts/titan_suit_host.gd`, and
   the two drivers, `scripts/player.gd` and `scripts/xiao_hou_zi.gd`.

## 2. The story (user, 2026-10-18)

**Fixed:**
- The hero gets in by **climbing the vent hoods** on the outside.
- **Kask and Pinestein still work together.** The city thinks him BLOCK's
  outcast; he is not.
- In Pinestein's lab the hero finds their work: they have been
  **experimenting on blorbs and making synthetic blorb slime**. The city
  blorbs are those synthetic blorbs: they exist because of his experiments,
  and BLOCK still makes them. Nothing lures them in from the desert.
- **The whole sequence is a fight against an evil organization.** BLOCK is
  human villainy first.
- **The Demon King, barely.** At the very end, one subtle line, in the
  moment, that Kask is being rewarded, or given more power, by the Demon
  King. A light touch, not a strong connection, and nothing else in the
  tower points to him.
- **The climax is a boss fight against a blorb mech**, which Kask and
  Pinestein pit against the hero together.
- **The mech:**
  - a mechanical body on a rig like the playable characters';
  - its head is a glass dome that a blorb fills to pilot it;
  - it can wear a blorb suit;
  - in the fight a city blorb pilots it, and it wears a **suit of city
    blorbs**;
  - **beaten, as with the False Hero:** the suit falls away and every city
    blorb in it, the pilot too, lands nearby as a real, joinable blorb the
    party can befriend and equip;
  - the mech is then the hero's: from then on **Blorbus mounts it** (fills
    its head) and drives it.

**Open:** what becomes of Kask and Pinestein after the fight.

**No text that guides.** No line names the mech, the slime or the way up.
The open louvres breathe warm, lit air at night (section 3); the lab's two
benches and two mugs say who works there. The one Demon King line is story,
said in character, and explains no mechanic.

## 3. The section through the tower

**Only four places are built** (user, 2026-10-18: keep it minimal): the
plant floor behind the open louvre, Pinestein's lab, Kask's floors and the
crown. Every other storey is solid mass inside the shell and is never
entered. Two lifts join the four, passing the rest without stopping.

The shaft is 26 by 24 m, 38 storeys to 150 m (3.95 m each), the crown 150
to 212 m. Storeys are numbered from the forecourt (L0). **The data is
`CityPlan.BLOCK_TOWER.inside`** (`tools/city_layout.py`), with checks: the
zones fill every storey once; each vent ring opens onto a plant floor; the
way in is the storey behind the louvre; every built place is a zone; the
core and lab are inside the shaft; the two lifts sit in the core clear of
each other, stop only at built storeys, chain way in to lab to Kask's
floors, and each one's gap shows a storey it passes; the climb's neighbour
is a real lot, 6 m off the east face and taller than the first ring; the
gallery is inside the crown. **The model:**
`docs/drawings/moy_block_tower_3d.html` (the section, the route, the mech).

| Storeys | Height (m) | Built | What |
|---|---|---|---|
| crown | 150 to 212 | **yes** | **the arena**: the hollow blade, ribs converging on the ridge; the eye slit (168 to 192) the one light; a glass gallery on the back slope at 164 m |
| L35 to L37 | 138 to 150 | **yes** | **Kask's floors**: her flat, sparse and dark, and the control room under the crown; the private lift's top stop |
| L31 to L34 | 122 to 138 | solid | the upper stacks |
| L30 | 118 | solid | plant floor, the 80% vent ring |
| L21 to L29 | 83 to 118 | solid | the hangar; **the private lift's gap at L24 shows the mech's empty frame** |
| L20 | 79 to 83 | **yes** | **the way in**: plant floor behind the 55% vent ring (82.5 m), its fans and ducts; the service lift's top stop |
| L12 to L19 | 47 to 79 | solid | the growing floors; **the service lift's gap at L16 shows tanks of city blorbs** |
| L11 | 43 to 47 | solid | plant floor, the 30% vent ring |
| L2 to L10 | 8 to 43 | solid | the stacks |
| L0 to L1 | 0 to 8 | solid | the base: the one door stays shut |
| L−2 to L−1 | −8 to 0 | **yes** | **Pinestein's lab, sealed**: a double-height vat hall of synthetic slime, blorb tanks, his bench beside Kask's; both lifts' bottom stop |

**The way through:**
1. **The climb.** Up the face of the 34-storey mid-rise east of the tower
   (`approach`), a 6 m leap to the 30% ring at 45 m, then up the hoods and
   the shaft's slits to the 55% ring. The gaps between rings are crossed
   with the powers the player has by then; nothing marks them.
2. **In.** Through the one hood with open louvres, in the east face at the
   55% ring, onto the plant floor at L20. At night it breathes warm, lit air.
3. **Down.** The service lift drops from L20 to the lab without stopping.
   One gap in its shaft, at L16, shows a growing floor's tanks.
4. **The lab.** The discovery.
5. **Up.** The lab's private lift (Pinestein's own way in) rises from L−2 to
   L35, 146 m, in one windowless ride; one gap, at L24, shows the hangar and
   the mech's empty frame. Kask's floors; the stair up into the crown.
6. **The arena.** Kask and Pinestein behind the gallery glass; the mech
   drops from the ridge, a city blorb filling its helmet, six city blorbs
   worn as a full suit, the head blorb over the helmet. Beaten, it kneels;
   the six and the pilot fall away as seven joinable city blorbs; Blorbus
   can mount it. The Demon King line comes
   here, at the very end. The hero leaves by the lift.

**Loading.** The inside is its own scene, kept out of the city's bake and
loaded only when the hero goes in (at the louvre). Each lift ride is where
the next place loads, so no loading screen shows. A gap is a shallow lit
pocket, not a floor.

## 4. The blorb mech (round P17a)

**What it is:**
- a playable character, the third **driver** (a script that builds a
  `TraversalContext`), after the hero and Xiao Hou Zi;
- not a vehicle: it walks, runs, jumps and climbs on its own rig;
- piloted by a blorb in its glass head; Blorbus pilots it for the player.

**Body** (drawn and listed in the model; build from its parts list):
- **on the hero's own rig** (user, 2026-10-18): every joint is the hero's
  joint, scaled by **1.05**: 1.99 m to the top of the head (the hero is
  1.90 m to the top of his head, 1.95 m with his hair). It walks through
  every door the hero does; Moy's closed doors are 2.2 m. Check it against
  the smallest door the hero uses.
- **thin limbs** (user): strength from strong material, not bulk, after
  Boston Dynamics' Atlas and Rogue One's K-2SO. Limbs are SuperEgg tubes
  joint to joint (ε 3 / 3): upper arm 0.030 m radius, forearm 0.027, thigh
  0.040, shin 0.034, with a slim piston behind each shin; actuator balls at
  shoulders, elbows, wrists, hips, knees and ankles.
- **one matte black metal** (user) for the whole body and every limb, the
  neck and the head's shell. The one exception is the chest plate, in
  bright steel.
- **shoulder pads** (user): a broad flattened SuperEgg over each shoulder
  (0.10 × 0.055 × 0.10, ε 5.5 / 2), for a stronger look.
- **the blue light** (user) is the city blorbs' own colour: the city
  blorb's exported albedo and glow, not a chosen azure. A recessed band
  round the abdomen, rings at the shoulders, knees and neck, and a vertical
  slit on the chest plate, echoing the tower's eye.
- **a robot abdomen** (user: no spine column or rods, which read fragile):
  two stacked armoured plates in the hero's abdomen proportions, ε 5.5 / 5.5,
  the band of light between them.
- **a neck** (user), for the movement cycles: a slim column on the hero's
  neck joint. No collar.
- **hands and feet are the hero's own** (user): his solid hand, digits
  implied, no fingers; his foot. Both at the mech's scale, in black steel.
- **the head** (user): the hero's own head shape (ε 2.5), squarish, at the
  mech's scale, in two parts split by **one clean curve**:
  - the **glass visor**: the face, round the temples and back over the
    front half of the crown, down to a **chin line** (user);
  - the **steel shell**: the back half, the jaw and the whole underside of
    the chin, black;
  - the cut, in the head's own frame normalized to its half-sizes, puts
    glass where `z > 0.02 + 0.55 × max(0, −y − 0.05)^1.6` and
    `y > −0.6 + 0.32 x²` (the chin line, rising a little toward the jaw's
    sides);
  - the visor **hinges at the crown** and swings up and forward to let a
    blorb climb in, then shuts over it.
- **the pilot fills the helmet** (user): it takes the shape of the shell's
  inside (the head's own SuperEgg, inset from the shell), with its core
  inside and **a blorb's own eyes on its skin** (the game's blorb eye mesh,
  user): opaque, about 0.04 m wide (a little larger than the hero's, user),
  and coloured as every blorb's are
  (`blorb.gd`: the body darkened by a quarter, or lightened on a very dark
  body), so they read through the visor. A city blorb pilot glows; Blorbus
  does not.
- **everything stays inside the shell** (user): the pilot is inset from the
  shell far enough that its eyes, standing proud of its skin as on any
  blorb, keep a millimetre inside the shell. In the model that inset comes
  to 0.87 of the head; the build measures its own the same way. Azure for a city blorb; brain pink (`BLORBUS_BODY_COLOR`) for
  Blorbus.

**Rig:**
- publishes the full rig-neutral joint vocabulary through its own
  `_blorb_suit_pivot_map()`, at the hero's joint positions × 1.05, with real
  joints wherever a power poses one: shoulders, elbows, wrists, fingertips,
  backs of the hands, hips, knees, ankles, toes, soles, spine, thorax, neck,
  head. Check each with `RigAdapter.articulates()`; aim for no aliased
  joints.
- Its body-relative lengths come out of `ctx.scaled()` and
  `ctx.height_fraction()` like any rig.
- The joint positions to start from are exported from the game:
  `tools/export_figure_reference.tscn` writes the hero's meshes and every
  pivot.

**Suit:**
- it wears a blorb suit through the same suit system as the hero: its
  `PlayableCharacterProfile` sets `suit_rig_scale` 1.05, as Xiao Hou Zi's
  sets his; a worn arm covers the whole arm and hand, a worn leg the whole
  leg and foot, as on the hero;
- the suit's pieces are built round the hero's limb widths, so on the
  mech's thin limbs they stand off the steel; draw them in with
  `suit_limb_fit` if they read as baggy, and say what was chosen;
- the suit's head blorb sits over the helmet as it sits over the hero's
  head; in the fight the mech wears all six pieces;
- every suit power and traversal mode works on it: the parity check
  (`tools/check_power_parity.py`) must pass with the mech as a driver, and
  no new `EXEMPT` entry.

**Piloting (mounting):**
- an empty mech kneels, visor up; a blorb that climbs into the head pilots
  it, and the visor shuts;
- the player's mount: Blorbus walks up and climbs into the head, as
  Xiao Hou Zi mounts Manchego; awareness moves into the mech through
  `party_control_director.gd`, the way it moves into Blorbus today;
- the hero's body follows like a companion while Blorbus pilots;
- dismount: the visor opens, Blorbus hops out; the mech kneels and stays.
- The interaction's prompt names the action only, as "Ride Manchego" does.

**The boss form:**
- the same mech, the same rig, driven by the NME controller: a city blorb
  pilot and a suit of city blorbs (azure-glassy, crackling);
- a named boss like False Hero: far more HP, a far larger XP reward;
- it uses its suit's powers as a player would;
- beaten, as with the False Hero: the visor opens, the suit falls away,
  and its six city blorbs and the pilot land nearby as wild, joinable
  blorbs the party can befriend and equip; the mech kneels, empty, and
  becomes the player's (a saved flag).

**Where to build it:** a test pad in the demo world or a sandbox scene; the
tower comes later. Leave a hook for the arena (round P17d).

**Checks (P17a):**
1. `check_power_parity.py` passes with three drivers.
2. Every traversal mode, run once on the mech, with a screenshot of each
   pose; any pose that does nothing is a failure (`articulates()`).
3. Blorbus mounts and dismounts; awareness returns cleanly; the hero
   follows.
4. The suit on, piece by piece and whole.
5. The boss: fight it on the pad with the hero and with Xiao Hou Zi, beat
   it, befriend and equip its city blorbs, mount it.
6. Collision: its body blocks; it walks through the smallest door the hero
   uses, and stands on a 1 m ledge.
7. The visor: opens and shuts on its crown hinge; the cut reads as one
   curve from the front, the side and three-quarter.

**Report:** `docs/diagnostics/<date>-moy-P17a.md` with the checks, the pose
screenshots (front, side, three-quarter, suited and bare, empty and
piloted) and every place the rig had to alias a joint.

## 4a. The people (round P17c)

The story's two, designed with the `character-design` skill. Their looks
are data, `docs/architecture/moy_pkg_P17_looks.json` (npc.gd properties),
built and drawn in the model's "people of the tower" viewer. Moy has no
dress charter yet (package P14 writes it); these two are designed ahead of
it, as modern city dress, and P14 takes them in.

- **Dr. Vera Kask** (she; director of BLOCK; lives on the top floors):
  - tall and straight; iron-grey hair in a tight bun;
  - a long blue-black dress with long sleeves, the tower's colour, legs
    covered; black gloves (she touches nothing herself); black shoes;
  - one thin vertical **pin** at the collar in the city blorbs' blue, the
    shape of the tower's eye: the one accent;
  - all in the existing kit except the pin (a small worn ornament).
- **Palbert Pinestein** (he; the city's outcast, in secret not):
  - older, slight, a little shorter than the hero;
  - **wild white hair** (user): a bald crown with a storm of white tufts
    round the sides and back, flaring out and up;
  - glasses (the first in the game: `has_glasses`);
  - an off-white **lab coat** (user: it hangs from the shoulders) from the
    shoulders to the knees, sleeves to the wrists, open at the front:
    narrow at the waist, opening to a V with folded lapels up the chest,
    and a little toward the hem; a collar round the back of the neck;
    a pocket sagging with batteries, one glowing in the city blorbs' blue;
  - a mustard shirt under it, showing in the V and at the cuffs; brown
    corduroy trousers, scuffed brown shoes; bare hands.
- **New shared pieces** (the kit lacks them; they go in the shared figure
  code, not in one character's script, and are recorded in the skill's
  toolkit):
  - `FigureHair.STYLE_WILD`, the wild hair, fitted through
    `FigureHair.hair_edges()` like every style;
  - `wears_lab_coat` on `npc.gd`: an open coat from the shoulders to the
    knees, built as pieces that follow the thorax, abdomen and hips (no
    single enclosing torso mesh), each cut by the same front opening; lapels,
    a collar, sleeves over each arm segment, a glowing-pocket option;
  - a collar pin as a small worn ornament.
- **Skin tones** are chosen, not assigned by role, from the full human range.
- The hero cut stays the player's alone.

## 5. Collision (all rounds)

- **Solid:** the shaft, the floors and walls of the four built places, the
  lift cars and shafts, the vats, tanks and benches, the gallery glass, the
  crown's faces. The solid mass needs no collision of its own: nothing can
  reach it.
- **Parkour landings:** the vent hoods (the outside's only holds), the plant
  floor's ducts, the crown's ribs.
- **Hazard:** the vats of slime (the hazard policy, not solid).
- **Decorative:** cables, conduit glow, the eye's light, what the gaps show.

## 6. Rounds

Each round gets its own build brief section here before it runs.

| Round | What | Level | Needs | Status |
|---|---|---|---|---|
| P17a | the blorb mech: rig, visor, pilot, suit, mount, boss form | L3 | nothing | **ready** (section 4) |
| P17b | the climb and the way in: vent rings, the open louvre, the plant floor at L20 | L3 | P6 (shaft at L2) | planned |
| P17c | the lab and the two lifts, with their gaps; the inside as its own scene, loaded on the rides; Kask and Pinestein (section 4a) with the wild hair, lab coat and pin | L3 | P17b | planned |
| P17d | Kask's floors, the crown arena, the boss fight | L3 | P17a, P17c | planned |
| P17e | the tower to L4: checks, performance, walk-through | L4 | all | planned |

**Viewpoints** (for every round): the forecourt from Civic Plaza (noon, and
night with the eye lit); the 55% ring from the east neighbour's roof; the
plant floor from the louvre; the vat hall; each lift's gap from its car;
the arena from the gallery and from its floor.

## Decisions log

- 2026-10-18 (user): the way in is the vent-hood climb.
- 2026-10-18 (user): Kask and Pinestein still work together; the lab holds
  their blorb experiments and synthetic blorb slime.
- 2026-10-18 (user): BLOCK serves the Demon King, subtly; also human
  villainy.
- 2026-10-18 (user): the climax is a boss fight against a blorb mech (a
  playable-style rig, mechanical, a glass head a blorb pilots, able to wear
  a blorb suit), piloted by a city blorb and suited; beaten, it becomes the
  hero's, and Blorbus mounts it.
- 2026-10-18 (user): no luring: the city blorbs exist because of
  Pinestein's experiments. The mech's suit is city blorbs, which are the
  synthetic blorbs. No mirror pane; the Demon King gets one subtle line at
  the end, about rewarding Kask. Beaten, the suit's city blorbs join the
  party, as the False Hero's do. The mech is human size and uses the hero's
  doors.
- 2026-10-18: the section (section 3) and the route (in at the 55% ring,
  down to the lab, up by the lift) are proposed, in review.
- 2026-10-18: the mech is built first, as P17a, because it needs no tower.
- 2026-10-18: the section is in the plan data (`BLOCK_TOWER.inside`) with
  checks, and drawn in `moy_block_tower_3d.html`. Drawing it moved the way
  in: the climb starts on the east neighbour (the mid-rises stand against
  the plot's back, so Glass Lane is 20 m away), and the 55% ring is L20,
  not L21. The boss wears five city blorbs and the pilot shows: six to
  befriend. Open for P6 and P17b: the 9 m base against the 7.9 m lobby.
- 2026-10-18 (user): keep the tower minimal. Four places are built (the
  way in at L20, the lab, Kask's floors, the crown); everything else is
  solid mass. A service lift goes down from the way in to the lab and the
  private lift up to Kask's floors, each with one gap showing a storey
  (tanks at L16, the mech's frame at L24). The inside is its own scene,
  loaded on the lift rides. Rounds are now P17a to P17e.
- 2026-10-18 (user): the mech, redesigned: on the hero's own joints × 1.05;
  thin limbs; black steel and bright steel; azure light at the spine,
  joints and chest; a neck, no collar; the hero's own solid hands (no
  fingers) and feet; the hero's head shape split by one curve into a glass
  visor hinged at the crown and a steel shell; the pilot a blorb with real
  blorb eyes. The suit is the game's own, worn through `suit_rig_scale`.
- 2026-10-18: the model's hero, suit and blorb are exported from the game
  (`tools/export_figure_reference.tscn`), not redrawn by hand.
- 2026-10-18 (user): the pilot fills the helmet, taking the shape of the
  shell's inside; the suit fits the mech's rig as it fits the hero's, the
  head blorb over the helmet as over his head. So the boss wears a full
  suit of six city blorbs with the pilot inside: seven to befriend.
- 2026-10-18 (user): character briefs for Kask and Pinestein (section 4a);
  Pinestein a mad scientist with wild hair.
- 2026-10-18 (user): the mech's limbs in the same matte black metal as its
  body (the chest plate stays bright steel); its shoulder pads back; its
  light the city blorbs' own colour. Pinestein's lab coat hangs from the
  shoulders, with lapels, a collar and sleeves.
- 2026-10-18 (user): the pilot's eyes are a blorb's eye colour and a little
  larger than the hero's.
- 2026-10-18 (user): a robot abdomen (two plates and a band of light) in
  place of the spine column and rods; the visor stops at a chin line, the
  chin's underside steel; the pilot wears a blorb's own eyes and sits inset
  so it and its eyes stay inside the shell.
