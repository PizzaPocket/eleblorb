# Moy Hotel fidelity follow-up

Date: 2026-10-18
Scope: additional Grand Hotel fidelity pass after Moy prototype pass 4. The
existing player, suit, vine, train, and city changes were preserved. The city
was rebaked offline. No web export, commit, or push was made.

## Changes

- Rebuilt the Hotel forecourt details around the real front entrance: a
  four-wing, collidable revolving door that turns in physics, flanking swing
  doors, the forecourt colonnade, the chandelier picture sign, the reception
  desk, concierge desk, and Iris stand.
- Added the measured sloped glass skylight with 4 m trusses, louvre band,
  front box gutter, outlets, and forecourt cistern. The skylight is collision
  solid. It remains part of the nearby Hotel pack set.
- Changed the atrium garden to the plan's 6 m gravel circle; added the six
  rocks at the 3D model's offsets, pavilion, and the two model trees. The
  runnel now has a shallow channel and visible water without a blocking water
  slab.
- Rebuilt the double ramps as the model's curved 18-section runs, with smooth
  guard rails, the model's midpoint support, and separate foot and head
  landings on both routes.
- Corrected the south gallery lean to step north as levels rise. Added the
  2.4 m gallery ledges, 1.1 m void guards, planter troughs and hanging plants,
  and closed room fronts and doors.
- Replaced the 300-crystal chandelier with the plan's 3,000 instances in one
  MultiMesh, added its five bronze rings, tapered arm and four suspension
  ropes. The winch remains static as the plan directs.
- Added the 40 tower ribs, the 40 ribbed tank drum and 40 fixed Windrose
  mullions. The Windrose remains a faux, sealed room as `city.md` specifies;
  its exterior ring of light turns once per in-game hour. The four capsule
  elevators retain the manual call controls and ordered 0, +6.5 and +89.5 m
  floor menu.
- Built the level 27 ring corridor, empty park-facing suite, glass window and
  closed public room frontage. Hotel geometry remains in separately activated
  static packs; Crossroads does not construct the Hotel at startup.
- Added the moving entrance door and Windrose scripts to the offline bake
  source signature. Added runtime assertions for the plan counts, public
  objects, end landings, and actual door/Windrose motion.

## Automated checks

- Offline bake succeeded: `MOY_BAKE packs=197 streets=22 buildings=47 lots=133
  old_houses=60`.
- `python3 tools/check_moy_bake.py`: current, 197 packs; 47 buildings, 133
  lots, 60 old houses, 22 streets.
- `tools/validate_city_plan.tscn`: 22 streets, 47 buildings, 133 lots,
  0 failures.
- `tools/validate_moy_runtime.tscn`: exit 0, failures=0. It activated 211
  runtime packs and confirmed 40 Hotel tower ribs, 40 drum ribs, 40 Windrose
  mullions, 3,000 chandelier crystals, five bronze rings, 11 gallery planting
  multimeshes, four ramp-end landings, the public room objects, turning door
  and Windrose, and four moving capsule lift bodies with the expected menu.
- Existing city runtime assertions also passed: 47 buildings, 133 lots, 60 old
  house bodies, 12 train consists / 30 independent cars, Leaf Hat suit
  handover, vine route handover, turbine rotation, city clocks, and the other
  pass-4 geometry checks.
- `git diff --check`: clean at diagnostic preparation.

## Not verified by these checks

The automated runtime loads and exercises the lift physics, door rotation,
Windrose rotation, and the documented counts. I did not physically ride the
hotel lift as either playable character, walk every Hotel gallery or ramp, or
inspect a rendered Hotel capture. The windowed Godot probe has previously
exited before producing a capture in this environment. The headless runtime
reports some renderer dummy-backend RID/material diagnostics; its rendered FPS
and GPU measurements are not valid performance results. Those remain for
interactive playtesting.

The realization boundary from `city.md` section 8.11 remains in force: the
Windrose interior, other tower floors, offices, Long Bar, and function rooms
are still sealed/faux massing. This pass does not add room furnishing, a
concierge character, Iris character logic, or elevator stops beyond the three
realized Hotel floors.
