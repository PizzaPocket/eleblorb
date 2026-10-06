class_name FacadeFeatures
extends RefCounted

## The catalogue of facade features that make siblings of one tradition into
## individuals (see the architecture skill's references/features.md): oriel and
## bay windows, a Juliet balcony, a Georgian door case, hood moulds over windows,
## a gable hoist, a rear oven outshut, a climbing rose on a trellis. Each is a
## SuperEgg composition hung on a TownProps.build_building() body, parametrised
## by position, so a village draws a varied set from one vocabulary.
##
## Frame: the building's own, with the front wall at z = -half_depth (outward is
## -Z) and the gable walls at x = +/- half_width (outward is +/-X). Floors are
## FLOOR_HEIGHT apart. Small trim is decorative; anything a body could stand on
## or walk into is solid.

const GLASS := Color(0.50, 0.68, 0.80)


static func _piece(
	body: StaticBody3D, half: Vector3, color: Color, position: Vector3, basis: Basis = Basis(),
	solid: bool = false, epsilon: float = SuperEgg.EPSILON_FLAT
) -> MeshInstance3D:
	var mesh := SuperEgg.build_part(half, color, epsilon, SuperEgg.EPSILON_FLAT)
	mesh.transform = Transform3D(basis, position)
	body.add_child(mesh)
	if solid:
		CollisionPolicy.add_box(body, mesh, half * 2.0, position, basis, false)
	else:
		CollisionPolicy.mark_decorative(mesh)
	return mesh


## Applies a named list of features. `features` entries are dictionaries:
## {"kind", "x" (centre along the wall), "floor" (0 or 1, default 1), "wall"
## ("front", default, or "east"/"west" for gables)}.
static func apply(
	building: StaticBody3D, w_cells: int, d_cells: int, floors: int, features: Array,
	entry_style: String, roof: Color, timber: Color, stone: Color, wall: Color,
	roof_form: Dictionary = {}
) -> void:
	var half_w := float(w_cells) * TownProps.CELL_SIZE * 0.5
	var half_d := float(d_cells) * TownProps.CELL_SIZE * 0.5
	for feature in features:
		var kind := str(feature["kind"])
		var x := float(feature.get("x", 0.0))
		var base := float(int(feature.get("floor", 1))) * TownProps.FLOOR_HEIGHT
		match kind:
			"oriel":
				oriel(building, x, -half_d, base, wall, timber, roof, false)
			"bay_window":
				oriel(building, x, -half_d, 0.0, wall, timber, roof, true)
			"juliet":
				juliet(building, x, -half_d, base, timber)
			"door_case":
				door_case(building, x, -half_d, TownProps.DOOR_WIDTH, TownProps.DOOR_HEIGHT, stone, timber)
			"hood_moulds":
				hood_moulds(building, -half_d, w_cells, floors, entry_style, stone)
			"gable_hoist":
				gable_hoist(building, float(feature.get("side", 1.0)), floors, half_w, half_d, timber)
			"oven_outshut":
				oven_outshut(building, x, half_d, floors, float(roof_form.get("catslide", 2.0)), roof)
			"cross_gable":
				RoofForms.cross_gable(
					building, d_cells, floors, x, float(feature.get("width", 3.8)), roof,
					wall if floors > 1 else stone, timber
				)
			"belfry":
				RoofForms.belfry(building, d_cells, floors, x, roof, timber)
			"rear_shed":
				rear_shed(building, w_cells, d_cells, floors, float(roof_form.get("catslide", 1.7)), timber, str(feature.get("stock", "sacks")))
			"rose":
				rose_trellis(building, x, -half_d, timber)


## A projecting window bay: floor and ceiling slabs, side panels, a glazed front
## on slender frame members, stepped corbels beneath (or a stone plinth when
## `grounded`), and a little pent roof. The wall opening behind it is left as it
## was, so the room looks out through the bay.
static func oriel(
	building: StaticBody3D, x: float, wall_z: float, base_y: float, wall: Color, timber: Color,
	roof: Color, grounded: bool
) -> void:
	var half_w := 0.66
	var depth := 0.62
	var y0 := base_y + (0.62 if grounded else 0.84)
	var y1 := base_y + 2.72
	var mid := (y0 + y1) * 0.5
	var half_h := (y1 - y0) * 0.5
	_piece(building, Vector3(half_w, 0.05, depth * 0.5), timber, Vector3(x, y0, wall_z - depth * 0.5), Basis(), true)
	_piece(building, Vector3(half_w + 0.04, 0.05, depth * 0.5 + 0.04), timber, Vector3(x, y1, wall_z - depth * 0.5), Basis(), true)
	for side: float in [-1.0, 1.0]:
		_piece(building, Vector3(0.04, half_h, depth * 0.5), wall, Vector3(x + side * half_w, mid, wall_z - depth * 0.5), Basis(), true)
		_piece(building, Vector3(0.05, half_h, 0.05), timber, Vector3(x + side * half_w, mid, wall_z - depth), Basis(), false)
	_piece(building, Vector3(half_w - 0.04, half_h - 0.08, 0.012), GLASS, Vector3(x, mid, wall_z - depth + 0.02), Basis(), false)
	_piece(building, Vector3(0.03, half_h, 0.035), timber, Vector3(x, mid, wall_z - depth - 0.005), Basis(), false)
	_piece(building, Vector3(half_w, 0.035, 0.035), timber, Vector3(x, mid + 0.25, wall_z - depth - 0.005), Basis(), false)
	_piece(building, Vector3(half_w + 0.02, 0.05, 0.05), timber, Vector3(x, y0 + 0.07, wall_z - depth - 0.01), Basis(), false)
	if grounded:
		_piece(building, Vector3(half_w + 0.06, (y0 - 0.02) * 0.5, depth * 0.5 + 0.04), Color(0.66, 0.64, 0.6), Vector3(x, (y0 - 0.02) * 0.5, wall_z - depth * 0.5 - 0.02), Basis(), true)
	else:
		for step in 3:
			var shrink := float(step) * 0.14
			_piece(
				building, Vector3(half_w * (0.92 - shrink), 0.07, 0.12 + float(step) * 0.07), timber.lightened(0.04 * float(step)),
				Vector3(x, y0 - 0.12 - float(step) * 0.13, wall_z - 0.12 - float(step) * 0.07), Basis(), false, SuperEgg.EPSILON_SOFT
			)
	var tilt := Basis(Vector3.RIGHT, -deg_to_rad(18.0))
	_piece(building, Vector3(half_w + 0.12, 0.04, depth * 0.5 + 0.14), roof, Vector3(x, y1 + 0.12, wall_z - depth * 0.5 - 0.02), tilt, false)
	# The shutters belong to the bay, not the wall behind it: each is hinged at the
	# bay's front corner and folded back flat against the outside of its side panel,
	# curved margin at the hinge, straight edge toward the house.
	var accent := roof.darkened(0.12)
	var leaf_width := depth - 0.06
	var leaf_mesh := OpeningTrim.half_slab(leaf_width, half_h - 0.06, 4.0, 0.04)
	var inset_mesh := OpeningTrim.half_slab(leaf_width, half_h - 0.06, 4.0, 0.03)
	for side: float in [-1.0, 1.0]:
		var leaf := MeshInstance3D.new()
		leaf.mesh = leaf_mesh
		leaf.material_override = _shutter_material(accent)
		leaf.rotation.y = PI * 0.5
		leaf.position = Vector3(x + side * (half_w + 0.065), mid, wall_z - depth + leaf_width + 0.02)
		building.add_child(leaf)
		CollisionPolicy.mark_decorative(leaf)
		var inset := MeshInstance3D.new()
		inset.mesh = inset_mesh
		inset.material_override = _shutter_material(accent.lightened(0.16))
		inset.scale = Vector3(0.74, 0.8, 1.0)
		inset.position = Vector3(leaf_width * 0.1, 0.0, side * 0.022)
		leaf.add_child(inset)
		CollisionPolicy.mark_decorative(inset)


static func _shutter_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	return material


## A Juliet balcony: a shallow balustrade across a window, held out on two
## corbels. One cannot step out; one stands at the opening.
static func juliet(building: StaticBody3D, x: float, wall_z: float, base_y: float, timber: Color) -> void:
	var half_w := 0.74
	var reach := 0.24
	var y_low := base_y + 0.96
	var y_top := base_y + 1.58
	var z := wall_z - reach
	_piece(building, Vector3(half_w, 0.045, reach * 0.5 + 0.04), timber, Vector3(x, y_low, wall_z - reach * 0.5), Basis(), true)
	_piece(building, Vector3(half_w, 0.04, 0.05), timber, Vector3(x, y_top, z), Basis(), true)
	for side: float in [-1.0, 1.0]:
		_piece(building, Vector3(0.05, (y_top - y_low) * 0.5 + 0.03, 0.05), timber, Vector3(x + side * half_w, (y_top + y_low) * 0.5, z), Basis(), true)
		_piece(building, Vector3(0.05, 0.1, 0.1), timber.lightened(0.05), Vector3(x + side * (half_w - 0.1), y_low - 0.12, wall_z - 0.1), Basis(), false, SuperEgg.EPSILON_SOFT)
	var count := 9
	for i in count:
		var bx := x + lerpf(-half_w + 0.14, half_w - 0.14, float(i) / float(count - 1))
		_piece(building, Vector3(0.022, (y_top - y_low) * 0.5 - 0.02, 0.022), timber.lightened(0.08), Vector3(bx, (y_top + y_low) * 0.5, z), Basis(), false, 2.4)


## A Georgian door case: pilasters, an entablature, a small pediment and a
## fanlight over the door, on a two-step stoop. Polite buildings only.
static func door_case(
	building: StaticBody3D, x: float, wall_z: float, door_width: float, door_height: float,
	stone: Color, timber: Color
) -> void:
	var pilaster := stone.lightened(0.08)
	for side: float in [-1.0, 1.0]:
		_piece(
			building, Vector3(0.13, (door_height + 0.25) * 0.5, 0.13), pilaster,
			Vector3(x + side * (door_width * 0.5 + 0.26), (door_height + 0.25) * 0.5, wall_z - 0.1), Basis(), true
		)
		_piece(building, Vector3(0.18, 0.08, 0.18), stone.darkened(0.06), Vector3(x + side * (door_width * 0.5 + 0.26), 0.08, wall_z - 0.1), Basis(), false)
	_piece(
		building, Vector3(door_width * 0.5 + 0.55, 0.1, 0.17), pilaster,
		Vector3(x, door_height + 0.3, wall_z - 0.12), Basis(), true
	)
	var pediment := MeshInstance3D.new()
	pediment.mesh = EntryDressing._prism(
		[Vector2(-door_width * 0.5 - 0.6, 0.0), Vector2(door_width * 0.5 + 0.6, 0.0), Vector2(0.0, 0.36)], 0.2
	)
	var material := StandardMaterial3D.new()
	material.albedo_color = pilaster
	material.roughness = 0.85
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	pediment.material_override = material
	pediment.position = Vector3(x, door_height + 0.4, wall_z - 0.12)
	building.add_child(pediment)
	CollisionPolicy.mark_decorative(pediment)
	_piece(building, Vector3(door_width * 0.5 - 0.1, 0.13, 0.02), GLASS, Vector3(x, door_height + 0.11, wall_z - 0.04), Basis(), false, 2.2)
	_piece(building, Vector3(0.025, 0.13, 0.03), timber, Vector3(x, door_height + 0.11, wall_z - 0.05), Basis(), false)
	EntryDressing._stoop(building, x, door_width + 1.0, 0.95, wall_z, stone, 2)


## Hood moulds (drip moulds): a small projecting slab with short returns over
## each window and wide window on the front wall, on every floor.
static func hood_moulds(
	building: StaticBody3D, wall_z: float, w_cells: int, floors: int, entry_style: String, stone: Color
) -> void:
	var width := float(w_cells) * TownProps.CELL_SIZE
	var mould := TownProps.TRIM_WOOD.lightened(0.12)
	for floor_index in floors:
		for opening in TownProps.panel_wall_openings("south", width, floor_index, floors, entry_style):
			var kind := str(opening["kind"])
			if kind != "window" and kind != "wide":
				continue
			var half := float(opening["width"]) * 0.5 + 0.2
			var y := float(opening["top"]) + 0.1
			var x := float(opening["center"])
			_piece(building, Vector3(half, 0.05, 0.1), mould, Vector3(x, y, wall_z - 0.16), Basis(), false, SuperEgg.EPSILON_SOFT)
			for side: float in [-1.0, 1.0]:
				_piece(building, Vector3(0.05, 0.1, 0.08), mould, Vector3(x + side * (half - 0.04), y - 0.1, wall_z - 0.14), Basis(), false)


## A loft door on a gable wall with a hoist above it, for hauling sacks and
## timber into the roof space. It is a working rig: a framed pair of boarded
## leaves (shut), a beam projecting under the rake from the wall, braced back to
## the wall below, a pulley block hung from the beam's tip, a rope running down
## from the block to a hook, and a sack riding on the hook at the loft sill. The
## beam, rope and sack are decorative; the door leaves are the wall's boards.
static func gable_hoist(
	building: StaticBody3D, side: float, floors: int, half_w: float, half_d: float, timber: Color
) -> void:
	# The outer face of a panel wall stands a little proud of its grid line.
	var wall_x := side * (half_w + 0.1)
	var peak_y := float(floors) * TownProps.FLOOR_HEIGHT + half_d * tan(TownProps.ROOF_PITCH)
	var door_base: float
	var door_height: float
	if floors > 1:
		# Above the head of a wheel on the same wall, so the two never meet.
		door_base = float(floors - 1) * TownProps.FLOOR_HEIGHT + 1.95
		door_height = 1.35
	else:
		door_base = TownProps.FLOOR_HEIGHT + 0.12
		door_height = 1.1
	var mid := door_base + door_height * 0.5
	var boards := timber.lightened(0.35)
	var frame := timber.darkened(0.12)
	# Two leaves with a visible meeting line, battens and strap hinges, in a frame.
	for leaf: float in [-1.0, 1.0]:
		_piece(
			building, Vector3(0.025, door_height * 0.5, 0.27), boards,
			Vector3(wall_x + side * 0.03, mid, leaf * 0.28), Basis(), false
		)
		for batten_y: float in [door_base + door_height * 0.22, door_base + door_height * 0.78]:
			_piece(building, Vector3(0.03, 0.035, 0.26), frame.darkened(0.3), Vector3(wall_x + side * 0.058, batten_y, leaf * 0.28), Basis(), false)
	_piece(building, Vector3(0.03, door_height * 0.5, 0.012), frame.darkened(0.4), Vector3(wall_x + side * 0.06, mid, 0.0), Basis(), false)
	for post: float in [-1.0, 1.0]:
		_piece(building, Vector3(0.045, door_height * 0.5 + 0.06, 0.05), frame, Vector3(wall_x + side * 0.045, mid, post * 0.6), Basis(), false)
	_piece(building, Vector3(0.045, 0.05, 0.66), frame, Vector3(wall_x + side * 0.045, door_base + door_height + 0.05, 0.0), Basis(), false)
	_piece(building, Vector3(0.05, 0.04, 0.66), frame, Vector3(wall_x + side * 0.05, door_base - 0.03, 0.0), Basis(), false)
	var beam_y := minf(door_base + door_height + 0.5, peak_y - 0.35)
	var tip := 1.35
	_piece(building, Vector3(tip * 0.5, 0.07, 0.07), timber, Vector3(wall_x + side * tip * 0.5, beam_y, 0.0), Basis(), false)
	# A knee brace from the wall below back up to the beam, so it is carried.
	var brace_from := Vector3(wall_x + side * 0.05, beam_y - 0.75, 0.0)
	var brace_to := Vector3(wall_x + side * (tip * 0.72), beam_y - 0.06, 0.0)
	var brace := SuperEgg.build_part(Vector3(0.045, (brace_to - brace_from).length() * 0.5, 0.045), timber, SuperEgg.EPSILON_FLAT, SuperEgg.EPSILON_FLAT)
	brace.position = (brace_from + brace_to) * 0.5
	brace.quaternion = Quaternion(Vector3.UP, (brace_to - brace_from).normalized())
	building.add_child(brace)
	CollisionPolicy.mark_decorative(brace)
	# The pulley block, its sheave, the rope down to a hook, and a sack on it.
	var block_x := wall_x + side * (tip - 0.08)
	_piece(building, Vector3(0.05, 0.1, 0.075), frame, Vector3(block_x, beam_y - 0.17, 0.0), Basis(), false)
	var sheave := SuperEgg.build_part(Vector3(0.03, 0.11, 0.11), Color(0.25, 0.22, 0.2), 2.0, 2.0)
	sheave.position = Vector3(block_x, beam_y - 0.2, 0.0)
	building.add_child(sheave)
	CollisionPolicy.mark_decorative(sheave)
	var hook_y := door_base + 0.55
	var rope_top := beam_y - 0.3
	_piece(building, Vector3(0.009, (rope_top - hook_y) * 0.5, 0.009), Color(0.62, 0.52, 0.34), Vector3(block_x, (rope_top + hook_y) * 0.5, 0.0), Basis(), false, 2.2)
	_piece(building, Vector3(0.02, 0.05, 0.02), Color(0.22, 0.22, 0.24), Vector3(block_x, hook_y - 0.04, 0.0), Basis(), false, 2.2)
	_piece(building, Vector3(0.2, 0.26, 0.18), Color(0.78, 0.68, 0.46), Vector3(block_x, hook_y - 0.3, 0.0), Basis(Vector3.UP, 0.4), false, SuperEgg.EPSILON_SOFT)


## The open outshut under a catslide: the rear slope runs on down to a low eave
## carried on a plate and square posts, the back door stands under it, and the
## trade keeps its stock there (sacks for the mill, faggots for the oven).
static func rear_shed(
	building: StaticBody3D, w_cells: int, d_cells: int, floors: int, run: float, timber: Color, stock: String,
	clear_x: float = INF
) -> void:
	var half_w := float(w_cells) * TownProps.CELL_SIZE * 0.5
	var half_d := float(d_cells) * TownProps.CELL_SIZE * 0.5
	var eave_y := float(floors) * TownProps.FLOOR_HEIGHT
	var post_z := half_d + run - 0.1
	# The post's top meets the roof's underside, flush with the wall top at the wall plane.
	var top_y := TownProps.roof_underside_y(eave_y, half_d, post_z) - 0.02
	var count := maxi(w_cells, 2) + 1
	for i in count:
		var x := lerpf(-half_w + 0.35, half_w - 0.35, float(i) / float(count - 1))
		_piece(building, Vector3(0.1, (top_y + 0.25) * 0.5, 0.1), timber, Vector3(x, (top_y - 0.25) * 0.5, post_z), Basis(), true)
	_piece(building, Vector3(half_w + 0.1, 0.1, 0.11), timber, Vector3(0.0, top_y - 0.05, post_z), Basis(), false)
	match stock:
		"sacks":
			for i in 7:
				var x := -half_w + 1.3 + float(i) * 0.95
				if absf(x - clear_x) < 1.5:
					continue
				var row := 0 if i % 3 != 2 else 1
				_piece(
					building, Vector3(0.34, 0.2, 0.22), Color(0.80, 0.72, 0.52).darkened(0.06 * float(i % 2)),
					Vector3(x, 0.2 + 0.4 * float(row), half_d + 0.45), Basis(Vector3.UP, 0.1 * float(i % 3 - 1)),
					true, 2.6
				)
		"faggots":
			for i in 6:
				var x := -half_w + 0.9 + float(i) * 0.5
				if absf(x - clear_x) < 1.5:
					continue
				_piece(
					building, Vector3(0.2, 0.2, 0.55), Color(0.46, 0.34, 0.2).lightened(0.05 * float(i % 3)),
					Vector3(x, 0.2 + (0.38 if i % 2 == 1 else 0.0), half_d + 0.7), Basis(), true, 2.4
				)


## A brick oven outshut under the catslide at the rear: a back wall and two
## sloping side walls that follow the roof's underside, and the oven's own stack
## rising through the roof.
static func oven_outshut(
	building: StaticBody3D, x: float, half_d: float, floors: int, run: float, roof: Color
) -> void:
	var brick := TownProps.OHIO_BRICK
	var width := 3.0
	var tan_pitch := tan(TownProps.ROOF_PITCH)
	var eave_y := float(floors) * TownProps.FLOOR_HEIGHT
	var back_z := half_d + run - 0.25
	var under_back := TownProps.roof_underside_y(eave_y, half_d, back_z) - 0.02
	var under_front := eave_y + 0.12
	_piece(building, Vector3(width * 0.5, under_back * 0.5, 0.11), brick, Vector3(x, under_back * 0.5, back_z), Basis(), true)
	var side: Array[Vector2] = [
		Vector2(half_d, 0.0), Vector2(back_z, 0.0), Vector2(back_z, under_back), Vector2(half_d, under_front),
	]
	for sign_value: float in [-1.0, 1.0]:
		RoofForms.prism(
			building, side, Vector3(x + sign_value * width * 0.5, 0.0, 0.0),
			Basis(Vector3(0, 0, 1), Vector3(0, 1, 0), Vector3(1, 0, 0)), 0.22, brick.darkened(0.04), true
		)
	var stack_z := back_z - 0.45
	var roof_y := TownProps.roof_top_y(eave_y, half_d, stack_z)
	_piece(building, Vector3(0.17, 0.85, 0.17), brick.darkened(0.08), Vector3(x + 0.55, roof_y + 0.45, stack_z), Basis(), true)
	_piece(building, Vector3(0.24, 0.05, 0.24), brick.darkened(0.2), Vector3(x + 0.55, roof_y + 1.33, stack_z), Basis(), false, SuperEgg.EPSILON_SOFT)


## A climbing rose on a lattice trellis beside the door.
static func rose_trellis(building: StaticBody3D, x: float, wall_z: float, timber: Color) -> void:
	var half_w := 0.55
	var height := 2.4
	for side: float in [-1.0, 1.0]:
		_piece(building, Vector3(0.035, height * 0.5, 0.035), timber, Vector3(x + side * half_w, height * 0.5, wall_z - 0.1), Basis(), false)
	for i in 5:
		var y := 0.4 + (height - 0.5) * float(i) / 4.0
		_piece(building, Vector3(half_w, 0.02, 0.02), timber.lightened(0.1), Vector3(x, y, wall_z - 0.12), Basis(), false)
	for i in 4:
		var px := lerpf(-half_w + 0.15, half_w - 0.15, float(i) / 3.0)
		_piece(building, Vector3(0.02, height * 0.5 - 0.1, 0.02), timber.lightened(0.1), Vector3(x + px, height * 0.5, wall_z - 0.12), Basis(), false)
	var leaf_colors: Array[Color] = [Color(0.17, 0.44, 0.22), Color(0.2, 0.5, 0.25)]
	var bloom_colors: Array[Color] = [Color(0.86, 0.28, 0.36), Color(0.94, 0.62, 0.7)]
	for i in 14:
		var t := float(i) / 13.0
		var px := x + sin(t * 9.0) * (half_w - 0.12)
		var py := 0.35 + t * (height - 0.5)
		_piece(building, Vector3(0.1, 0.09, 0.06), leaf_colors[i % 2], Vector3(px, py, wall_z - 0.17), Basis(), false, 2.2)
		if i % 3 == 0:
			_piece(building, Vector3(0.055, 0.055, 0.05), bloom_colors[(i / 3) % 2], Vector3(px + 0.04, py + 0.05, wall_z - 0.22), Basis(), false, 2.0)
