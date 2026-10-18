# Walking, liquid and flight boundaries — 18 October 2026

The old human auto-step feature had not been deleted. Its terrain and prop
helpers were skipped on tagged ramps to prevent repeated lifts on continuous
slopes, and the prop helper's upward collision test could reject contact with
the floor itself. Xiao lacked the corresponding prop-step path. Swimming
mostly consulted the analytic basin floor; a built ramp above that floor did
not reliably end swimming. The swim surface clamp also prevented powered
ascent from crossing into air.

## Shared implementation

- `WorldSupport.try_step_up()` handles ordinary walking ledges with full-body
  up/forward/down collision checks. It runs only with grounded walking intent,
  leaves slopes to normal physics, rejects steep landing normals, checks
  overhead clearance and does not advance XZ independently of the controller.
  Its maximum rise is 0.35 m at the reference rig size, scaled through
  `TraversalContext`. The existing dirt-bike path remains separate.
- `LiquidEnvironment.try_stand()` checks actual walkable collision close to
  the feet, including a short probe toward the bank. It requires enough head
  clearance above the liquid and a clear body-sized lift. It updates the
  support floor and clears vertical swim velocity when standing takes over.
  Rigs that tilt their collider for swimming provide their captured upright
  collider transform through `TraversalContext`, so a horizontal swimmer
  cannot stand into a ceiling that only the swimming pose fits beneath.
  Deep submerged surfaces cannot trigger this handoff. The general swimming
  depth threshold now starts before the skull base goes underwater.
- `FlightMode` owns surface-exit eligibility and its latch. Upward input or a
  jump can start a powered breach near the normal floating height. The latch
  lasts through the surface crossing so the swim clamp cannot recapture the
  body. It cannot start Air flight deep underwater. Fire lift still needs its
  held, powered limb pair, available MP and unoccupied hands. Hover controllers
  retain the attained height instead of returning to their underwater target.
- `FlightMode.suppress_fire()` and `SuitPowers` disable Fire jets while immersed
  in water, except for the bounded surface breach. Wading and lava retain Fire
  powers. Air feet no longer enable unrestricted underwater flight.

The human and Xiao drivers supply their input, equipment, rig profile and
origin-to-feet offset to these shared rules. No new movement algorithm is
implemented separately for either character. This does not claim that all
older character-specific locomotion has been migrated.

## Verification

Run `tools/validate_mobility_transitions.tscn` with headless Godot. It exercises
both rig scales against small lips, tagged ramps and raised landings, tall
obstacles, low ceilings, airborne step rejection, swimming onto a bank, shallow
built support above a deep analytic bed, deep-water swimming, upward-velocity
handoff, surface-flight latching, Air feet, and water/lava Fire restrictions.
It also invokes the actual human and Xiao environment adapters to check shallow
support and chest-flight eligibility at depth and at the surface.

The mobility transition validator passed with zero failures at both scales,
including actual driver transitions and upright clearance for a tilted swimmer.
The tests run in an isolated project copy, not alongside the editor's import
cache. The existing `player_support_handoff_probe.tscn` checks floor seams and
wall rejection. Power parity, pose ownership and design-language checks also
run. These are automated physics/controller checks, not a rendered walkthrough
of every settlement or a completion of the older movement refactor.
