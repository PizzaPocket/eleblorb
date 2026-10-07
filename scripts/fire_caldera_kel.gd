class_name FireCalderaKel
extends RefCounted

## The Kel foundry, armory and residence (fire_caldera_buildings.md, section 4;
## Daro, Vesa and Ruun). The city's working foundry: Daro's alloys, Vesa's
## arms and armour, Ruun learning; visitors come only to the armory gallery.
##
## Its own idea: a temper-colour facade. Heated steel takes oxide colours
## (straw, bronze, purple, blue) that a smith reads to judge its temper; Kel is
## clad in heat-tinted steel panels graded along the building from straw at the
## west to blue at the east, its makers' craft on its own walls. Over the hall,
## a sawtooth north-light roof glazed in cast rolled glass in the forge
## colours, garnet and amber.
##
## Plan (brief, audited): the front row (8 m, to the promenade) holds the
## armory gallery (west) and the descent hall with the lift and the protected
## ramp's head (east); the back row (7 m, to the service loop) holds the
## workshop (west), the receiving bay and the alloy store. The site rises 1.25
## m to the service loop, so the receiving bay is a loading dock at the loop's
## level: its door opens straight onto the yard, an overhead handling rail runs
## from the yard through the wall over the dock, and a ramp and the bay's
## lower strip take goods down to the workshop and the descent hall. The alloy
## store sits at the dock's level behind its forged door.
##
## The residence is its own small house on the roof of the back row, reached
## by a covered ramp-bridge from the quiet uphill ground on the east, so the
## family never passes through the foundry. Local +Z faces the promenade.

const SIZE := Vector2(19.0, 15.0)
const STOREY := 5.0
const DOCK := 1.25
const RESIDENCE := 5.2
const BACK_ROW := -0.5
const PARTITION := FireCalderaBuildings.BASALT_PARTITION
const INNER_DOOR_WIDTH := FireCalderaBuildings.INNER_DOOR_WIDTH
const INNER_DOOR_HEIGHT := FireCalderaBuildings.INNER_DOOR_HEIGHT
const GARNET := Color(0.60, 0.12, 0.18, 0.62)
const AMBER := Color(0.95, 0.58, 0.16, 0.6)
const IRON := CalderaShell.STEEL_BLUED
const REFRACTORY := FireCalderaRenewal.REFRACTORY
const FLOOR := Color(0.30, 0.28, 0.27)
## The temper colours, straw to blue.
const TEMPER: Array[Color] = [Color(0.80, 0.68, 0.40), Color(0.66, 0.44, 0.24), Color(0.48, 0.26, 0.42), Color(0.20, 0.27, 0.52)]
const DOCK_DOOR_X := 2.3
const DESCENT_DOOR_X := 2.7
const STAFF_DOOR_X := -5.0
const HOME_DOOR_Z := -4.0
const BED_XS: Array[float] = [3.3]
const BED_ZS: Array[float] = [-6.6, -5.1, -3.6]


## The temper colour at x across the building.
static func temper(x: float) -> Color:
	var t := clampf((x + SIZE.x * 0.5) / SIZE.x, 0.0, 1.0) * float(TEMPER.size() - 1)
	var i := mini(int(t), TEMPER.size() - 2)
	return TEMPER[i].lerp(TEMPER[i + 1], t - float(i))


static func _steel_bays(wall_start_x: float, along_sign: float, edges: Array, kinds: Dictionary) -> Array:
	var bays := []
	var from := 0.0
	for to: float in edges:
		var mid := wall_start_x + along_sign * (from + to) * 0.5
		var bay := {"to": to, "kind": "stone", "band": -1, "steel": temper(mid)}
		if kinds.has(to):
			bay.merge(kinds[to], true)
		bays.append(bay)
		from = to
	return bays


static func spec_hall() -> Dictionary:
	var clear := CalderaShell.CLEAR_GLASS
	return {
		"size": SIZE, "stained": [GARNET, AMBER], "storey": STOREY, "roof": false, "transom": false,
		"walls": {
			# The gallery's glass to the promenade and its door; the descent
			# hall's steel.
			"front": _steel_bays(-SIZE.x * 0.5, 1.0, [2.5, 5.0, 7.6, 10.0, 14.5, 19.0], {
				2.5: {"kind": "glass", "tint": clear}, 5.0: {"kind": "glass", "tint": clear},
				7.6: {"kind": "door", "label": "gallery door"}, 10.0: {"kind": "glass", "tint": clear},
			}),
			# Against the uphill ground: steel, the dock's door at the yard's level.
			"back": _steel_bays(-SIZE.x * 0.5, 1.0, [4.5, 9.0, 10.5, 13.1, 15.0, 19.0], {
				13.1: {"kind": "door", "sill": DOCK, "clear": 2.4, "height": 2.3, "label": "dock door"},
			}),
			"west": _steel_bays(-SIZE.x * 0.5, 0.0, [5.0, 10.0, 12.5, 15.0], {
				12.5: {"kind": "glass", "tint": clear}, 15.0: {"kind": "glass", "tint": clear},
			}),
			"east": _steel_bays(SIZE.x * 0.5, 0.0, [5.0, 10.0, 15.0], {}),
		},
	}


static func spec_residence() -> Dictionary:
	var clear := CalderaShell.CLEAR_GLASS
	var smoky := CalderaShell.SMOKY_GLASS
	return {
		"size": Vector2(8.0, 6.5), "offset": Vector2(5.5, -4.25), "stained": [GARNET, AMBER], "storey": 3.4,
		"pitch": 0.0, "transom": false, "overhang": {"east": 0.0},
		"walls": {
			"front": _steel_bays(1.5, 1.0, [4.0, 8.0], {4.0: {"kind": "glass", "tint": smoky}}),
			# Over the yard toward the crater rim.
			"back": _steel_bays(1.5, 1.0, [2.7, 5.4, 8.0], {2.7: {"kind": "glass", "tint": clear}, 5.4: {"kind": "glass", "tint": clear}, 8.0: {"kind": "glass", "tint": clear}}),
			"west": _steel_bays(1.5, 0.0, [3.2, 6.5], {}),
			"east": _steel_bays(9.5, 0.0, [2.2, 4.8, 6.5], {4.8: {"kind": "door", "label": "home door"}}),
		},
	}


static func build(parent: Node3D, entry: Dictionary, line: Dictionary) -> StaticBody3D:
	var body := CalderaShell.build(parent, entry, float(line["datum"]), spec_hall())
	_floors(body)
	_partitions(body)
	_sawtooth(body)
	_crane(body)
	var home := StaticBody3D.new()
	home.name = "KelHome"
	home.collision_layer = 1
	home.collision_mask = 0
	home.position = Vector3(0, RESIDENCE, 0)
	body.add_child(home)
	CalderaShell.add_volume(home, spec_residence())
	_residence(home)
	_bridge(body)
	_gallery(body)
	_workshop(body)
	_descent(body)
	_lights(body, home)
	_temper_panels(body)
	return body


## Every steel panel takes the temper shader: its place in the straw-to-blue
## sweep along the building, and within it the bands and the angle-dependent
## shift that heat-tinted steel shows.
static func _temper_panels(body: StaticBody3D) -> void:
	var material := ShaderMaterial.new()
	material.shader = _temper_shader()
	for panel in body.find_children("*", "MeshInstance3D", true, false):
		if not panel.has_meta("steel_panel"):
			continue
		var mesh := panel as MeshInstance3D
		var x := (body.global_transform.affine_inverse() * mesh.global_position).x
		mesh.material_override = material
		mesh.set_instance_shader_parameter("base", clampf((x + SIZE.x * 0.5) / SIZE.x, 0.0, 1.0))


static func _temper_shader() -> Shader:
	var shader := Shader.new()
	shader.code = """
shader_type spatial;

instance uniform float base = 0.0;
uniform vec3 straw : source_color = vec3(0.80, 0.68, 0.40);
uniform vec3 bronze : source_color = vec3(0.66, 0.42, 0.22);
uniform vec3 purple : source_color = vec3(0.46, 0.24, 0.44);
uniform vec3 blue : source_color = vec3(0.20, 0.28, 0.54);

varying vec3 world;

void vertex() {
	world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

vec3 temper(float t) {
	t = clamp(t, 0.0, 1.0) * 3.0;
	if (t < 1.0) return mix(straw, bronze, t);
	if (t < 2.0) return mix(bronze, purple, t - 1.0);
	return mix(purple, blue, t - 2.0);
}

void fragment() {
	// Heat-tinted steel: the panel's own temper along the building, banded
	// by height as the heat crept up it, shifting with the angle of view.
	float bands = sin(world.y * 2.1 + sin(world.x * 0.9 + world.z * 0.7) * 1.3) * 0.07;
	float angle = (1.0 - abs(dot(NORMAL, VIEW))) * 0.18;
	ALBEDO = temper(base * 0.85 + 0.05 + bands + angle);
	METALLIC = 0.78;
	ROUGHNESS = 0.28;
}
"""
	return shader


# ---------------------------------------------------------------------------
# Floors, partitions, roof.
# ---------------------------------------------------------------------------

static func _floors(body: StaticBody3D) -> void:
	var levels: Array = FireCalderaPlan.plot("KEL")["levels"]
	var dock: Rect2 = levels[0]["rect"]
	var store: Rect2 = levels[1]["rect"]
	var ramp: Rect2 = levels[2]["rect"]
	FireCalderaOren._block(body, "LoadingDock", Vector3(dock.get_center().x, DOCK * 0.5, dock.get_center().y), Vector3(dock.size.x - 0.2, DOCK, dock.size.y - 0.2), FLOOR)
	FireCalderaOren._block(body, "AlloyStoreFloor", Vector3(store.get_center().x, DOCK * 0.5, store.get_center().y), Vector3(store.size.x - 0.2, DOCK, store.size.y - 0.2), FLOOR)
	FireCalderaOren._wedge(body, "DockRamp", ramp.position, ramp.end, DOCK, 0.0, false, FLOOR)
	# The dock's edge: a steel rail where it stands above the strip.
	CalderaShell._beam(body, Vector3(dock.position.x + 0.1, DOCK + 1.0, dock.end.y), Vector3(ramp.position.x - 0.05, DOCK + 1.0, dock.end.y), Vector2(0.05, 0.05), IRON)
	CalderaShell._beam(body, Vector3(ramp.end.x + 0.05, DOCK + 1.0, dock.end.y), Vector3(dock.end.x - 0.1, DOCK + 1.0, dock.end.y), Vector2(0.05, 0.05), IRON)
	# The roof of the back row: the floor of the residence above.
	FireCalderaOren._block(body, "BackRowRoof", Vector3(4.5, STOREY + 0.1, (BACK_ROW - SIZE.y * 0.5) * 0.5), Vector3(10.2, 0.2, -BACK_ROW + SIZE.y * 0.5 + 0.2), FLOOR.lightened(0.05))


static func _partitions(body: StaticBody3D) -> void:
	var hx := SIZE.x * 0.5
	var hz := SIZE.y * 0.5
	# Between the rows: the gallery's staff door into the workshop; the descent
	# hall's door from the receiving bay's lower strip; the store raised.
	_wall(body, Vector2(-hx, BACK_ROW), Vector2(-0.5, BACK_ROW), 0.0, [[STAFF_DOOR_X, "staff door", INNER_DOOR_WIDTH]])
	_wall(body, Vector2(-0.5, BACK_ROW), Vector2(5.5, BACK_ROW), 0.0, [[DESCENT_DOOR_X, "descent door", INNER_DOOR_WIDTH]])
	_wall(body, Vector2(5.5, BACK_ROW), Vector2(hx, BACK_ROW), DOCK, [])
	# The gallery and the descent hall: no door; customers stay in the gallery.
	_wall(body, Vector2(0.5, BACK_ROW), Vector2(0.5, hz), 0.0, [])
	# Workshop and receiving: a wide door on the lower strip for goods.
	_wall(body, Vector2(-0.5, -hz), Vector2(-0.5, BACK_ROW), 0.0, [[-1.6, "workshop goods door", 2.0]])
	# Receiving and the alloy store: the forged door at the dock's level.
	_wall(body, Vector2(5.5, -hz), Vector2(5.5, -5.9), 0.0, [])
	_wall(body, Vector2(5.5, -5.9), Vector2(5.5, -4.1), DOCK, [[-5.0, "alloy store door", INNER_DOOR_WIDTH]])
	_wall(body, Vector2(5.5, -4.1), Vector2(5.5, BACK_ROW), 0.0, [])


## A stone partition from `from` to `to` on a floor at `base`, up to the roof,
## with superellipse doors ([position, label, width]).
static func _wall(body: StaticBody3D, from: Vector2, to: Vector2, base: float, doors: Array) -> void:
	var along_x := absf(to.x - from.x) > absf(to.y - from.y)
	var start := from.x if along_x else from.y
	var finish := to.x if along_x else to.y
	var fixed := from.y if along_x else from.x
	var height := STOREY - base
	var cursor := start
	for door: Array in doors:
		var at: float = door[0]
		var width: float = door[2]
		var low := at - width * 0.5 - 0.3
		var high := at + width * 0.5 + 0.3
		if low - cursor > 0.05:
			_slab(body, cursor, low, fixed, along_x, base, height)
		var mid := (low + high) * 0.5
		var origin := Vector3(mid, base, fixed) if along_x else Vector3(fixed, base, mid)
		CalderaShell.door_opening(body, origin, 0.0 if along_x else PI * 0.5, high - low, height, 0.18, width, INNER_DOOR_HEIGHT, 1, PARTITION, IRON)
		var point := Vector2(at, fixed) if along_x else Vector2(fixed, at)
		var normal := Vector2(0, 1) if along_x else Vector2(1, 0)
		for direction: Vector2 in [normal, -normal]:
			ClearZones.add(body, str(door[1]), "door", point, direction, 0.0, 1.0, width * 0.5, base + 0.05, base + 1.9)
		cursor = high
	if finish - cursor > 0.05:
		_slab(body, cursor, finish, fixed, along_x, base, height)
	if base > 0.0:
		_slab(body, start, finish, fixed, along_x, 0.0, base)


static func _slab(body: StaticBody3D, s0: float, s1: float, fixed: float, along_x: bool, base: float, height: float) -> void:
	var size := Vector3(s1 - s0, height, 0.18) if along_x else Vector3(0.18, height, s1 - s0)
	var at := Vector3((s0 + s1) * 0.5, base + height * 0.5, fixed) if along_x else Vector3(fixed, base + height * 0.5, (s0 + s1) * 0.5)
	FireCalderaOren._block(body, "Partition", at, size, PARTITION)


## The sawtooth roof over the front row and the workshop: each tooth a steel
## slope rising toward the back and a vertical face of cast rolled glass,
## garnet shading to amber, between steel mullions.
static func _sawtooth(body: StaticBody3D) -> void:
	var rise := 1.4
	var hx := SIZE.x * 0.5
	var teeth := [
		[-hx, hx, SIZE.y * 0.5, 3.5], [-hx, hx, 3.5, BACK_ROW],
		[-hx, -0.5, BACK_ROW, -4.0], [-hx, -0.5, -4.0, -SIZE.y * 0.5],
	]
	for tooth: Array in teeth:
		var x0: float = tooth[0]
		var x1: float = tooth[1]
		var low_z: float = tooth[2]
		var high_z: float = tooth[3]
		var depth := low_z - high_z
		var angle := atan2(rise, depth)
		var slab := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(x1 - x0 + 0.3, 0.16, sqrt(depth * depth + rise * rise) + 0.2)
		slab.mesh = box
		slab.material_override = SolidModel.material(TEMPER[3].darkened(0.4), 0.4, 0.6)
		slab.position = Vector3((x0 + x1) * 0.5, STOREY + rise * 0.5 + 0.08, (low_z + high_z) * 0.5)
		slab.rotation.x = angle
		body.add_child(slab)
		CollisionPolicy.add_box(body, slab, box.size, slab.position, Basis(Vector3.RIGHT, angle), true)
		var panes := int((x1 - x0) / 1.6)
		for i in panes:
			var a := lerpf(x0, x1, float(i) / float(panes))
			var b := lerpf(x0, x1, float(i + 1) / float(panes))
			var tint := GARNET.lerp(AMBER, float(i) / float(maxi(panes - 1, 1)))
			CalderaShell._pane(body, "SawtoothGlass", Vector3((a + b) * 0.5, STOREY + rise * 0.5, high_z), Vector2((b - a) * 0.5 - 0.04, rise * 0.5 - 0.02), 0.0, tint)
			CalderaShell._metal(body, Vector3(b, STOREY + rise * 0.5, high_z), Vector3(0.08, rise, 0.1), IRON, false)


## The overhead handling rail: two runway girders from inside the dock out
## through the back wall over the yard on two columns, a travelling bridge
## with its hoist and hook.
static func _crane(body: StaticBody3D) -> void:
	var y := 4.4
	var z_in := -1.0
	var z_out := -10.4
	for x: float in [DOCK_DOOR_X - 1.4, DOCK_DOOR_X + 1.4]:
		CalderaShell._beam(body, Vector3(x, y, z_in), Vector3(x, y, z_out), Vector2(0.3, 0.2), IRON)
		CalderaShell._metal(body, Vector3(x, y * 0.5, z_out + 0.2), Vector3(0.24, y, 0.24), IRON, true)
	CalderaShell._metal(body, Vector3(DOCK_DOOR_X, y - 0.25, -6.0), Vector3(3.2, 0.28, 0.3), TEMPER[1], false)
	CalderaShell._metal(body, Vector3(DOCK_DOOR_X, y - 0.6, -6.0), Vector3(0.4, 0.4, 0.4), IRON, false)
	CalderaShell._beam(body, Vector3(DOCK_DOOR_X, y - 0.8, -6.0), Vector3(DOCK_DOOR_X, DOCK + 1.6, -6.0), Vector2(0.03, 0.03), IRON)
	CalderaFurniture.piece(body, Vector3(0.1, 0.14, 0.05), IRON, Vector3(DOCK_DOOR_X, DOCK + 1.45, -6.0), 0.0, false, 2.2)


# ---------------------------------------------------------------------------
# The residence and its covered ramp-bridge.
# ---------------------------------------------------------------------------

## The home on the roof: a sleeping room to the west with a lava bed for each
## of the three, a receiving room to the east by the door with Ruun's bench,
## where the tools come back to the wrong sibling's rack.
static func _residence(home: StaticBody3D) -> void:
	_wall_home(home)
	for z in BED_ZS:
		CalderaFurniture.piece(home, Vector3(1.1, 0.28, 0.5), CalderaShell.BASALT, Vector3(BED_XS[0], 0.28, z), 0.0, true, 4.0)
		FireCalderaBuildings._glow(home, "BedLava", Vector3(0.95, 0.02, 0.38), Vector3(BED_XS[0], 0.55, z), Color(1.0, 0.42, 0.08))
	CalderaFurniture.concealed_light(home, Vector3(3.3, 0.9, -5.1), Color(1.0, 0.55, 0.22), 0.9, 4.0)
	# Ruun's bench and the three racks above it, a tool in the wrong one.
	CalderaFurniture.table(home, Vector3(8.1, 0.0, -1.75), 0.0, 2.2, 0.7)
	for i in 3:
		var rack_x := 7.3 + 0.8 * float(i)
		CalderaShell._metal(home, Vector3(rack_x, 1.6, -1.25), Vector3(0.6, 0.04, 0.06), TEMPER[i + 1], false)
		for j in 3:
			var wrong := i == 0 and j == 2
			CalderaFurniture.piece(home, Vector3(0.02, 0.16, 0.02), TEMPER[2 if wrong else i + 1].darkened(0.1), Vector3(rack_x - 0.2 + 0.2 * float(j), 1.42, -1.3), 0.0, false, 6.0)
	for x: float in [6.4, 7.7]:
		CalderaFurniture.piece(home, Vector3(0.34, 0.22, 0.3), CalderaShell.BASALT.lightened(0.06), Vector3(x, 0.22, -6.2), 0.0, true, SuperEgg.EPSILON_SOFT)


static func _wall_home(home: StaticBody3D) -> void:
	# The sleeping room and the receiving room, one door between, near the front.
	var low := -2.2 - INNER_DOOR_WIDTH * 0.5 - 0.3
	var high := -2.2 + INNER_DOOR_WIDTH * 0.5 + 0.3
	var height := 3.4
	FireCalderaOren._block(home, "Partition", Vector3(5.5, height * 0.5, (-7.5 + low) * 0.5), Vector3(0.18, height, low + 7.5), PARTITION)
	CalderaShell.door_opening(home, Vector3(5.5, 0.0, (low + high) * 0.5), PI * 0.5, high - low, height, 0.18, INNER_DOOR_WIDTH, INNER_DOOR_HEIGHT, 1, PARTITION, IRON)
	FireCalderaOren._block(home, "Partition", Vector3(5.5, height * 0.5, (high - 1.0) * 0.5), Vector3(0.18, height, -1.0 - high), PARTITION)
	for direction: Vector2 in [Vector2(1, 0), Vector2(-1, 0)]:
		ClearZones.add(home, "bedroom door", "door", Vector2(5.5, -2.2), direction, 0.0, 1.0, INNER_DOOR_WIDTH * 0.5, 0.05, 1.9)


## The covered ramp-bridge from the uphill ground on the east up to the home's
## door: a cast ramp, a landing on steel posts, a roof on posts over both.
static func _bridge(body: StaticBody3D) -> void:
	var levels: Array = FireCalderaPlan.plot("KEL")["levels"]
	var ramp: Rect2 = levels[3]["rect"]
	var head: Rect2 = levels[4]["rect"]
	var foot := float(levels[3]["from"])
	FireCalderaOren._wedge(body, "HomeRamp", ramp.position, ramp.end, foot, RESIDENCE, false, FLOOR)
	FireCalderaOren._block(body, "HomeLanding", Vector3(head.get_center().x, RESIDENCE - 0.1, head.get_center().y), Vector3(head.size.x, 0.2, head.size.y), FLOOR)
	for z: float in [head.position.y + 0.15, head.end.y - 0.15]:
		CalderaShell._metal(body, Vector3(head.end.x - 0.15, (RESIDENCE - 0.2) * 0.5, z), Vector3(0.14, RESIDENCE - 0.2, 0.14), IRON, true)
	# The cover: a steel roof following the ramp at 2.6 m, on posts.
	var x0 := ramp.position.x - 0.1
	var x1 := ramp.end.x + 0.1
	var roof_from := Vector3((x0 + x1) * 0.5, foot + 2.6, ramp.position.y)
	var roof_to := Vector3((x0 + x1) * 0.5, RESIDENCE + 2.6, ramp.end.y)
	var cover := CalderaShell._beam(body, roof_from, roof_to, Vector2(0.08, x1 - x0 + 0.3), temper(9.5))
	cover.material_override = SolidModel.material(temper(9.5), 0.32, 0.75)
	CalderaShell._metal(body, Vector3((x0 + x1) * 0.5, RESIDENCE + 2.6, head.get_center().y), Vector3(x1 - x0 + 0.3, 0.08, head.size.y), temper(9.5), false)
	for i in 4:
		var t := float(i) / 3.0
		var z := lerpf(ramp.position.y + 0.2, ramp.end.y, t)
		var y := lerpf(foot, RESIDENCE, t)
		for x: float in [x0, x1]:
			CalderaShell._metal(body, Vector3(x, y + 1.3, z), Vector3(0.08, 2.6, 0.08), IRON, false)
	var holder := MeshInstance3D.new()
	body.add_child(holder)
	CollisionPolicy.add_box(body, holder, Vector3(0.08, 1.1, ramp.size.y), Vector3(x1, (foot + RESIDENCE) * 0.5 + 0.55, ramp.get_center().y), Basis(Vector3.RIGHT, -atan2(RESIDENCE - foot, ramp.size.y)), false)


# ---------------------------------------------------------------------------
# The rooms.
# ---------------------------------------------------------------------------

## The armory gallery: finished armour on stands inside thick cast-glass
## vitrines lit from below, so each piece glows as if fresh from the forge;
## forged weapon racks behind glass on the west wall; Daro's counter facing
## the door and her fitting stool.
static func _gallery(body: StaticBody3D) -> void:
	var glass := SolidModel.material(Color(0.86, 0.90, 0.92, 0.18), 0.04, 0.05)
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	for x: float in [-7.6, -5.6, -0.9]:
		var z := 4.2
		CalderaFurniture.piece(body, Vector3(0.45, 0.25, 0.45), REFRACTORY, Vector3(x, 0.25, z), 0.0, true, 7.0)
		FireCalderaBuildings._glow(body, "VitrineGlow", Vector3(0.38, 0.01, 0.38), Vector3(x, 0.51, z), Color(1.0, 0.55, 0.2))
		var case := CalderaFurniture.piece(body, Vector3(0.44, 0.9, 0.44), Color(0.86, 0.90, 0.92, 0.18), Vector3(x, 1.4, z), 0.0, false, 9.0)
		case.material_override = glass
		# A suit of armour on its stand: torso, shoulders, helm.
		var tone := temper(x).lightened(0.15)
		CalderaShell._metal(body, Vector3(x, 0.9, z), Vector3(0.05, 0.8, 0.05), IRON, false)
		var polished := SolidModel.material(tone, 0.2, 0.9)
		var parts: Array[MeshInstance3D] = [CalderaFurniture.piece(body, Vector3(0.2, 0.28, 0.13), tone, Vector3(x, 1.45, z), 0.0, false, 3.0), CalderaFurniture.piece(body, Vector3(0.11, 0.13, 0.12), tone, Vector3(x, 1.95, z), 0.0, false, 2.4)]
		for side: float in [-1.0, 1.0]:
			parts.append(CalderaFurniture.piece(body, Vector3(0.1, 0.07, 0.12), tone, Vector3(x + side * 0.24, 1.68, z), 0.0, false, 2.4))
		for part in parts:
			part.material_override = polished
		CalderaFurniture.concealed_light(body, Vector3(x, 0.7, z), Color(1.0, 0.6, 0.3), 0.4, 2.0)
	# Weapon racks behind glass along the west wall's steel.
	for i in 2:
		var z := -0.0 + 1.0 + 2.6 * float(i)
		CalderaShell._metal(body, Vector3(-9.15, 1.6, z + 0.6), Vector3(0.08, 2.4, 1.6), IRON, false)
		for j in 4:
			CalderaShell._beam(body, Vector3(-9.0, 0.6, z - 0.1 + 0.4 * float(j)), Vector3(-9.0, 2.5, z + 0.1 + 0.4 * float(j)), Vector2(0.03, 0.06), TEMPER[j % 4].lightened(0.2))
		var front := CalderaFurniture.piece(body, Vector3(0.02, 1.2, 0.8), Color(0.86, 0.90, 0.92, 0.18), Vector3(-8.8, 1.6, z + 0.6), 0.0, false, 9.0)
		front.material_override = glass
	# Daro's counter facing the door, her fitting stool beside it.
	CalderaFurniture.counter(body, Vector3(-1.8, 0.0, 1.6), PI, 2.4)
	CalderaShell._metal(body, Vector3(-3.6, 0.3, 0.9), Vector3(0.08, 0.6, 0.08), IRON, false)
	CalderaFurniture.piece(body, Vector3(0.2, 0.05, 0.2), CalderaFurniture.SILICA, Vector3(-3.6, 0.62, 0.9), 0.0, true, SuperEgg.EPSILON_SOFT)
	FireCalderaBuildings._marker(body, "DaroStand", Vector3(-1.8, 0.0, 0.7), 0.0)


## The workshop: Vesa's power hammer, press, welding table, grinder bank and
## quench tank; a refractory forge with its open fire; Ruun's finishing bench
## with polishing wheels; Daro's alloy bench with crucibles.
static func _workshop(body: StaticBody3D) -> void:
	# The forge: a refractory hearth with its mouth glowing, a hood above.
	CalderaFurniture.piece(body, Vector3(0.8, 0.5, 0.6), REFRACTORY, Vector3(-8.4, 0.5, -6.6), 0.0, true, 6.0)
	FireCalderaBuildings._glow(body, "ForgeMouth", Vector3(0.35, 0.18, 0.01), Vector3(-8.4, 0.62, -5.99), Color(1.0, 0.5, 0.12))
	CalderaShell._metal(body, Vector3(-8.4, 2.6, -6.6), Vector3(1.4, 0.6, 1.0), IRON, false)
	CalderaShell._metal(body, Vector3(-8.4, 3.9, -6.9), Vector3(0.4, 2.0, 0.4), IRON, false)
	CalderaFurniture.concealed_light(body, Vector3(-8.4, 1.2, -5.6), Color(1.0, 0.5, 0.15), 1.4, 6.0)
	# The power hammer: a tall frame, its ram and anvil.
	CalderaShell._metal(body, Vector3(-6.0, 1.3, -6.7), Vector3(0.9, 2.6, 0.6), TEMPER[0].darkened(0.3), true)
	CalderaShell._metal(body, Vector3(-6.0, 1.2, -6.15), Vector3(0.3, 0.5, 0.4), IRON, false)
	CalderaFurniture.piece(body, Vector3(0.35, 0.4, 0.3), IRON, Vector3(-6.0, 0.4, -5.95), 0.0, true, 6.0)
	# The press, the welding table, the grinder bank.
	CalderaShell._metal(body, Vector3(-3.9, 1.1, -6.8), Vector3(1.0, 2.2, 0.5), TEMPER[1].darkened(0.3), true)
	CalderaFurniture.table(body, Vector3(-4.5, 0.0, -3.6), 0.0, 2.0, 1.0)
	for i in 3:
		CalderaFurniture.piece(body, Vector3(0.14, 0.14, 0.04), CalderaShell.STAINLESS, Vector3(-1.9 + 0.5 * float(i), 1.1, -6.95), 0.0, false, 2.0)
	CalderaShell._metal(body, Vector3(-1.4, 0.45, -6.95), Vector3(1.7, 0.9, 0.5), IRON, true)
	# The oil quench tank.
	CalderaShell._metal(body, Vector3(-7.9, 0.4, -3.4), Vector3(1.2, 0.8, 0.8), IRON, true)
	CalderaFurniture.piece(body, Vector3(0.55, 0.01, 0.35), Color(0.08, 0.07, 0.06), Vector3(-7.9, 0.81, -3.4), 0.0, false, 7.0)
	# Ruun's finishing bench, Daro's alloy bench.
	CalderaFurniture.table(body, Vector3(-7.6, 0.0, -1.2), 0.0, 2.2, 0.7)
	for x: float in [-8.2, -7.6]:
		CalderaFurniture.piece(body, Vector3(0.14, 0.14, 0.03), CalderaFurniture.FIBRE_GREY, Vector3(x, 1.0, -1.2), 0.0, false, 2.0)
	CalderaFurniture.table(body, Vector3(-3.0, 0.0, -1.3), 0.0, 2.2, 0.7)
	for i in 3:
		CalderaFurniture.piece(body, Vector3(0.08, 0.07, 0.08), REFRACTORY, Vector3(-3.6 + 0.5 * float(i), 0.86, -1.3), 0.0, false, 2.4)
	FireCalderaBuildings._marker(body, "VesaStand", Vector3(-6.0, 0.0, -5.0), PI)


## The descent hall: the lift's steel cage and the protected ramp's head, a
## refractory portal with its forged gate, toward the deep forge.
static func _descent(body: StaticBody3D) -> void:
	for corner: Vector2 in [Vector2(6.6, 5.2), Vector2(9.0, 5.2), Vector2(6.6, 7.0), Vector2(9.0, 7.0)]:
		CalderaShell._metal(body, Vector3(corner.x, STOREY * 0.5, corner.y), Vector3(0.12, STOREY, 0.12), IRON, true)
	CalderaShell._metal(body, Vector3(7.8, 0.06, 6.1), Vector3(2.3, 0.12, 1.7), REFRACTORY, false)
	var portal := CalderaFurniture.piece(body, Vector3(1.4, 1.6, 0.4), REFRACTORY, Vector3(5.0, 1.6, 1.0), 0.0, true, 6.0)
	portal.name = "DescentPortal"
	CalderaShell._metal(body, Vector3(5.0, 1.3, 1.42), Vector3(1.6, 2.4, 0.06), IRON, false)
	for i in 4:
		CalderaShell._beam(body, Vector3(4.4 + 0.4 * float(i), 0.2, 1.46), Vector3(4.4 + 0.4 * float(i), 2.4, 1.46), Vector2(0.03, 0.03), TEMPER[i])


static func _lights(body: StaticBody3D, home: StaticBody3D) -> void:
	for at: Vector3 in [Vector3(-5.0, 4.3, 3.5), Vector3(5.0, 4.3, 3.5), Vector3(-5.0, 4.3, -3.5), Vector3(2.5, 4.0, -3.5), Vector3(7.5, 4.0, -3.5)]:
		CalderaFurniture.concealed_light(body, at, CalderaFurniture.LED_WARM, 0.9, 7.0)
	for at: Vector3 in [Vector3(3.5, 2.8, -4.0), Vector3(7.5, 2.8, -3.0)]:
		CalderaFurniture.concealed_light(home, at, CalderaFurniture.LED_WARM, 0.8, 5.0)


## The three lava beds, for the terrain's lava queries.
static func register_lava(body: Node3D, terrain: Node) -> void:
	for z in BED_ZS:
		var world := PackedVector2Array()
		var height := 0.0
		for corner: Vector2 in [Vector2(-0.9, -0.34), Vector2(0.9, -0.34), Vector2(0.9, 0.34), Vector2(-0.9, 0.34)]:
			var at := body.global_transform * Vector3(BED_XS[0] + corner.x, RESIDENCE + 0.55, z + corner.y)
			world.append(Vector2(at.x, at.z))
			height = at.y
		terrain.register_lava_polygon(world, height)
