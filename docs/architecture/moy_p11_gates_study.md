# P11 gates — design study

2026-10-24. **Design study for review.** Follows the accepted wall study
(`moy_p11_architectural_study.md`) and the whole-circuit programme
(`WALL.kit.circuit`). Data: `WALL.kit.gates` in `tools/city_layout.py`.
Model: `docs/drawings/moy_wall_gates_3d.html` (https://claude.ai/artifact/QqXwjfVDt6XD6bKQBPVVEv).

## What is designed here

- **North and South Gates:** one gatehouse design, two siblings.
- **East Gate (City Hall's arch) and West Gate (twin towers):** their buildings
  are locked; P11 designs only where the wall meets them, plus the West Gate's
  bridge-roof garden.
- Station operation, lifts, moving ramps and platforms stay with P10.

## Locked inputs

- Gatehouse 44 m along the wall, 24 m deep (12 m wall + 12 m outward).
- Street opening 10 × 8 m, superellipse head n5.5.
- Two three-tier corner towers: 7 / 5.6 / 4.2 m, tier pitch 3.2, base 14.5,
  thin flat steel roofs, no timber eaves.
- Wall Line platforms at +14.2 (rail 13.2, floor +1.0), outer platform
  v 0.9 to 3.9, inner platform overhanging the city face.
- Watch-walk ramps 12 → 14.2 over 22 m, landing on the outer platform.
- A bell at each gate (city.md section 6); the gates stand open and are watched.

## The problem with the inherited massing

The old gatehouse ran full-height side masses to 14.5 m across the whole
24 m depth, straight through the track envelope. The new design keeps
everything above the wall's top **outside the railway**: the deck at +14.2
starts at the outer platform's edge and runs outward.

## North and South gatehouse

**People and purposes.**
- Everyone arriving from the desert, the works, the launch site's service road.
- The Wall Watch: watches the gate, rings the bell, keeps the towers.
- Rail passengers changing between the Wall Line, the Spine and the street.

**Plan, from the city outward (local v, from the wall's centreline).**

| Zone | v | What |
|---|---|---|
| Passage | −6 to 6 | 12 m vault through the railway viaduct, retained masonry, stone rings on both faces |
| Court | 6 to 15 | open to the sky, 18 m wide: 10 m street, 4 m aprons each side; 9 m deep so daylight reaches the passage |
| Wings | 6 to 18, u 9 to 22 | station core on one side, the Watch's gate room on the other |
| Outer gate | 15 to 18 | outer arch, same curve as the passage; the gallery above it |

**Wings, ground floor.**
- **Station core** (P10's): a 3 m loggia behind a 6 m arcade onto the court,
  holding the lift and the moving-ramp scissor up to the outer platform.
- **The Watch's gate room:** a 1.4 m door onto the court, its own stair up
  to the bell tower. A Watch bench in the court by the outer gate.

**Section.**
- Passage 8 m clear; railway deck 12; tracks; platforms +14.2.
- **The deck:** one level at +14.2, U-shaped round the court: the outer
  platform, the wing roofs and the outer gallery. Guarded 1.1 m round the
  court (steel posts and rail, glass infill); 1.1 m parapet on the desert and
  side edges, open where the watch-walk ramps land.
- **Station shade** at +20.4 over both platforms: steel posts on the
  platforms at 6 m, three beams, open timber blades. Clears a train by 2.4 m.
- **Towers** on the deck's outer corners (u ±18.5, v 14.5), clear of the court
  and the platform:
  - tier 1, an open loggia on four stone piers;
  - tier 2, a lookout room, a superellipse window each face;
  - tier 3, a lantern lookout.
  - Each tier: ceramic walls between stone corner piers, stone coping, thin
    steel roof plate with a 0.45 m overhang.
- **The bell:** one hollow bronze bell on a steel beam between two piers,
  under the first-tier roof of the tower on the Watch's side, rope to the
  loggia floor. The other tower's loggia has a bench and the view.

**Elevations.** The wall's datums carry round the gatehouse:
- stone plinth 0 to 1.05, broken at the arches;
- bearing belt 6.05 to 6.35;
- recessed ceramic fields between stone piers (wing corners, mid-wing, court
  corners);
- coping under the deck; parapet with stone cap.

**Siblings.** Same construction and datums; they differ in occupation and
hand.

| | South Gate | North Gate |
|---|---|---|
| Faces | the market lanes, the Arches, Market Square | the estate, the launch site's service road |
| Court | garden court: two planted beds, benches | working court: plain stone, the service track's kerb lines |
| Hand | Watch wing on +u | mirrored |

## East and West: where the wall meets them

- **Terminal pier:** the wall's last bay ends on a full-height stone pier,
  2.5 m along, against the gate building, capped at the wall's coping. The
  plinth and belt carry on round the building's base.
- **Train-hall mouths:** a 0.6 m stone surround with an n8 head round each
  mouth where the tracks pass through (both faces of each leg or tower).
- **East:** no change to City Hall, its front, its halls or its program.
- **West:** no change to the towers or the bridge. Its roof at +42 is the
  community garden:
  - two long beds against the guards along the open edges;
  - benches facing them;
  - the middle walk kept clear, 3 m clear at both tower doors.

## Exclusions

- Crenellations, timber pagoda eaves, painted gate names or numerals,
  shut gate leaves (the gates stand open).
- Anything above the wall's top inside the track envelope.

## Checks (in `city_layout.py`)

- The court leaves side aprons beside the street.
- The deck is at the platform floor level.
- The passage has structure between it and the deck.
- The towers stay on the gatehouse, off the court and off the platform.
- The station shade clears a train.
- West roof beds keep the tower doors' arrival clear; the middle walk is wide
  enough.

## Open questions for review

1. The open court is new. It changes the inherited solid gatehouse into a
   barbican with daylight. Keep it, or return to a solid 24 m passage?
2. Is the bell on the Watch's side right, or should the bell sit over the
   passage on the gallery?
3. Should the North Gate's working court get any planting at all?

## Decisions

- 2026-10-24: user asked to design the gates next, after accepting the wall
  study and seeing the whole-circuit model.
