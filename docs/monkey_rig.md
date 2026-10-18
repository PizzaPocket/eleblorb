# Stuffed-animal monkey rig

Xiao Hou Zi and the Plant Kingdom's generated monkeys share `MonkeyFigure`
and `MonkeyGait`. Invisible articulated joints deform continuous soft limbs;
adding a wrist or ankle must not append visible segments or increase the
character's authored reach. Population proportions and appearance remain in
`JungleVillager.body_variant()`, used by both generation and the regression
probe. Xiao Hou Zi keeps the builder's default compact proportions.

## Shape and attachments

- Shoulder sockets fit the actual torso radius at shoulder height. Their
  resting outward angle follows the local torso slope. This makes compact
  pears and elongated villagers use the same fitting rule. Power poses read
  each body's resolved resting shoulder angle.
- Hip sockets fit inside the torso's local cross-section, including its
  forward shift when leaning. Knees divide the embedded hip-to-ankle span;
  the ankle stays at the authored floor-relative height.
- Arms run through shoulder, elbow, wrist/hand and fingertip. The hand is
  carved from the existing forearm span. The rounded cap ends at the real
  fingertip, rather than extending another radius beyond it. Hands have a
  gently swept, rounded taper reminiscent of a boomerang tip in outline;
  their cross-section stays plump and round, rather than flat or spherical.
- Legs widen gently into one rounded stuffed foot. The foot rounds downward
  to the sole; its toe is a marker on the front surface of that same mass.
  There is no independently appended toe bulb below the foot. The broadest
  point sits low, with a restrained forward sweep and a soft knee taper;
  the heel surface must not fold back on itself at rest.
- `suit_arm_profile()` and `suit_leg_profile()` publish the live bare-limb
  centre-lines, radii and endpoint frames. Suit shells inflate those radii.
  Dimensions are transformed through the actual rig basis, including each
  generated variant's scale; there is no fixed display-scale assumption.

The shared tube builder's optional endpoint tangent and radius easing apply
only to callers that request them. Existing human and other tube silhouettes
retain their previous defaults.

## Movement

`MonkeyGait.pose()` is called by both the companion and the villagers.
Shoulders swing opposite hips; knees and elbows follow the human gait's
confirmed phase/sign conventions. Offsets are relative to each built body's
rest pose, preserving stoop, shoulder spread and relaxed elbows. Locomotion
restores head pitch without replacing gaze yaw. Character drivers retain
movement, cadence, traversal priority, and arm-power ownership.

## Blorb eyes and cores

`SuitSurface` caches the committed limb mesh's triangles in bounded ring
bands. Eyes project to their actual local skin surface and orient to that
surface; the live hand/foot frame supplies their stable left/right direction.
Eye mesh scale follows the current size instead of retaining its first pose.

Cores have independent interior hints: hands follow the hand centre-line;
feet sit above the wearer's foot. Surface intersections keep the hint inside,
and exact point/triangle clearance bounds the whole core sphere with a margin.
The core mesh scales on each update, so changing limb thickness cannot leave
an oversized core poking through. These attachment rules apply to both human
and monkey limb shells. Torso/head construction and specialised mermaid face
placement retain their own existing paths.

## Verification

Close the Godot editor before running the probes:

```sh
Godot --headless --path . tools/monkey_rig_probe.tscn
Godot --headless --path . tools/probe_crouch.tscn
python3 tools/check_body_pose_owner.py
python3 tools/check_power_parity.py
python3 tools/check_design_language.py
```

The monkey probe checks Xiao Hou Zi and every min/max combination of generated
size, limb length and tail length. It checks socket coverage, bone lengths,
actual mesh endpoints, sole geometry, gait flexion, suit fit, core containment,
eye-to-skin attachment, and bent human arms/feet. Repeated poses must produce
identical eye positions. Tests intersect the committed mesh independently of
the production surface cache.

`-- --render` saves a front/side/gait/suit gallery to `/tmp/monkey_after.png`.
`-- --detail` saves isolated human/monkey limbs to `/tmp/suit_attachments.png`,
with inspection-only transparency to expose their cores. `-- --benchmark`
reports the cost of rebuilding an arm and foot, including surface fitting.
