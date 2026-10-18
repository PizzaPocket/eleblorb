# Moy prototype pass 4 diagnostic

Date: 2026-10-18
Scope: pass 4 implementation and validation in the local working tree. No web
export, commit, or push was made. Existing local player, suit, and vine changes
were preserved.

## Implemented

- Added the Civic Plaza from `CityPlan.CIVIC_SQUARE`: split paving, two lawns,
  the cross-axis, the reflecting pool, tree rows, fountains, monuments,
  statues, and flagstaffs. Kept the plan-authored trees and planting counts.
- Replaced the City Hall cascades with geometry from `ARCH.front`: the rostrum,
  both scissor legs, City Steps, galleries, landings, over-track walks, outer
  flights, guards, and destination-controlled lifts.
- Added moving straight and helical escalator handrails, configured at the
  escalator travel speed. Closed the escalator sections with solid top and
  underside geometry and kept glass balustrades collidable.
- Rebuilt the Crossing dome as the glass shell and white lattice, cut the four
  clock eyes open and ray-checked their clearance, added the crown ring and
  bell, and built the Clock Room floor, widened platforms, four arrival wells,
  guarded three-sided wells, and four lift lanterns. Added the +41.6 m stop to
  the four Crossing lifts. There are no eye escalators or landings.
- Rebuilt the park pond profile from `PARK.pond`, put the shared village water
  material on its surface, registered the water/hazard metadata, and connected
  its surface and bed to the terrain liquid queries. The surface collider that
  could trap the player has been removed.
- Fixed the generated-plan writer so `CityPlan.CIVIC_SQUARE` is emitted into
  `scripts/city_plan.gd`. Updated the bake signature and validator for the
  pass-4 source set and counts. Fixed the performance probe's `views` scope and
  the runtime validator's lift selection and duplicate-node-name assumptions.
- The Grand Hotel remains as implemented in pass 3, per pass 4's explicit
  “stays as built” instruction. It was not expanded in this pass. Its four
  capsule lift bodies and ordered three-stop menus pass automated checks, and
  a live physics call moves a capsule. This does not establish full fidelity to
  the detailed hotel model: the revolving door is a static visual, the model's
  revolving Windrose has no implementation, and the chandelier uses 300
  visible crystals rather than the model's 3,000. Passenger rides and hotel
  circulation remain physically unverified.

## Automated checks that passed

- `python3 tools/city_layout.py`: completed and wrote 22 streets, 47
  buildings, 133 lots, and 9 courts. It emitted a Shapely distance warning;
  see the data-drift note below.
- Offline bake: `MOY_BAKE packs=188 streets=22 buildings=47 lots=133
  old_houses=60`.
- `python3 tools/check_moy_bake.py`: current, 188 packs; 47 buildings, 133
  lots, 60 old houses, and 22 streets.
- `tools/validate_city_plan.tscn`: 22 streets, 47 buildings, 133 lots,
  0 failures.
- `tools/validate_moy_runtime.tscn`: exit 0, `failures=0`. It confirmed
  complete QA pack activation, all 60 old houses, all 133 lot bodies, expected
  building bodies, Civic Plaza's 14 trees, 28 City Hall front escalator lanes,
  eight Clock Room arrival lanes, four tower lifts with the room stop, the
  four clock-eye ray paths, and existing Deck/park counts and recorded
  placements.
- Runtime checks confirmed four west-facing moving turbines at 2 rpm, 12
  consists with 30 independent rideable cars, the four service schedules and
  station dwell times, sampled train clearance, 6.5 m Deck-lift motion, the
  four hotel capsule bodies and menu order, the human↔Xiao Hou Zi complete Plant
  suit handover, and six vine-route handover chains.
- Added clock-angle assertions for all four faces at 3:00, 9:15, and 12:00;
  all passed. The seconds indicator remains removed.
- The QA scene reached its ready state with the full Plant suit and the real
  party controls. The headless Crossroads probe loaded Moy, reached all 185
  eligible packs, and completed two unload/reload cycles with zero packs after
  unload and packs ready after reload.
- Bake freshness was checked after the final bake. `git diff --check` was
  clean at diagnostic preparation.

## Measured performance and limits

The probe's actual windowed/rendered invocation was attempted after fixing its
parse error, but Godot exited immediately with status 134, before creating a
log. Rendered FPS, draw calls, GPU memory, and rendered reload performance are
therefore **not measured**.

The headless probe did complete. Its renderer reports zero draw calls and zero
video memory, so its frame-rate figures are not rendering results and are not
reported as FPS. CPU-side streaming measurements from that run:

- Crossroads startup through `main.tscn`: 23.5 s; static resource memory was
  about 1,056 MiB before entering Moy.
- Moy approach/load: 7.86 s; 185 packs active, about 1,266 MiB static memory.
- Across 579 activation-frame samples, the largest frame was 92.69 ms; 30
  samples exceeded 50 ms. The two unload/reload cycles took 11.10 s and
  11.69 s, respectively.
- The isolated QA probe completed 188 pack activations and showed a 45.6 ms
  mean frame interval in the dummy renderer. This is headless timing only.

Godot's headless logs also contain `wrong RID`, null mesh/storage, and
`unimplemented base type` errors during pack streaming and Xiao Hou Zi/player
mesh updates, plus dummy-renderer RID leaks at shutdown. The scripted validator
still exits with zero failures, but these engine errors need a renderer-backed
follow-up; the failed windowed launch prevented determining which reproduce
with the real renderer. The macOS CA-certificate lookup warning appears on
Godot runs and is separate from the Moy checks.

## Not physically verified

No hands-on game session was performed. In particular, neither playable
character was physically walked over every City Hall, Clock Room, Deck,
escalator, ramp, landing, or tower exit; neither was used to board and ride
every train; and the pond was not waded/swum from above and below. The four
Crossing lift rides, eye flight/glide traversal, underside collision checks,
hotel rides, and full hotel route were not physically tested. Automated
geometry, ray, schedule, and handover checks are not substitutes for those
walkthroughs.

## Plan/data discrepancies

- Regeneration used Python 3.9.6 and Shapely 2.0.7 and emitted
  `RuntimeWarning: invalid value encountered in distance`. It changes the
  generated `WALL`, `OLD_TOWN`, and `OLD_HOUSES` constants relative to the
  checked-out generated file: `WALL` serialization is 7,409→7,408 characters,
  `OLD_TOWN` 16,092→16,178, and `OLD_HOUSES` 21,114→21,131. This includes
  polygon vertex/rounding differences. I have left the tool-generated output
  required for the new build, but these incidental geometry changes are not
  approved layout edits and should be reconciled with the plan owner/tooling.
- The pond profile calls the centre bed −2.1 m relative to park ground while
  the surface is −0.3 m relative to ground. Those authored values yield 1.8 m
  of water depth below the surface. The implementation follows the profile;
  the validator reports 1.8 m. The plan's prose “2.1 m deep” conflicts with
  those numbers.
- Pass 4 names the Grand Hotel as unchanged. The detail gaps listed above
  remain in the frozen pass-3 implementation and need a later scoped hotel
  pass if full model-object fidelity is required.
