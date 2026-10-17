# Moy prototype pass 3 diagnostic

Date: 2026-10-17
Source: latest pulled `main` plus local pass-3 changes and the follow-up below.
No commit or push was made.

## Implemented

- Rebuilt the city from `CityPlan`: 24 streets, 50 building records, 133 lots,
  60 irregular old houses, four garden towers, all listed Deck and park
  planting, columns, parapets, beds and climbers.
- Replaced the Crossing tower TorusMesh galleries/hoops with flat annuli and
  continuous escalator hand strips; added per-contact helix tangent travel.
- Opened the East and West Gate lower station bridges, with platforms, shells,
  glass sides and open track ends. Kept gate and tower passages open.
- Curved Wall Line platforms and sampled only scheduled train positions for
  building/platform clearance.
- Added the Crossing dome, four game-time clocks and the bell swing scheduler.
  No suitable bell audio asset exists, so the named sound placeholder remains.
- Added Civic Plaza / Meridian Walk public routes, hotel public interior and
  four rideable capsule bodies. The hotel interior is now a separate
  baked pack, loaded near the hotel and force-loaded by the QA scene.
- Retained offline baking and 160-node pack subdivision. QA still uses the
  real player, party controls, a full Leaf Hat plant suit, Xiao Hou Zi, two
  Fighting companions with their normal Boxing Gloves, and one Air companion.

## Verified passes

- `python3 tools/check_moy_bake.py`: pass for the initial pass-3 bake, 131
  packs. It was not rerun after the follow-up changes below.
- `Godot --headless --rendering-method gl_compatibility --path .
  res://tools/bake_moy_city.tscn`: pass; 24 / 50 / 133 / 60 plan counts.
- `Godot --headless --rendering-method gl_compatibility --path .
  res://tools/validate_moy_runtime.tscn`: exit 0, `failures=0`.
- Runtime validator confirmed 158 Deck columns, 127 parapets, 41 beds, 9 Deck
  trees, 23 park trees, 62 shrubs, 28 reed clumps, 21 rocks, 6 agave, 104
  climber panels, 8 Meridian piers and 8 Spine frames. It also confirmed four
  clocks, four wind turbines, 12 consists / 30 independent cars, the scheduled
  dwell behavior, the full-suit human↔Xiao Hou Zi handover, and all six tested
  vine route handover chains.
- Scheduled train clearance: zero sampled overlaps across all 12 consists;
  4,320 car samples per two-car consist and 6,480 per three-car consist.
- Runtime geometry checks confirmed 56 continuous profiles, 24 moving flights,
  32 landings, 104 tangent climbers, four open gate passages and two Deck ramp
  towers. Plan-record placement checks passed at 0.05 m tolerance.
- The hotel pack was activated in QA as three pieces (`cell_hotel_interior`
  plus two split pieces); its stop levels and live capsule motion passed the
  original script checks before the control revision below.

## Performance measurements and limits

Headless QA log `/tmp/moy-validate-final.log`: 131 pack activations; individual
instantiate-plus-add time max 18.417 ms, p95 2.352 ms. Activation-frame time
max 141.996 ms, p95 47.036 ms. The 13 frames sampled after all 131 packs were
active ranged to 78.259 ms (p95 56.656 ms). These are headless measurements,
including startup/QA overhead, not a rendered FPS result. They reveal material
activation and steady-state spikes that need a rendered follow-up.

The required windowed rendered probe was attempted with
`tools/moy_performance_probe.tscn`, but the process exited before writing a
probe log or emitting measurements in this environment (process status 134).
Rendered FPS, draw calls, video memory and rendered reload-cycle performance
are therefore **untested**. Do not treat the headless timings as a substitute.

The bake and runtime process report a macOS CA-certificate lookup error, and
headless shutdown reports dummy-renderer/RID object leaks. Both commands exit
successfully; the runtime validator reports `failures=0`. The QA full-suit
rebuild also emits dummy-mesh/RID errors under the headless renderer. Their
absence/presence in a rendered run remains unverified.

## Not physically verified

The scripted checks do not demonstrate a human or Xiao Hou Zi physically
walking every hotel/gallery/escalator/ramp endpoint, changing lines both ways,
boarding a train through a door, or riding each hotel capsule end-to-end and
getting off at all three stops. The hotel capsule schedules and movement are
verified in code, but passenger carry and both characters' complete rides are
untested. The clock test checked the moving time indicators, but not all four
faces at 3:00 / 9:15 / 12:00 or a complete game-day audit of bell strikes.
No tower interior screenshot was captured. Hotel near-distance
activation/release and repeated unload/reload cycles were implemented but not
measured in the required rendered probe. The actual bell sound is absent; only
the scheduled swing/placeholder is present.

## Plan/data contradiction

The platform envelope cannot satisfy both authored dimensions: the platform
offset implied by `PLATFORMS.edge = 1.4 m` and `CROSS.track = 1.5 m` leaves the
3.6 m train car overlapping a 3.0 m-wide platform by 0.4 m. The plan text
requires a 7.5 cm boarding gap. The builder preserves the plan data and instead
uses `track + car half-width + 0.075 + platform half-width` for the platform
center offset, with a further curve allowance for Wall Line cars. This creates
the specified gap but does not use `PLATFORMS.edge` as the center offset. The
data needs an owner decision on which measurement is authoritative.

## Follow-up design adjustments

- Replaced scheduled hotel capsule motion and automatic public-lift cycles
  with Fire Kingdom-style controls: a call post at each stop and an onboard
  destination menu ordered from the highest served floor down. This applies to
  hotel capsules, Deck lifts, station-core lifts and Crossing tower lifts. The
  hotel tower's former solid cylinder collider is now a faceted shell with
  full-height openings at the four authored capsule slots, including at the
  top stop so the player can exit.
- Park paving now has an actual elliptical hole over the terrain's existing
  pond basin, so neither the baked paving nor its collider seals the water.
  `PARK.lawn` remains green; `PARK.dry_garden` reads as gravel. These are the
  only plan-defined grass and dry-garden areas.
- Removed the fast seconds bead from all four clock faces and their update
  script. The hour and minute arrows and bell scheduler remain. This explicitly
  supersedes the drawing's seconds-bead detail for the next handoff, per the
  owner's direction.
- Straight escalators now have a baked, closed return-belt ribbon with rounded
  end turns and transverse tread marks that circulate at the configured 0.9
  m/s speed. Treads travel uphill on the up lane and downhill on the paired
  lane. The Crossing's helical hands now also have visible lower belt returns
  and tread strips that run in the travel direction. The original ramp surface
  remains the only walking collider.
- Replaced the Crossing's green placeholder panels with dense sheets made from
  the existing jungle hanging-vine SuperEgg leaves, stored as MultiMeshes.
  Added plan-directed coral-vine sheets to the Spine portal columns and four
  faces around each Meridian pier stem from +2 to +28 m, matching `GREEN`'s
  sleeve specification.
- Refreshed the offline bake after these edits: `MOY_BAKE packs=165`, 24
  streets, 50 buildings, 133 lots and 60 old houses; process exited 0. The
  pass-3 runtime validator, checker and rendered walk were not rerun after
  these follow-ups. Escalator animation, physical vine appearance and rendered
  performance remain unverified in a live walk.

## Push-time CityPlan validator correction

The pre-push city check exposed a validator assumption that every street must
enter the Rim Walk. Meridian Avenue is authored as an exterior East Gate
approach: its plan rectangle lies just east of the Rim boundary while touching
the Civic Plaza open area. `tools/validate_city_plan.gd` now accepts an
outside-Rim street only when its named wall gate anchor is on that street and
it joins a plan-defined public open. The CityPlan layout and generated bake
were not changed. Verification: `tools/check_moy_bake.py` passed and
`validate_city_plan` reported 24 streets, 50 buildings, 133 lots, 0 failures.
