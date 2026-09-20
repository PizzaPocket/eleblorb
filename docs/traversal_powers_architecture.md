# Traversal powers: one implementation, every character

Scope for making every suit power, accessory and traversal mode available to
every playable character, on rigs of any size and shape.

## Why the gaps exist

Powers are implemented per character, not per power.

- `player.gd:1936-1948` returns early for every non-human body. Piloting Xiao
  Hou Zi hands off to `_update_xiao_hou_zi_control()`, so nothing below that
  line runs for him: the swim, snowboard, crystal, penguin and mermaid
  systems all live below it.
- `xiao_hou_zi.gd` re-implements what it needs as a parallel `_direct_*`
  family (about 60 state variables). It has swimming, flight, fire jets,
  lava walking, the dirt bike and ice skates. It has no snowboard, crystal
  skates, penguin suit, mermaid tail, lava diving, cloud or canopy support,
  and no pitched body for swimming or flight.
- Every other party member gets a third path: `_update_generic_party_control()`
  (`player.gd:3460`) delegates to that member's own `drive_from_player()`.

So a new power costs one implementation per character, and is a gap for
everyone else until someone ports it. The one power that works everywhere,
zero-gravity propulsion, is the one already written as shared code
(`_update_remote_zero_g()`).

## What already generalises

Worth building on rather than replacing:

- `PlayableCharacterProfile` (`playable_character_profile.gd`) already carries
  size, gait and rig-fit data per character, including `suit_rig_scale` and
  the per-joint `suit_limb_fit` dictionary.
- Both rigs already publish the **same rig-neutral joint names** through
  `_blorb_suit_pivot_map()` (`player.gd:1700`, `xiao_hou_zi.gd:372`):
  `arm_left_shoulder`, `leg_right_ankle`, `spine`, `head` and so on. The suit
  system already dresses two different skeletons through that one vocabulary.
- `HumanoidLocomotion` is already a body-agnostic maths module taking a
  profile (`ground_speed()`, `gravity_surface_glide()`, `ballistic_step()`).
- `PartyControl` already has a duck-typed control contract:
  `playable_id()`, `has_playable_capability()`, `drive_from_player()`,
  `prepare_direct_control_environment()`, `uses_pitched_movement_input()`.

The missing layer is between those two: the powers themselves.

## Target architecture

**1. `TraversalContext`** — one small object built per body per frame:
the body, its profile, its `BlorbSuitController`, its rig adapter, the frame's
input (direction, sprint, jump), the terrain and world queries, and delta.
Powers read it and write to `body.velocity`, `body.global_position` and the
rig. Nothing in a power refers to `Player` or to a character by name.

**2. `TraversalMode`** — one class per power, one instance per body, holding
that body's own state (so no state dictionaries keyed by instance):

```
id() -> StringName
requires() -> Dictionary      # suit pieces and items that gate it
is_available(ctx) -> bool     # suit state + profile capability
update(ctx) -> bool           # true if it owned this frame's movement
pose(ctx) -> void             # rig-neutral pose, applied only if it owned
```

Each existing power becomes one of these: `SwimMode`, `MermaidTailMode`,
`PenguinMode`, `SnowboardMode`, `IceSkateMode`, `CrystalSkateMode`,
`DirtbikeMode`, `AirFlightMode`, `FootHoverMode`, `FireJetMode`,
`LavaWalkMode`, `LavaDiveMode`, `ZeroGMode`.

**3. `RigAdapter`** — the joint vocabulary above, plus the profile's scale
data, plus graceful absence (MonkeyFigure has no `neck`; a pose asking for one
gets a no-op rather than a crash). Poses are written once against joint names
and land correctly on any rig.

**4. `TraversalDirector`** — owns the ordered mode list for a body, runs
`update()` in priority order, and the first mode that returns true owns the
frame and supplies the pose. This replaces the long `if/elif` chains in
`player.gd::_physics_process` and becomes the single body-pose owner that
`tools/check_body_pose_owner.py` enforces.

**5. Capability gating stays data.** A character opts out of a power only
through an explicit profile capability (Xiao has no `needs_breath` by design).
Everything else is available to anyone whose suit satisfies `requires()`.

## Scaling to different rigs

The rule: **no power may contain an absolute distance.** Every length is
expressed one of three ways.

- A fraction of `profile.standing_height` (ride heights, step limits, sink
  depths, the snowboard's deck lift).
- A speed from `HumanoidLocomotion` given the profile (never a raw m/s).
- An angle, which is already scale-free (most pose work).

`TraversalContext` provides `ctx.scaled(metres)` converting a human-authored
reference length into this body's equivalent, so existing tuned constants can
move across unchanged and stay meaningful on a rig a quarter the size.
Equipment built onto the rig keeps using the suit's existing `suit_limb_fit`
path, which already solves the "short limbs, broad wrists" problem.

## Migration slices

Each slice ships and is verified on its own. Behaviour for the human must not
change in slices 0 to 5; the whole point is that Xiao and the others gain.

0. **Scaffolding, no behaviour change.** Context, mode base, director, rig
   adapter. Move exactly one simple power (ice skates) onto it for the human
   only, and confirm the human is unchanged.
1. **Water.** Swim, dive, lakebed walk, mermaid tail, and the pitched
   swimming body (`_pose_body_skull_anchored`). Highest visible value: Xiao
   currently swims bolt upright.
2. **Snow and ice.** Snowboard, crystal skates, penguin suit.
3. **Air.** Flight, foot hover, and cloud/canopy support queries, which Xiao
   never makes at all.
4. **Fire.** Hover jets, limb flight, lava walking, lava diving.
5. **Ground and space.** Dirt bike, zero-g (already shared, folded in for
   uniformity).
6. **Delete the duplicates.** Remove the `_direct_*` family from
   `xiao_hou_zi.gd` and the power branches from `player.gd`, leaving each
   character with its own gait, rig and unique abilities only. This slice is
   where the line count comes back down.

## Verification

A headless parity probe (`tools/probe_parity.gd`) that, for every
(character x power) pair, places the body in a scenario where the power should
engage, drives it for a fixed number of frames, and asserts the expected
outcome (engaged, moved, posed). It prints the parity matrix, so the table
stops being something anyone maintains by hand and becomes a build artifact.
Run it before and after every slice.

Per-slice, the existing approach continues: probe the specific behaviour on
the scratch copy and compare numbers before and after.

## Risks

- `player.gd` is about 8,700 lines and its power branches are entangled with
  grounded state, terrain snapping and pose ownership. Slices 0 and 1 must
  prove the pattern on the human before anything is deleted.
- Pose ownership is already guarded by a tool; the director has to take that
  role deliberately rather than by accident.
- Camera anchoring (the skull anchor) is tied to the human head node and needs
  a rig-adapter route before slice 1 lands.
- Some powers bake human proportions into constants. Slice 0 should add
  `ctx.scaled()` and convert the constants of the first power moved, so the
  pattern is set before the bulk arrives.

## Non-goals

Changing how any power feels for the human, redesigning the suit visuals, or
unifying the characters' distinct gaits and silhouettes. Each character keeps
its own movement character; only the powers become common.
