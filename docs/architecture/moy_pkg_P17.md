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
4. For round P17a: `docs/traversal_powers_architecture.md`,
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

The shaft is 26 by 24 m, about 38 storeys to 150 m (3.95 m each), the crown
150 to 212 m. Floors are numbered from the forecourt (L0).

| Level | Height (m) | What | Beat |
|---|---|---|---|
| Crown | 150 to 212 | **the arena**: the hollow blade, ribs converging on the ridge; the eye slit (168 to 192) the one light; a glass control gallery on the back slope | the boss fight (5) |
| L35 to L37 | 138 to 150 | **Kask's floors**: her flat, sparse and dark, and the control room under the crown; the lift's top stop | the approach (4) |
| L30 | 118.5 | plant floor, the 80% vent ring | |
| L22 to L29 | 87 to 115 | **the hangar**: two double-height floors where the mech is built and tested, its spare glass heads on racks | the mech glimpsed, empty (3) |
| L21 | 83 | plant floor, **the 55% vent ring: the way in** | entry (1) |
| L12 to L20 | 47 to 79 | **the growing floors**: tanks where city blorbs are grown from synthetic slime, and pens of new ones | (2) |
| L11 | 43.5 | plant floor, the 30% vent ring | |
| L3 to L10 | 12 to 40 | **the stacks**: machine floors, rows of humming cabinets; no people, only machines | |
| L0 to L2 | 0 to 9 | **the base**: the one door, a bare lobby, machines that keep it; set back 4 m under the shaft | |
| L−2 to L−1 | −9 to 0 | **Pinestein's lab, sealed**: a double-height vat hall of synthetic slime, blorb tanks, his bench beside Kask's | the discovery (2) |

**The way through**, top to bottom and back:
1. **The climb.** From a neighbour's roof across Glass Lane, up the vent
   rings (30%, then 55%) on the hoods and the shaft's slits. One hood at the
   55% ring has open louvres. The gaps between rings are crossed with the
   powers the player has by then; nothing marks them.
2. **Down.** Through the plant floor and the service stair in the core:
   past the growing floors and the stacks to the sealed lab, which opens from
   the stair's foot. The discovery.
3. **The lift.** The lab's private lift (Pinestein's own way in) rises from
   L−2 to Kask's floors, about 150 m, in one windowless ride: the slits
   flicker past.
4. **Kask's floors.** Her flat; the control room; the stair up into the
   crown.
5. **The arena.** Kask and Pinestein behind the gallery glass; the mech
   drops from the ridge, a city blorb glowing azure in its head, suited in
   city blorbs. Beaten, it kneels; its suit and pilot fall away as joinable
   city blorbs; Blorbus can mount it. The Demon King line comes here, at
   the very end. The hero leaves by the lift.

The hangar (L22 to L29) is passed on the stair down: the mech's frame seen
empty, before it is met.

## 4. The blorb mech (round P17a)

**What it is:**
- a playable character, the third **driver** (a script that builds a
  `TraversalContext`), after the hero and Xiao Hou Zi;
- not a vehicle: it walks, runs, jumps and climbs on its own rig;
- piloted by a blorb in its glass head; Blorbus pilots it for the player.

**Body:**
- **human size** (user): as tall as the tallest human the game has, no
  taller, so it walks through every door built for the hero; check it
  against the smallest door the hero uses;
- **mechanical**, from SuperEgg parts: riveted plates, exposed pistons at
  the knees and elbows, cable runs, a boxy pelvis, three-fingered hands;
  dark steel with BLOCK's blue-black;
- **the head**: a clear glass dome on a steel collar. Empty, it is clear
  glass; piloted, the pilot fills it, its hue showing through (azure for a
  city blorb, brain pink for Blorbus), its eyes looking out.

**Rig:**
- publishes the full rig-neutral joint vocabulary through its own
  `_blorb_suit_pivot_map()`, with real joints wherever a power poses one:
  shoulders, elbows, wrists, hands, hips, knees, ankles, toes, spine,
  thorax, neck, head. Check each with `RigAdapter.articulates()`; aim for no
  aliased joints.
- Its body-relative lengths come out of `ctx.scaled()` and
  `ctx.height_fraction()` like any rig.

**Suit:**
- it wears a blorb suit through the same suit system as the hero (head
  over the glass dome, chest, arms, legs), each worn blorb shaped to the
  mech's limbs;
- every suit power and traversal mode works on it: the parity check
  (`tools/check_power_parity.py`) must pass with the mech as a driver, and
  no new `EXEMPT` entry.

**Piloting (mounting):**
- an empty mech stands still; a blorb that enters the dome pilots it;
- the player's mount: Blorbus walks up and climbs into the head, as
  Xiao Hou Zi mounts Manchego; awareness moves into the mech through
  `party_control_director.gd`, the way it moves into Blorbus today;
- the hero's body follows like a companion while Blorbus pilots;
- dismount: Blorbus hops out of the dome; the mech kneels and stays.
- The interaction's prompt names the action only, as "Ride Manchego" does.

**The boss form:**
- the same mech, the same rig, driven by the NME controller: a city blorb
  pilot and a suit of city blorbs (azure-glassy, crackling);
- a named boss like False Hero: far more HP, a far larger XP reward;
- it uses its suit's powers as a player would;
- beaten, as with the False Hero: the suit falls away and its city blorbs
  and the pilot land nearby as wild, joinable blorbs the party can befriend
  and equip; the mech kneels, empty, and becomes the player's (a saved
  flag).

**Where to build it:** a test pad in the demo world or a sandbox scene; the
tower comes later. Leave a hook for the arena (round P17e).

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

**Report:** `docs/diagnostics/<date>-moy-P17a.md` with the checks, the pose
screenshots (front, side, three-quarter, suited and bare, empty and
piloted) and every place the rig had to alias a joint.

## 5. Collision (all rounds)

- **Solid:** the shaft, floors, walls, the core and stair, the vats, tanks
  and pens, the hangar's frames, the gallery glass, the crown's faces.
- **Parkour landings:** the vent hoods (the outside's only holds), the
  plant floors' gantries, the hangar's crane rails, the crown's ribs.
- **Hazard:** the vats of slime (the hazard policy, not solid).
- **Decorative:** cables, conduit glow, the eye's light.

## 6. Rounds

Each round gets its own build brief section here before it runs.

| Round | What | Level | Needs | Status |
|---|---|---|---|---|
| P17a | the blorb mech: rig, pilot, suit, mount, boss form | L3 | nothing | **ready** (section 4) |
| P17b | the climb and the way in: vent rings, the open louvres, the plant floor at L21 | L3 | P6 (shaft at L2) | planned |
| P17c | down: the stair, the growing floors, the stacks, the hangar seen in passing | L2 | P17b | planned |
| P17d | the sealed lab and the lift | L3 | P17c | planned |
| P17e | Kask's floors, the crown arena, the boss fight | L3 | P17a, P17d | planned |
| P17f | the whole tower to L4: checks, performance, walk-through | L4 | all | planned |

**Viewpoints** (for every round): the forecourt from Civic Plaza (noon, and
night with the eye lit); the 55% ring from Glass Lane; the vat hall; the
lift's door at L−2; the arena from the gallery and from its floor.

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
