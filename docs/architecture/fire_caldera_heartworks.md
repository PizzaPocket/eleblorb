# Fire Caldera: the whole plan, above and below the lava

Status: **proposed for review, 2026-10-17.** The surface city is built; the
Caldera Heartworks under it is not yet part of the playable world. This
document replaces the first Heartworks proposal (2026-10-15), whose numbers
could not all be true at once (section 9). It keeps that proposal's intent:
its sphere, rings, falls, rooms and the Jewel Changi precedent.

Sources, each the only place its numbers live:

- **Surface:** `FireCalderaPlan` (`scripts/fire_caldera_plan.gd`) and
  `FireCalderaGround`, as built. Read with `fire_caldera_layout.md`, which owns
  where the city's programs meet the caldera.
- **Below the lava:** `tools/fire_caldera_heartworks_layout.py`, which writes
  `scripts/fire_caldera_heartworks_plan.gd` (`FireCalderaHeartworksPlan`) and
  fails when the section stops fitting together (section 8).
- **Model:** `docs/drawings/fire_caldera_3d.html`, the surface export and the
  Heartworks plan together, with x-ray and section views.

Frame: `FireCalderaPlan`'s local plan frame. The origin is the reservoir's
centre; +y runs from the kingdom gate toward Civic; +x is a visitor's right at
the gate. A **bearing** is `atan2(y, x)` in degrees: Kel is about 0, Civic 90,
Renewal 180, and the gate −90. **Depths** are metres below the lava's surface
(`FireCalderaGround.LAVA_Y`, world height 29.2).

## 1. Premise

The caldera's lava mouth is a broad, continuously filled reservoir, and under it
the lava people keep the volcano's working heart: the **Heartworks**, a great
hollow sphere inside the rock. Three gated falls drop through it to a collection
basin. Working rings follow its shell, and three enclosed risers return the flow
to the city. The Fire people are stewards of the volcano: they read, divide,
cool, return and relieve its flows, and the city is one large instrument kept
over generations.

Jewel Changi supplies four spatial ideas, not an appearance:

1. One falling element, seen from many levels, organises a very large interior.
2. Terraces and crossings make a deep void public space.
3. The falling medium changes the chamber's light, air and sound.
4. Collection and recirculation are part of the building.

The Fire translation uses the volcanic-modern charter: a cast-basalt shell,
blackened steel, large protected glass and mineral lenses. Branching forged
metal appears only at named supports, rails, screens and gates. No plants
survive in the chamber.

## 2. The whole section

From the crater lip to the sphere's floor, in world height (Y) and depth below
the lava (D):

| Level | Y | D | What |
|---|---:|---:|---|
| Crater lip, Tempering Gate | 48.5 | — | the true gate; the arrival gallery starts here |
| Gate inn porch | 49.5 | — | the inn's platform, reached by the HG branch |
| Highline | 42.5 | — | the glass civic ring and the four docked buildings |
| Rear service orbit | 33.3 | — | G2, behind the plots |
| Lava promenade, Renewal deck | 30.25 / 30.48 | — | G1 round the bank; the Renewal deck at its level |
| Lava surface | 29.2 | 0 | the reservoir: one continuous surface |
| Settling shelf | 24.2 | 5 | the reservoir's bed over the crown, with the baffles |
| Crown Gallery (C0) | 18.7 | 10.5 | the one dry ring, round the throat |
| Throat floor = sphere's cap | 17.6 | 11.6 | the gated sluices of the three falls |
| Sphere's inner top | 15.2 | 14 | the oculus lens |
| C1 Steward Ring | 5.2 | 24 | Renewal chamber, manifold, Renewal shelf |
| C2 Civic Ring | −8.8 | 38 | observatory, archive, Civic Crossing |
| C3 Works Ring | −22.8 | 52 | forge, materials bay, Forge Arm |
| Sphere's equator | −26.8 | 56 | 42 m radius |
| C4 Inspection Ring | −38.8 | 68 | sampling and isolation stations |
| C5 Return Gallery | −52.8 | 82 | collection gates, riser intakes, bypass |
| Basin pool | −62.8 | 92 | receives every fall |
| Sphere's floor | −68.8 | 98 | refractory works |

## 3. The surface and its raised pathways

The surface is built and is not changed by this plan, except for the reservoir's
bed (section 4) and four new things that meet the ground: three immersion
shelves and two crown-stair kiosks. The routes below are `FireCalderaPlan.routes()`
as exported. Lengths are along the plan; heights are world Y.

### 3.1 The raised network

| Route | Width | From → to | Heights | Length, grade | Notes |
|---|---:|---|---|---|---|
| H0 arrival gallery | 3.8 | Tempering Gate (0, −112) → the Highline's outer edge | 48.5 → 42.5 | 40.5 m, 15% | a gentle bow; level for its first 8%; a T landing on the ring |
| HG inn branch | 3.0 | H0 at its 12 m station → the inn's porch | 46.8 → 49.5 | 15.3 m, 17.5% | leaves H0's gate-side edge square, lands square on the porch's guard opening |
| D_GUEST | 2.4 | the inn's platform, front to receiving side | 49.5 | 20.3 m | private |
| H1 Highline | 4.8 | the full ring, radius 72 | 42.5 | 452 m, level | glass deck 0.22 m thick on 12 forked steel frames; guards on both edges |
| D_NAHL, D_VARA, D_CIVIC, D_IREN | 2.4 | the ring → each dock's front and back doors | 42.5 | 20–29 m | each dock is a superelliptic platform on one concave service pier; the ring's deck is trimmed to it |
| H2W, H2E Renewal ramps | 3.2 | the ring's inner edge → the Renewal deck's north and south sides | 42.5 → 30.48 | 66.5 m each, 18% | mirrored; three flights with two 7 m half-circle returns and a final quarter-turn |
| H4 Oren spiral | 2.4 | the ring's inner edge → Oren's roof terrace, rear edge | 42.5 → 38.0 | 29.7 m, 15% | clear of the lift lobby |
| E1, E2, E3 emergency spokes | 3.5 | the ring → refuge shelves 92 m out | 42.5 → about 38 | 20 m | E1 at −175°, E2 at 65°, E3 at 155°; E0 is the arrival gallery |

Rules that hold everywhere on it:

- **Joins.** A branch starts on its parent's actual edge. The parent's guard
  opens only along the branch's width, and both handrails meet there. An
  unconnected edge stays closed. The arrival gallery and the emergency spokes
  meet the ring's outer edge; Renewal's ramps and Oren's spiral meet its inner
  edge.
- **Docks.** A ring-docked building's platform is level with the ring. The
  ring's outer guard opens only along the dock.
- **Kel has no Highline link.** Its sawtooth building keeps its own
  circulation; the Kel ribbon (H5) was removed.
- **Grades.** No civic ribbon exceeds 22%; the steepest is a Renewal ramp at
  18%.
- **Structure.** The Highline is civic architecture on its own frames, not a
  terrace cut into the volcano. The natural bowl continues, visible and
  collidable, beneath it.

### 3.2 The ground network

| Route | Width | Where | Height |
|---|---:|---|---|
| G1 lava promenade | 3.5 | round the whole bank, 3 m in front of each ground building's facade | level, 30.25 (30.14 to 30.48) |
| G2 rear service orbit | 3.2 | radius 77.5, clear of the Highline's line | follows the bowl, 33.3 |
| P_ and S_ spurs | 2.8 / 2.6 | public thresholds from G1, receiving thresholds from G2, for Oren, Kel, Aro and Renewal | to each door, up to 9% |

The promenade and service orbit have no rails at their edges: the lava's edge
stays open.

### 3.3 New on the surface

- **Three immersion shelves**, each a stepped basalt tongue into the lava from
  the promenade:
  - **S0** from Renewal's deck, at 185°;
  - **S1** from the observation landing in front of Civic, at 90°;
  - **S2** from Kel's protected landing, at −20°.
- **Two crown-stair kiosks** on the lava promenade, each a small glass
  pavilion over a stair and lift core:
  - **CA** at 112°, between Civic and Aro;
  - **CB** at 240°, near the arrival, south of Renewal.

  Both stand clear of the arrival-to-Civic sightline.

## 4. The crown

- **The reservoir stays one continuous lava surface**, about 52 m in mean
  radius, with its irregular bank. From above, it reads as uninterrupted lava.
- **Its bed is new.** The live ground digs a 22 m parabolic bowl. Inside the
  bank, the bed now shelves smoothly from the bank to a level **settling
  shelf** 5 m deep, from radius 24 inward. Refractory baffles stand on the
  shelf at 30°, 150° and 270°, between the three intakes. They let gas leave
  through vents and heavy mineral load settle, where Pela and the stewards
  sample it.
- **The throat**, 17 m in radius, drops through the shelf. It is a lava-filled
  well floored by the sphere's cap, 11.6 m deep at its centre and 15 m at its
  wall. In its floor are the **three gated sluices** of the falls, and at its
  centre the **oculus**: a 6 m refractory glass lens through which the
  throat's glow lights the chamber.
- **The Crown Gallery (C0)** is the one dry ring. It is cut into the crown
  round the throat, 10.5 m down, 4.2 m wide, with a 4 m ceiling under 1.5 m of
  roof.
  - Its inner wall is structural glass onto the molten throat.
  - Lens wells in its floor look down into the chamber.
  - The three sluice **gate houses** (G0, G1, G2) open off it, at the falls'
    bearings.
  - It is reached only by the two crown stairs: two directions out. Nothing
    below it is dry.

## 5. The sphere and its rings

- **The sphere:** 84 m across inside (radius 42), its centre 56 m down, its
  shell 2.4 m of refractory cast basalt with embedded steel ribs.
- **Webs:** broad radial basalt webs tie the shell into the volcano at the
  rings, and denser structure surrounds the crown and the basin. The webs form
  pressure compartments and equipment bays without breaking the reading of one
  room.

The rings follow the shell. The shell overhangs the upper rings, so they are
galleries cut back into it. The works ring straddles the equator. The lower
rings are terraces standing out from the shell. Every floor is 4.2 m wide with
at least 3 m of headroom, and each ring is a full loop: every room on it has
two directions out.

| Ring | Depth | Floor's plan radii | Form | Program |
|---|---:|---|---|---|
| C1 Steward Ring | 24 | 27.2–31.4 | gallery behind the shell | Renewal chamber L0, manifold L1, the Renewal shelf, daily flow balancing |
| C2 Civic Ring | 38 | 37.9–42.1 | gallery behind the shell | deep observatory L2, fired archive L3, the Civic Crossing |
| C3 Works Ring | 52 | 39.7–43.9 | half inside, half behind | forge L4, materials bay L5, the Forge Arm |
| C4 Inspection Ring | 68 | 36.0–40.2 | terrace | inspection stations I0–I2 at the three falls' bearings |
| C5 Return Gallery | 82 | 28.8–33.0 | terrace | the three risers' intakes, the emergency bypass B0 |

**The Civic Crossing** is one 4.2 m bridge across the void at C2. It runs on a
chord 14 m from the axis, on the gate's side, from −22° to −158°. From its
middle, the Heartfall is seen face-on. It stays more than 6 m from every fall
and never passes over an impact.

**The basin** fills the sphere's floor with refractory works.

- **The receiving pool** is 16 m in radius, its surface 92 m down. Every fall
  lands inside it.
- **Two concentric lips**, at 16–20 m and 20–23 m, separate:
  - reusable flow, for the risers;
  - heavy sediment, for recovery;
  - gas, for the relief system;
  - emergency overflow, through the bypass to a sacrificial natural tube
    outside the shell.
- **No walk passes over an impact.** The Return Gallery looks into the basin
  from its terrace.

## 6. The falls and what catches them

Each fall leaves a gated sluice in the throat's floor. It drops from a spout in
the cap as a sheet across its bearing, narrowing as it accelerates. Each can
stop while the others run. Clear sectors between them keep the sightlines,
swimming routes, ventilation and crossings open.

| Fall | Bearing | Plan radius | Width (spout → foot) | Drops | Catch |
|---|---:|---:|---|---|---|
| F0 Heartfall | 90 | 11 | 9 → 5 | 15.5 → 92 | the basin pool |
| F1 Forge Fall | −10 | 14 | 5 → 3.5 | 16.4 → 51 | the splitter bowl on the Forge Arm |
| F1v Forge veil | −10 | 11 | 3 → 1.8 | 51.6 → 92 | the basin pool |
| F2 Renewal Fall | 198 | 14 | 5.5 → 4.2 | 16.4 → 23.6 | the tempering pool on the Renewal shelf |
| F2v Renewal veil | 198 | 9 | 3.5 → 2 | 24 → 92 | the basin pool |

- **The Heartfall** is the civic and ceremonial fall, on the gate-to-Civic
  axis. It is seen from every ring, and lit from within it lights the lower
  chamber.
- **The Renewal shelf** is a broad basalt deck held out from C1 over the void
  at 198°, spanning ±15° and running from the ring to 9 m from the axis.
  - The Renewal Fall drops 7 m into its tempering pool, 11–17 m out.
  - Shallow warm pools step down to it across the shelf: the communal
    immersion terraces in front of the Renewal chamber.
  - Its inner lip is a weir. What the pool does not hold falls on as the
    Renewal veil.
- **The Forge Arm** is a steel-and-basalt arm 4 m wide across the void at C3,
  at −10°, from the ring to 10.5 m out.
  - The Forge Fall drops 35 m into a 3.5 m splitter bowl near its end.
  - A third of the flow runs out along the arm's 2.2 m lava channel into the
    forge. The rest falls on as the Forge veil.
  - A stewards' walk runs beside the channel; it is not a public route.

## 7. Rooms, and the ways in and out

### 7.1 Rooms

Rooms are dug into the rock behind their rings, each with a glass front onto
the ring, 14 m deep.

| Room | Ring | Bearing | Width | Who and what |
|---|---|---:|---:|---|
| L0 Renewal chamber | C1 | 198 | 22 | communal immersion and the coming-of-age practice, onto the Renewal shelf |
| L1 Primary manifold | C1 | 145 | 18 | Miru and Tovan's thermal distribution; the Aro return's valve station; the city's spine |
| L2 Deep observatory | C2 | 90 | 18 | Selka's instruments, facing the Heartfall across the void |
| L3 Fired archive | C2 | 118 | 16 | cast and engraved records; Aru's work; the Civic lift |
| L4 High-temperature forge | C3 | −18 | 24 (9 tall) | Daro, Vesa and Ruun's hot floor, fed along the Forge Arm; the Kel lift |
| L5 Experimental materials bay | C3 | 24 | 18 | the shared Kel and Vara testing space; the Vara lift |

The gate houses (G0–G2, on C0), the inspection stations (I0–I2, on C4) and the
emergency bypass (B0, on C5) are small working bays, each with its own door
onto its ring.

### 7.2 The three lava entries (public, after the Lava Helm)

Every way into the chamber passes through lava. Each entry runs:

1. **Shelf.** The swimmer leaves the plot's immersion shelf and crosses about
   20 m of the reservoir.
2. **Portal and lock.** A portal in the bed, 36 m out, opens into a **pressure
   lock**: an outer gate, a chamber that drains, an inner door. This is how
   the dry tunnels stay dry under a lava lake.
3. **Tunnel.** A level tunnel runs 9 m down, out under the bank, to a race
   well.
4. **Race well.** A helix 7 m in radius, its axis 68 m from the centre, at a
   30% pitch: a stair for going up, with a lava flume beside it for going
   down.
5. **Into the room.** A level tunnel enters the room through its back wall.

| Entry | Shelf | Race well | Turns | Arrives |
|---|---|---:|---:|---|
| S0 | Renewal's immersion tongue | 202° | 1.1 | L0 Renewal chamber, C1: the gentlest and most social way in |
| S1 | the observation landing in front of Civic | 78° | 2.2 | L2 deep observatory, C2: the deep scientific descent |
| S2 | Kel's protected hot-work landing | −2° | 3.3 | L4 forge, C3: the industrial way, kept out of the gallery |

### 7.3 The dry ways (public, before the Lava Helm)

- **CA** (112°) and **CB** (240°): a stair and lift core from the promenade
  11.5 m down, then a level tunnel under the settling shelf to the Crown
  Gallery. The lifts make the Crown Gallery step-free.

### 7.4 Stairs between the rings

Eight enclosed stairs run in the rock behind the shell, two between each pair
of neighbouring rings. Each goes from a door on one ring to a door on the next,
at a 32° pitch, 2.4 m wide, and none passes through a room:

| Stairs | Between | Doors at (upper → lower) |
|---|---|---|
| K12a, K12b | C1 and C2 | 40° → 11°; 240° → 211° |
| K23a, K23b | C2 and C3 | 160° → 187°; 300° → 273° |
| K34a, K34b | C3 and C4 | 60° → 29°; 250° → 219° |
| K45a, K45b | C4 and C5 | 130° → 102°; 320° → 292° |

### 7.5 Service shafts (residents and goods, not public ways in)

| Shaft | From | To | Rise |
|---|---|---|---:|
| LK Kel lift | Kel's floor | L4 forge | 52.7 m |
| LV Vara lift | Vara's dock | L5 materials bay | 65.3 m |
| LC Civic lift | Civic, behind its reservoir front | L3 archive | 51.3 m |
| LA Aro descent | the protected descent already cut through Aro's podium | L1 manifold | 22.4 m |

Each shaft's foot meets a level passage into its room's back wall.

### 7.6 Escape

Every ring keeps a way to the surface with any one way closed. Nothing below
the Crown Gallery is reachable without passing through lava. A lower room is
never more than one ring-loop away from two different stairs.

## 8. Return and relief

Three enclosed lava risers run in the rock 6 m behind the shell. Each goes from
its intake on the Return Gallery up past the Steward Ring, then out under the
bank into the city's buried service spine:

| Riser | Bearing | Serves | Relief |
|---|---:|---|---|
| V0 Aro return | 145 | L0, L1; the household thermal spine; valve station in the manifold | a branch out and up to the west shelf (E1) |
| V1 Kel return | −15 | L4, L5; the hot industrial return; valve station by the forge | — |
| V2 Civic relief return | 72 | L2, L3; instrumented | a branch out and up to the far shelf (E2) |

Pressure differential and thermal convection do most of the work; valve
stations trim and isolate the flow. The risers show as glowing seams,
instrument bays and protected glass sections, never as open pipes beside a
walk. Relief vents only toward the west and far shelves: never toward the
Tempering Gate, the inn or the large glass fronts.

## 9. What changed from the first model, and why

| First proposal | Problem | Now |
|---|---|---|
| sphere centre 38.4 m down, radius 42 | the sphere's top stood 3.6 m **above** the lava, so the "submerged throat" was the sphere's open top | the centre is 56 m down: the top is 14 m below the lava, under a solid crown |
| throat r 17 "5 m below the surface" | at 5 m the sphere was 25.5 m across, not 17; nothing held the lava above an open chamber | the throat is a lava-filled well in the crown, floored by the cap; the falls leave through gated sluices |
| Crown Gallery 4 m down, dry | 4 m down was inside the lava | 10.5 m down, cut into the crown, under 1.5 m of roof; the reservoir's bed becomes a 5 m shelf over it |
| rings as flat circles at fixed depths | the shell overhangs the upper rings: no headroom | galleries cut into the shell above the equator, terraces below, 3 m of headroom checked |
| falls from the intakes to "the basin" and "a splitter" | falls from the cap at 17 m out could not reach rings 27–42 m out; nothing caught them | F2 lands in the Renewal shelf's pool, F1 in the Forge Arm's splitter; the veils and F0 land in a 16 m pool (was 12) |
| rooms at plan points (e.g. L4 at (24, 3)) | inside the void | dug into the rock behind their rings |
| entries and lifts as lines | no lock, no route, no depth | real ways: shelf, portal and lock, race well, tunnel; shafts with their passages |
| Civic relief riser at 278° | toward the gate, against the relief rule | 72°, venting to the far shelf |
| ring ids H0–H5 | the same ids as the Highline's routes | C0–C5 |

## 10. Light, sound and character

- **Light.** The throat's glow through the oculus is a narrow, changing orange
  light, not an open cone. The falls light the lower chamber from within.
  Cobalt and teal mineral lenses mark the science, cooling and return systems.
  The upper rings catch reflections from the crown, the middle rings see
  moving light across the shell, and the bottom stays dark except for the
  impact glow and the return seams.
- **Sound.**
  - a broad low roar in the open void;
  - quieter, resonant galleries behind pressure doors;
  - valve pulses on the Steward Ring;
  - deep impacts at the basin.
- **Steam and gas** appear only at the separators and relief points.

## 11. Before the Lava Helm, and after

**Before.** The Crown Gallery's glass shows the molten throat, the gate houses
at work and, through its lens wells, the upper rings and the moving residents.
The immersion shelves and the surface portals read as resident infrastructure,
without text. Unsuitable companions wait on dry pads by the shelves.

**After.** The three entries open three depths:

- Renewal, to C1;
- Civic, to C2;
- Kel, to C3.

The player can circle every ring and cross on the Civic Crossing. They can swim
beside the falls, never blindly through them. The deepest reward is
understanding the return system, not merely reaching the bottom. Residents keep
one schedule identity above and below.

## 12. To build it

- Read every number from `FireCalderaHeartworksPlan`; never edit that file by
  hand. When the review approves this section:
  - move `tools/validate_fire_plan.gd` and its model export onto it;
  - delete `FireCalderaPlan`'s `HEARTWORKS`, `HEART_LEVELS`, `HEART_FALLS`,
    `HEART_RISERS`, `LOWER_ROOMS`, `LOWER_PASSAGES`, `IMMERSION_SHELVES` and
    `LIFTS`.
- Replace `FireCalderaGround.height` inside the bank with the new bed
  (`bed_depth` in the plan tool): the shelf, the throat's vertical wall and
  the cap. The lava's extent and hazard query follow the same function.
- **Collision.** Substantial geometry is solid under `CollisionPolicy`:
  - the shell;
  - ring floors and their guards;
  - the Crossing, the shelf and the arm;
  - the basin's lips;
  - the tunnels, wells and stairs.

  The falls and the pools use the hazard policy and the lava surface API, not
  a solid collider.
- Build props from SuperEgg parts and the shared Fire builders. Build the
  Crown Gallery's glass and every guard as continuous ribbons, like the
  Highline's.

## 13. Open questions

1. Keep the sphere at 84 m? With its top 14 m down, its floor is 98 m below the
   lava (world −69).
2. Keep the Heartfall on the gate-to-Civic axis (face-on from the Civic
   Crossing), or shift it off-axis?
3. Add a thin overflow veil used only at high pressure?
4. Should the Crown Gallery's lens wells show the basin before the Lava Helm,
   or only the upper rings?
5. The crown stairs' lifts make the Crown Gallery step-free. Nothing below it
   is dry; agree?
6. Is **Caldera Heartworks** the working name, or do the Fire people have their
   own?
7. Emergency spoke E3 is at 155° in `FireCalderaPlan`, on the north-west, but
   `fire_caldera_layout.md` calls it the east ascent from Kel and Oren. Which is
   intended?
