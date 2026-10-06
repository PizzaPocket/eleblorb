extends Node3D
const NPC_SCENE := preload("res://scenes/npc.tscn")
const ROOF_SNOW := ElementPalette.SNOW_BODY
const ROOF_STRUCTURE := Color(0.24, 0.18, 0.15)
const WALL_COLORS: Array[Color] = [Color(0.48,0.32,0.2), Color(0.58,0.42,0.28), Color(0.42,0.31,0.25)]
const WINTER_APPEARANCE := {
	"skin_colors": [
		Color(0.99, 0.89, 0.78), Color(0.47, 0.33, 0.23),
		Color(0.87, 0.68, 0.52), Color(0.25, 0.17, 0.12),
		Color(0.96, 0.82, 0.69), Color(0.62, 0.45, 0.32),
		Color(0.76, 0.58, 0.42), Color(0.33, 0.22, 0.16),
	],
	"shirt_colors": [
		Color(0.23, 0.4, 0.68), Color(0.62, 0.17, 0.22),
		Color(0.18, 0.5, 0.38), Color(0.48, 0.28, 0.62),
		Color(0.72, 0.43, 0.12), Color(0.16, 0.46, 0.56),
		Color(0.52, 0.24, 0.38), Color(0.28, 0.36, 0.52),
	],
	"pants_colors": [
		Color(0.16, 0.2, 0.3), Color(0.32, 0.22, 0.16),
		Color(0.22, 0.31, 0.25), Color(0.24, 0.18, 0.34),
		Color(0.38, 0.25, 0.12), Color(0.12, 0.3, 0.36),
		Color(0.34, 0.16, 0.22), Color(0.2, 0.25, 0.36),
	],
	"shoe_colors": [
		Color(0.12, 0.1, 0.09), Color(0.24, 0.13, 0.08),
		Color(0.1, 0.16, 0.18), Color(0.18, 0.1, 0.2),
		Color(0.3, 0.18, 0.08), Color(0.08, 0.18, 0.22),
		Color(0.22, 0.08, 0.1), Color(0.12, 0.14, 0.2),
	],
	"glove_colors": [
		Color(0.12, 0.15, 0.22), Color(0.38, 0.2, 0.12),
		Color(0.14, 0.28, 0.25), Color(0.28, 0.14, 0.34),
		Color(0.42, 0.27, 0.1), Color(0.12, 0.25, 0.32),
		Color(0.34, 0.12, 0.18), Color(0.18, 0.2, 0.28),
	],
	"hair_colors": [
		Color(0.08, 0.055, 0.04), Color(0.58, 0.36, 0.15),
		Color(0.28, 0.14, 0.065), Color(0.82, 0.74, 0.62),
		Color(0.55, 0.16, 0.08), Color(0.14, 0.09, 0.065),
		Color(0.68, 0.52, 0.28), Color(0.32, 0.3, 0.32),
	],
	"female_body_scales": [0.88, 0.93, 0.97, 1.0],
	"male_body_scales": [1.01, 1.06, 1.11, 1.15],
	"female_chest_scales": [0.9, 0.94, 0.97, 1.0],
	"male_chest_scales": [1.02, 1.07, 1.12, 1.17],
	"female_hip_scales": [1.02, 1.08, 1.13, 1.17],
	"male_hip_scales": [0.95, 0.99, 1.03, 1.07],
	"abdomen_scales": [1.0, 1.12, 1.04, 1.24, 1.08, 1.28, 1.16, 1.2],
	"female_hair_styles": [FigureHair.STYLE_PONYTAIL, FigureHair.STYLE_LONG, FigureHair.STYLE_BUN, FigureHair.STYLE_PIGTAILS],
	"male_hair_styles": [FigureHair.STYLE_FLAT_TOP, FigureHair.STYLE_AFRO, FigureHair.STYLE_BUZZCUT, FigureHair.STYLE_BUZZCUT],
	"long_hair_lengths": [0.04, 0.12, 0.08, 0.0],
	"dress_indices": [2, 6],
	"dress_has_covered_legs": true,
	"sleeve_style": ProceduralFigure.SLEEVE_STYLE_LONG,
}
const IDENTITIES := [
	{"name": "Elin", "female": true, "lines": [
		"Snow soaks up sound. I listen for the sounds that still carry: a shout, a slab letting go, a chair stopping.",
		"Tomas gives me the ice and Niko gives me the lift. The bell is mine.",
	]},
	{"name": "Tomas", "female": false, "lines": [
		"The lake groans low before a storm. An hour before it hits, it goes silent. That's the one to worry about.",
		"Soren cuts only where I've pushed a pole into the ice and it stayed dry. He argues. The pole wins.",
	]},
	{"name": "Mara", "female": true, "lines": [
		"Gloves, boots, lift harnesses. Everyone complains about the gloves. The harness stitching gets the second pass.",
		"Freya pays for her mittens in smoked trout. I'd rather have coin, but I haven't turned the trout down yet.",
	]},
	{"name": "Soren", "female": false, "lines": [
		"Ice blorbs sit on the clearest freezes. Black ice, no bubbles. When they're there, I cut somewhere else.",
		"The cold store never gets a flame. Tomas carried a lit lantern in once. I haven't let it go.",
	]},
	{"name": "Anja", "female": true, "lines": [
		"A west wind brings needles off the north ridge. When they come from the south, I wait a day before I mark trails.",
		"Berries go on Solveig's board, logs go to the stacks, stormfall I clear. The standing wood I leave to itself.",
	]},
	{"name": "Niko", "female": false, "lines": [
		"Our roofs wear winter better than we do. I'm up there with a shovel. They just sit.",
		"I check every chair bolt before the first run. Elin checks me. She doesn't mention it.",
	]},
	{"name": "Freya", "female": true, "lines": [
		"Something silver moved under the fishing hole yesterday. Ivar says it was my reflection. My reflection isn't that long.",
		"Rye from Astrid, mittens from Mara, and I pay in smoked trout. Everyone's happy except the trout.",
	]},
]

## The Snow Village, built from SnowPlan (the single authored layout). This node
## paints the worn ground, raises every building through LogHouse, dresses each
## by programme (SnowBuildings, NordicHearth, SnowInteriors), lays out the yard's
## landmarks, lamps and windbreak pines, and reports its layout as plain data
## for tools/validate_village.gd.

const LANE_SAMPLE_SPACING := 2.4
const ACCENTS: Array[Color] = [Color(0.52, 0.18, 0.14), Color(0.70, 0.48, 0.18), Color(0.20, 0.44, 0.42)]
const RESIDENT_IDENTITY := {
	"Elin": 0, "Tomas": 1, "Mara": 2, "Soren": 3, "Anja": 4, "Niko": 5, "Freya": 6,
}

var _terrain: Node
var _rng := RandomNumberGenerator.new()
## Dedicated to ChimneySmoke's own per-frame recycling, so unrelated draws on
## _rng can never shift the plumes' random sequence.
var _smoke_rng := RandomNumberGenerator.new()
var _smoke_puffs: Array[ChimneySmoke.Puff] = []
var _center := Vector2.ZERO
var _layout_solids: Array[Dictionary] = []
var _layout_doors: Array[Dictionary] = []
var _layout_facing: Array[Dictionary] = []
var _layout_strokes: Array[Dictionary] = []
var _layout_blobs: Array[Dictionary] = []
var _layout_gates: Array[Dictionary] = []
var _pending_inn: StaticBody3D


func _ready() -> void:
	_terrain = get_node("../Terrain")
	_rng.seed = 20260911
	_smoke_rng.seed = 5591
	_center = _terrain.get_village_center()
	_build_village()
	_build_fishing_camp()


func _process(delta: float) -> void:
	ChimneySmoke.animate(_smoke_puffs, delta, _smoke_rng)


## Everything the validator needs, as plain village-local data.
func layout_report() -> Dictionary:
	return {
		"solids": _layout_solids, "doors": _layout_doors, "gates": _layout_gates, "facing": _layout_facing,
		"strokes": _layout_strokes, "blobs": _layout_blobs, "course": [], "bridge": Vector2(9999.0, 9999.0),
		"start": SnowPlan.YARD_CENTER + Vector2(5.0, 4.0),
		"grid_min": Vector2(-70.0, -80.0), "grid_size": Vector2(230.0, 220.0),
	}


func _ground(world: Vector2) -> float:
	return _terrain.get_mesh_height(world.x, world.y)


func _plan_point(at: Vector2, yaw: float, local: Vector2) -> Vector2:
	return at + Vector2(local.x * cos(yaw) + local.y * sin(yaw), -local.x * sin(yaw) + local.y * cos(yaw))


func _plan_direction(yaw: float, local: Vector2) -> Vector2:
	return Vector2(local.x * cos(yaw) + local.y * sin(yaw), -local.x * sin(yaw) + local.y * cos(yaw))


func _record_solid(label: String, kind: String, at: Vector2, half: Vector2, yaw: float, attached: String = "") -> void:
	_layout_solids.append({"name": label, "kind": kind, "center": at, "half": half, "yaw": yaw, "attached": attached})


func _build_village() -> void:
	_build_ground_plan()
	var index := 0
	for spec: Dictionary in SnowPlan.BUILDINGS:
		_build_building(spec, index)
		index += 1
	_build_yard_features()
	_build_grounds()
	_build_winter_merchant()
	_build_lamps()
	_build_windbreak()
	_build_residents()


# ---------------------------------------------------------------------------
# Ground
# ---------------------------------------------------------------------------

func _build_ground_plan() -> void:
	# Paint, not geometry: the yard, plaza and lanes are trodden earth projected
	# into the terrain (see GroundPaint), so they follow every bump of the ground.
	var strokes: Array = []
	for way: Dictionary in SnowPlan.WAYS:
		var points: Array[Vector2] = []
		points.assign(way["points"])
		var world: Array[Vector2] = []
		for local in GroundPaint.smooth(points, LANE_SAMPLE_SPACING):
			world.append(_center + local)
		strokes.append({"points": world, "width": float(way["width"])})
		_layout_strokes.append({"points": points, "width": float(way["width"])})
	var blobs: Array = [
		{"center": _center + SnowPlan.YARD_CENTER, "radii": SnowPlan.YARD_RADII},
		{"center": _center + SnowPlan.PLAZA_CENTER, "radii": SnowPlan.PLAZA_RADII},
	]
	for wear: Dictionary in SnowPlan.WEAR_BLOBS:
		blobs.append({"center": _center + (wear["center"] as Vector2), "radii": wear["radii"]})
		_layout_blobs.append({"center": wear["center"], "radii": wear["radii"]})
	_layout_blobs.append({"center": SnowPlan.YARD_CENTER, "radii": SnowPlan.YARD_RADII})
	_layout_blobs.append({"center": SnowPlan.PLAZA_CENTER, "radii": SnowPlan.PLAZA_RADII})
	GroundPaint.paint(
		self, strokes, blobs, _ground(_center), "TrodderGround",
		Color(0.90, 0.82, 0.68), Color(0.97, 0.93, 0.82), 0.8, 20260912
	)


# ---------------------------------------------------------------------------
# Buildings
# ---------------------------------------------------------------------------

func _build_building(source: Dictionary, index: int) -> void:
	var spec := source.duplicate(true)
	var at: Vector2 = spec["at"]
	var yaw := deg_to_rad(float(spec["yaw"]))
	var kind := str(spec["kind"])
	spec["log_color"] = LogHouse.LOG_COLORS[index % LogHouse.LOG_COLORS.size()]
	spec["pitch_deg"] = float(spec.get("pitch_deg", 50.0 if kind == "stabbur" else 46.0))
	spec["bellcast"] = bool(spec.get("bellcast", false))
	spec["openings"] = SnowBuildings.openings_for(spec)
	var accent := ACCENTS[index % ACCENTS.size()]
	for opening: Dictionary in spec["openings"]:
		opening["accent"] = accent
	if bool(spec.get("turf", false)):
		spec["roof_color"] = Color(0.30, 0.34, 0.27)
	if bool(spec.get("open_front", false)):
		spec["skip_walls"] = ["front"]
	var body := LogHouse.build(spec)
	body.name = str(spec["name"])
	var lift := 0.0
	if bool(spec.get("raised", false)):
		lift = 0.9
		SnowBuildings.stabbur_piers(body, spec, lift)
	if spec.has("gallery"):
		SnowBuildings.gallery(body, spec)
	if spec.has("lean_to"):
		var lean: Dictionary = spec["lean_to"]
		SnowBuildings.lean_to(body, spec, float(lean["side"]), float(lean["depth"]))
	if bool(spec.get("bell_frame", false)):
		SnowBuildings.bell_tower(body, spec)
	NordicHearth.build(body, spec, _smoke_rng, _smoke_puffs)
	SnowInteriors.build(body, spec)
	_dress_kind(body, spec)
	body.position = Vector3(at.x + _center.x, _ground(_center + at) + lift, at.y + _center.y)
	body.rotation.y = yaw
	add_child(body)
	_record_building(spec, at, yaw)
	if kind == "inn":
		_pending_inn = body
	elif kind == "inn_wing" and _pending_inn != null:
		_open_inn(_pending_inn, body)


## Astrid's inn keeps the rest-and-lodging function every inn has: a paid night in
## a guest bed in the sleeping wing, with the keeper at her counter in the hall.
func _open_inn(hall: StaticBody3D, wing: StaticBody3D) -> void:
	var inn := VillageInn.new()
	inn.world_id = "ice_kingdom"
	inn.point_id = "snow_village_inn"
	inn.fee = 20
	inn.innkeeper_name = "Astrid Snowrest"
	add_child(inn)
	var wake := Marker3D.new()
	wake.position = wing.get_meta("wake_local", Vector3(-6.0, 0.88, 1.6))
	wing.add_child(wake)
	var stand := Marker3D.new()
	stand.position = wing.get_meta("stand_local", Vector3(-3.0, 0.1, -2.1))
	wing.add_child(stand)
	inn._wake_marker = wake
	inn._stand_marker = stand
	var keeper: Node3D = NPC_SCENE.instantiate()
	keeper.set_terrain_reference(_terrain)
	keeper.display_name = "Astrid Snowrest"
	keeper.stationary = true
	keeper.fixed_ground_y = hall.global_position.y
	VillagerAppearance.apply_profile(keeper, 0, 0, true, WINTER_APPEARANCE)
	var lines: Array[String] = [
		"Boots in the mudroom, boards in the drying room. The stove dries a mitten in an hour and a boot overnight.",
		"I bake the rye at four. By five Freya has two loaves under her coat for Solveig, and the rest are still cooling.",
		"The long room sleeps six. On rescue nights it sleeps nine, and nobody complains about the floor.",
	]
	keeper.talk_lines = lines
	keeper.dialog_actions_provider = inn._rest_actions
	var keeper_local: Vector3 = hall.get_meta("keeper_local", Vector3(-1.4, 0.0, 3.85))
	hall.add_child(keeper)
	keeper.position = keeper_local
	# Derive the orientation from the place Astrid serves. Her figure's local
	# +Z is its forward axis, so this continues to work if the counter moves.
	var room_focus := Vector2(-1.4, 0.0)
	var keeper_to_room := room_focus - Vector2(keeper_local.x, keeper_local.z)
	keeper.facing_degrees = rad_to_deg(atan2(keeper_to_room.x, keeper_to_room.y))
	inn._register.call_deferred()


func _dress_kind(body: StaticBody3D, spec: Dictionary) -> void:
	var cells: Vector2 = spec["cells"]
	var width := cells.x * LogHouse.CELL
	var depth := cells.y * LogHouse.CELL
	match str(spec["kind"]):
		"icehouse":
			# Earth banked against the walls: soft mounds, no fire, no window.
			for side: float in [-1.0, 1.0]:
				var berm := SuperEgg.build_part(
					Vector3(0.9, 0.75, depth * 0.5 - 0.3), Color(0.62, 0.68, 0.74), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
				)
				berm.position = Vector3(side * (width * 0.5 + 0.55), 0.5, 0.0)
				body.add_child(berm)
				CollisionPolicy.add_box(body, berm, Vector3(1.8, 1.5, depth - 0.6), berm.position, Basis(), true)
			var back_berm := SuperEgg.build_part(
				Vector3(width * 0.5 - 0.3, 0.75, 0.9), Color(0.62, 0.68, 0.74), SuperEgg.EPSILON_SOFT, SuperEgg.EPSILON_FLAT
			)
			back_berm.position = Vector3(0.0, 0.5, depth * 0.5 + 0.55)
			body.add_child(back_berm)
			CollisionPolicy.add_box(body, back_berm, Vector3(width - 0.6, 1.5, 1.8), back_berm.position, Basis(), true)
		"woodstore":
			for row in 3:
				SnowBuildings.log_stack(body, Vector3(-width * 0.5 + 2.0 + float(row) * 2.9, 0.0, depth * 0.5 - 0.7), 2.4, 4 + row % 2)
		"forester":
			SnowBuildings.log_stack(body, Vector3(width * 0.5 - 1.3, 0.0, depth * 0.5 + 0.7), 2.6, 4, 0.0)
		"bathhouse":
			SnowBuildings.log_stack(body, Vector3(-1.3, 0.0, depth * 0.5 + 0.7), 2.4, 3, 0.0)
		"inn":
			# Benches under the gallery for those waiting, below the common-room windows.
			Furnishings.bench(body, Vector3(0.4, 0.16, -depth * 0.5 - 0.7), 0.0, 1.7)
			Furnishings.bench(body, Vector3(-2.8, 0.16, -depth * 0.5 - 0.7), 0.0, 1.7)
		"rescue":
			# A rack of rescue sleds at the gallery's far end.
			for sx: float in [-0.55, 0.55]:
				var post := SuperEgg.build_part(Vector3(0.06, 0.9, 0.06), SnowGrounds.TIMBER, 4.0, 4.0)
				post.position = Vector3(width * 0.5 - 1.0 + sx, 0.9, -depth * 0.5 - 0.8)
				body.add_child(post)
				CollisionPolicy.add_box(body, post, Vector3(0.12, 1.8, 0.12), post.position, Basis(), false)
			var sled_colors: Array[Color] = [Color(0.7, 0.28, 0.2), Color(0.2, 0.42, 0.6), Color(0.78, 0.6, 0.2)]
			for i in 3:
				var sled := SuperEgg.build_part(Vector3(0.28, 0.025, 0.95), sled_colors[i], 4.0, 4.0)
				sled.position = Vector3(width * 0.5 - 1.0 - 0.4 + 0.4 * float(i), 1.0, -depth * 0.5 - 0.8)
				sled.rotation.x = -0.55
				body.add_child(sled)
				CollisionPolicy.mark_decorative(sled)


func _record_building(spec: Dictionary, at: Vector2, yaw: float) -> void:
	var cells: Vector2 = spec["cells"]
	var width := cells.x * LogHouse.CELL
	var depth := cells.y * LogHouse.CELL
	var name_text := str(spec["name"])
	_record_solid(name_text, "building", at, Vector2(width, depth) * 0.5, yaw, str(spec.get("attached_to", "")))
	for opening: Dictionary in spec["resolved_openings"]:
		if str(opening["kind"]) != "door":
			continue
		if spec.has("passage_x") and absf(float(opening["x"]) - float(spec["passage_x"])) < 0.01 \
				and str(opening["wall"]) == ("front" if str(spec["kind"]) == "inn_wing" else "back"):
			continue
		var x := float(opening["x"])
		var local_pos := Vector2.ZERO
		var local_dir := Vector2.ZERO
		match str(opening["wall"]):
			"front":
				local_pos = Vector2(x, -depth * 0.5)
				local_dir = Vector2(0, -1)
			"back":
				local_pos = Vector2(x, depth * 0.5)
				local_dir = Vector2(0, 1)
			"west":
				local_pos = Vector2(-width * 0.5, x)
				local_dir = Vector2(-1, 0)
			_:
				local_pos = Vector2(width * 0.5, x)
				local_dir = Vector2(1, 0)
		var label := name_text if str(opening["wall"]) == "front" else name_text + " (back)"
		_layout_doors.append({
			"name": label, "kind": "door", "width": float(opening["width"]),
			"pos": _plan_point(at, yaw, local_pos), "dir": _plan_direction(yaw, local_dir),
		})
	if bool(spec.get("open_front", false)):
		# An open-fronted store is entered along its whole front.
		_layout_doors.append({
			"name": name_text, "kind": "door", "width": 3.0,
			"pos": _plan_point(at, yaw, Vector2(0.0, -depth * 0.5)), "dir": _plan_direction(yaw, Vector2(0, -1)),
		})
	if spec.has("lean_to"):
		var lean: Dictionary = spec["lean_to"]
		var side := float(lean["side"])
		var depth_out := float(lean["depth"])
		_record_solid(
			name_text + "LeanTo", "shed", _plan_point(at, yaw, Vector2(side * (width * 0.5 + depth_out * 0.5), 0.0)),
			Vector2(depth_out * 0.5, depth * 0.5), yaw, name_text
		)



# ---------------------------------------------------------------------------
# Grounds: plots, fences, firewood, snow banks
# ---------------------------------------------------------------------------

func _world3(local: Vector2) -> Vector3:
	var world := _center + local
	return Vector3(world.x, _ground(world), world.y)


func _building_spec(label: String) -> Dictionary:
	for spec: Dictionary in SnowPlan.BUILDINGS:
		if str(spec["name"]) == label:
			return spec
	return {}


func _build_grounds() -> void:
	for plot: Dictionary in SnowPlan.PLOTS:
		_build_plot(plot)
	for pile: Dictionary in SnowPlan.WOODPILES:
		_build_woodpile(pile)
	_build_snow_banks()


## One enclosed plot: fence on every side but the house wall it abuts, a gate on the
## side the lane serves, raised beds, a barrel and a compost heap.
func _build_plot(plot: Dictionary) -> void:
	var rect: Rect2 = plot["rect"]
	var x0 := rect.position.x
	var z0 := rect.position.y
	var x1 := x0 + rect.size.x
	var z1 := z0 + rect.size.y
	var gate_spec: Dictionary = plot["gate"]
	var boards: Array = plot["board_sides"]
	var abuts := str(plot["abuts"])
	var sides := {
		"north": [Vector2(x0, z0), Vector2(x1, z0)], "south": [Vector2(x0, z1), Vector2(x1, z1)],
		"west": [Vector2(x0, z0), Vector2(x0, z1)], "east": [Vector2(x1, z0), Vector2(x1, z1)],
	}
	for side: String in sides.keys():
		var a: Vector2 = sides[side][0]
		var b: Vector2 = sides[side][1]
		if side == abuts:
			# The house is this side. Short returns close any gap to its corners.
			var spec := _building_spec(str(plot.get("house", "")))
			if not spec.is_empty():
				continue
			continue
		var segments: Array = [[a, b]]
		if str(gate_spec["side"]) == side:
			var at := float(gate_spec["at"])
			var along := (b - a).normalized()
			var gate_point := Vector2(at, a.y) if side in ["north", "south"] else Vector2(a.x, at)
			segments = [[a, gate_point - along * 0.7], [gate_point + along * 0.7, b]]
			var gate_world := _world3(gate_point)
			SnowGrounds.gate(self, gate_world, atan2(-(b.y - a.y), b.x - a.x))
			var inward := Vector2(0, -1) if side == "south" else (Vector2(0, 1) if side == "north" else (Vector2(1, 0) if side == "west" else Vector2(-1, 0)))
			_layout_gates.append({"pos": gate_point, "dir": inward})
		for segment: Array in segments:
			var sa: Vector2 = segment[0]
			var sb: Vector2 = segment[1]
			if sa.distance_to(sb) < 0.3:
				continue
			SnowGrounds.fence_run(self, _world3(sa), _world3(sb), boards.has(side))
			var direction := (sb - sa).normalized()
			_record_solid(str(plot["name"]) + "Fence", "fence", (sa + sb) * 0.5, Vector2(sa.distance_to(sb) * 0.5, 0.12), atan2(-direction.y, direction.x))
	if str(plot["name"]) == "ForesterYard":
		# Short returns from the yard's north and south fences to the house corners.
		for z_pair in [[21.5, 23.2], [32.8, 34.5]]:
			SnowGrounds.fence_run(self, _world3(Vector2(-31.2, z_pair[0])), _world3(Vector2(-31.2, z_pair[1])), false)
			_record_solid("ForesterYardReturn", "fence", Vector2(-31.2, (z_pair[0] + z_pair[1]) * 0.5), Vector2(0.12, 0.85), 0.0)
	var seed_value := 100
	for bed_spec: Dictionary in plot["beds"]:
		var at: Vector2 = bed_spec["at"]
		var size: Vector2 = bed_spec["size"]
		SnowGrounds.bed(self, _world3(at), size, str(bed_spec["kind"]), seed_value)
		seed_value += 17
		_record_solid(str(plot["name"]) + "Bed", "prop", at, size * 0.5, 0.0)
	SnowGrounds.water_barrel(self, _world3(plot["barrel"]))
	_record_solid("WaterBarrel", "prop", plot["barrel"], Vector2(0.4, 0.4), 0.0)
	SnowGrounds.compost(self, _world3(plot["compost"]))
	_record_solid("CompostHeap", "prop", plot["compost"], Vector2(0.9, 0.75), 0.0)
	if plot.has("stacks"):
		for stack: Vector3 in plot["stacks"]:
			SnowBuildings.log_stack(self, _world3(Vector2(stack.x, stack.y)), 2.4, 4, stack.z)
			var half := Vector2(1.2, 0.5) if absf(stack.z) < 0.1 else Vector2(0.5, 1.2)
			_record_solid("YardWoodStack", "prop", Vector2(stack.x, stack.y), half, 0.0)
		var block: Vector2 = plot["block"]
		SnowGrounds.chopping_block(self, _world3(block))
		_record_solid("ChoppingBlock", "prop", block, Vector2(0.3, 0.3), 0.0)
		var horse: Vector2 = plot["sawhorse"]
		SnowGrounds.sawhorse(self, _world3(horse), 0.3)
		_record_solid("Sawhorse", "prop", horse, Vector2(0.7, 0.3), 0.3)


## Firewood stacked on a blank back wall, under the eave and below the sills.
func _build_woodpile(pile: Dictionary) -> void:
	var spec := _building_spec(str(pile["building"]))
	if spec.is_empty():
		return
	var at: Vector2 = spec["at"]
	var yaw := deg_to_rad(float(spec["yaw"]))
	var cells: Vector2 = spec["cells"]
	var depth := cells.y * LogHouse.CELL
	var length := float(pile["length"])
	var local := Vector2(float(pile["x"]), depth * 0.5 + 0.62)
	var spot := _plan_point(at, yaw, local)
	SnowBuildings.log_stack(self, _world3(spot), length, int(pile["rows"]), yaw)
	_record_solid(str(pile["building"]) + "Woodpile", "prop", spot, Vector2(length * 0.5, 0.5), yaw, str(pile["building"]))


## Snow drifted against the walls that face the weather (west), below the sills,
## never across a door, a lane or a gallery.
func _build_snow_banks() -> void:
	var counter := 0
	for spec: Dictionary in SnowPlan.BUILDINGS:
		var kind := str(spec["kind"])
		if kind in ["stabbur", "woodstore", "icehouse", "naust"]:
			continue
		var at: Vector2 = spec["at"]
		var yaw := deg_to_rad(float(spec["yaw"]))
		var cells: Vector2 = spec["cells"]
		var width := cells.x * LogHouse.CELL
		var depth := cells.y * LogHouse.CELL
		var openings := SnowBuildings.openings_for(spec)
		var walls := {
			"front": {"normal": Vector2(0, -1), "centre": Vector2(0, -depth * 0.5), "length": width, "turn": 0.0},
			"back": {"normal": Vector2(0, 1), "centre": Vector2(0, depth * 0.5), "length": width, "turn": 0.0},
			"west": {"normal": Vector2(-1, 0), "centre": Vector2(-width * 0.5, 0), "length": depth, "turn": PI * 0.5},
			"east": {"normal": Vector2(1, 0), "centre": Vector2(width * 0.5, 0), "length": depth, "turn": PI * 0.5},
		}
		for wall: String in walls.keys():
			var info: Dictionary = walls[wall]
			var normal := _plan_direction(yaw, info["normal"])
			if normal.dot(Vector2(-1, 0)) < 0.7:
				continue
			if wall == "front" and spec.has("gallery"):
				continue
			var wall_length: float = info["length"]
			# Intervals along the wall (local coordinate), minus door spans.
			var intervals: Array[Vector2] = [Vector2(-wall_length * 0.5 + 0.9, wall_length * 0.5 - 0.9)]
			for opening: Dictionary in openings:
				if str(opening["wall"]) != wall or str(opening["kind"]) != "door":
					continue
				var half_span := float(opening["width"]) * 0.5 + 1.9
				intervals = TownProps._subtract_interval(intervals, Vector2(float(opening["x"]) - half_span, float(opening["x"]) + half_span))
			for interval in intervals:
				if interval.y - interval.x < 1.8:
					continue
				# Short drifts rather than one long bank, so a woodpile or a lane
				# interrupts only the drift it touches.
				var chunks := maxi(int(ceil((interval.y - interval.x) / 3.4)), 1)
				for chunk in chunks:
					var from := lerpf(interval.x, interval.y, float(chunk) / float(chunks))
					var to := lerpf(interval.x, interval.y, float(chunk + 1) / float(chunks))
					if to - from < 1.6:
						continue
					var middle := (from + to) * 0.5
					var along_axis := Vector2(1, 0) if wall in ["front", "back"] else Vector2(0, 1)
					var local_point: Vector2 = (info["centre"] as Vector2) + along_axis * middle + (info["normal"] as Vector2) * 1.3
					var spot := _plan_point(at, yaw, local_point)
					if _bank_blocked(spot, to - from - 0.4):
						continue
					counter += 1
					SnowGrounds.snow_bank(self, _world3(spot), to - from - 0.5, yaw + float(info["turn"]), 0.7, 500 + counter)


func _bank_blocked(spot: Vector2, length: float) -> bool:
	for way: Dictionary in SnowPlan.WAYS:
		var points: Array = way["points"]
		for i in points.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(spot, points[i], points[i + 1])
			if spot.distance_to(closest) < float(way["width"]) * 0.5 + length * 0.5 + 0.4:
				return true
	for solid: Dictionary in _layout_solids:
		if str(solid["kind"]) == "building":
			continue
		if spot.distance_to(solid["center"]) < (solid["half"] as Vector2).length() + 1.2:
			return true
	return false

# ---------------------------------------------------------------------------
# Yard: communal fire court, cistern, weather mast
# ---------------------------------------------------------------------------

func _build_yard_features() -> void:
	for feature: Dictionary in SnowPlan.YARD_FEATURES:
		var at: Vector2 = feature["at"]
		var world := _center + at
		var node := Node3D.new()
		node.name = str(feature["name"])
		node.position = Vector3(world.x, _ground(world), world.y)
		add_child(node)
		match str(feature["kind"]):
			"communal_hearth":
				var radius := float(feature["radius"])
				SnowGrounds.communal_hearth_court(node, Vector3.ZERO, radius)
				_record_solid(str(feature["name"]), "prop", at, Vector2(radius, radius), 0.0)
			"mound":
				var radii: Vector2 = feature["radii"]
				var mound := StaticBody3D.new()
				mound.collision_layer = 1
				node.add_child(mound)
				var turf := SuperEgg.build_part(Vector3(radii.x + 0.3, 0.2, radii.y + 0.3), Color(0.40, 0.44, 0.34), 2.4, 2.2)
				turf.position.y = 0.05
				mound.add_child(turf)
				CollisionPolicy.mark_decorative(turf)
				var mesh := SuperEgg.build_part(Vector3(radii.x, 0.85, radii.y), Color(0.9, 0.93, 0.96), 2.2, 2.0)
				mesh.position.y = 0.0
				mound.add_child(mesh)
				CollisionPolicy.add_box(mound, mesh, Vector3(radii.x * 1.5, 1.2, radii.y * 1.5), Vector3(0, 0.35, 0), Basis(), true)
				_record_solid(str(feature["name"]), "prop", at, radii * 0.8, 0.0)
			"stone":
				var holder := StaticBody3D.new()
				holder.collision_layer = 1
				holder.position.y = 0.7
				# The carved face looks toward the lake road, where travellers arrive.
				holder.rotation.y = -2.5
				node.add_child(holder)
				var height := float(feature["height"])
				var stone := SuperEgg.build_part(Vector3(0.5, height * 0.5, 0.17), Color(0.50, 0.51, 0.54), 4.6, 3.0)
				stone.position.y = height * 0.5
				holder.add_child(stone)
				CollisionPolicy.add_box(holder, stone, Vector3(1.0, height, 0.36), stone.position, stone.basis, false)
				# Carved symbols, never letters: three incised bands and a ring.
				for i in 3:
					var band := SuperEgg.build_part(Vector3(0.36, 0.03, 0.02), Color(0.22, 0.24, 0.28), 4.0, 4.0)
					band.position = Vector3(0.0, 0.7 + float(i) * 0.38, -0.175)
					band.rotation.y = 0.0
					holder.add_child(band)
					CollisionPolicy.mark_decorative(band)
				_record_solid(str(feature["name"]), "prop", at, Vector2(0.55, 0.22), -2.5)
			"fire_ring":
				var radius := float(feature["radius"])
				var holder := StaticBody3D.new()
				holder.collision_layer = 1
				node.add_child(holder)
				for i in 12:
					var angle := TAU * float(i) / 12.0
					var rock := SuperEgg.build_part(Vector3(0.24, 0.17, 0.2), Color(0.5, 0.5, 0.52).darkened(0.05 * float(i % 3)), 2.8, 2.8)
					rock.position = Vector3(cos(angle) * radius * 0.55, 0.15, sin(angle) * radius * 0.55)
					rock.rotation.y = -angle
					holder.add_child(rock)
					CollisionPolicy.mark_decorative(rock)
				for i in 6:
					var angle := TAU * (float(i) + 0.5) / 6.0 + 0.3
					var seat := SuperEgg.build_part(Vector3(0.5, 0.14, 0.14), LogHouse.LOG_COLORS[i % 3], 4.0, 4.0)
					seat.position = Vector3(cos(angle) * radius, 0.15, sin(angle) * radius)
					seat.rotation.y = -angle + PI * 0.5
					holder.add_child(seat)
					CollisionPolicy.mark_decorative(seat)
				var embers := ParticleFX.build_flame_particles(9, 0.5, 0.75, 1.5, 2.4, -0.5)
				embers.position.y = 0.2
				node.add_child(embers)
				CollisionPolicy.mark_decorative(embers)
				var glow := OmniLight3D.new()
				glow.position.y = 1.0
				glow.light_color = Color(1.0, 0.55, 0.22)
				glow.light_energy = 1.1
				glow.omni_range = 9.0
				glow.shadow_enabled = false
				node.add_child(glow)
				_record_solid(str(feature["name"]), "prop", at, Vector2(radius * 0.6, radius * 0.6), 0.0)
			"cistern":
				var radius := float(feature["radius"])
				var holder := StaticBody3D.new()
				holder.collision_layer = 1
				node.add_child(holder)
				var curb := SuperEgg.build_part(Vector3(radius, 0.4, radius), Color(0.55, 0.55, 0.58), 3.0, 3.0)
				curb.position.y = 0.4
				holder.add_child(curb)
				CollisionPolicy.add_cylinder(holder, curb, radius, 0.8, curb.position, false)
				var cap := SuperEgg.build_part(Vector3(radius * 0.85, 0.06, radius * 0.85), LogHouse.LOG_COLORS[1], 3.4, 3.4)
				cap.position.y = 0.84
				holder.add_child(cap)
				CollisionPolicy.mark_decorative(cap)
				_record_solid(str(feature["name"]), "prop", at, Vector2(radius, radius), 0.0)
			"mast":
				var height := float(feature["height"])
				var holder := StaticBody3D.new()
				holder.collision_layer = 1
				node.add_child(holder)
				var pole := SuperEgg.build_part(Vector3(0.1, height * 0.5, 0.1), LogHouse.LOG_COLORS[2], 4.0, 4.0)
				pole.position.y = height * 0.5
				holder.add_child(pole)
				CollisionPolicy.add_box(holder, pole, Vector3(0.2, height, 0.2), pole.position, Basis(), false)
				# A wind vane and a streamer: Elin reads the weather from them.
				var vane := SuperEgg.build_part(Vector3(0.5, 0.08, 0.02), Color(0.72, 0.3, 0.2), 4.0, 4.0)
				vane.position = Vector3(0.45, height - 0.2, 0)
				holder.add_child(vane)
				CollisionPolicy.mark_decorative(vane)
				_record_solid(str(feature["name"]), "prop", at, Vector2(0.3, 0.3), 0.0)


## Solveig's winter-goods frontage. The displayed Toboggan is built from the
## exact catalog geometry used in hand and inventory.
func _build_winter_merchant() -> void:
	var position_2d := _center + SnowPlan.WINTER_STALL
	var yaw := atan2(SnowPlan.YARD_CENTER.x - SnowPlan.WINTER_STALL.x, SnowPlan.YARD_CENTER.y - SnowPlan.WINTER_STALL.y)
	# Face the yard squarely rather than at a skew angle.
	yaw = PI * 0.5 * roundf(yaw / (PI * 0.5))
	var stall_data := TownProps.build_stall(Color(0.31, 0.38, 0.58))
	var stall := stall_data["body"] as StaticBody3D
	stall.name = "WinterGoodsStall"
	stall.position = Vector3(position_2d.x, _ground(position_2d), position_2d.y)
	stall.rotation.y = yaw
	add_child(stall)
	_record_solid("WinterGoodsStall", "stall", SnowPlan.WINTER_STALL, Vector2(1.5, 0.9), yaw)
	_layout_facing.append({"name": "WinterGoodsStall", "kind": "stall", "pos": SnowPlan.WINTER_STALL, "dir": _plan_direction(yaw, Vector2(0, 1))})
	var display := TobogganHelm.build_visual(1.0)
	display.name = "DisplayToboggan"
	display.position = Vector3(0.0, float(stall_data["counter_y"]) + 0.08, 0.0)
	stall.add_child(display)
	var vendor: Node3D = NPC_SCENE.instantiate()
	vendor.set_terrain_reference(_terrain)
	vendor.stationary = true
	vendor.is_vendor = true
	vendor.display_name = "Solveig Woolcap"
	vendor.shop_category = "snow"
	var lines: Array[String] = [
		"Every Toboggan has a double cuff. The two that came back with frost inside were single.",
		"Astrid's rye and Anja's berries sit at the end of my board. Neither of them has a stall.",
	]
	vendor.vendor_lines = lines
	VillagerAppearance.apply_profile(vendor, IDENTITIES.size() + 1, 4, true, WINTER_APPEARANCE)
	var layout := TownProps.vendor_layout(position_2d, yaw)
	var vendor_position := layout["position"] as Vector2
	vendor.position = Vector3(vendor_position.x, _ground(vendor_position), vendor_position.y)
	vendor.facing_degrees = layout["facing_degrees"] as float
	add_child(vendor)


func _build_lamps() -> void:
	for spot: Vector2 in SnowPlan.LAMPS:
		var world := _center + spot
		var lantern := TownProps.build_lantern()
		lantern.position = Vector3(world.x, _ground(world), world.y)
		add_child(lantern)
		_record_solid("Lamp", "prop", spot, Vector2(0.2, 0.2), 0.0)


func _build_windbreak() -> void:
	var grove_rng := RandomNumberGenerator.new()
	grove_rng.seed = 90210
	for grove: Dictionary in SnowPlan.PINE_GROVES:
		var centre: Vector2 = grove["center"]
		var placed := 0
		var attempts := 0
		while placed < int(grove["count"]) and attempts < 60:
			attempts += 1
			var angle := grove_rng.randf_range(0.0, TAU)
			var distance := sqrt(grove_rng.randf()) * float(grove["radius"])
			var spot := centre + Vector2(cos(angle), sin(angle)) * distance
			if not _pine_spot_is_clear(spot):
				continue
			var world := _center + spot
			var tree := NatureProps.build_pine_tree(grove_rng.randf_range(6.5, 10.5), ElementPalette.SNOW_BODY)
			tree.position = Vector3(world.x, _ground(world), world.y)
			tree.rotation.y = grove_rng.randf_range(0.0, TAU)
			add_child(tree)
			_record_solid("Pine", "tree", spot, Vector2(0.5, 0.5), 0.0)
			placed += 1


## A pine never stands on a way, within 4 m of a building or in the yard.
func _pine_spot_is_clear(spot: Vector2) -> bool:
	for way: Dictionary in SnowPlan.WAYS:
		var points: Array = way["points"]
		for i in points.size() - 1:
			var closest := Geometry2D.get_closest_point_to_segment(spot, points[i], points[i + 1])
			if spot.distance_to(closest) < float(way["width"]) * 0.5 + 2.5:
				return false
	for blob in [[SnowPlan.YARD_CENTER, SnowPlan.YARD_RADII], [SnowPlan.PLAZA_CENTER, SnowPlan.PLAZA_RADII]]:
		var offset: Vector2 = spot - (blob[0] as Vector2)
		var radii: Vector2 = blob[1]
		if Vector2(offset.x / (radii.x + 2.0), offset.y / (radii.y + 2.0)).length() < 1.0:
			return false
	for building: Dictionary in _layout_solids:
		if str(building["kind"]) != "building":
			continue
		var at: Vector2 = building["center"]
		var half: Vector2 = building["half"]
		var yaw: float = building["yaw"]
		var offset := spot - at
		var local := Vector2(offset.x * cos(yaw) - offset.y * sin(yaw), offset.x * sin(yaw) + offset.y * cos(yaw))
		if absf(local.x) < half.x + 4.0 and absf(local.y) < half.y + 4.0:
			return false
	return true


# ---------------------------------------------------------------------------
# People
# ---------------------------------------------------------------------------

func _build_residents() -> void:
	for resident: String in RESIDENT_IDENTITY.keys():
		if not SnowPlan.HOMES.has(resident):
			continue
		var home: Dictionary = SnowPlan.HOMES[resident]
		_spawn_villager(_center + (home["at"] as Vector2), int(RESIDENT_IDENTITY[resident]), resident)


## Local plan entries converted to world coordinates for NPC.
func _world_schedule(local_entries: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for local_entry: Dictionary in local_entries:
		var converted := local_entry.duplicate(true)
		converted["at"] = _center + (local_entry["at"] as Vector2)
		var route: Array[Vector2] = []
		for local_point in local_entry.get("route", []):
			var point: Vector2 = local_point
			route.append(_center + point)
		converted["route"] = route
		result.append(converted)
	return result


func _spawn_villager(pos: Vector2, index: int, resident: String = "") -> void:
	var npc: Node3D = NPC_SCENE.instantiate()
	npc.set_terrain_reference(_terrain)
	var identity: Dictionary = IDENTITIES[index]
	npc.display_name = identity["name"]
	var lines: Array[String] = []
	lines.assign(identity["lines"])
	npc.talk_lines = lines
	var gender_index: int = _gender_index_through(index, bool(identity["female"]))
	VillagerAppearance.apply_profile(npc, index, gender_index, bool(identity["female"]), WINTER_APPEARANCE)
	npc.wander_boundary_center = _terrain.get_village_center()
	npc.wander_boundary_radius = _terrain.get_village_radius() - 8.0
	npc.position = Vector3(pos.x,_terrain.get_mesh_height(pos.x,pos.y),pos.y)
	if SnowPlan.DAILY_SCHEDULES.has(resident):
		npc.call("configure_daily_schedule", _world_schedule(SnowPlan.DAILY_SCHEDULES[resident]))
	add_child(npc)





func _build_fishing_camp() -> void:
	var hole: Vector2 = _terrain.get_fishing_hole_center()
	var ice_y: float = _terrain.get_ice_level()
	var fisher_pos := hole + Vector2(3.8, 0.0)
	var hut_pos := hole + Vector2(7.0,1.5)
	var hut_spec := {
		"name": "IvarsIceHut", "cells": Vector2(1, 1), "floors": 1, "log_color": LogHouse.LOG_COLORS[3],
		"openings": [{"wall": "front", "x": 0.0, "width": 1.2, "bottom": 0.0, "top": LogHouse.DOOR_TOP, "kind": "door", "leaves": 1}],
	}
	var hut := LogHouse.build(hut_spec)
	hut.position = Vector3(hut_pos.x,ice_y,hut_pos.y)
	var hut_to_fisher: Vector2 = fisher_pos - hut_pos
	# The hut door is local -Z, so its yaw is the negated target heading.
	hut.rotation.y = atan2(-hut_to_fisher.x, -hut_to_fisher.y)
	add_child(hut)
	var fisher: Node3D = NPC_SCENE.instantiate()
	fisher.set_terrain_reference(_terrain)
	fisher.fixed_ground_y = ice_y + 0.08
	fisher.display_name = "Ivar"
	fisher.stationary = true
	VillagerAppearance.apply_profile(fisher, IDENTITIES.size(), 3, false, WINTER_APPEARANCE)
	var fisher_to_hole: Vector2 = hole - fisher_pos
	fisher.facing_degrees = rad_to_deg(atan2(fisher_to_hole.x, fisher_to_hole.y))
	var lines: Array[String] = [
		"I clear the hole before dawn. By noon it has a skin again.",
		"The hut is a windbreak and a place for my bait. I sleep at home, next to a stove, like a person.",
	]
	fisher.talk_lines = lines
	fisher.position = Vector3(fisher_pos.x,ice_y+0.08,fisher_pos.y)
	add_child(fisher)
	# The target sits below the ice opening. NPC owns the articulated rod and
	# computes its line from the live rod tip every frame.
	# The rod/line are world-space geometry parented to current_scene. During
	# this village's _ready(), that root is still constructing its children;
	# defer the gear creation one frame so the three add_child calls are legal.
	fisher.call_deferred("equip_fishing_rod",Vector3(hole.x,ice_y-1.1,hole.y))


func _gender_index_through(population_index: int, female: bool) -> int:
	var gender_index := 0
	for i in population_index:
		if bool(IDENTITIES[i]["female"]) == female:
			gender_index += 1
	return gender_index
