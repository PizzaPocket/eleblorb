class_name TornadoTail
extends RefCounted

## Shared swirling tornado lower body used by the Sky Kingdom's Tempestars --
## the same "replace the hips downward, keep the hidden leg pivots available
## for existing code" technique AquaticTail already established for merfolk/
## Fish Goblins (see that file's own class doc). Per direct correction: each
## segment's own cross-section is square (equal width and depth, not a
## flattened oval), the segment nearest the body is the BIGGEST and the
## bottom-most one the smallest (tapering to a point at the ground, not the
## other way around), and the whole funnel spins much faster than an
## ordinary idle sway.

const DEFAULT_COLOR := Color(0.64, 0.68, 0.74)
## Multiplies the caller's own slow idle `phase` for the spin only -- the
## gentle sway (see animate()'s own rotation.x/z) keeps using `phase`
## directly, so this can run much faster without also speeding up the wobble.
const SPIN_SPEED := 9.0
## Per direct correction ("the top one should be the biggest with the bottom
## one the smallest, like a tornado shape") -- BIG_SCALE is the segment
## closest to the body, SMALL_SCALE the ground-facing tip.
const BIG_SCALE := 1.35
const SMALL_SCALE := 0.22
## Per direct correction ("a few more layers to compensate" for the height
## lost by making every band's own height proportional to its own width --
## see HEIGHT_TO_WIDTH_RATIO below) -- also still reads as "six or eight
## narrow banded segments... rather than a few very tall ones," just with
## enough of them to keep the funnel a reasonable total height.
const SEGMENT_COUNT := 12
## Every band's own half-length is this fraction of its own width, so a
## band nearer the tip (much narrower, per BIG_SCALE/SMALL_SCALE above)
## reads as a smaller ring in the SAME proportions as a band nearer the
## body, instead of stretching oblong (unchanged height against a shrinking
## width) the way a fixed half-length did.
const HEIGHT_TO_WIDTH_RATIO := 0.45
## Per direct correction ("the other layers quickly become too rounded") --
## every band now shares the SAME epsilon as the topmost one used to have
## instead of rounding off further down the funnel.
const SEGMENT_EPSILON := 3.4


static func add_to_hips(
	hips: MeshInstance3D, _scale_factor: float = 1.0,
	funnel_color: Color = DEFAULT_COLOR, funnel_material: Material = null
) -> Array[Node3D]:
	var pivots: Array[Node3D] = []
	var rig := hips.get_parent() as Node3D
	var hip_bounds := hips.get_aabb()
	var torso_join_y := hips.position.y + hip_bounds.position.y + hip_bounds.size.y
	hips.visible = false
	var parent: Node3D = rig
	# A single shared base radius (not separate width/depth figures) keeps
	# every ring's own cross-section square rather than flattened into an
	# oval that happened to match the hip's own wider-than-deep footprint.
	var base_radius := (hip_bounds.size.x + hip_bounds.size.z) * 0.23
	var previous_half_length := 0.0
	for index in SEGMENT_COUNT:
		var progress := float(index) / float(SEGMENT_COUNT - 1)
		var side := base_radius * lerpf(BIG_SCALE, SMALL_SCALE, progress)
		var half_length := side * HEIGHT_TO_WIDTH_RATIO
		var pivot := Node3D.new()
		pivot.name = "TornadoPivot%02d" % index
		pivot.position = (
			Vector3(0.0, torso_join_y, hips.position.z)
			if index == 0
			else Vector3(0.0, -previous_half_length * 1.8, 0.0)
		)
		parent.add_child(pivot)
		var segment := SuperEgg.build_part(
			Vector3(side, half_length, side), funnel_color, SEGMENT_EPSILON, SEGMENT_EPSILON
		)
		# Per direct correction ("I ask that the tornado lower bodies be
		# exactly the same material as clouds I don't see that they are") --
		# build_part()'s own material is an ordinary SHADED StandardMaterial3D,
		# so even an identical Color value still reads as darker/lit compared
		# to the sky's actual cloud puffs, which are unshaded. When the caller
		# hands in the real shared cloud material, use it directly instead of
		# build_part()'s own so the funnel is lit (or rather, NOT lit) exactly
		# like a cloud.
		if funnel_material != null:
			segment.set_surface_override_material(0, funnel_material)
		segment.position = Vector3(0.0, -half_length, 0.0)
		pivot.add_child(segment)
		pivots.append(pivot)
		parent = pivot
		previous_half_length = half_length
	return pivots


## Each successive segment spins a little faster than the one above it, for
## a layered swirl rather than one rigid rotating cone, plus a gentle wobble
## sway so a Tempestar planted in one spot still reads as alive -- the same
## spirit as AquaticTail.animate()'s idle sway, just spin-driven instead of
## fin-driven.
static func animate(pivots: Array[Node3D], phase: float, strength: float = 1.0) -> void:
	for index in pivots.size():
		pivots[index].rotation.y = phase * SPIN_SPEED * (1.0 + float(index) * 0.3)
		var sway := phase * 0.6 - float(index) * 0.5
		pivots[index].rotation.x = sin(sway) * deg_to_rad(5.0) * strength
		pivots[index].rotation.z = cos(sway * 0.8) * deg_to_rad(5.0) * strength
